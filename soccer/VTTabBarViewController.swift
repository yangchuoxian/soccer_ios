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
        tabDiscoverNavigationViewController.tabBarItem.tag = TabIndex.Discover.rawValue
        tabMessageNavigationViewController.tabBarItem = UITabBarItem(title: "消息", image: UIImage(named: "tab_chat_outline"), selectedImage: UIImage(named: "tab_chat"))
        tabMessageNavigationViewController.tabBarItem.tag = TabIndex.Message.rawValue
        tabTeamNavigationViewController.tabBarItem = UITabBarItem(title: "球队", image: UIImage(named: "tab_football_outline"), selectedImage: UIImage(named: "tab_football"))
        tabTeamNavigationViewController.tabBarItem.tag = TabIndex.Team.rawValue
        tabMeNavigationViewController.tabBarItem = UITabBarItem(title: "我的", image: UIImage(named: "tab_person_outline"), selectedImage: UIImage(named: "tab_person"))
        tabMeNavigationViewController.tabBarItem.tag = TabIndex.Me.rawValue
        
        self.totalNumOfUnreadMessages = 0
        let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        let numOfUnreads = dbManager.loadDataFromDB(
            "select count(id) from messages where status=? and recipientId=?",
            parameters: [MessageStatus.Unread.rawValue, Singleton_CurrentUser.sharedInstance.userId!]
        )

        self.totalNumOfUnreadMessages = numOfUnreads[0][0].integerValue
        if self.totalNumOfUnreadMessages > 0 {
            (self.tabBar.items![TabIndex.Message.rawValue] ).badgeValue = "\(Int(self.totalNumOfUnreadMessages))"
        }
        
        // listen to totalNumOfUnreadMessagesChanged message and handles it by updating the badge value on top of tabbar icon
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateTotalNumOfUnreadMessages:", name: "totalNumOfUnreadMessagesChanged", object: nil)
        self.tabBar.barTintColor = ColorLighterGray
        // set up the tab bar icon color when selected
        UITabBar.appearance().tintColor = ColorSettledGreen
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func updateTotalNumOfUnreadMessages(notification: NSNotification) {
        let actionInfo = notification.object as! [NSObject: AnyObject]
        if (actionInfo["action"] as! String) == "+" {
            self.totalNumOfUnreadMessages = self.totalNumOfUnreadMessages + actionInfo["quantity"]!.integerValue
        } else {
            self.totalNumOfUnreadMessages = self.totalNumOfUnreadMessages - actionInfo["quantity"]!.integerValue
        }
        if self.totalNumOfUnreadMessages > 0 {
            (self.tabBar.items![TabIndex.Message.rawValue] ).badgeValue = "\(self.totalNumOfUnreadMessages)"
        } else {
            (self.tabBar.items![TabIndex.Message.rawValue] ).badgeValue = nil
        }
    }
    
    override func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
    }
    
    override func viewControllerForUnwindSegueAction(action: Selector, fromViewController: UIViewController, withSender sender: AnyObject?) -> UIViewController? {
        return self.selectedViewController?.viewControllerForUnwindSegueAction(action, fromViewController: fromViewController, withSender: sender)
    }
    
}
