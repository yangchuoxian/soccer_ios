//
//  DBManager.h
//  soccer
//
//  Created by 杨逴先 on 15/3/23.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface DBManager : NSObject

@property (nonatomic, strong) NSString *documentsDirectory;
@property (nonatomic, strong) NSString *databaseFilename;

@property (nonatomic, strong) NSMutableArray *arrResults;
@property (nonatomic, strong) NSMutableArray *arrColumnNames;
@property (nonatomic) NSInteger affectedRows;
@property (nonatomic) long long lastInsertedRowID;

- (instancetype)initWithDatabaseFilename:(NSString *)dbFilename;
- (void)copyDatabaseIntoDocumentsDirectory;
- (void)runQuery:(const char *)query isQueryExecutable:(BOOL)queryExecutable statementParameters:(NSArray *)parameters;
- (NSArray *)loadDataFromDB:(NSString *)query parameters:(NSArray *)parameters;
- (void)modifyDataInDB:(NSString *)query parameters:(NSArray *)parameters;

@end
