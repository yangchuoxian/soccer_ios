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
        refreshControl.tintColor = UIColor.black
        refreshControl.backgroundColor = ColorBackgroundGray
        
        return refreshControl
    }
    
    static func setupTableFooterButtonWithTitle(_ title: String, backgroundColor: UIColor) -> UIButton {
        let tableFooterButton = UIButton(type: .system)
        tableFooterButton.setTitle(title, for: UIControlState())
        tableFooterButton.setTitleColor(UIColor.white, for: UIControlState())
        tableFooterButton.backgroundColor = backgroundColor
        
        tableFooterButton.frame = CGRect(x: 15, y: 15, width: ScreenSize.width - 30, height: 40)
        tableFooterButton.layer.cornerRadius = 2.0
        
        return tableFooterButton
    }
    
    static func setupTableSectionHeaderTitle(_ title: String) -> UILabel {
        let sectionHeaderLabel = UILabel(frame: CGRect(x: 20, y: 6, width: 220, height: TableSectionHeaderHeight - 2 * 6))
        sectionHeaderLabel.text = title
        sectionHeaderLabel.font = UIFont.systemFont(ofSize: 15.0)
        sectionHeaderLabel.textColor = UIColor.lightGray
        sectionHeaderLabel.backgroundColor = UIColor.clear
        
        return sectionHeaderLabel
    }
    
    static func customizeTextField(_ textField: UITextField, iconName: String) {
        let borderColor = UIColor(red: 221/255.0, green: 221/255.0, blue: 221/255.0, alpha: 1.0)
        
        // make the textField has only bottom border
        let borderWidth: CGFloat = 1
        let textFieldBorder = UIView(frame: CGRect(x: 0, y: textField.frame.size.height - borderWidth, width: textField.frame.size.width, height: borderWidth))
        textFieldBorder.backgroundColor = borderColor
        textField.addSubview(textFieldBorder)
        // add icon padding inside textField
        let icon = UIImageView(image: UIImage(named: iconName))
        icon.frame = CGRect(x: 0, y: 0, width: icon.image!.size.width + 15.0, height: icon.image!.size.height)
        icon.contentMode = .center
        
        // add left side icon inside textField
        textField.leftViewMode = .always
        textField.leftView = icon
        textField.clearButtonMode = .whileEditing
    }
    
    static func customizeAvatarImage(_ avatarImage: UIImageView) {
        avatarImage.backgroundColor = UIColor.white
        avatarImage.layer.borderWidth = 2.0
        avatarImage.layer.borderColor = UIColor.white.cgColor
        avatarImage.layer.masksToBounds = true
        avatarImage.layer.cornerRadius = avatarImage.frame.size.width / 2
    }
    
    static func customizeNavigationBar(_ viewController: UIViewController, title: String) {
        viewController.navigationController?.navigationBar.tintColor = UIColor.white
        viewController.navigationController?.navigationBar.topItem!.title = ""
        viewController.title = title
    }
    
    static func customizeTopTabButton(_ button: UIButton) {
        let borderColor = ColorBackgroundGray
        let buttonBorder = CALayer()
        
        buttonBorder.borderColor = borderColor.cgColor
        buttonBorder.frame = CGRect(x: 0, y: button.frame.size.height - 1, width: button.frame.size.width, height: button.frame.size.height)
        buttonBorder.borderWidth = 1
        button.layer.addSublayer(buttonBorder)
        button.layer.masksToBounds = true
    }
    
    static func customizeTextView(_ textView: UITextView, placeholder p: String?) {
        let borderColor = UIColor(red: 221/255.0, green: 221/255.0, blue: 221/255.0, alpha: 1.0)
        let textViewBorder = CALayer()
        
        textViewBorder.borderColor = borderColor.cgColor
        textViewBorder.frame = CGRect(x: 0, y: textView.frame.size.height - 1, width: textView.frame.size.width, height: textView.frame.size.height)
        textViewBorder.borderWidth = 1
        
        textView.layer.addSublayer(textViewBorder)
        textView.layer.masksToBounds = true
        
        textView.placeholder = p
    }
    
    static func addRightViewToTextField(_ textField: UITextField, withText text: String) {
        let rightView = UILabel(frame: CGRect(x: 0, y: 0, width: 40, height: 21))
        rightView.contentMode = .center
        rightView.text = text
        textField.rightViewMode = .always
        textField.rightView = rightView
    }
    
    static func showAlertViewWithInput(_ title: String, delegate d: AnyObject) {
        let searchAlertView = UIAlertView(title: "", message: title, delegate: (d as? UIAlertViewDelegate), cancelButtonTitle: "取消", otherButtonTitles: "确定")
        searchAlertView.alertViewStyle = .plainTextInput
        searchAlertView.textField(at: 0)?.placeholder = title
        searchAlertView.textField(at: 0)?.delegate = d as? UITextFieldDelegate
        searchAlertView.show()
    }
    
    static func showAlertView(_ title: String, delegate d: AnyObject) {
        let alertView = UIAlertView(title: "", message: title, delegate: (d as? UIAlertViewDelegate), cancelButtonTitle: "取消", otherButtonTitles: "确定")
        alertView.alertViewStyle = .default
        alertView.show()
    }
    
    static func setupViewBorder(_ view: AnyObject, borderWidth bWidth: CGFloat, borderColor bColor: UIColor, hasTopBorder: Bool, hasLeftBorder: Bool, hasBottomBorder: Bool, hasRightBorder: Bool) {
        let viewToAddBorder = view as! UIView
        if hasTopBorder {
            let topBorder = UIView(frame: CGRect(x: 0, y: 0, width: viewToAddBorder.frame.size.width, height: bWidth))
            topBorder.backgroundColor = bColor
            viewToAddBorder.addSubview(topBorder)
            viewToAddBorder.bringSubview(toFront: topBorder)
        }
        if hasLeftBorder {
            let leftBorder = UIView(frame: CGRect(x: 0, y: 0, width: bWidth, height: viewToAddBorder.frame.size.height))
            leftBorder.backgroundColor = bColor
            viewToAddBorder.addSubview(leftBorder)
            viewToAddBorder.bringSubview(toFront: leftBorder)
        }
        if hasBottomBorder {
            let bottomBorder = UIView(frame: CGRect(x: 0, y: viewToAddBorder.frame.size.height - bWidth, width: viewToAddBorder.frame.size.width, height: bWidth))
            bottomBorder.backgroundColor = bColor
            viewToAddBorder.addSubview(bottomBorder)
            viewToAddBorder.bringSubview(toFront: bottomBorder)
        }
        if hasRightBorder {
            let rightBorder = UIView(frame: CGRect(x: viewToAddBorder.frame.size.width - bWidth, y: 0, width: bWidth, height: viewToAddBorder.frame.size.height))
            rightBorder.backgroundColor = bColor
            viewToAddBorder.addSubview(rightBorder)
            viewToAddBorder.bringSubview(toFront: rightBorder)
        }
    }
    
    static func dropShadowForView(_ view: UIView) {
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.5
        view.layer.shadowRadius = 0.6
        view.layer.shadowOffset = CGSize(width: 1.0, height: 1.0)
        view.backgroundColor = ColorBackgroundGray
    }
    
}
