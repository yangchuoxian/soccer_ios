//
//  User.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/2.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class User: NSObject {
   
    var userId = ""
    var username = ""
    var email = ""
    var name = ""
    var introduction = ""
    var balance = ""
    var points = ""
    var phoneNumber = ""
    var location = ""
    var height = ""
    var weight = ""
    var position = ""
    var gender = ""
    var careerAge = ""
    var dateOfBirth = ""
    var averageAbility = ""
    var numToReviewOnAverageAbility = ""
    var speed = ""
    var numToReviewOnSpeed = ""
    var jumpAbility = ""
    var numToReviewOnJumpAbility = ""
    var explosiveForceAbility = ""
    var numToReviewOnExplosiveForceAbility = ""
    var conscious = ""
    var numToReviewOnConscious = ""
    var cooperation = ""
    var numToReviewOnCooperation = ""
    var personality = ""
    var numToReviewOnPersonality = ""
    var distanceToCurrentUser = ""
    
    init(data: [NSObject: AnyObject]) {
        self.userId = Toolbox.getValidStringValue(data["id"])
        self.username = Toolbox.getValidStringValue(data["username"])
        self.email = Toolbox.getValidStringValue(data["email"])
        self.name = Toolbox.getValidStringValue(data["name"])
        self.introduction = Toolbox.getValidStringValue(data["introduction"])
        self.balance = Toolbox.getValidStringValue(data["balance"])
        self.points = Toolbox.getValidStringValue(data["points"])
        self.phoneNumber = Toolbox.getValidStringValue(data["phoneNumber"])
        self.location = Toolbox.getValidStringValue(data["location"])
        self.height = Toolbox.getValidStringValue(data["height"])
        self.weight = Toolbox.getValidStringValue(data["weight"])
        self.gender = Toolbox.getValidStringValue(data["gender"])
        self.position = Toolbox.getValidStringValue(data["position"])
        self.careerAge = Toolbox.getValidStringValue(data["careerAge"])
        self.dateOfBirth = Toolbox.getValidStringValue(data["dateOfBirth"])
        self.averageAbility = Toolbox.getValidStringValue(data["averageAbility"])
        self.numToReviewOnAverageAbility = Toolbox.getValidStringValue(data["numToReviewOnAverageAbility"])
        self.speed = Toolbox.getValidStringValue(data["speed"])
        self.numToReviewOnSpeed = Toolbox.getValidStringValue(data["numToReviewOnSpeed"])
        self.jumpAbility = Toolbox.getValidStringValue(data["jumpAbility"])
        self.numToReviewOnJumpAbility = Toolbox.getValidStringValue(data["numToReviewOnJumpAbility"])
        self.explosiveForceAbility = Toolbox.getValidStringValue(data["explosiveForceAbility"])
        self.numToReviewOnExplosiveForceAbility = Toolbox.getValidStringValue(data["numToReviewOnExplosiveForceAbility"])
        self.conscious = Toolbox.getValidStringValue(data["conscious"])
        self.numToReviewOnConscious = Toolbox.getValidStringValue(data["numToReviewOnConscious"])
        self.cooperation = Toolbox.getValidStringValue(data["cooperation"])
        self.numToReviewOnCooperation = Toolbox.getValidStringValue(data["numToReviewOnCooperation"])
        self.personality = Toolbox.getValidStringValue(data["personality"])
        self.numToReviewOnPersonality = Toolbox.getValidStringValue(data["numToReviewOnPersonality"])
        self.distanceToCurrentUser = Toolbox.getValidStringValue(data["distanceToCurrentUser"])
    }
    
}
