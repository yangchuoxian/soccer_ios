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
        case getActivityPersonnel
        case setupActivityAttendeesStatus
    }
    
    var hasAttendeesSettled = ActivityAttendeesStatus.notSettled.rawValue
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
        self.refreshControl?.addTarget(self, action: #selector(VTAttendeesTableViewController.refreshAttendees), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(self.refreshControl!)
        
        // remove separators of cells for static table view
        self.clearsSelectionOnViewWillAppear = true
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)

        self.tableView.rowHeight = CustomTableRowHeight
        self.navigationController!.navigationBar.topItem!.title = ""
        
        NotificationCenter.default.addObserver(self, selector: #selector(VTAttendeesTableViewController.postActivityAttendeesStatusToServer), name: NSNotification.Name(rawValue: "establishedRecordActivityAttendeesStatus"), object: nil)
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
        self.currentHttpRequest = .getActivityPersonnel
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // Display a message and an image when the table is empty
        let emptyTableBackgroundView:UIView = UIView(frame: CGRect(x: 0, y: self.tableView.frame.origin.y, width: self.tableView.frame.size.width, height: self.tableView.frame.size.height))
        emptyTableBackgroundView.tag = TagValue.emptyTableBackgroundView.rawValue
        
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
        label_noAttendeeHint.textAlignment = .center
        label_noAttendeeHint.sizeToFit()
        
        emptyTableBackgroundView.addSubview(imageView_noAttendeeIcon)
        emptyTableBackgroundView.addSubview(label_noAttendeeHint)
        
        if self.acceptedMembers.count > 0 || self.rejectedMembers.count > 0{
            self.tableView.backgroundView = nil
            
            // remove all subviews in tableView
            for subView in self.tableView.subviews {
                if subView.tag == TagValue.emptyTableBackgroundView.rawValue {
                    subView.removeFromSuperview()
                }
            }
        } else {
            self.tableView.addSubview(emptyTableBackgroundView)
            self.tableView.sendSubview(toBack: emptyTableBackgroundView)
        }
        
        // return the number of sections
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return self.acceptedMembers.count
        } else if section == 1 {
            return self.rejectedMembers.count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
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
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
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
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 1 {
            if self.shouldAllowChangeAttendeesParticipatingStatus() == true && self.hasAttendeesSettled == ActivityAttendeesStatus.notSettled.rawValue {
                let footerView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: TableSectionFooterHeightWithButton))
                self.button_submitAttendeesParticipatingStatus = Appearance.setupTableFooterButtonWithTitle("提交参与人员名单", backgroundColor: ColorSettledGreen)
                self.button_submitAttendeesParticipatingStatus?.addTarget(self, action: #selector(VTAttendeesTableViewController.submitMembersParticipatingStatus), for: .touchUpInside)
                footerView.addSubview(self.button_submitAttendeesParticipatingStatus!)
                
                return footerView
            }
        }
        let emptyFooterView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: 0))
        emptyFooterView.backgroundColor = UIColor.clear
        return emptyFooterView
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = self.tableView.dequeueReusableCell(withIdentifier: "attendeeCell") as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "attendeeCell")
        }
        var member: User
        if (indexPath as NSIndexPath).section == 0 {
            member = self.acceptedMembers[(indexPath as NSIndexPath).row]
        } else {
            member = self.rejectedMembers[(indexPath as NSIndexPath).row]
        }
        
        let imageView_userAvatar = cell?.contentView.viewWithTag(1) as! UIImageView
        Toolbox.loadAvatarImage(member.userId, toImageView: imageView_userAvatar, avatarType: AvatarType.team)
        let label_username = cell?.contentView.viewWithTag(2) as! UILabel
        label_username.text = member.username
        let label_position = cell?.contentView.viewWithTag(3) as! UILabel
        label_position.text = member.position
        
        let label_attendedOrNotHint = cell?.contentView.viewWithTag(4) as? UILabel
        
        for view in cell!.contentView.subviews {
            if view.theClassName == "UISwitch" {
                let switch_attendedOrNot = view as! UISwitch
                if !self.shouldAllowChangeAttendeesParticipatingStatus() {
                    label_attendedOrNotHint!.isHidden = true
                    switch_attendedOrNot.isHidden = true
                }
                if self.hasAttendeesSettled == ActivityAttendeesStatus.settled.rawValue {
                    label_attendedOrNotHint!.isHidden = false
                    if self.participatedMemberIds.contains(member.userId) {
                        label_attendedOrNotHint!.text = "已参加"
                    } else {
                        label_attendedOrNotHint!.text = "未参加"
                    }
                    switch_attendedOrNot.isHidden = true
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
        if self.activityStatus != ActivityStatus.done.rawValue || self.teamCaptainId != Singleton_CurrentUser.sharedInstance.userId {
            return false
        } else {
            return true
        }
    }
    
    func submitMembersParticipatingStatus() {
        if #available(iOS 8.0, *) {
            let alertController = UIAlertController(title: "", message: "参与人员确定后，即无法更改，是否继续？", preferredStyle: .alert)
            let actionCancel = UIAlertAction(title: "取消", style: .cancel) {
                ACTION in return
            }
            let actionOk = UIAlertAction(title: "确定", style: .default) {
                ACTION in
                NotificationCenter.default.post(
                    name: Notification.Name(rawValue: "establishedRecordActivityAttendeesStatus"), object: nil
                )
                return
            }
            
            alertController.addAction(actionCancel)
            alertController.addAction(actionOk)
            present(alertController, animated: true, completion: nil)
        } else {
            Appearance.showAlertView("参与人员确定后，即无法更改，是否继续？", delegate: self)
        }
    }
    
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        alertView.dismiss(withClickedButtonIndex: buttonIndex, animated: true)
        if buttonIndex == 1 {
            self.postActivityAttendeesStatusToServer()
        }
    }
    
    func postActivityAttendeesStatusToServer() {
        // iterate all table cells to check UISwitch on/off value
        let numOfRowsInAcceptedMembersSection = self.tableView.numberOfRows(inSection: 0)
        let numOfRowsInRejectedMembersSection = self.tableView.numberOfRows(inSection: 1)
        if numOfRowsInAcceptedMembersSection > 0 {
            for i in 0...(numOfRowsInAcceptedMembersSection - 1) {
                let tableCell = self.tableView.cellForRow(at: IndexPath(row: i, section: 0))
                for view in tableCell!.contentView.subviews {
                    if view.theClassName == "UISwitch" {
                        let switch_attendedOrNot = view as! UISwitch
                        if switch_attendedOrNot.isOn {
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
                let tableCell = self.tableView.cellForRow(at: IndexPath(row: i, section: 1))
                for view in tableCell!.contentView.subviews {
                    if view.theClassName == "UISwitch" {
                        let switch_attendedOrNot = view as! UISwitch
                        if switch_attendedOrNot.isOn {
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
        self.currentHttpRequest = .setupActivityAttendeesStatus
    }

    func connection(_ connection: NSURLConnection, didReceive data: Data) {
        self.responseData?.append(data)
    }
    
    func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        self.refreshControl?.endRefreshing()
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络超时")
        self.responseData = nil
        self.responseData = NSMutableData()
        self.HUD?.hide(true)
        self.HUD = nil
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        self.refreshControl?.endRefreshing()
        self.HUD?.hide(true)
        self.HUD = nil
        if self.currentHttpRequest == .getActivityPersonnel {   // get activity personnel http request
            let attendeesDictionary = (try? JSONSerialization.jsonObject(with: self.responseData! as Data, options: .mutableLeaves)) as? [AnyHashable: Any]
            if attendeesDictionary != nil { // http request succeeded
                self.hasAttendeesSettled = attendeesDictionary!["hasAttendeesSettled"] as! Int
                self.acceptedMembers.removeAll()
                self.rejectedMembers.removeAll()
                self.participatedMemberIds.removeAll()
                self.bailedMemberIds.removeAll()
                for acceptedMemberDictionary in (attendeesDictionary!["acceptedMembers"] as! [[AnyHashable: Any]]) {
                    self.acceptedMembers.append(User(data: acceptedMemberDictionary as [NSObject : AnyObject]))
                }
                for rejectedMemberDictionary in (attendeesDictionary!["rejectedMembers"] as! [[AnyHashable: Any]]) {
                    self.rejectedMembers.append(User(data: rejectedMemberDictionary as [NSObject : AnyObject]))
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
                let errorMessage = NSString(data: self.responseData! as Data, encoding: String.Encoding.utf8.rawValue)
                Toolbox.showCustomAlertViewWithImage("unhappy", title: errorMessage as! String)
            }
        } else if self.currentHttpRequest == .setupActivityAttendeesStatus {    // set up activity attendees status http request
            let responseStr = NSString(data: self.responseData! as Data, encoding: String.Encoding.utf8.rawValue)
            if responseStr == "OK" {
                self.hasAttendeesSettled = ActivityAttendeesStatus.settled.rawValue
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
