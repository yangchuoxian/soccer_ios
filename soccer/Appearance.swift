//
//  Appearance.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/28.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

let ColorDarkerBlue = UIColor(red: 35/255.0, green: 149/255.0, blue: 236/255.0, alpha:1.0)
let ColorOrange = UIColor(red: 251/255.0, green: 107/255.0, blue: 91/255.0, alpha: 1.0)
let ColorGreen = UIColor(red: 146/255.0, green: 207/255.0, blue: 92/255.0, alpha: 1.0)
let ColorSettledGreen = UIColor(red: 101/255.0, green: 192/255.0, blue: 89/255.0, alpha: 1.0)
let ColorDarkerGreen = UIColor(red: 44/255.0, green: 200/255.0, blue: 125/255.0, alpha: 1.0)
let ColorSolidGreen = UIColor(red: 97/255.0, green: 195/255.0, blue: 185/255.0, alpha: 1.0)
let ColorBackgroundGray = UIColor(red: 244/255.0, green: 245/255.0, blue: 249/255.0, alpha: 1.0)
let ColorLighterGray = UIColor(red: 245/255.0, green: 245/255.0, blue: 245/255.0, alpha: 1.0)
let EmptyImageColor = UIColor(red: 200/255.0, green: 200/255.0, blue: 200/255.0, alpha: 1.0)
let ColorYellow = UIColor(red: 240/255.0, green: 173/255.0, blue: 78/255.0, alpha: 1.0)
let ColorDefaultBlue = UIColor(red: 0/255.0, green: 122/255.0, blue: 255/255.0, alpha: 1.0)
let ColorSolidBlue = UIColor(red: 77/255.0, green: 176/255.0, blue: 205/255.0, alpha: 1.0)
let ColorBiege = UIColor(red: 242/255.0, green: 241/255.0, blue: 237/255.0, alpha: 1.0)
let ColorNearBlack = UIColor(red: 33/255.0, green: 34/255.0, blue: 36/255.0, alpha: 1.0)

@objc class Appearance: NSObject {
    
    static func setupRefreshControl() -> UIRefreshControl {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor.blackColor()
        refreshControl.backgroundColor = ColorBackgroundGray
        
        return refreshControl
    }
    
    static func setupTableFooterButtonWithTitle(title: String, backgroundColor: UIColor) -> UIButton {
        let tableFooterButton = UIButton(type: .System)
        tableFooterButton.setTitle(title, forState: .Normal)
        tableFooterButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        tableFooterButton.backgroundColor = backgroundColor
        
        tableFooterButton.frame = CGRect(x: 15, y: 15, width: ScreenSize.width - 30, height: 40)
        tableFooterButton.layer.cornerRadius = 2.0
        
        return tableFooterButton
    }
    
    static func setupTableSectionHeaderTitle(title: String) -> UILabel {
        let sectionHeaderLabel = UILabel(frame: CGRect(x: 20, y: 6, width: 220, height: TableSectionHeaderHeight - 2 * 6))
        sectionHeaderLabel.text = title
        sectionHeaderLabel.font = UIFont.systemFontOfSize(15.0)
        sectionHeaderLabel.textColor = UIColor.lightGrayColor()
        sectionHeaderLabel.backgroundColor = UIColor.clearColor()
        
        return sectionHeaderLabel
    }
    
    static func customizeTextField(textField: UITextField, iconName: String) {
        let borderColor = UIColor(red: 221/255.0, green: 221/255.0, blue: 221/255.0, alpha: 1.0)
        
        // make the textField has only bottom border
        let borderWidth: CGFloat = 1
        let textFieldBorder = UIView(frame: CGRectMake(0, textField.frame.size.height - borderWidth, textField.frame.size.width, borderWidth))
        textFieldBorder.backgroundColor = borderColor
        textField.addSubview(textFieldBorder)
        // add icon padding inside textField
        let icon = UIImageView(image: UIImage(named: iconName))
        icon.frame = CGRect(x: 0, y: 0, width: icon.image!.size.width + 15.0, height: icon.image!.size.height)
        icon.contentMode = .Center
        
        // add left side icon inside textField
        textField.leftViewMode = .Always
        textField.leftView = icon
        textField.clearButtonMode = .WhileEditing
    }
    
    static func customizeAvatarImage(avatarImage: UIImageView) {
        avatarImage.backgroundColor = UIColor.whiteColor()
        avatarImage.layer.borderWidth = 2.0
        avatarImage.layer.borderColor = UIColor.whiteColor().CGColor
        avatarImage.layer.masksToBounds = true
        avatarImage.layer.cornerRadius = avatarImage.frame.size.width / 2
    }
    
    static func customizeNavigationBar(viewController: UIViewController, title: String) {
        viewController.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        viewController.navigationController?.navigationBar.topItem!.title = ""
        viewController.title = title
    }
    
    static func customizeTopTabButton(button: UIButton) {
        let borderColor = ColorBackgroundGray
        let buttonBorder = CALayer()
        
        buttonBorder.borderColor = borderColor.CGColor
        buttonBorder.frame = CGRect(x: 0, y: button.frame.size.height - 1, width: button.frame.size.width, height: button.frame.size.height)
        buttonBorder.borderWidth = 1
        button.layer.addSublayer(buttonBorder)
        button.layer.masksToBounds = true
    }
    
    static func customizeTextView(textView: UITextView, placeholder p: String?) {
        let borderColor = UIColor(red: 221/255.0, green: 221/255.0, blue: 221/255.0, alpha: 1.0)
        let textViewBorder = CALayer()
        
        textViewBorder.borderColor = borderColor.CGColor
        textViewBorder.frame = CGRect(x: 0, y: textView.frame.size.height - 1, width: textView.frame.size.width, height: textView.frame.size.height)
        textViewBorder.borderWidth = 1
        
        textView.layer.addSublayer(textViewBorder)
        textView.layer.masksToBounds = true
        
        textView.placeholder = p
    }
    
    static func addRightViewToTextField(textField: UITextField, withText text: String) {
        let rightView = UILabel(frame: CGRectMake(0, 0, 40, 21))
        rightView.contentMode = .Center
        rightView.text = text
        textField.rightViewMode = .Always
        textField.rightView = rightView
    }
    
    static func showAlertViewWithInput(title: String, delegate d: AnyObject) {
        let searchAlertView = UIAlertView(title: "", message: title, delegate: (d as? UIAlertViewDelegate), cancelButtonTitle: "取消", otherButtonTitles: "确定")
        searchAlertView.alertViewStyle = .PlainTextInput
        searchAlertView.textFieldAtIndex(0)?.placeholder = title
        searchAlertView.textFieldAtIndex(0)?.delegate = d as? UITextFieldDelegate
        searchAlertView.show()
    }
    
    static func showAlertView(title: String, delegate d: AnyObject) {
        let alertView = UIAlertView(title: "", message: title, delegate: (d as? UIAlertViewDelegate), cancelButtonTitle: "取消", otherButtonTitles: "确定")
        alertView.alertViewStyle = .Default
        alertView.show()
    }
    
    static func setupViewBorder(view: AnyObject, borderWidth bWidth: CGFloat, borderColor bColor: UIColor, hasTopBorder: Bool, hasLeftBorder: Bool, hasBottomBorder: Bool, hasRightBorder: Bool) {
        let viewToAddBorder = view as! UIView
        if hasTopBorder {
            let topBorder = UIView(frame: CGRectMake(0, 0, viewToAddBorder.frame.size.width, bWidth))
            topBorder.backgroundColor = bColor
            viewToAddBorder.addSubview(topBorder)
            viewToAddBorder.bringSubviewToFront(topBorder)
        }
        if hasLeftBorder {
            let leftBorder = UIView(frame: CGRectMake(0, 0, bWidth, viewToAddBorder.frame.size.height))
            leftBorder.backgroundColor = bColor
            viewToAddBorder.addSubview(leftBorder)
            viewToAddBorder.bringSubviewToFront(leftBorder)
        }
        if hasBottomBorder {
            let bottomBorder = UIView(frame: CGRectMake(0, viewToAddBorder.frame.size.height - bWidth, viewToAddBorder.frame.size.width, bWidth))
            bottomBorder.backgroundColor = bColor
            viewToAddBorder.addSubview(bottomBorder)
            viewToAddBorder.bringSubviewToFront(bottomBorder)
        }
        if hasRightBorder {
            let rightBorder = UIView(frame: CGRectMake(viewToAddBorder.frame.size.width - bWidth, 0, bWidth, viewToAddBorder.frame.size.height))
            rightBorder.backgroundColor = bColor
            viewToAddBorder.addSubview(rightBorder)
            viewToAddBorder.bringSubviewToFront(rightBorder)
        }
    }
    
    static func dropShadowForView(view: UIView) {
        view.layer.shadowColor = UIColor.blackColor().CGColor
        view.layer.shadowOpacity = 0.5
        view.layer.shadowRadius = 0.6
        view.layer.shadowOffset = CGSizeMake(1.0, 1.0)
        view.backgroundColor = ColorBackgroundGray
    }
    
}
