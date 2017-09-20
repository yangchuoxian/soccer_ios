//
//  Activity.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/2.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class Activity: NSObject {
    
    var activityId: String?
    var initiator: String?
    var date: String?
    var time: String?
    var dateTime: String?
    var place: String?
    var type: Int?
    var status: Int?
    var minimumNumberOfPeople: Int = 0
    var nameOfA: String?
    var idOfA: String?
    var nameOfB = ""
    var idOfB = ""
    var scoreOfA: Int?
    var scoreOfB: Int?
    var note = ""
    var latitude = ""
    var longitude = ""
    
    deinit {
        self.activityId = nil
        self.initiator = nil
        self.date = nil
        self.time = nil
        self.dateTime = nil
        self.place = nil
        self.type = nil
        self.status = nil
        self.nameOfA = nil
        self.idOfA = nil
        self.scoreOfA = nil
        self.scoreOfB = nil
    }
    
    init(data: [String: AnyObject]) {
        self.activityId = data["id"] as? String
        self.initiator = data["initiator"] as? String
        if !Toolbox.isDateStringServerDateFormat(data["time"] as! String) {
            self.date = data["date"] as? String
            self.time = data["time"] as? String
        } else {
            let date = Date(dateTimeString: data["time"] as! String)
            self.date = date.getDateString()
            self.time = date.getTimeString()
        }
        self.dateTime = self.date! + " " + self.time!
        self.place = data["place"] as? String
        self.type = data["type"] as? Int
        self.status = data["status"] as? Int
        if data["minimumNumberOfPeople"] != nil {
            self.minimumNumberOfPeople = data["minimumNumberOfPeople"] as! Int
        }
        self.nameOfA = data["nameOfA"] as? String
        self.idOfA = data["idOfA"] as? String
        if data["nameOfB"] != nil && data["idOfB"] != nil {
            self.nameOfB = data["nameOfB"] as! String
            self.idOfB = data["idOfB"] as! String
        }
        if data["scoreOfA"] != nil {
            self.scoreOfA = data["scoreOfA"] as? Int
        }
        if data["scoreOfB"] != nil {
            self.scoreOfB = data["scoreOfB"] as? Int
        }
        if data["note"] != nil {
            self.note = data["note"] as! String
        }
        let geoInfo = data["geoCoordinates"] as? [String: AnyObject]
        if geoInfo != nil {
            let coordinates = geoInfo!["coordinates"] as? [AnyObject]
            if coordinates != nil {
                self.latitude = "\(coordinates![1])"
                self.longitude = "\(coordinates![0])"
            }
        } else {
            let latitude = Toolbox.getValidStringValue(data["latitude"])
            let longitude = Toolbox.getValidStringValue(data["longitude"])
            if Toolbox.isStringValueValid(latitude) && Toolbox.isStringValueValid(longitude) {
                self.latitude = latitude
                self.longitude = longitude
            }
        }
    }
    
    func saveOrUpdateActivityInDatabase() -> Int {
        let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        let currentUser = Singleton_CurrentUser.sharedInstance
        // first off, check if such activyt with the activityId exists in local database already, if so, update the activity record, otherwise, add a new activity
        let existedActivity = dbManager?.loadData(
            fromDB: "select * from activities where activityId=? and forUserId=?",
            parameters: [self.activityId!, currentUser.userId!]
        )
        
        var safeDatabaseQuery: String
        var queryParams: [AnyObject]
        if (existedActivity?.count)! > 0 {  // activity record exists, should update
            safeDatabaseQuery = "update activities set initiator=?,date=?,time=?,place=?,type=?,status=?,minimumNumberOfPeople=?,nameOfA=?,idOfA=?,nameOfB=?,idOfB=?,scoreOfA=?,scoreOfB=?,note=?,latitude=?,longitude=? where activityId=? and forUserId=?"
            queryParams = [
                self.initiator! as AnyObject,
                self.date! as AnyObject,
                self.time! as AnyObject,
                self.place! as AnyObject,
                "\(self.type!)" as AnyObject,
                "\(self.status!)" as AnyObject,
                "\(self.minimumNumberOfPeople)" as AnyObject,
                self.nameOfA!,
                self.idOfA!,
                self.nameOfB,
                self.idOfB,
                "\(self.scoreOfA)",
                "\(self.scoreOfB)",
                self.note,
                self.latitude,
                self.longitude,
                self.activityId!,
                currentUser.userId!
            ]
        } else {    // new activity, should insert
            safeDatabaseQuery = "insert into activities(activityId,initiator,date,time,place,type,status,minimumNumberOfPeople,nameOfA,idOfA,nameOfB,idOfB,scoreOfA,scoreOfB,note,forUserId,latitude,longitude) values(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
            queryParams = [
                self.activityId! as AnyObject,
                self.initiator! as AnyObject,
                self.date! as AnyObject,
                self.time! as AnyObject,
                self.place! as AnyObject,
                "\(self.type!)" as AnyObject,
                "\(self.status!)" as AnyObject,
                "\(self.minimumNumberOfPeople)",
                self.nameOfA!,
                self.idOfA!,
                self.nameOfB,
                self.idOfB,
                "\(self.scoreOfA)",
                "\(self.scoreOfB)",
                self.note,
                currentUser.userId!,
                self.latitude,
                self.longitude
            ]
        }
        dbManager?.modifyData(inDB: safeDatabaseQuery, parameters: queryParams)
        if dbManager?.affectedRows == 0 {    // query failed
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "数据库操作失败")
            return ErrorCode.localDatabaseError.rawValue
        } else {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "activityRecordSavedOrUpdated"), object: self)
            return 1
        }
    }
    
    static func formatDatabaseRecordToActivity(_ databaseRecord: [AnyObject]) -> Activity {
        let activityDictionary = [
            "activityId": databaseRecord[ActivityTableIndex.activityId.rawValue],
            "initiator": databaseRecord[ActivityTableIndex.initiator.rawValue],
            "date": databaseRecord[ActivityTableIndex.date.rawValue],
            "time": databaseRecord[ActivityTableIndex.time.rawValue],
            "place": databaseRecord[ActivityTableIndex.place.rawValue],
            "type": databaseRecord[ActivityTableIndex.activityType.rawValue].intValue,
            "status": databaseRecord[ActivityTableIndex.status.rawValue].intValue,
            "minimumNumberOfPeople": databaseRecord[ActivityTableIndex.minimumNumberOfPeople.rawValue].intValue,
            "nameOfA": databaseRecord[ActivityTableIndex.nameOfA.rawValue],
            "idOfA": databaseRecord[ActivityTableIndex.idOfA.rawValue],
            "nameOfB": databaseRecord[ActivityTableIndex.nameOfB.rawValue],
            "idOfB": databaseRecord[ActivityTableIndex.idOfB.rawValue],
            "scoreOfA": databaseRecord[ActivityTableIndex.scoresOfA.rawValue].intValue,
            "scoreOfB": databaseRecord[ActivityTableIndex.scoresOfB.rawValue].intValue,
            "note": databaseRecord[ActivityTableIndex.note.rawValue],
            "forUserId": databaseRecord[ActivityTableIndex.forUserId.rawValue],
            "latitude": databaseRecord[ActivityTableIndex.latitude.rawValue],
            "longitude": databaseRecord[ActivityTableIndex.longitude.rawValue]
        ]
        return Activity(data: activityDictionary)
    }
}
