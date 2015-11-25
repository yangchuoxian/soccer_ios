//
//  VTAttendeesTableViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/19.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTAttendeesTableViewController: UITableViewController, NSURLConnectionDelegate, NSURLConnectionDataDelegate, UIAlertViewDelegate {
    
    enum HttpRequest {
        case GetActivityPersonnel
        case SetupActivityAttendeesStatus
    }
    
    var hasAttendeesSettled = ActivityAttendeesStatus.NotSettled.rawValue
    var currentHttpRequest: HttpRequest?
    var acceptedMembers = [User]()
    var rejectedMembers = [User]()
    var participatedMemberIds = [String]()
    var bailedMemberIds = [String]()
    var teamName: String?
    var teamId: String?
    var activityId: String?
    var teamCaptainId: String?
    var activityStatus: Int?
    var responseData: NSMutableData? = NSMutableData()
    var HUD: MBProgressHUD?
    var button_submitAttendeesParticipatingStatus: UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Appearance.customizeNavigationBar(self, title: "参与人员")
        // add the UIRefreshControl to tableView
        self.refreshControl = Appearance.setupRefreshControl()
        self.refreshControl?.addTarget(self, action: "refreshAttendees", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(self.refreshControl!)
        
        // remove separators of cells for static table view
        self.clearsSelectionOnViewWillAppear = true
        self.tableView.tableFooterView = UIView(frame: CGRectZero)

        self.tableView.rowHeight = CustomTableRowHeight
        self.navigationController!.navigationBar.topItem!.title = ""
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "postActivityAttendeesStatusToServer", name: "establishedRecordActivityAttendeesStatus", object: nil)
        // get team attendees for this activity from server
        self.refreshAttendees()
    }
    
    func refreshAttendees() {
        let urlToGetAttendeesOfTeamForActivity:String = URLGetActivityPersonnelForTeam + "?activityId=\(self.activityId!)&teamId=\(self.teamId!)"
        let connection = Toolbox.asyncHttpGetFromURL(urlToGetAttendeesOfTeamForActivity, delegate: self)
        if connection == nil {
            // inform the user that the connection failed
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        }
        self.currentHttpRequest = .GetActivityPersonnel
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Display a message and an image when the table is empty
        let emptyTableBackgroundView:UIView = UIView(frame: CGRect(x: 0, y: self.tableView.frame.origin.y, width: self.tableView.frame.size.width, height: self.tableView.frame.size.height))
        emptyTableBackgroundView.tag = TagValue.EmptyTableBackgroundView.rawValue
        
        let imageView_noAttendeeIcon = UIImageView(image: UIImage(named: "no_team"))
        imageView_noAttendeeIcon.frame = CGRect(
            x: ScreenSize.width / 2 - 55,
            y: ScreenSize.height / 2 - (55 + ToolbarHeight + NavigationbarHeight),
            width: 110,
            height: 110
        )
        imageView_noAttendeeIcon.tag = 1
        let label_noAttendeeHint = UILabel(frame: CGRect(
            x: ScreenSize.width / 2 - 55,
            y: imageView_noAttendeeIcon.frame.origin.y + 120,
            width: self.tableView.frame.size.width,
            height: 50
        ))
        label_noAttendeeHint.tag = 2
        label_noAttendeeHint.text = "暂无参与人员"
        label_noAttendeeHint.textColor = EmptyImageColor
        label_noAttendeeHint.numberOfLines = 0
        label_noAttendeeHint.textAlignment = .Center
        label_noAttendeeHint.sizeToFit()
        
        emptyTableBackgroundView.addSubview(imageView_noAttendeeIcon)
        emptyTableBackgroundView.addSubview(label_noAttendeeHint)
        
        if self.acceptedMembers.count > 0 || self.rejectedMembers.count > 0{
            self.tableView.backgroundView = nil
            
            // remove all subviews in tableView
            for subView in self.tableView.subviews {
                if subView.tag == TagValue.EmptyTableBackgroundView.rawValue {
                    subView.removeFromSuperview()
                }
            }
        } else {
            self.tableView.addSubview(emptyTableBackgroundView)
            self.tableView.sendSubviewToBack(emptyTableBackgroundView)
        }
        
        // return the number of sections
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return self.acceptedMembers.count
        } else if section == 1 {
            return self.rejectedMembers.count
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            if self.acceptedMembers.count > 0 {
                return TableSectionHeaderHeight
            }
        } else if section == 1 {
            if self.rejectedMembers.count > 0 {
                return TableSectionHeaderHeight
            }
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 1 {
            if self.shouldAllowChangeAttendeesParticipatingStatus() {
                // if current user is captain of the team, and if the activity is already done, 
                // then allows captain to update attendees participating status by adding a 
                // participating status submit button int section 2 footer view
                return TableSectionFooterHeightWithButton
            } else {
                return 0
            }
        } else {
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 1 {
            if self.shouldAllowChangeAttendeesParticipatingStatus() == true && self.hasAttendeesSettled == ActivityAttendeesStatus.NotSettled.rawValue {
                let footerView = UIView(frame: CGRectMake(0, 0, ScreenSize.width, TableSectionFooterHeightWithButton))
                self.button_submitAttendeesParticipatingStatus = Appearance.setupTableFooterButtonWithTitle("提交参与人员名单", backgroundColor: ColorSettledGreen)
                self.button_submitAttendeesParticipatingStatus?.addTarget(self, action: "submitMembersParticipatingStatus", forControlEvents: .TouchUpInside)
                footerView.addSubview(self.button_submitAttendeesParticipatingStatus!)
                
                return footerView
            }
        }
        let emptyFooterView = UIView(frame: CGRectMake(0, 0, ScreenSize.width, 0))
        emptyFooterView.backgroundColor = UIColor.clearColor()
        return emptyFooterView
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            if self.acceptedMembers.count > 0 {
                let view_header = UIView(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: TableSectionHeaderHeight))
                view_header.backgroundColor = ColorBackgroundGray
                view_header.addSubview(Appearance.setupTableSectionHeaderTitle("" + self.teamName! + " 同意参加的球员"))
                
                return view_header
            }
        } else if section == 1 {
            if self.rejectedMembers.count > 0 {
                let view_header = UIView(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: TableSectionHeaderHeight))
                view_header.backgroundColor = ColorBackgroundGray
                view_header.addSubview(Appearance.setupTableSectionHeaderTitle("" + self.teamName! + " 拒绝参加的球员"))
                
                return view_header
            }
        }
        return nil
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = self.tableView.dequeueReusableCellWithIdentifier("attendeeCell") as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: "attendeeCell")
        }
        var member: User
        if indexPath.section == 0 {
            member = self.acceptedMembers[indexPath.row]
        } else {
            member = self.rejectedMembers[indexPath.row]
        }
        
        let imageView_userAvatar = cell?.contentView.viewWithTag(1) as! UIImageView
        Toolbox.loadAvatarImage(member.userId, toImageView: imageView_userAvatar, avatarType: AvatarType.Team)
        let label_username = cell?.contentView.viewWithTag(2) as! UILabel
        label_username.text = member.username
        let label_position = cell?.contentView.viewWithTag(3) as! UILabel
        label_position.text = member.position
        
        let label_attendedOrNotHint = cell?.contentView.viewWithTag(4) as? UILabel
        
        for view in cell!.contentView.subviews {
            if view.theClassName == "UISwitch" {
                let switch_attendedOrNot = view as! UISwitch
                if !self.shouldAllowChangeAttendeesParticipatingStatus() {
                    label_attendedOrNotHint!.hidden = true
                    switch_attendedOrNot.hidden = true
                }
                if self.hasAttendeesSettled == ActivityAttendeesStatus.Settled.rawValue {
                    label_attendedOrNotHint!.hidden = false
                    if self.participatedMemberIds.contains(member.userId) {
                        label_attendedOrNotHint!.text = "已参加"
                    } else {
                        label_attendedOrNotHint!.text = "未参加"
                    }
                    switch_attendedOrNot.hidden = true
                }
            }
        }
        return cell!
    }
    
    /**
    *  Current user can set the player's attended or not status ONLY IF:
    * 1. the activity is already happened, and
    * 2. current user is the team captain of this team
    * otherwise, hide the hint label and toggle switch
    * If cell is in the rejected members section, hide the hint label and toggle switch as well
    */
    func shouldAllowChangeAttendeesParticipatingStatus() -> Bool {
        if self.activityStatus != ActivityStatus.Done.rawValue || self.teamCaptainId != Singleton_CurrentUser.sharedInstance.userId {
            return false
        } else {
            return true
        }
    }
    
    func submitMembersParticipatingStatus() {
        if #available(iOS 8.0, *) {
            let alertController = UIAlertController(title: "", message: "参与人员确定后，即无法更改，是否继续？", preferredStyle: .Alert)
            let actionCancel = UIAlertAction(title: "取消", style: .Cancel) {
                ACTION in return
            }
            let actionOk = UIAlertAction(title: "确定", style: .Default) {
                ACTION in
                NSNotificationCenter.defaultCenter().postNotificationName(
                    "establishedRecordActivityAttendeesStatus", object: nil
                )
                return
            }
            
            alertController.addAction(actionCancel)
            alertController.addAction(actionOk)
            presentViewController(alertController, animated: true, completion: nil)
        } else {
            Appearance.showAlertView("参与人员确定后，即无法更改，是否继续？", delegate: self)
        }
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        alertView.dismissWithClickedButtonIndex(buttonIndex, animated: true)
        if buttonIndex == 1 {
            self.postActivityAttendeesStatusToServer()
        }
    }
    
    func postActivityAttendeesStatusToServer() {
        // iterate all table cells to check UISwitch on/off value
        let numOfRowsInAcceptedMembersSection = self.tableView.numberOfRowsInSection(0)
        let numOfRowsInRejectedMembersSection = self.tableView.numberOfRowsInSection(1)
        if numOfRowsInAcceptedMembersSection > 0 {
            for i in 0...(numOfRowsInAcceptedMembersSection - 1) {
                let tableCell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0))
                for view in tableCell!.contentView.subviews {
                    if view.theClassName == "UISwitch" {
                        let switch_attendedOrNot = view as! UISwitch
                        if switch_attendedOrNot.on {
                            self.participatedMemberIds.append(self.acceptedMembers[i].userId)
                        } else {
                            self.bailedMemberIds.append(self.acceptedMembers[i].userId)
                        }
                        break
                    }
                }
            }
        }
        if numOfRowsInRejectedMembersSection > 0 {
            for i in 0...(numOfRowsInRejectedMembersSection - 1) {
                let tableCell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: 1))
                for view in tableCell!.contentView.subviews {
                    if view.theClassName == "UISwitch" {
                        let switch_attendedOrNot = view as! UISwitch
                        if switch_attendedOrNot.on {
                            self.participatedMemberIds.append(self.rejectedMembers[i].userId)
                        }
                        break
                    }
                }
            }
        }
        let participatedIdsJSON = Toolbox.convertDictionaryOrArrayToJSONString(self.participatedMemberIds)
        let bailedIdsJSON = Toolbox.convertDictionaryOrArrayToJSONString(self.bailedMemberIds)
        
        let connection = Toolbox.asyncHttpPostToURL(
            URLSetupActivityAttendeesStatus,
            parameters: "activityId=\(self.activityId!)&teamId=\(self.teamId!)&participatedUserIds=\(participatedIdsJSON)&bailedUserIds=\(bailedIdsJSON)",
            delegate: self
        )
        if connection == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: nil)
        }
        self.currentHttpRequest = .SetupActivityAttendeesStatus
    }

    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        self.responseData?.appendData(data)
    }
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        self.refreshControl?.endRefreshing()
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络超时")
        self.responseData = nil
        self.responseData = NSMutableData()
        self.HUD?.hide(true)
        self.HUD = nil
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        self.refreshControl?.endRefreshing()
        self.HUD?.hide(true)
        self.HUD = nil
        if self.currentHttpRequest == .GetActivityPersonnel {   // get activity personnel http request
            let attendeesDictionary = (try? NSJSONSerialization.JSONObjectWithData(self.responseData!, options: .MutableLeaves)) as? [NSObject: AnyObject]
            if attendeesDictionary != nil { // http request succeeded
                self.hasAttendeesSettled = attendeesDictionary!["hasAttendeesSettled"] as! Int
                self.acceptedMembers.removeAll()
                self.rejectedMembers.removeAll()
                self.participatedMemberIds.removeAll()
                self.bailedMemberIds.removeAll()
                for acceptedMemberDictionary in (attendeesDictionary!["acceptedMembers"] as! [[NSObject: AnyObject]]) {
                    self.acceptedMembers.append(User(data: acceptedMemberDictionary))
                }
                for rejectedMemberDictionary in (attendeesDictionary!["rejectedMembers"] as! [[NSObject: AnyObject]]) {
                    self.rejectedMembers.append(User(data: rejectedMemberDictionary))
                }
                for participatedMemberId in (attendeesDictionary!["participatedMemberIds"] as! [String]) {
                    self.participatedMemberIds.append(participatedMemberId)
                }
                for bailedMemberId in (attendeesDictionary!["bailedMemberIds"] as! [String]) {
                    self.bailedMemberIds.append(bailedMemberId)
                }
                self.teamCaptainId = attendeesDictionary!["teamCaptain"] as? String
                self.tableView.reloadData()
            } else {    // http request failed with error
                let errorMessage = NSString(data: self.responseData!, encoding: NSUTF8StringEncoding)
                Toolbox.showCustomAlertViewWithImage("unhappy", title: errorMessage as! String)
            }
        } else if self.currentHttpRequest == .SetupActivityAttendeesStatus {    // set up activity attendees status http request
            let responseStr = NSString(data: self.responseData!, encoding: NSUTF8StringEncoding)
            if responseStr == "OK" {
                self.hasAttendeesSettled = ActivityAttendeesStatus.Settled.rawValue
                self.tableView.reloadData()
            } else {
                Toolbox.showCustomAlertViewWithImage("unhappy", title: responseStr as! String)
            }
        }
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    deinit {
        self.acceptedMembers.removeAll()
        self.rejectedMembers.removeAll()
        self.participatedMemberIds.removeAll()
        self.bailedMemberIds.removeAll()
        self.teamName = nil
        self.teamId = nil
        self.activityId = nil
        self.teamCaptainId = nil
        self.responseData = nil
        self.HUD = nil
        self.currentHttpRequest = nil
    }
}
