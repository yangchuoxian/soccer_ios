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

        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        // the below sets the background color of table view footer and header
        UITableViewHeaderFooterView.appearance().tintColor = UIColor.clear
        // listen to settingsInstructionComplete message and handles it
        NotificationCenter.default.addObserver(self, selector: #selector(VTSystemSettingsTableViewController.notifySettingsInstructionComplete(_:)), name: NSNotification.Name(rawValue: "settingsInstructionComplete"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "设置")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func notifySettingsInstructionComplete(_ notification: Notification) {
        let nameOfSettingsOption: String = (notification.object as AnyObject).object(forKey: "settings") as! String
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        if (indexPath as NSIndexPath).section == 2 && (indexPath as NSIndexPath).row == 2 {   // table cell of clean cache data is tapped
            let HUD = MBProgressHUD(view: self.navigationController?.view)
            self.view.addSubview(HUD!)
            HUD?.show(true)
            HUD?.hide(true)
            Toolbox.showCustomAlertViewWithImage("checkmark", title: "缓存清理成功")
        }
        if (indexPath as NSIndexPath).section == 3 && (indexPath as NSIndexPath).row == 0 {   // logout cell tapped
            self.submitLogout()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "aboutUsSegue" {
            let destinationViewController = segue.destination as! VTPostViewController
            destinationViewController.postType = .AboutUs
        } else if segue.identifier == "FAQSegue" {
            let destinationViewController = segue.destination as! VTPostViewController
            destinationViewController.postType = .FAQ
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
            self.button_logout?.removeTarget(nil, action: nil, for: .allEvents)
            self.button_logout = nil
        }
        self.responseData = nil
    }
    
}
