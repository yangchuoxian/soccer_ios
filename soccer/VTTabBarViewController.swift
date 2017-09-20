//
//  VTTabBarViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/2.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTTabBarViewController: UITabBarController {
    
    var totalNumOfUnreadMessages: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        // promatically add view controllers as tabbar controllers since we're separating tabbar controllers into different storyboards
        let tabDiscoverStoryboard = UIStoryboard(name: StoryboardNames.TabDiscover.rawValue, bundle: nil)
        let tabDiscoverNavigationViewController = tabDiscoverStoryboard.instantiateInitialViewController() as! UINavigationController
        
        let tabMessageStoryboard = UIStoryboard(name: StoryboardNames.TabMessage.rawValue, bundle: nil)
        let tabMessageNavigationViewController = tabMessageStoryboard.instantiateInitialViewController() as! UINavigationController
        
        let tabTeamStoryboard = UIStoryboard(name: StoryboardNames.TabTeam.rawValue, bundle: nil)
        let tabTeamNavigationViewController = tabTeamStoryboard.instantiateInitialViewController() as! UINavigationController
        
        let tabMeStoryboard = UIStoryboard(name: StoryboardNames.TabMe.rawValue, bundle: nil)
        let tabMeNavigationViewController = tabMeStoryboard.instantiateInitialViewController() as! UINavigationController
        
        self.viewControllers = [tabDiscoverNavigationViewController, tabMessageNavigationViewController, tabTeamNavigationViewController, tabMeNavigationViewController]
        
        tabDiscoverNavigationViewController.tabBarItem = UITabBarItem(title: "发现", image: UIImage(named: "tab_discover"), selectedImage: UIImage(named: "tab_discover"))
        tabDiscoverNavigationViewController.tabBarItem.tag = TabIndex.discover.rawValue
        tabMessageNavigationViewController.tabBarItem = UITabBarItem(title: "消息", image: UIImage(named: "tab_chat_outline"), selectedImage: UIImage(named: "tab_chat"))
        tabMessageNavigationViewController.tabBarItem.tag = TabIndex.message.rawValue
        tabTeamNavigationViewController.tabBarItem = UITabBarItem(title: "球队", image: UIImage(named: "tab_football_outline"), selectedImage: UIImage(named: "tab_football"))
        tabTeamNavigationViewController.tabBarItem.tag = TabIndex.team.rawValue
        tabMeNavigationViewController.tabBarItem = UITabBarItem(title: "我的", image: UIImage(named: "tab_person_outline"), selectedImage: UIImage(named: "tab_person"))
        tabMeNavigationViewController.tabBarItem.tag = TabIndex.me.rawValue
        
        self.totalNumOfUnreadMessages = 0
        let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        let numOfUnreads = dbManager?.loadData(
            fromDB: "select count(id) from messages where status=? and recipientId=?",
            parameters: [MessageStatus.unread.rawValue, Singleton_CurrentUser.sharedInstance.userId!]
        )

        self.totalNumOfUnreadMessages = numOfUnreads[0][0].intValue
        if self.totalNumOfUnreadMessages > 0 {
            (self.tabBar.items![TabIndex.message.rawValue] ).badgeValue = "\(Int(self.totalNumOfUnreadMessages))"
        }
        
        // listen to totalNumOfUnreadMessagesChanged message and handles it by updating the badge value on top of tabbar icon
        NotificationCenter.default.addObserver(self, selector: #selector(VTTabBarViewController.updateTotalNumOfUnreadMessages(_:)), name: NSNotification.Name(rawValue: "totalNumOfUnreadMessagesChanged"), object: nil)
        self.tabBar.barTintColor = ColorLighterGray
        // set up the tab bar icon color when selected
        UITabBar.appearance().tintColor = ColorSettledGreen
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func updateTotalNumOfUnreadMessages(_ notification: Notification) {
        let actionInfo = notification.object as! [AnyHashable: Any]
        if (actionInfo["action"] as! String) == "+" {
            self.totalNumOfUnreadMessages = self.totalNumOfUnreadMessages + (actionInfo["quantity"]! as AnyObject).intValue
        } else {
            self.totalNumOfUnreadMessages = self.totalNumOfUnreadMessages - (actionInfo["quantity"]! as AnyObject).intValue
        }
        if self.totalNumOfUnreadMessages > 0 {
            (self.tabBar.items![TabIndex.message.rawValue] ).badgeValue = "\(self.totalNumOfUnreadMessages)"
        } else {
            (self.tabBar.items![TabIndex.message.rawValue] ).badgeValue = nil
        }
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
    }
    
    override func forUnwindSegueAction(_ action: Selector, from fromViewController: UIViewController, withSender sender: Any?) -> UIViewController? {
        return self.selectedViewController?.forUnwindSegueAction(action, from: fromViewController, withSender: sender)
    }
    
}
