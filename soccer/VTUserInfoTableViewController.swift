//
//  VTUserInfoTableViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/29.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTUserInfoTableViewController: UITableViewController {
    
    @IBOutlet weak var label_username: UILabel!
    @IBOutlet weak var label_email: UILabel!
    @IBOutlet weak var label_name: UILabel!
    @IBOutlet weak var label_location: UILabel!
    @IBOutlet weak var label_phoneNumber: UILabel!
    @IBOutlet weak var imageView_avatar: UIImageView!
    @IBOutlet weak var imageView_QRCode: UIImageView!
    @IBOutlet weak var label_careerAge: UILabel!
    @IBOutlet weak var label_position: UILabel!
    @IBOutlet weak var label_height: UILabel!
    @IBOutlet weak var label_weight: UILabel!
    @IBOutlet weak var label_gender: UILabel!
    @IBOutlet weak var label_dateOfBirth: UILabel!
    @IBOutlet weak var textView_introduction: UITextView!
    @IBOutlet weak var switch_isLookingForTeam: UISwitch!

    let positions = ["门将", "左后卫", "右后卫", "中后卫", "左中场", "右中场", "攻击型中场", "前锋",]
    let genders = ["男", "女"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = true
        
        // this will remove extra separators from tableView
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        // retrieve username, avatar image, email address, actual name, phone number, location from singleton currentUser instance and show them
        let currentUser = Singleton_CurrentUser.sharedInstance
        self.label_username.text = currentUser.username
        self.label_email.text = currentUser.email
        
        if Toolbox.isStringValueValid(currentUser.name) {
            self.label_name.text = currentUser.name
        }
        if Toolbox.isStringValueValid(currentUser.location) {
            self.label_location.text = currentUser.location
        }
        if Toolbox.isStringValueValid(currentUser.phoneNumber) {
            self.label_phoneNumber.text = currentUser.phoneNumber
        }
        if Toolbox.isStringValueValid(currentUser.position) {
            self.label_position.text = currentUser.position
        }
        if Toolbox.isStringValueValid(currentUser.introduction) {
            self.textView_introduction.text = currentUser.introduction
        }
        if Toolbox.isStringValueValid(currentUser.height) {
            self.label_height.text = currentUser.height! + " cm"
        }
        if Toolbox.isStringValueValid(currentUser.weight) {
            self.label_weight.text = currentUser.weight! + " kg"
        }
        if Toolbox.isStringValueValid(currentUser.careerAge) {
            self.label_careerAge.text = currentUser.careerAge! + " 年"
        }
        if Toolbox.isStringValueValid(currentUser.dateOfBirth) {
            self.label_dateOfBirth.text = currentUser.dateOfBirth
        }
        if Toolbox.isStringValueValid(currentUser.gender) {
            self.label_gender.text = currentUser.gender
        }
        if currentUser.isLookingForTeam == LookForTeamStatus.IsLookingForTeam.rawValue {
            self.switch_isLookingForTeam.setOn(true, animated: false)
        } else {
            self.switch_isLookingForTeam.setOn(false, animated: false)
        }

        self.textView_introduction.userInteractionEnabled = false
        // load current user avatar
        Toolbox.loadAvatarImage(currentUser.userId!, toImageView: self.imageView_avatar, avatarType: AvatarType.User)
 
        self.imageView_avatar.layer.cornerRadius = 5.0
        self.tableView.rowHeight = DefaultTableRowHeight
        
        // listen to userInfoUpdated message and handles it by updating the user info value
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateUserInfo:", name: "userInfoUpdated", object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "基本资料")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func updateUserInfo(notification: NSNotification) {
        let nameOfUpdatedUserInfo = (notification.object as! NSDictionary).objectForKey("userInfoIndex") as! String
        let currentUser = Singleton_CurrentUser.sharedInstance
        if nameOfUpdatedUserInfo == "userAvatar" {
            let avatarFilePath = Toolbox.getAvatarImagePathForModelId(currentUser.userId!)
            self.imageView_avatar.image = UIImage(contentsOfFile: avatarFilePath!)
            Toolbox.showCustomAlertViewWithImage("checkmark", title: "头像更新成功")
        } else if nameOfUpdatedUserInfo == "username" {
            self.label_username.text = currentUser.username
            Toolbox.showCustomAlertViewWithImage("checkmark", title: "用户名更新成功")
        } else if nameOfUpdatedUserInfo == "email" {
            self.label_email.text = currentUser.email
            Toolbox.showCustomAlertViewWithImage("checkmark", title: "邮箱地址更新成功")
        } else if nameOfUpdatedUserInfo == "name" {
            self.label_name.text = currentUser.name
            Toolbox.showCustomAlertViewWithImage("checkmark", title: "姓名更新成功")
        } else if nameOfUpdatedUserInfo == "phoneNumber" {
            self.label_phoneNumber.text = currentUser.phoneNumber
            Toolbox.showCustomAlertViewWithImage("checkmark", title: "手机号码更新成功")
        } else if nameOfUpdatedUserInfo == "location" {
            self.label_location.text = currentUser.location
            Toolbox.showCustomAlertViewWithImage("checkmark", title: "地址信息更新成功")
        } else if nameOfUpdatedUserInfo == "height" {
            self.label_height.text = currentUser.height! + " cm"
            Toolbox.showCustomAlertViewWithImage("checkmark", title: "身高信息更改成功")
        } else if nameOfUpdatedUserInfo == "weight" {
            self.label_weight.text = currentUser.weight! + " kg"
            Toolbox.showCustomAlertViewWithImage("checkmark", title: "体重信息更改成功")
        } else if nameOfUpdatedUserInfo == "introduction" {
            self.textView_introduction.text = currentUser.introduction
            Toolbox.showCustomAlertViewWithImage("checkmark", title: "个人简介更新成功")
        } else if nameOfUpdatedUserInfo == "careerAge" {
            self.label_careerAge.text = currentUser.careerAge! + " 年"
            Toolbox.showCustomAlertViewWithImage("checkmark", title: "球龄更新成功")
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if indexPath.section == 2 {
            switch indexPath.row {
            case 0: // birth date cell selected
                let selectedDate = NSDate()
                let selectedTableCell = self.tableView.cellForRowAtIndexPath(indexPath)
                let birthDatePicker = ActionSheetDatePicker(title: "选择生日", datePickerMode: .Date, selectedDate: selectedDate, minimumDate: nil, maximumDate: nil, target: self, action: "birthDateSelected:", cancelAction: nil, origin: selectedTableCell)
                birthDatePicker.hideCancel = false
                birthDatePicker.showActionSheetPicker()
                break
            case 2: // player position cell selected
                ActionSheetStringPicker.showPickerWithTitle("选择场上位置",
                    rows: self.positions,
                    initialSelection: 0,
                    doneBlock: {
                        picker, index, value in
                        self.label_position.text = value as? String
                        Singleton_CurrentUser.sharedInstance.updateUserInfo(
                            "position", infoValue: value)
                        return
                    }, cancelBlock: {
                        picker in return
                    }, origin: self.view)
                break
            case 5: // gender cell selected
                ActionSheetStringPicker.showPickerWithTitle("选择性别",
                    rows: self.genders,
                    initialSelection: 0,
                    doneBlock: {
                        picker, index, value in
                        self.label_gender.text = value as? String
                        Singleton_CurrentUser.sharedInstance.updateUserInfo("gender", infoValue: value)
                        return
                    }, cancelBlock: {
                        picker in return
                    }, origin: self.view)
                break
            default:
                break
            }
        }
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: 0))
        footerView.backgroundColor = UIColor.clearColor()
        
        return footerView
    }
    
    func birthDateSelected(selectedDate: NSDate) {
        let dateOfBirth = (selectedDate.description as NSString).substringToIndex(10)
        self.label_dateOfBirth.text = dateOfBirth
        Singleton_CurrentUser.sharedInstance.updateUserInfo("dateOfBirth", infoValue: dateOfBirth)
    }
    
    @IBAction func changeIsLookingForGroupStatus(sender: AnyObject) {
        var isLookingForTeam = LookForTeamStatus.NotLookingForTeam.rawValue
        if self.switch_isLookingForTeam.on == true {    // looking for team status set to true
            isLookingForTeam = LookForTeamStatus.IsLookingForTeam.rawValue
        }
        Singleton_CurrentUser.sharedInstance.updateUserInfo("isLookingForTeam", infoValue: isLookingForTeam)
    }
    
    @IBAction func unwindToUserInfoTableView(segue: UIStoryboardSegue) {
    }
    
    deinit {
        if self.imageView_QRCode != nil {
            self.imageView_QRCode.image = nil
        }
        if self.imageView_avatar != nil {
            self.imageView_avatar.image = nil
        }
    }
}
