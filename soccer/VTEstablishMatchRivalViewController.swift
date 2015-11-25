//
//  VTEstablishMatchRivalViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/7.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTEstablishMatchRivalViewController: UIViewController, UIAlertViewDelegate, UITextFieldDelegate {
    
    var selectedRivalTeamId: String?
    var searchKeyword = ""
    
    @IBOutlet weak var button_nextStep: UIButton!
    @IBOutlet weak var view_containerOfNextStepButton: UIView!
    @IBOutlet weak var containerViewBottomLayoutConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // hide the next step button at start, show the next step button only when user has selected rival team
        self.view_containerOfNextStepButton.alpha = 0
        // remove navigation bar back button text, just show the chevron_left icon
        self.navigationController!.navigationBar.topItem!.title = ""
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "showNextStepButton:", name: "selectedRival", object: nil)
        // add right button in navigation bar programmatically
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Stop, target: self, action: "cancelNewActivityPublication")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "选择比赛对手")
    }
    
    func cancelNewActivityPublication() {
        self.performSegueWithIdentifier("unwindToTeamCalendarSegue", sender: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showNextStepButton(notification: NSNotification) {
        self.selectedRivalTeamId = notification.object as? String
        
        self.view_containerOfNextStepButton.alpha = 1.0
        self.containerViewBottomLayoutConstraint.constant = 61
    }

    @IBAction func searchTeamsByName(sender: AnyObject) {
        // hide the next step button
        self.view_containerOfNextStepButton.alpha = 0
        self.containerViewBottomLayoutConstraint.constant = 0
        
        if #available(iOS 8.0, *) {
            let alertController = UIAlertController(title: "", message: "请输入要搜索的球队名称", preferredStyle: .Alert)
            let actionCancel = UIAlertAction(title: "取消", style: .Cancel) {
                ACTION in return
            }
            let actionInput = UIAlertAction(title: "确定", style: .Default) {
                ACTION in
                // retrieve the user input in textField and start searching
                let textField = alertController.textFields?.first as UITextField?
                let searchKeyword = textField?.text
                
                // if user did not input anything, do not search
                if searchKeyword == nil {
                    return
                }
                if (searchKeyword!).characters.count == 0 {
                    return
                }
                NSNotificationCenter.defaultCenter().postNotificationName(
                    "launchSearchRivals", object: searchKeyword
                )
            }
            
            alertController.addAction(actionCancel)
            alertController.addAction(actionInput)
            alertController.addTextFieldWithConfigurationHandler({
                (textField: UITextField) in
                textField.placeholder = "球队名称"
                textField.keyboardType = .Default
            })
            presentViewController(alertController, animated: true, completion: nil)
        } else {
            Appearance.showAlertViewWithInput("请输入球队名称", delegate: self)
        }
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        self.searchKeyword = textField.text!
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        alertView.dismissWithClickedButtonIndex(buttonIndex, animated: true)
        if buttonIndex == 1 && self.searchKeyword.characters.count > 0 {
            NSNotificationCenter.defaultCenter().postNotificationName("launchSearchRivals", object: searchKeyword)
        }
    }
    
    @IBAction func showNearbyTeams(sender: AnyObject) {
        // hide the next step button
        self.view_containerOfNextStepButton.alpha = 0
        self.containerViewBottomLayoutConstraint.constant = 0
        NSNotificationCenter.defaultCenter().postNotificationName("getNearbyRivals", object: nil)
    }
    
    @IBAction func nextStep(sender: AnyObject) {
        if self.selectedRivalTeamId == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "请选定对手球队")
            return
        }
        // retrieve activity info
        var activityInfo = NSUserDefaults.standardUserDefaults().objectForKey("activityInfo") as! [String: AnyObject]
        // save selected rival team id in userDefaults
        activityInfo["idOfTeamB"] = self.selectedRivalTeamId!
        NSUserDefaults.standardUserDefaults().setObject(activityInfo, forKey: "activityInfo")
        self.performSegueWithIdentifier("matchNoteSegue", sender: self)
    }
    
    deinit {
        self.selectedRivalTeamId = nil
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
