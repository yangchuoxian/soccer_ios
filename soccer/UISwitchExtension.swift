//
//  UISwitchExtension.swift
//  soccer
//
//  Created by 杨逴先 on 15/9/27.
//  Copyright © 2015年 VisionTech. All rights reserved.
//

import ObjectiveC

private var customValueKey: Int = 0

extension UISwitch {
    var customValue: Int? {
        set {
            objc_setAssociatedObject(
                self,
                &customValueKey,
                newValue as Int?,
                objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
        get {
            return objc_getAssociatedObject(self, &customValueKey) as? Int
        }
    }
}