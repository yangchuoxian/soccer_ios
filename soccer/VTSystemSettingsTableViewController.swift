//
//  VTSystemSettingsTableViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/30.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTSystemSettingsTableViewController: UITableViewController, NSURLConnectionDelegate, NSURLConnectionDataDelegate {
    
    var HUD: MBProgressHUD?
    var button_logout: UIButton?
    var responseData: NSMutableData? = NSMutableData()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        // the below sets the background color of table view footer and header
        UITableViewHeaderFooterView.appearance().tintColor = UIColor.clearColor()
        // listen to settingsInstructionComplete message and handles it
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "notifySettingsInstructionComplete:", name: "settingsInstructionComplete", object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "设置")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func notifySettingsInstructionComplete(notification: NSNotification) {
        let nameOfSettingsOption: String = notification.object?.objectForKey("settings") as! String
        if nameOfSettingsOption == "feedback" {
            Toolbox.showCustomAlertViewWithImage("checkmark", title: "提交意见成功")
        } else {
            Toolbox.showCustomAlertViewWithImage("checkmark", title: "修改密码成功")
        }
    }
    
    func submitLogout() {
        let urlToLogout = URLLogout + "?id=" + Singleton_CurrentUser.sharedInstance.userId!
        var connection = Toolbox.asyncHttpGetFromURL(urlToLogout, delegate: self)
        if connection == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: nil)
        }
        connection = nil
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if indexPath.section == 2 && indexPath.row == 2 {   // table cell of clean cache data is tapped
            let HUD = MBProgressHUD(view: self.navigationController?.view)
            self.view.addSubview(HUD)
            HUD.show(true)
            HUD.hide(true)
            Toolbox.showCustomAlertViewWithImage("checkmark", title: "缓存清理成功")
        }
        if indexPath.section == 3 && indexPath.row == 0 {   // logout cell tapped
            self.submitLogout()
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "aboutUsSegue" {
            let destinationViewController = segue.destinationViewController as! VTPostViewController
            destinationViewController.postType = .AboutUs
        } else if segue.identifier == "FAQSegue" {
            let destinationViewController = segue.destinationViewController as! VTPostViewController
            destinationViewController.postType = .FAQ
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
        if responseStr == "logged out" {    // successfully logged out
            Singleton_CurrentUser.sharedInstance.logout()
        } else {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "退出登录失败")
        }
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    deinit {
        self.HUD = nil
        if self.button_logout != nil {
            self.button_logout?.removeTarget(nil, action: nil, forControlEvents: .AllEvents)
            self.button_logout = nil
        }
        self.responseData = nil
    }
    
}
