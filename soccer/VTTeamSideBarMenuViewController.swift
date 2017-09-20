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
    var selectedTeamId = UserDefaults.standard.string(forKey: "teamIdSelectedInTeamsList")
    var selectedTeamName = ""
    var currentEntryIndex = 1

    let menuEntryHeight: CGFloat = 54
    let numberOfMenuEntries = 5
    static let cellIdentifier = "menuEntryCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.selectedTeamName = Team.retrieveTeamNameFromLocalDatabaseWithTeamId(self.selectedTeamId!)
        self.icon_basicInfo = UIImageView(frame: CGRect(x: 15, y: (self.menuEntryHeight - 20) / 2, width: 20, height: 20))
        self.icon_basicInfo?.image = UIImage(named: "details")
        self.icon_basicInfo?.image = self.icon_basicInfo?.image!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        self.icon_basicInfo?.tintColor = UIColor.white
        
        self.icon_activities = UIImageView(frame: CGRect(x: 15, y: (self.menuEntryHeight - 20) / 2, width: 20, height: 20))
        self.icon_activities?.image = UIImage(named: "activities")
        self.icon_activities?.image = self.icon_activities?.image!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        self.icon_activities?.tintColor = UIColor.white

        self.icon_members = UIImageView(frame: CGRect(x: 15, y: (self.menuEntryHeight - 20) / 2, width: 20, height: 20))
        self.icon_members?.image = UIImage(named: "members")
        self.icon_members?.image = self.icon_members?.image!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        self.icon_members?.tintColor = UIColor.white
        
        self.icon_arrangement = UIImageView(frame: CGRect(x: 15, y: (self.menuEntryHeight - 20) / 2, width: 20, height: 20))
        self.icon_arrangement?.image = UIImage(named: "player_positions")
        self.icon_arrangement?.image = self.icon_arrangement?.image!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        self.icon_arrangement?.tintColor = UIColor.white
        
        self.imageView_avatar = UIImageView(frame: CGRect(x: 15, y: (self.menuEntryHeight - 40) / 2, width: 40, height: 40))
        self.imageView_avatar?.backgroundColor = UIColor.white
        self.imageView_avatar?.layer.borderWidth = 1.0
        self.imageView_avatar?.layer.borderColor = UIColor.white.cgColor
        self.imageView_avatar?.layer.masksToBounds = true
        self.imageView_avatar?.layer.cornerRadius = self.imageView_avatar!.frame.size.width / 2

        
        self.menuTableView = UITableView(frame: CGRect(x: 0, y: (self.view.frame.size.height - self.menuEntryHeight * CGFloat(self.numberOfMenuEntries)) / 2.0, width: self.view.frame.size.width, height: self.menuEntryHeight * CGFloat(self.numberOfMenuEntries)))
        self.menuTableView?.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleWidth]
        self.menuTableView?.delegate = self
        self.menuTableView?.dataSource = self
        self.menuTableView?.isOpaque = false
        self.menuTableView?.backgroundColor = UIColor.clear
        self.menuTableView?.separatorStyle = .none
        self.menuTableView?.bounces = false
        
        self.view.addSubview(self.menuTableView!)
        
        // listen to teamRecordSavedOrUpdated message and handles it by updating team info in current view controller
        NotificationCenter.default.addObserver(self, selector: #selector(VTTeamSideBarMenuViewController.updateTeamInfo), name: NSNotification.Name(rawValue: "teamRecordSavedOrUpdated"), object: nil)
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).row != self.currentEntryIndex {
            switch (indexPath as NSIndexPath).row {
            case 1:
                let storyboard = UIStoryboard(name: StoryboardNames.TeamGeneralInfo.rawValue, bundle: nil)
                let navigationController = storyboard.instantiateViewController(withIdentifier: "teamGeneralInfoNavigationController") as! UINavigationController
                navigationController.setViewControllers([storyboard.instantiateViewController(withIdentifier: "teamGeneralTableViewController")], animated: false)
                self.sideMenuViewController.setContentViewController(navigationController, animated: true)
                
                self.icon_basicInfo?.tintColor = UIColor.lightGray
                self.icon_activities?.tintColor = UIColor.white
                self.icon_members?.tintColor = UIColor.white
                self.icon_arrangement?.tintColor = UIColor.white
                break
            case 2:
                let storyboard = UIStoryboard(name: StoryboardNames.TeamCalendar.rawValue, bundle: nil)
                let navigationController = storyboard.instantiateViewController(withIdentifier: "teamCalendarNavigationController") as! UINavigationController
                navigationController.setViewControllers([storyboard.instantiateViewController(withIdentifier: "teamCalendarViewController")], animated: false)
                self.sideMenuViewController.setContentViewController(navigationController, animated: true)
                
                self.icon_basicInfo?.tintColor = UIColor.white
                self.icon_activities?.tintColor = UIColor.lightGray
                self.icon_members?.tintColor = UIColor.white
                self.icon_arrangement?.tintColor = UIColor.white
                break
            case 3:
                let storyboard = UIStoryboard(name: StoryboardNames.TeamMembers.rawValue, bundle: nil)
                let navigationController = storyboard.instantiateViewController(withIdentifier: "teamMembersNavigationController") as! UINavigationController
                navigationController.setViewControllers([storyboard.instantiateViewController(withIdentifier: "membersContainerViewController")], animated: false)
                self.sideMenuViewController.setContentViewController(navigationController, animated: true)
                
                self.icon_basicInfo?.tintColor = UIColor.white
                self.icon_activities?.tintColor = UIColor.white
                self.icon_members?.tintColor = UIColor.lightGray
                self.icon_arrangement?.tintColor = UIColor.white
                break
            case 4:
                self.icon_basicInfo?.tintColor = UIColor.white
                self.icon_activities?.tintColor = UIColor.white
                self.icon_members?.tintColor = UIColor.white
                self.icon_arrangement?.tintColor = UIColor.lightGray
                break
                default:
                break
            }
            self.currentEntryIndex = (indexPath as NSIndexPath).row
        }
        self.sideMenuViewController.hideViewController()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.menuEntryHeight
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.numberOfMenuEntries
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: VTTeamSideBarMenuViewController.cellIdentifier)
        
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: VTTeamSideBarMenuViewController.cellIdentifier)
            cell?.backgroundColor = UIColor.clear
            cell?.textLabel?.font = UIFont(name: "HelveticaNeue", size: 17)
            cell?.textLabel?.textColor = UIColor.white
            cell?.textLabel?.highlightedTextColor = UIColor.lightGray
            cell?.selectedBackgroundView = UIView()
        }
        
        switch (indexPath as NSIndexPath).row {
        case 0:
            Toolbox.loadAvatarImage(self.selectedTeamId!, toImageView: self.imageView_avatar!, avatarType: AvatarType.team)
            cell?.textLabel?.text = "           \(self.selectedTeamName)"
            cell?.textLabel?.highlightedTextColor = UIColor.white
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
