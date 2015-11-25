//
//  Ground.swift
//  soccer
//
//  Created by 杨逴先 on 15/10/19.
//  Copyright © 2015年 VisionTech. All rights reserved.
//

import UIKit

class Ground: NSObject {
    var groundId = ""
    var city = ""
    var name = ""
    var address = ""
    var contact = ""
    var phone = ""
    var capacity = ""
    var numberOfTeams = ""
    var numberOfActivities = ""
    var latitude = ""
    var longitude = ""
    var distanceToCurrentUser = ""
    
    init(data: [String: AnyObject]) {
        self.groundId = Toolbox.getValidStringValue(data["id"])
        self.city = Toolbox.getValidStringValue(data["city"])
        self.name = Toolbox.getValidStringValue(data["name"])
        self.address = Toolbox.getValidStringValue(data["address"])
        self.contact = Toolbox.getValidStringValue(data["contact"])
        self.phone = Toolbox.getValidStringValue(data["phone"])
        self.capacity = Toolbox.getValidStringValue(data["capacity"])
        self.numberOfTeams = Toolbox.getValidStringValue(data["numberOfTeams"])
        self.numberOfActivities = Toolbox.getValidStringValue(data["numberOfActivities"])
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
        self.distanceToCurrentUser = Toolbox.getValidStringValue(data["distanceToCurrentUser"]) + " km"
    }
}
