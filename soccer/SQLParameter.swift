//
//  SQLParameter.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/2.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class SQLParameter: NSObject {
   
    var parameterType: ParamType
    var parameterIndex: Int = 0
    var parameterStringValue: String = ""
    var parameterIntegerValue: Int = 0
    
    init(value: AnyObject, index: Int) {
        self.parameterIndex = index
        let stringValue = value as? String
        if stringValue != nil {
            self.parameterStringValue = value as! String
            self.parameterType = .string
        } else {
            self.parameterIntegerValue = value as! Int
            self.parameterType = .integer
        }
    }
    
    init(stringValue: String, index: Int) {
        self.parameterType = .string
        self.parameterStringValue = stringValue
        self.parameterIndex = index
    }
    
    init(integerValue: Int, index: Int) {
        self.parameterType = .integer
        self.parameterIntegerValue = integerValue
        self.parameterIndex = index
    }
}
