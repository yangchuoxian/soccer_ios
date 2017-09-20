//
//  NSObjectExtension.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/10.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

extension NSObject {
    // get class name of instance
    var theClassName: String {
        return NSStringFromClass(type(of: self)).components(separatedBy: ".").last!
    }
}
