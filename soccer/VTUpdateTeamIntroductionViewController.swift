//
//  VTUpdateTeamIntroductionViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/20.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTUpdateTeamIntroductionViewController: UIViewController, NSURLConnectionDelegate, NSURLConnectionDataDelegate, UITextViewDelegate {
    
    var HUD: MBProgressHUD?
    var teamId: String?
    var introduction: String?
    var responseData: NSMutableData? = NSMutableData()

    @IBOutlet weak var textView_introduction: UITextView!
    @IBOutlet weak var button_submit: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Appearance.customizeNavigationBar(self, title: "球队简介")
        Appearance.customizeTextView(self.textView_introduction, placeholder: "请输入球队简介(300字以内)")
        
        // makes sure the text of textView stays at the top inside the textView
        self.automaticallyAdjustsScrollViewInsets = false
        
        self.teamId = NSUserDefaults.standardUserDefaults().objectForKey("teamIdSelectedInTeamsList") as? String
        self.textView_introduction.text = self.introduction
        self.textView_introduction.delegate = self
        // Get the placeholder label, if the introduction is not empty, we should hide the placeholder label
        let placeHolderLabel = self.textView_introduction.viewWithTag(TagValue.TextViewPlaceholder.rawValue)
        if self.introduction?.characters.count > 0 {
            placeHolderLabel?.hidden = true
        }

    }
    
    func textViewDidChange(textView: UITextView) {
        // Get the placeholder label
        let placeHolderLabel = textView.viewWithTag(TagValue.TextViewPlaceholder.rawValue)
        if !textView.hasText() {
            placeHolderLabel?.hidden = false
        } else {
            placeHolderLabel?.hidden = true
        }
        
        let enteredIntroductionLength = Toolbox.trim(self.textView_introduction.text).characters.count
        if enteredIntroductionLength > 0 && enteredIntroductionLength < 300 {
            Toolbox.toggleButton(self.button_submit, enabled: true)
        } else {
            Toolbox.toggleButton(self.button_submit, enabled: false)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        // resign the keyboard when tapped somewhere else other than the text field or the keyboard itself
        self.textView_introduction.resignFirstResponder()
    }
    
    @IBAction func updateTeamIntroduction(sender: AnyObject) {
        self.introduction = Toolbox.trim(self.textView_introduction.text)
        if !Toolbox.isStringValueValid(self.introduction) {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "请输入球队简介")
            return
        }
        if (self.introduction!).characters.count > 300 {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "球队简介须在300字以内")
            return
        }
        var connection = Toolbox.asyncHttpPostToURL(URLChangeTeamIntroduction, parameters: "id=" + self.teamId! + "&introduction=" + self.introduction!, delegate: self)
        if connection == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: nil)
        }
        // release the allocated memory
        connection = nil
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        self.responseData?.appendData(data)
    }
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        self.HUD?.hide(true)
        self.HUD = nil
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络超时")
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        self.HUD?.hide(true)
        self.HUD = nil
        let responseStr:NSString = NSString(data: self.responseData!, encoding: NSUTF8StringEncoding)!
        
        if responseStr == "OK" {    // team introduction updated successfully
            // update the team introduction in local database
            let dbManager:DBManager = DBManager(databaseFilename: "soccer_ios.sqlite")
            let correspondingTeams = dbManager.loadDataFromDB(
                "select * from teams where teamId=?",
                parameters: [self.teamId!]
            )
            if correspondingTeams.count > 0 {  // team with such team id found in local database
                let team = Team.formatDatabaseRecordToTeamFormat(correspondingTeams[0] as! [AnyObject])
                // update team introduction in dictionary and then save it in local database
                team.introduction = self.introduction!
                // save the updated team in local database
                team.saveOrUpdateTeamInDatabase()
                
                // unwind navigation controller to the previous view controller
                self.navigationController?.popViewControllerAnimated(true)
            } else {    // team with the team id NOT found in local database
                Toolbox.showCustomAlertViewWithImage("unhappy", title: "本地球队不存在")
            }
        } else {    // team introduction update failed with error message
            Toolbox.showCustomAlertViewWithImage("unhappy", title: responseStr as String)
        }
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    deinit {
        self.HUD = nil
        self.teamId = nil
        self.introduction = nil
        self.responseData = nil
    }
}
