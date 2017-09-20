//
//  Singleton_UserOwnedTeam.swift
//  soccer
//
//  Created by 杨逴先 on 15/10/23.
//  Copyright © 2015年 VisionTech. All rights reserved.
//

import UIKit

/// The singleton class of the team that current logged in user is the captain of
class Singleton_UserOwnedTeam: NSObject {
    
    static let sharedInstance = Singleton_UserOwnedTeam()
    
    var teamId = ""
    var teamName = ""
    var type = ""
    var maximumNumberOfPeople = 0
    var points = 0
    var wins = 0
    var loses = 0
    var ties = 0
    var captainUserId = ""
    var numberOfMembers = 0
    var location = ""
    var createdAt = ""
    var introduction = ""
    var homeCourt = ""
    var isRecruiting = ""
    var latitude = ""
    var longitude = ""

    func getTeamInfoFrom(_ teamObject: Team) {
        self.teamId = teamObject.teamId
        self.teamName = teamObject.teamName
        self.type = teamObject.type
        self.maximumNumberOfPeople = teamObject.maximumNumberOfPeople
        self.points = teamObject.points
        self.wins = teamObject.wins
        self.loses = teamObject.loses
        self.ties = teamObject.ties
        self.captainUserId = teamObject.captainUserId
        self.numberOfMembers = teamObject.numberOfMembers
        self.location = teamObject.location
        self.createdAt = teamObject.createdAt
        self.introduction = teamObject.introduction
        self.homeCourt = teamObject.homeCourt
        self.isRecruiting = teamObject.isRecruiting
        // get team geo coordinates
        self.latitude = teamObject.latitude
        self.longitude = teamObject.longitude
    }
    
    func resetUserOwnedTeamInfo() {
        self.teamId = ""
        self.teamName = ""
        self.type = ""
        self.maximumNumberOfPeople = 0
        self.points = 0
        self.wins = 0
        self.loses = 0
        self.ties = 0
        self.captainUserId = ""
        self.numberOfMembers = 0
        self.location = ""
        self.createdAt = ""
        self.introduction = ""
        self.homeCourt = ""
        self.isRecruiting = ""
        self.latitude = ""
        self.longitude = ""
    }
}
