//
//  VTActivityNoteViewController.swift
//  soccer
//
//  Created by tejingcai on 15/7/10.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTActivityNoteViewController: UIViewController, NSURLConnectionDelegate, NSURLConnectionDataDelegate, UITextViewDelegate {

    @IBOutlet weak var textView_activityNote: UITextView!
    @IBOutlet weak var button_publish: UIButton!
    
    var HUD: MBProgressHUD?
    var responseData: NSMutableData? = NSMutableData()
    var isNewActivityMatchInitiatedFromDiscoverTab = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // remove navigation bar back button text, just show the chevron_left icon
        self.navigationController!.navigationBar.topItem!.title = ""
        Appearance.customizeNavigationBar(self, title: "活动备注")
        // makes sure the text of textView stays at the top inside the textView
        self.automaticallyAdjustsScrollViewInsets = false
        
        Appearance.customizeTextView(self.textView_activityNote, placeholder: "请输入活动备注消息(300字数以内)")
        self.textView_activityNote.delegate = self
        
        // add right button in navigation bar to cancel new activity publication
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(VTActivityNoteViewController.cancelPublishingNewActivity))
    }
   
    func cancelPublishingNewActivity() {
        if self.isNewActivityMatchInitiatedFromDiscoverTab == true {
            self.performSegue(withIdentifier: "unwindToTeamBriefIntroSegue", sender: self)
        } else {
            self.performSegue(withIdentifier: "unwindToTeamCalendarSegue", sender: self)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // resign the keyboard when tapped somewhere else other than the text field or the keyboard itself
        self.textView_activityNote.resignFirstResponder()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        // Get the placeholder label
        let placeHolderLabel = textView.viewWithTag(TagValue.textViewPlaceholder.rawValue)
        if !textView.hasText {
            placeHolderLabel?.isHidden = false
        } else {
            placeHolderLabel?.isHidden = true
        }
        
        let enteredNoteLength = Toolbox.trim(self.textView_activityNote.text).characters.count
        if enteredNoteLength >= 400 {   // note length too long
            Toolbox.toggleButton(self.button_publish, enabled: false)
        } else {
            Toolbox.toggleButton(self.button_publish, enabled: true)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func publishNewActivity(_ sender: AnyObject) {
        self.textView_activityNote.resignFirstResponder()
        // retrieve activity info from userDefaults
        var activityInfo = UserDefaults.standard.object(forKey: "activityInfo") as! [String: String]
        let activityNote = Toolbox.trim(self.textView_activityNote.text)
        activityInfo["note"] = activityNote
        UserDefaults.standard.set(activityInfo, forKey: "activityInfo")
        
        // convert activityInfo dictionary to JSON string to post to server
        let activityInfoJSONString = Toolbox.convertDictionaryOrArrayToJSONString(activityInfo)
        let idOfInitiatorTeam = Singleton_UserOwnedTeam.sharedInstance.teamId
        let postParameters = "idOfTeamA=\(idOfInitiatorTeam)&newActivity=\(activityInfoJSONString)"
        let connection = Toolbox.asyncHttpPostToURL(URLPublishNewActivity, parameters: postParameters, delegate: self)
        
        if connection == nil {
            // inform the user that the connection failed
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
        let publishedActivityDictionary = (try? JSONSerialization.jsonObject(with: self.responseData! as Data, options: .mutableLeaves)) as? [String: AnyObject]
        
        if publishedActivityDictionary != nil { // new activity published successfully with new activity json data
            // post a notification to let other view controllers new activity published
            let newActivity = Activity(data: publishedActivityDictionary!)
            newActivity.saveOrUpdateActivityInDatabase()
            NotificationCenter.default.post(
                name: Notification.Name(rawValue: "newActivityPublished"), object: newActivity)
            
            // find out from which view controller/tab did this activity initiated,
            // if this activity is a match initiated from discover tab -> teams list sorted by point -> send a challenge, then current view controller should unwind back to the team list table view
            // otherwise if the activity is initiated from team calendar view controller, then current view controller should unwind back to team calendar view
            if self.isNewActivityMatchInitiatedFromDiscoverTab == true {
                self.performSegue(withIdentifier: "unwindToTeamBriefIntroSegue", sender: self)
            } else {
                self.performSegue(withIdentifier: "unwindToTeamCalendarSegue", sender: self)
            }
        } else {    // new activity published failed with error message
            let errorMessage = NSString(data: self.responseData! as Data, encoding: String.Encoding.utf8.rawValue)!
            Toolbox.showCustomAlertViewWithImage("unhappy", title: errorMessage as String)
        }
        UserDefaults.standard.removeObject(forKey: "activityInfo")
        
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    deinit {
        self.HUD = nil
        self.responseData = nil
    }
}
