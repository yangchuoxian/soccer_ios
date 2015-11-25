//
//  VTMemberProfileTableViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/3.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTMemberProfileTableViewController: UITableViewController, UIActionSheetDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate, UIAlertViewDelegate {
    
    let actionIndex_deleteTeamMember = 1
    let actionIndex_promoteTeamCaptain = 2
    
    enum HttpRequest {
        case deleteTeamMember
        case promoteTeamCaptain
    }

    @IBOutlet weak var imageView_avatar: UIImageView!
    @IBOutlet weak var label_username: UILabel!
    @IBOutlet weak var label_dateOfBirth: UILabel!
    @IBOutlet weak var label_careerAge: UILabel!
    @IBOutlet weak var label_position: UILabel!
    @IBOutlet weak var label_height: UILabel!
    @IBOutlet weak var label_weight: UILabel!
    @IBOutlet weak var label_gender: UILabel!
    @IBOutlet weak var textView_introduction: UITextView!
    
    var userObject: User?
    var button_sendMessage: UIButton?
    var HUD: MBProgressHUD?
    var indexOfCurrentHttpRequest: HttpRequest?
    var removeTeamMemberOrPromoteTeamCaptainAlertView: UIAlertView?
    var currentActionIndexForAlertView: Int?
    var responseData: NSMutableData? = NSMutableData()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.clearsSelectionOnViewWillAppear = true
        Appearance.customizeAvatarImage(self.imageView_avatar)
        Toolbox.removeBottomShadowOfNavigationBar(self.navigationController!.navigationBar)
        // retrieve current selected team info to decide whether current logged in user is the captain of the selected team,
        // since only the captain is allowed to make changes to the team members,
        // changes like
        // a. remove the member from the team or
        // b. promote the member as the new captain
        let currentTeamId = NSUserDefaults.standardUserDefaults().stringForKey("teamIdSelectedInTeamsList")
        let captainUserId = Team.retrieveCaptainIdFromLocalDatabaseWithTeamId(currentTeamId!)
        
        let currentUser = Singleton_CurrentUser.sharedInstance
        if captainUserId != nil {
            // current logged user is the captain of this team
            // also, if the user on this profile page is actually current logged in user, you CANNOT remove yourself from the team or set yourself as the captain since you already are
            if currentUser.userId == captainUserId &&
                currentUser.userId != self.userObject!.userId {
                    // add right button in navigation bar programmatically
                    // since current user is the captain of this team, he/she is allowed to make changes to members in this team
                    self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "more"),
                        style: .Plain,
                        target: self,
                        action: "showExtraActionsAvailableToTeamMember")
            }
        } else {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "没有找到球队")
        }
        
        // load user avatar asynchronously
        Toolbox.loadAvatarImage(self.userObject!.userId, toImageView: self.imageView_avatar, avatarType: AvatarType.User)
        self.label_username.text = self.userObject!.username

        if Toolbox.isStringValueValid(self.userObject!.dateOfBirth) {
            self.label_dateOfBirth.text = self.userObject!.dateOfBirth
        }
        if Toolbox.isStringValueValid(self.userObject!.careerAge) {
            self.label_careerAge.text = self.userObject!.careerAge
        }
        if Toolbox.isStringValueValid(self.userObject!.position) {
            self.label_position.text = self.userObject!.position
        }
        if Toolbox.isStringValueValid(self.userObject!.height) {
            self.label_height.text = "\(self.userObject!.height) cm"
        }
        if Toolbox.isStringValueValid(self.userObject!.weight) {
            self.label_weight.text = "\(self.userObject!.weight) kg"
        }
        if Toolbox.isStringValueValid(self.userObject!.gender) {
            self.label_gender.text = self.userObject!.gender
        }
        if Toolbox.isStringValueValid(self.userObject!.introduction) {
            self.textView_introduction.text = self.userObject!.introduction
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // Set this in the root view controller so that the back button displays back instead of the root view controller name
        Appearance.customizeNavigationBar(self, title: "球员资料")
        // clear the selection style of previously selected table cell
        let selectedIndexPath = self.tableView.indexPathForSelectedRow
        if selectedIndexPath != nil {
            self.tableView.deselectRowAtIndexPath(selectedIndexPath!, animated: true)
        }
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section != 3 {
            return DefaultTableSectionFooterHeight
        } else {
            if Singleton_CurrentUser.sharedInstance.userId != self.userObject!.userId {
                return TableSectionFooterHeightWithButton
            } else {
                return DefaultTableSectionFooterHeight
            }
        }
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section != 3 {
            return UIView(frame: CGRectZero)
        } else {
            let footerView = UIView(frame: CGRectMake(0, 0, ScreenSize.width, TableSectionFooterHeightWithButton))
            
            // only when the current logged user is NOT the user showing in this profile page, do we  add a "send message" button at the bottom, since user cannot send message to himself/herself
            if Singleton_CurrentUser.sharedInstance.userId != self.userObject!.userId {
                // add send message button
                self.button_sendMessage = Appearance.setupTableFooterButtonWithTitle("发送消息", backgroundColor: ColorSettledGreen)
                self.button_sendMessage?.addTarget(self, action: "sendMessageToTeamMember", forControlEvents: .TouchUpInside)
                footerView.addSubview(self.button_sendMessage!)
            }
            return footerView
        }
    }
    
    deinit {
        if self.imageView_avatar != nil {
            self.imageView_avatar.image = nil
        }
        self.userObject = nil
        
        if self.button_sendMessage != nil {
            self.button_sendMessage?.removeTarget(nil, action: nil, forControlEvents: .AllEvents)
            self.button_sendMessage = nil
        }
        
        if self.removeTeamMemberOrPromoteTeamCaptainAlertView != nil {
            self.removeTeamMemberOrPromoteTeamCaptainAlertView?.delegate = nil
            self.removeTeamMemberOrPromoteTeamCaptainAlertView = nil
        }
        self.currentActionIndexForAlertView = nil
        self.responseData = nil
        
        self.HUD = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showExtraActionsAvailableToTeamMember() {
        let setAsCaptain = "设为队长"
        let removeFromTeam = "踢出球队"
        let cancelTitle = "取消"
        let actionSheet = UIActionSheet(
            title: nil,
            delegate: self,
            cancelButtonTitle: cancelTitle,
            destructiveButtonTitle: nil,
            otherButtonTitles: removeFromTeam, setAsCaptain
        )
        actionSheet.showInView(self.view)
    }
    
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 0 {   // cancel button clicked
            return
        }
        var hintMessage = ""
        if buttonIndex == 1 {     // remove this team member from the team
            self.currentActionIndexForAlertView = actionIndex_deleteTeamMember
            hintMessage = "是否确定将该球员踢出球队？"
        } else if buttonIndex == 2 {      // set this team member as captain
            self.currentActionIndexForAlertView = actionIndex_promoteTeamCaptain
            hintMessage = "是否确定将该球员任命为队长？"
        }
        self.removeTeamMemberOrPromoteTeamCaptainAlertView = UIAlertView(
            title: hintMessage,
            message: "",
            delegate: self,
            cancelButtonTitle: "取消",
            otherButtonTitles: "确定"
        )
        self.removeTeamMemberOrPromoteTeamCaptainAlertView?.delegate = self
        self.removeTeamMemberOrPromoteTeamCaptainAlertView?.show()
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 1 {     // establish button clicked, submit the request to either delete team member or promote team captain
            let currentTeamId = NSUserDefaults.standardUserDefaults().stringForKey("teamIdSelectedInTeamsList")
            let postParametersString = "userId=\(self.userObject!.userId)&teamId=\(currentTeamId!)&booted=true"
            
            var connection: NSURLConnection?
            switch self.currentActionIndexForAlertView! {
            case actionIndex_deleteTeamMember:
                connection = Toolbox.asyncHttpPostToURL(URLDeleteTeamMember, parameters: postParametersString, delegate: self)
                self.indexOfCurrentHttpRequest = .deleteTeamMember
                break
            case actionIndex_promoteTeamCaptain:
                connection = Toolbox.asyncHttpPostToURL(URLChangeTeamCaptain, parameters: postParametersString, delegate: self)
                self.indexOfCurrentHttpRequest = .promoteTeamCaptain
                break
            default:
                break
            }
            
            if connection == nil {
                Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
            } else {
                self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: nil)
            }
        }
    }
    
    func sendMessageToTeamMember() {
        self.performSegueWithIdentifier("sendMessageToTeamMemberSegue", sender: self)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "sendMessageToTeamMemberSegue" {
            let currentUser = Singleton_CurrentUser.sharedInstance
            let destinationViewController = segue.destinationViewController as! VTConversationCollectionViewController
            destinationViewController.messageGroupId = Message.decideMessageGroupId(currentUser.userId!, receiverUserId: self.userObject!.userId, messageType: MessageType.OneToOneMessage.rawValue)
            destinationViewController.secondUserId = self.userObject!.userId
            destinationViewController.receiverUsername = self.userObject!.username
        } else if segue.identifier == "memberStatsSegue" {
            let destinationViewController = segue.destinationViewController as! VTMemberStatsTableViewController
            destinationViewController.userObject = self.userObject
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
        
        if self.indexOfCurrentHttpRequest == .promoteTeamCaptain {
            if responseStr == "OK" {
                // go back to the members table view controller and also notify that captain has changed with the captain user id
                NSNotificationCenter.defaultCenter().postNotificationName(
                    "teamCaptainChangedOnServer",
                    object: self.userObject!.userId
                )
                self.navigationController?.popViewControllerAnimated(true)
            } else {    // http request failed with error message
                var HUD = MBProgressHUD(view: self.navigationController?.view)
                self.navigationController?.view.addSubview(HUD)
                HUD.customView = UIImageView(image: UIImage(named: "unhappy"))
                // Set custom view mode
                HUD.mode = .CustomView
                HUD.labelText = responseStr as! String
                HUD.show(true)
                // hide and remove HUD view a while after
                HUD.hide(true, afterDelay: 1)
                HUD = nil
            }
        } else if self.indexOfCurrentHttpRequest == .deleteTeamMember {
            if responseStr == "OK" {
                let currentTeamId = NSUserDefaults.standardUserDefaults().stringForKey("teamIdSelectedInTeamsList")
                // update the number of members for this team in local database
                let newNumberOfMembers = Team.changeNumberOfMembersInTeam(currentTeamId!, reduce: true)
                if newNumberOfMembers != ErrorCode.LocalDatabaseError.rawValue {
                    let teamInfoAfterDeletingTeamMember = [
                        "deletedMemberUserId": self.userObject!.userId,
                        "newNumberOfMembers": "\(newNumberOfMembers)"
                    ]
                    // go back to the members table view controller and also notify that team member has been removed
                    NSNotificationCenter.defaultCenter().postNotificationName("teamMemberDeletedOnServer", object: teamInfoAfterDeletingTeamMember)
                    self.navigationController?.popViewControllerAnimated(true)
                } else {
                    Toolbox.showCustomAlertViewWithImage("unhappy", title: "本地数据库操作失败")
                }
            } else {    // http request failed with error message
                Toolbox.showCustomAlertViewWithImage("unhappy", title: responseStr as! String)
            }
        }
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
}
