//
//  VTTutorialPageContentViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/27.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTTutorialPageContentViewController: UIViewController {
    
    let numOfTutorialPages = 3
    var pageIndex: Int = 0
    var imageName: String = ""

    @IBOutlet weak var button_enterApp: UIButton!
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.backgroundImageView.image = UIImage(named: self.imageName)
        self.button_enterApp.setTitle("进入" + AppDisplayName, forState: .Normal)
        
        self.button_enterApp.backgroundColor = ColorDarkerGreen
        self.button_enterApp.layer.cornerRadius = 2.0
        
        if self.pageIndex == (self.numOfTutorialPages - 1) {
            self.button_enterApp.enabled = true
            self.button_enterApp.hidden = false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func startToUseApp(sender: AnyObject) {
        // check if username and password is saved in keychain, if so, login automatically
        let userCredential = Toolbox.getUserCredential()
        if userCredential != nil {    // username and loginToken already stored in keychain, get user info and then change rootViewController to mainTabBarViewController
            let currentUserId = userCredential!["currentUserId"]
            // set post parameters
            let getParametersString = Toolbox.addDeviceIDAndDeviceTypeToHttpRequestParameters("?id=\(currentUserId!)")
            let userInfoResponseData = Toolbox.syncHttpGetFromURL(URLGetUserInfo + "\(getParametersString)")
            if userInfoResponseData != nil {
                let userJSON = (try? NSJSONSerialization.JSONObjectWithData(userInfoResponseData!, options: .MutableLeaves)) as? [NSObject: AnyObject]
                if userJSON != nil {    // get user info succeeded
                    Singleton_CurrentUser.sharedInstance.processUserLogin(userJSON!)
                    return
                }
            }
        }
        Toolbox.switchToLoginViewController()
    }
    
}
