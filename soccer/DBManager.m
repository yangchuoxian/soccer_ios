//
//  DBManager.m
//  soccer
//
//  Created by 杨逴先 on 15/3/23.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

#import "DBManager.h"
#import "soccer-Swift.h"

@implementation DBManager

- (instancetype)initWithDatabaseFilename:(NSString *)dbFilename {
    self = [super init];
    if (self) {
        // Set the documents directory path to the documentsDirectory property.
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        self.documentsDirectory = [paths objectAtIndex:0];
        
        // Keep the database filename.
        self.databaseFilename = dbFilename;
        
        // Copy the database file into the documents directory if necessary.
        [self copyDatabaseIntoDocumentsDirectory];
    }
    return self;
}

- (void)copyDatabaseIntoDocumentsDirectory {
    // Check if the database file exists in the documents directory.
    NSString *destinationPath = [self.documentsDirectory stringByAppendingPathComponent:self.databaseFilename];
    if (![[NSFileManager defaultManager] fileExistsAtPath:destinationPath]) {
        // The database file does not exist in the documents directory, so copy it from the main bundle now.
        NSString *sourcePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:self.databaseFilename];
        NSError *error;
        [[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destinationPath error:&error];
        
        // Check if any error occurred during copying and display it.
        if (error != nil) {
            NSLog(@"%@", [error localizedDescription]);
        }
    }
}

- (void)compileSQLInjectionFreeStatement:(sqlite3_stmt *)statement fromParameters:(NSArray *)parameters {
    for (SQLParameter *parameter in parameters) {
        int index = (int)(parameter.parameterIndex);
        
        if (parameter.parameterType == ParamTypeInteger) {  // parameter is integer
            sqlite3_bind_int64(statement, index, parameter.parameterIntegerValue);
        } else {    // parameter is string
            if ([parameter.parameterStringValue isKindOfClass:[NSNull class]] ||
                parameter.parameterStringValue == nil) {
                // the string parameter could possibly be NSNull, in that case write "EMPTY" in local database instead
                NSString *stringToIndicateEmpty = @"EMPTY";
                sqlite3_bind_text(statement, index, [stringToIndicateEmpty cStringUsingEncoding:NSUTF8StringEncoding], -1, nil);
            } else {
                sqlite3_bind_text(statement, index, [parameter.parameterStringValue cStringUsingEncoding:NSUTF8StringEncoding], -1, nil);
            }
        }
    }
}

- (void)runQuery:(const char *)query isQueryExecutable:(BOOL)queryExecutable statementParameters:(NSArray *)parameters {
    // Create a sqlite object.
    sqlite3 *sqlite3Database;
    
    // Set the database file path.
    NSString *databasePath = [self.documentsDirectory stringByAppendingPathComponent:self.databaseFilename];
    
    // Initialize the results array.
    if (self.arrResults != nil) {
        [self.arrResults removeAllObjects];
        self.arrResults = nil;
    }
    self.arrResults = [[NSMutableArray alloc] init];
    
    // Initialize the column names array.
    if (self.arrColumnNames != nil) {
        [self.arrColumnNames removeAllObjects];
        self.arrColumnNames = nil;
    }
    self.arrColumnNames = [[NSMutableArray alloc] init];
    
    // Open the database.
    BOOL openDatabaseResult = sqlite3_open([databasePath UTF8String], &sqlite3Database);
    if(openDatabaseResult == SQLITE_OK) {
        // Declare a sqlite3_stmt object in which will be stored the query after having been compiled into a SQLite statement.
        sqlite3_stmt *compiledStatement;
        
        // Load all data from database to memory.
        BOOL prepareStatementResult = sqlite3_prepare_v2(sqlite3Database, query, -1, &compiledStatement, NULL);
        if(prepareStatementResult == SQLITE_OK) {
            // Check if the query is non-executable.
            if (!queryExecutable) {
                // In this case data must be loaded from the database.
                
                // Declare an array to keep the data for each fetched row.
                NSMutableArray *arrDataRow;
                
                [self compileSQLInjectionFreeStatement:compiledStatement fromParameters:parameters];
                
                // Loop through the results and add them to the results array row by row.
                while(sqlite3_step(compiledStatement) == SQLITE_ROW) {
                    // Initialize the mutable array that will contain the data of a fetched row.
                    arrDataRow = [[NSMutableArray alloc] init];
                    
                    // Get the total number of columns.
                    int totalColumns = sqlite3_column_count(compiledStatement);
                    
                    // Go through all columns and fetch each column data.
                    for (int i=0; i<totalColumns; i++){
                        // Convert the column data to text (characters).
                        char *dbDataAsChars = (char *)sqlite3_column_text(compiledStatement, i);
                        
                        // If there are contents in the currenct column (field) then add them to the current row array.
                        if (dbDataAsChars != NULL) {
                            // Convert the characters to string.
                            [arrDataRow addObject:[NSString  stringWithUTF8String:dbDataAsChars]];
                        }
                        
                        // Keep the current column name.
                        if (self.arrColumnNames.count != totalColumns) {
                            dbDataAsChars = (char *)sqlite3_column_name(compiledStatement, i);
                            [self.arrColumnNames addObject:[NSString stringWithUTF8String:dbDataAsChars]];
                        }
                    }
                    
                    // Store each fetched data row in the results array, but first check if there is actually data.
                    if (arrDataRow.count > 0) {
                        [self.arrResults addObject:arrDataRow];
                    }
                }
            } else {
                // This is the case of an executable query (insert, update, ...).
                
                [self compileSQLInjectionFreeStatement:compiledStatement fromParameters:parameters];
                
                // Execute the query.
                int executeQueryResults = sqlite3_step(compiledStatement);
                if (executeQueryResults == SQLITE_DONE) {
                    // Keep the affected rows.
                    self.affectedRows = sqlite3_changes(sqlite3Database);
                    
                    // Keep the last inserted row ID.
                    self.lastInsertedRowID = sqlite3_last_insert_rowid(sqlite3Database);
                } else {
                    // If could not execute the query show the error message on the debugger.
                    NSLog(@"DB Error: %s", sqlite3_errmsg(sqlite3Database));
                }
            }
        } else {
            // In the database cannot be opened then show the error message on the debugger.
            NSLog(@"%s", sqlite3_errmsg(sqlite3Database));
        }
        
        // Release the compiled statement from memory.
        sqlite3_finalize(compiledStatement);
        
    }
    
    // Close the database.
    sqlite3_close(sqlite3Database);
}

/* SELECT database record */
- (NSArray *)loadDataFromDB:(NSString *)query parameters:(NSArray *)parameters {
    NSMutableArray *statementParams = [[NSMutableArray alloc] init];
    SQLParameter *sqlParam;
    int i = 1;

    for (id parameter in parameters) {
        if ([parameter isKindOfClass:[NSString class]]) {
            sqlParam = [[SQLParameter alloc] initWithStringValue:parameter index:i];
        } else {
            sqlParam = [[SQLParameter alloc] initWithIntegerValue:[parameter integerValue] index:i];
        }
        [statementParams addObject:sqlParam];
        i ++;
    }

    // Run the query and indicate that is not executable.
    // The query string is converted to a char* object.
    [self runQuery:[query UTF8String] isQueryExecutable:NO statementParameters:statementParams];
    // Returned the loaded results.
    return (NSArray *)self.arrResults;
}

/* INSERT, UPDATE or DELETE database record */
- (void)modifyDataInDB:(NSString *)query parameters:(NSArray *)parameters {
    NSMutableArray *statementParams = [[NSMutableArray alloc] init];
    SQLParameter *sqlParam;
    int i = 1;
    for (id parameter in parameters) {
        if ([parameter isKindOfClass:[NSString class]]) {
            sqlParam = [[SQLParameter alloc] initWithStringValue:parameter index:i];
        } else {
            sqlParam = [[SQLParameter alloc] initWithIntegerValue:[parameter integerValue] index:i];
        }
        [statementParams addObject:sqlParam];
        i ++;
    }
    // Run the query and indicate that is executable.
    [self runQuery:[query UTF8String] isQueryExecutable:YES statementParameters:statementParams];
}

- (void)dealloc {
    [self.arrResults removeAllObjects];
    self.arrResults = nil;
    
    [self.arrColumnNames removeAllObjects];
    self.arrColumnNames = nil;
    
    self.documentsDirectory = nil;
    self.databaseFilename = nil;
}

@end
