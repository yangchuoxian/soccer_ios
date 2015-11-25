//
//  VTUpdateTeamNameViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/20.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTUpdateTeamNameViewController: UIViewController, NSURLConnectionDelegate, NSURLConnectionDataDelegate, UITextFieldDelegate {
    
    var teamName: String?
    var teamId: String?
    var HUD: MBProgressHUD?
    var responseData: NSMutableData? = NSMutableData()
    
    @IBOutlet weak var input_teamName: UITextField!
    @IBOutlet weak var button_submit: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.teamId = NSUserDefaults.standardUserDefaults().objectForKey("teamIdSelectedInTeamsList") as? String
        self.input_teamName.text = self.teamName
        self.input_teamName.addTarget(self, action: "validateUserInput", forControlEvents: .EditingChanged)
        self.input_teamName.delegate = self
        
        Appearance.customizeTextField(self.input_teamName, iconName: "jersey")
        Appearance.customizeNavigationBar(self, title: "更改球队名")
    }
    
    func validateUserInput() {
        let enteredTeamNameLength = Toolbox.trim(self.input_teamName.text!).characters.count
        if enteredTeamNameLength > 0 && enteredTeamNameLength < 100 {
            Toolbox.toggleButton(self.button_submit, enabled: true)
        } else {
            Toolbox.toggleButton(self.button_submit, enabled: false)
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == self.input_teamName {
            if self.button_submit.enabled {
                self.input_teamName.resignFirstResponder()
                self.button_submit.sendActionsForControlEvents(.TouchUpInside)
                return true
            }
            return false
        }
        return false
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        // resign the keyboard when tapped somewhere else other than the text field or the keyboard itself
        self.input_teamName.resignFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func updateTeamName(sender: AnyObject) {
        let newTeamName = Toolbox.trim(self.input_teamName.text!)
        let connection = Toolbox.asyncHttpPostToURL(URLChangeTeamName, parameters: "teamId=\(self.teamId!)&teamName=\(newTeamName)", delegate: self)
        if connection == nil {
            // inform the user that the connection failed
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            self.teamName = newTeamName
            self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: nil)
        }
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
        
        if responseStr == "OK" {    // team name update successfully
            // update the team name in local database
            let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
            var correspondingTeams = dbManager.loadDataFromDB(
                "select * from teams where teamId=?",
                parameters: [self.teamId!]
            )
            if correspondingTeams.count > 0 {   // team with such team id found in local database
                let team = Team.formatDatabaseRecordToTeamFormat(correspondingTeams[0] as! [AnyObject])
                // update team name in dictionary and then save it in local database
                team.teamName = self.teamName!
                // save the updated team in local database
                team.saveOrUpdateTeamInDatabase()
                // unwind navigation controller to the previous view controller
                self.navigationController?.popViewControllerAnimated(true)
            } else {    // team with the team id NOT found in local database
                Toolbox.showCustomAlertViewWithImage("unhappy", title: "本地球队不存在")
            }
        } else {    // team name update failed with error
            Toolbox.showCustomAlertViewWithImage("unhappy", title: responseStr as String)
        }
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    deinit {
        self.teamName = nil
        self.teamId = nil
        self.HUD = nil
        self.responseData = nil
    }
}
