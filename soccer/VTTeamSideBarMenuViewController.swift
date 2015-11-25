//
//  VTTeamSideBarMenuViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/9/21.
//  Copyright © 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTTeamSideBarMenuViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var menuTableView: UITableView?
    var icon_basicInfo: UIImageView?
    var icon_activities: UIImageView?
    var icon_members: UIImageView?
    var icon_arrangement: UIImageView?
    var imageView_avatar: UIImageView?
    var selectedTeamId = NSUserDefaults.standardUserDefaults().stringForKey("teamIdSelectedInTeamsList")
    var selectedTeamName = ""
    var currentEntryIndex = 1

    let menuEntryHeight: CGFloat = 54
    let numberOfMenuEntries = 5
    static let cellIdentifier = "menuEntryCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.selectedTeamName = Team.retrieveTeamNameFromLocalDatabaseWithTeamId(self.selectedTeamId!)
        self.icon_basicInfo = UIImageView(frame: CGRectMake(15, (self.menuEntryHeight - 20) / 2, 20, 20))
        self.icon_basicInfo?.image = UIImage(named: "details")
        self.icon_basicInfo?.image = self.icon_basicInfo?.image!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        self.icon_basicInfo?.tintColor = UIColor.whiteColor()
        
        self.icon_activities = UIImageView(frame: CGRectMake(15, (self.menuEntryHeight - 20) / 2, 20, 20))
        self.icon_activities?.image = UIImage(named: "activities")
        self.icon_activities?.image = self.icon_activities?.image!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        self.icon_activities?.tintColor = UIColor.whiteColor()

        self.icon_members = UIImageView(frame: CGRectMake(15, (self.menuEntryHeight - 20) / 2, 20, 20))
        self.icon_members?.image = UIImage(named: "members")
        self.icon_members?.image = self.icon_members?.image!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        self.icon_members?.tintColor = UIColor.whiteColor()
        
        self.icon_arrangement = UIImageView(frame: CGRectMake(15, (self.menuEntryHeight - 20) / 2, 20, 20))
        self.icon_arrangement?.image = UIImage(named: "player_positions")
        self.icon_arrangement?.image = self.icon_arrangement?.image!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        self.icon_arrangement?.tintColor = UIColor.whiteColor()
        
        self.imageView_avatar = UIImageView(frame: CGRectMake(15, (self.menuEntryHeight - 40) / 2, 40, 40))
        self.imageView_avatar?.backgroundColor = UIColor.whiteColor()
        self.imageView_avatar?.layer.borderWidth = 1.0
        self.imageView_avatar?.layer.borderColor = UIColor.whiteColor().CGColor
        self.imageView_avatar?.layer.masksToBounds = true
        self.imageView_avatar?.layer.cornerRadius = self.imageView_avatar!.frame.size.width / 2

        
        self.menuTableView = UITableView(frame: CGRectMake(0, (self.view.frame.size.height - self.menuEntryHeight * CGFloat(self.numberOfMenuEntries)) / 2.0, self.view.frame.size.width, self.menuEntryHeight * CGFloat(self.numberOfMenuEntries)))
        self.menuTableView?.autoresizingMask = [.FlexibleTopMargin, .FlexibleBottomMargin, .FlexibleWidth]
        self.menuTableView?.delegate = self
        self.menuTableView?.dataSource = self
        self.menuTableView?.opaque = false
        self.menuTableView?.backgroundColor = UIColor.clearColor()
        self.menuTableView?.separatorStyle = .None
        self.menuTableView?.bounces = false
        
        self.view.addSubview(self.menuTableView!)
        
        // listen to teamRecordSavedOrUpdated message and handles it by updating team info in current view controller
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateTeamInfo", name: "teamRecordSavedOrUpdated", object: nil)
    }
    
    /**
    Team name or avatar changed possibly, reload the team name and avatar regardless
    */
    func updateTeamInfo() {
        self.selectedTeamName = Team.retrieveTeamNameFromLocalDatabaseWithTeamId(self.selectedTeamId!)
        self.menuTableView?.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row != self.currentEntryIndex {
            switch indexPath.row {
            case 1:
                let storyboard = UIStoryboard(name: StoryboardNames.TeamGeneralInfo.rawValue, bundle: nil)
                let navigationController = storyboard.instantiateViewControllerWithIdentifier("teamGeneralInfoNavigationController") as! UINavigationController
                navigationController.setViewControllers([storyboard.instantiateViewControllerWithIdentifier("teamGeneralTableViewController")], animated: false)
                self.sideMenuViewController.setContentViewController(navigationController, animated: true)
                
                self.icon_basicInfo?.tintColor = UIColor.lightGrayColor()
                self.icon_activities?.tintColor = UIColor.whiteColor()
                self.icon_members?.tintColor = UIColor.whiteColor()
                self.icon_arrangement?.tintColor = UIColor.whiteColor()
                break
            case 2:
                let storyboard = UIStoryboard(name: StoryboardNames.TeamCalendar.rawValue, bundle: nil)
                let navigationController = storyboard.instantiateViewControllerWithIdentifier("teamCalendarNavigationController") as! UINavigationController
                navigationController.setViewControllers([storyboard.instantiateViewControllerWithIdentifier("teamCalendarViewController")], animated: false)
                self.sideMenuViewController.setContentViewController(navigationController, animated: true)
                
                self.icon_basicInfo?.tintColor = UIColor.whiteColor()
                self.icon_activities?.tintColor = UIColor.lightGrayColor()
                self.icon_members?.tintColor = UIColor.whiteColor()
                self.icon_arrangement?.tintColor = UIColor.whiteColor()
                break
            case 3:
                let storyboard = UIStoryboard(name: StoryboardNames.TeamMembers.rawValue, bundle: nil)
                let navigationController = storyboard.instantiateViewControllerWithIdentifier("teamMembersNavigationController") as! UINavigationController
                navigationController.setViewControllers([storyboard.instantiateViewControllerWithIdentifier("membersContainerViewController")], animated: false)
                self.sideMenuViewController.setContentViewController(navigationController, animated: true)
                
                self.icon_basicInfo?.tintColor = UIColor.whiteColor()
                self.icon_activities?.tintColor = UIColor.whiteColor()
                self.icon_members?.tintColor = UIColor.lightGrayColor()
                self.icon_arrangement?.tintColor = UIColor.whiteColor()
                break
            case 4:
                self.icon_basicInfo?.tintColor = UIColor.whiteColor()
                self.icon_activities?.tintColor = UIColor.whiteColor()
                self.icon_members?.tintColor = UIColor.whiteColor()
                self.icon_arrangement?.tintColor = UIColor.lightGrayColor()
                break
                default:
                break
            }
            self.currentEntryIndex = indexPath.row
        }
        self.sideMenuViewController.hideMenuViewController()
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return self.menuEntryHeight
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.numberOfMenuEntries
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(VTTeamSideBarMenuViewController.cellIdentifier)
        
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: VTTeamSideBarMenuViewController.cellIdentifier)
            cell?.backgroundColor = UIColor.clearColor()
            cell?.textLabel?.font = UIFont(name: "HelveticaNeue", size: 17)
            cell?.textLabel?.textColor = UIColor.whiteColor()
            cell?.textLabel?.highlightedTextColor = UIColor.lightGrayColor()
            cell?.selectedBackgroundView = UIView()
        }
        
        switch indexPath.row {
        case 0:
            Toolbox.loadAvatarImage(self.selectedTeamId!, toImageView: self.imageView_avatar!, avatarType: AvatarType.Team)
            cell?.textLabel?.text = "           \(self.selectedTeamName)"
            cell?.textLabel?.highlightedTextColor = UIColor.whiteColor()
            cell?.contentView.addSubview(self.imageView_avatar!)
            break
        case 1:
            cell?.textLabel?.text = "        基本信息"
            cell?.contentView.addSubview(self.icon_basicInfo!)
            break
        case 2:
            cell?.textLabel?.text = "        活动日程"
            cell?.contentView.addSubview(self.icon_activities!)
            break
        case 3:
            cell?.textLabel?.text = "        成员列表"
            cell?.contentView.addSubview(self.icon_members!)
            break
        case 4:
            cell?.textLabel?.text = "        排兵布阵"
            cell?.contentView.addSubview(self.icon_arrangement!)
        default:
            break
        }
        
        return cell!
    }

}
