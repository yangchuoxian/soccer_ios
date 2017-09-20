//
//  Team.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/2.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class Team: NSObject {
    var teamId: String = ""
    var teamName: String = ""
    // team sports type
    var type: String = ""
    var maximumNumberOfPeople: Int = 0
    var points: Int = 0
    // number of won matches
    var wins: Int = 0
    // number of lost matches
    var loses: Int = 0
    // number of tied matches
    var ties: Int = 0
    var captainUserId = ""
    var numberOfMembers = 0
    var location = ""
    var createdAt = ""
    var introduction = ""
    var homeCourt = ""
    var isRecruiting = ""
    var latitude = ""
    var longitude = ""
    var distanceToCurrentUser = ""
    
    init(data: [AnyHashable: Any]) {
        self.teamId = Toolbox.getValidStringValue(data["id"])
        self.teamName = Toolbox.getValidStringValue(data["name"])
        self.type = Toolbox.getValidStringValue(data["type"])
        self.maximumNumberOfPeople = Toolbox.getValidIntValue(data["maximumNumberOfPeople"])
        self.points = Toolbox.getValidIntValue(data["points"])
        self.wins = Toolbox.getValidIntValue(data["wins"])
        self.loses = Toolbox.getValidIntValue(data["loses"])
        self.ties = Toolbox.getValidIntValue(data["ties"])
        if data["captain"] != nil {
            self.captainUserId = data["captain"] as! String
        } else if data["captainUserId"] != nil {
            self.captainUserId = data["captainUserId"] as! String
        }
        self.numberOfMembers = Toolbox.getValidIntValue(data["numberOfMembers"])
        self.location = Toolbox.getValidStringValue(data["location"])
        self.createdAt = Toolbox.getValidStringValue(data["createdAt"])
        self.introduction = Toolbox.getValidStringValue(data["introduction"])
        self.homeCourt = Toolbox.getValidStringValue(data["homeCourt"])
        self.isRecruiting = Toolbox.getValidStringValue(data["isRecruiting"])
        if let geoCoordinates = data["geoCoordinates"] as? [AnyHashable: Any] {
            if let coordinatesArray = geoCoordinates["coordinates"] as? [AnyObject] {
                self.longitude = "\(coordinatesArray[0])"
                self.latitude = "\(coordinatesArray[1])"
            }
        }
        if let latitude = data["latitude"] as? String {
            self.latitude = latitude
        }
        if let longitude = data["longitude"] as? String {
            self.longitude = longitude
        }
        self.distanceToCurrentUser = Toolbox.getValidStringValue(data["distanceToCurrentUser"])
    }
    
    func saveOrUpdateTeamInDatabase() -> Int {
        let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        let currentUser = Singleton_CurrentUser.sharedInstance
        // first off, check if such team with the teamId exists in local database already, if so, DO NOT insert it into database but update its information
        // forUserId is a database column to tell which user this team database record is for
        let existedTeam = dbManager?.loadData(
            fromDB: "select * from teams where teamId=? and forUserId=?",
            parameters: [teamId, currentUser.userId!]
        )
        
        var dateString: String
        if !Toolbox.isDateStringServerDateFormat(self.createdAt) {
            // if timeString is not of the format "yyyy-MM-dd'T'HH:mm:ss.SSSz"
            dateString = self.createdAt
        } else {
            dateString = Date(dateTimeString: self.createdAt).getDateString()
        }
        
        var safeDatabaseQuery: String
        var queryParams: [AnyObject]
        if (existedTeam?.count)! > 0 {  // team already exists, update the existed team record
            // prepare database update query string
            safeDatabaseQuery = "update teams set name=?,type=?,maximumNumberOfPeople=?,wins=?,loses=?,ties=?,captainUserId=?,numberOfMembers=?,location=?,createdAt=?,introduction=?,homeCourt=?,points=?,isRecruiting=?,latitude=?,longitude=? where teamId=? and forUserId=?"
            queryParams = [
                self.teamName as AnyObject,
                self.type as AnyObject,
                self.maximumNumberOfPeople as AnyObject,
                self.wins as AnyObject,
                self.loses as AnyObject,
                self.ties as AnyObject,
                self.captainUserId as AnyObject,
                self.numberOfMembers,
                self.location,
                dateString,
                self.introduction,
                self.homeCourt,
                self.points,
                self.isRecruiting,
                self.latitude,
                self.longitude,
                self.teamId,
                currentUser.userId!
            ]
        } else {    // new team, add it to local database
            // prepare database insert query string
            safeDatabaseQuery = "insert into teams(teamId,name,type,maximumNumberOfPeople,wins,loses,ties,forUserId,captainUserId,numberOfMembers,location,createdAt,introduction,homeCourt,points,isRecruiting,latitude,longitude) values(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
            queryParams = [
                self.teamId as AnyObject,
                self.teamName as AnyObject,
                self.type as AnyObject,
                self.maximumNumberOfPeople as AnyObject,
                self.wins as AnyObject,
                self.loses as AnyObject,
                self.ties as AnyObject,
                currentUser.userId!,
                self.captainUserId,
                self.numberOfMembers,
                self.location,
                dateString,
                self.introduction,
                self.homeCourt,
                self.points,
                self.isRecruiting,
                self.latitude,
                self.longitude
            ]
        }
        
        dbManager?.modifyData(inDB: safeDatabaseQuery, parameters: queryParams)
        if dbManager?.affectedRows == 0 {    // query failed
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "数据库操作失败")
            return ErrorCode.localDatabaseError.rawValue
        } else {
            if self.captainUserId == Singleton_CurrentUser.sharedInstance.userId {
                // current user is the team captain of this team
                Singleton_UserOwnedTeam.sharedInstance.getTeamInfoFrom(self)
            }
            NotificationCenter.default.post(
                name: Notification.Name(rawValue: "teamRecordSavedOrUpdated"), object: self)
            return 1
        }
    }
    
    /**
     * After receiving teams list from server, this function is invoked to check if there are more teams in local database
     * than the number of received teams, if so, meaning that one or more teams has removed the current user as member,
     * and in that case, the local database should be updated by deleting the corresponding team(s) as well to indicate
     * that the current user is no longer a member of those teams
     */
    static func checkUserMembershipInTeams(_ receivedTeams: [Team]) {
        // initialize database manager instance
        let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        let currentUser = Singleton_CurrentUser.sharedInstance
        // first off, retrieve all teams of current user in local database table
        let localTeamsList = dbManager?.loadData(fromDB: "select * from teams where forUserId=?", parameters: [currentUser.userId!])
        
        var idsOfReceivedTeams = [String]()
        for receivedTeam in receivedTeams {
            idsOfReceivedTeams.append(receivedTeam.teamId)
        }
        
        var teamIdsToDelete = [String]()
        for teamDatabaseRecord in localTeamsList! {
            let teamIdOfLocalTeamRecord = (teamDatabaseRecord as! [AnyObject])[TeamTableIndex.teamId.rawValue] as! String
            if !idsOfReceivedTeams.contains(teamIdOfLocalTeamRecord) {
                // this local team is NOT found in the list of received teams,
                // should remove it from local database, so add it to teamIdsToDelete list for later deletion
                teamIdsToDelete.append(teamIdOfLocalTeamRecord)
            }
        }
        if teamIdsToDelete.count > 0 {
            Team.deleteTeamsInLocalDatabaseForCurrentUser(teamIdsToDelete)
        }
        
        teamIdsToDelete.removeAll(keepingCapacity: false)
        idsOfReceivedTeams.removeAll(keepingCapacity: false)
    }
    
    static func deleteTeamsInLocalDatabaseForCurrentUser(_ teamIdsToDelete: [String]) {
        if teamIdsToDelete.count == 0 {
            return
        }
        let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        // for all the team ids in teamIdsToDelete, delete each one of its corresponding team record from local database
        for teamIdToDelete in teamIdsToDelete {
            dbManager?.modifyData(inDB: "delete from teams where teamId=? and forUserId=?", parameters: [teamIdToDelete, Singleton_CurrentUser.sharedInstance.userId!])
            if teamIdToDelete == Singleton_UserOwnedTeam.sharedInstance.teamId {
                // curret user is the captain of this team that is about to be deleted, so we should clear UserOwnedTeam
                Singleton_UserOwnedTeam.sharedInstance.resetUserOwnedTeamInfo()
            }
        }
        // there are teams deleted from local database, so send a notification to notify VTTeamsTableViewController that one or more teams have been deleted, and its tableView should be updated as well
        NotificationCenter.default.post(
            name: Notification.Name(rawValue: "teamsDeletedLocally"), object: teamIdsToDelete)
    }
    
    static func formatDatabaseRecordToTeamFormat(_ databaseRecord: [AnyObject]) -> Team {
        let teamFormatDictionary = [
            "id": databaseRecord[TeamTableIndex.teamId.rawValue],
            "name": databaseRecord[TeamTableIndex.name.rawValue],
            "type": databaseRecord[TeamTableIndex.teamType.rawValue],
            "maximumNumberOfPeople": databaseRecord[TeamTableIndex.maximumNumberOfPeople.rawValue],
            "wins": databaseRecord[TeamTableIndex.wins.rawValue],
            "loses": databaseRecord[TeamTableIndex.loses.rawValue],
            "ties": databaseRecord[TeamTableIndex.ties.rawValue],
            "forUserId": databaseRecord[TeamTableIndex.forUserId.rawValue],
            "captainUserId": databaseRecord[TeamTableIndex.captainUserId.rawValue],
            "numberOfMembers": databaseRecord[TeamTableIndex.numberOfMembers.rawValue],
            "location": databaseRecord[TeamTableIndex.location.rawValue],
            "createdAt": databaseRecord[TeamTableIndex.createdAt.rawValue],
            "introduction": databaseRecord[TeamTableIndex.introduction.rawValue],
            "homeCourt": databaseRecord[TeamTableIndex.homeCourt.rawValue],
            "points": databaseRecord[TeamTableIndex.points.rawValue],
            "isRecruiting": databaseRecord[TeamTableIndex.isRecruiting.rawValue],
            "latitude": databaseRecord[TeamTableIndex.latitude.rawValue],
            "longitude": databaseRecord[TeamTableIndex.longitude.rawValue]
        ]
        return Team(data: teamFormatDictionary)
    }
    
    static func retrieveCaptainIdFromLocalDatabaseWithTeamId(_ teamId: String) -> String? {
        let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        let teams = dbManager?.loadData(fromDB: "select * from teams where teamId=?", parameters: [teamId])
        
        if (teams?.count)! > 0 {
            let team = Team.formatDatabaseRecordToTeamFormat(teams?[0] as! [AnyObject])
            return team.captainUserId
        } else {
            return nil
        }
    }
    
    static func retrieveTeamNameFromLocalDatabaseWithTeamId(_ teamId: String) -> String {
        let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        let teams = dbManager?.loadData(fromDB: "select * from teams where teamId=?", parameters: [teamId])
        if (teams?.count)! > 0 {
            let team = Team.formatDatabaseRecordToTeamFormat(teams?[0] as! [AnyObject])
            return team.teamName
        } else {
            return ""
        }
    }
    
    static func changeCaptainTo(_ userId: String, forTeam: String) -> Int {
        let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        dbManager?.modifyData(inDB: "update teams set captainUserId=? where teamId=?", parameters: [userId, forTeam])
        let numOfAffectedDatabaseRow = dbManager?.affectedRows
        
        return numOfAffectedDatabaseRow!
    }
    
    /**
     * Once team member deleted on server, in local database, the number of members for corresponding team should also be updated by subtract the number by 1
     */
    static func changeNumberOfMembersInTeam(_ teamId: String, reduce r: Bool) -> Int {
        let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        // retrieve original number of members for this team
        let teams = dbManager?.loadData(fromDB: "select * from teams where teamId=?", parameters: [teamId])
        
        let originalNumberOfMembers = teams?[0][TeamTableIndex.numberOfMembers.rawValue].intValue
        var newNumberOfMembers = 0
        if r {  // number of member reduced
            newNumberOfMembers = originalNumberOfMembers - 1
        } else {    // number of mmeber increased
            newNumberOfMembers = originalNumberOfMembers + 1
        }
        dbManager?.modifyData(inDB: "update teams set numberOfMembers=? where teamId=?", parameters: [newNumberOfMembers, teamId])
        
        if (dbManager?.affectedRows)! > 0 {
            // database manipulation succeeded, return the new number of members for this team
            return originalNumberOfMembers - 1
        } else {
            // database manipulation failed
            return ErrorCode.localDatabaseError.rawValue
        }
    }
    
    deinit {
    }
    
}
