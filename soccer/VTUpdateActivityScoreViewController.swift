//
//  VTUpdateActivityScoreViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/9/4.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTUpdateActivityScoreViewController: UIViewController, NSURLConnectionDelegate, NSURLConnectionDataDelegate, UITextFieldDelegate {

    @IBOutlet weak var input_selfTeamScore: UITextField!
    @IBOutlet weak var button_save: UIButton!
    
    var responseData: NSMutableData? = NSMutableData()
    var HUD: MBProgressHUD?
    var activityId: String?
    var teamId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController!.navigationBar.topItem!.title = ""
        Appearance.customizeNavigationBar(self, title: "我方得分")
        Appearance.customizeTextField(self.input_selfTeamScore, iconName: "match_outline")
        self.input_selfTeamScore.addTarget(self, action: "validateUserInput", forControlEvents: .EditingChanged)
        self.input_selfTeamScore.delegate = self
    }
    
    func validateUserInput() {
        let enteredScore = Int(Toolbox.trim(self.input_selfTeamScore.text!))
        if enteredScore >= 0 && enteredScore <= 300 {
            Toolbox.toggleButton(self.button_save, enabled: true)
        } else {
            Toolbox.toggleButton(self.button_save, enabled: false)
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == self.input_selfTeamScore {
            if self.button_save.enabled {
                self.input_selfTeamScore.resignFirstResponder()
                self.button_save.sendActionsForControlEvents(.TouchUpInside)
                return true
            }
        }
        return false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.input_selfTeamScore.resignFirstResponder()
    }
    
    @IBAction func submitSelfTeamScore(sender: AnyObject) {
        let score = Toolbox.trim(self.input_selfTeamScore.text!)
        let connection = Toolbox.asyncHttpPostToURL(URLSetActivityScoreForTeam, parameters: "activityId=\(self.activityId!)&teamId=\(self.teamId!)&score=\(score)", delegate: self)
        if connection == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
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
        
        let responseStr = NSString(data: self.responseData!, encoding: NSUTF8StringEncoding)
        if responseStr == "OK" {
            NSNotificationCenter.defaultCenter().postNotificationName("scoreUpdated", object: self.input_selfTeamScore.text)
            self.performSegueWithIdentifier("unwindToActivityInfoTableViewSegue", sender: self)
        } else {
            self.input_selfTeamScore.text = nil
            Toolbox.toggleButton(self.button_save, enabled: false)
            Toolbox.showCustomAlertViewWithImage("unhappy", title: responseStr as! String)
        }
        
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    deinit {
        self.responseData = nil
        self.HUD = nil
    }
    
}
