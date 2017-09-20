//
//  VTUpdateActivityScoreViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/9/4.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}

fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}


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
        self.input_selfTeamScore.addTarget(self, action: #selector(VTUpdateActivityScoreViewController.validateUserInput), for: .editingChanged)
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.input_selfTeamScore {
            if self.button_save.isEnabled {
                self.input_selfTeamScore.resignFirstResponder()
                self.button_save.sendActions(for: .touchUpInside)
                return true
            }
        }
        return false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.input_selfTeamScore.resignFirstResponder()
    }
    
    @IBAction func submitSelfTeamScore(_ sender: AnyObject) {
        let score = Toolbox.trim(self.input_selfTeamScore.text!)
        let connection = Toolbox.asyncHttpPostToURL(URLSetActivityScoreForTeam, parameters: "activityId=\(self.activityId!)&teamId=\(self.teamId!)&score=\(score)", delegate: self)
        if connection == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: nil)
        }
    }
    
    func connection(_ connection: NSURLConnection, didReceive data: Data) {
        self.responseData?.append(data)
    }
    
    func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        self.HUD?.hide(true)
        self.HUD = nil
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络超时")
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        self.HUD?.hide(true)
        self.HUD = nil
        
        let responseStr = NSString(data: self.responseData! as Data, encoding: String.Encoding.utf8.rawValue)
        if responseStr == "OK" {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "scoreUpdated"), object: self.input_selfTeamScore.text)
            self.performSegue(withIdentifier: "unwindToActivityInfoTableViewSegue", sender: self)
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
