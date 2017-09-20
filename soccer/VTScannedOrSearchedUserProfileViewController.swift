//
//  VTScannedOrSearchedUserProfileTableViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/2.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTScannedOrSearchedUserProfileTableViewController: UITableViewController, UIActionSheetDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate {

    enum ApplicationResponse {
        case accept
        case reject
    }
    
    var userObject: User?
    var HUD: MBProgressHUD?
    var currentApplicationResponse: ApplicationResponse?
    var responseData: NSMutableData? = NSMutableData()
    var applicationMessageId: String?
    /**
     * if the user is already a potential user, meaning that either
     * a. the team captain has already sent an invitation to him/her and this user hasn't respond to the invitation yet, then the team captain can NO longer send another invitation to him/her, or
     * b. the user has already sent an application for membership to this team, the team captain could either accept or reject the user's application
     */
    var potentialMemberType: PotentialMemberType?
    var button_sendInvitation: UIButton?
    
    @IBOutlet weak var imageView_avatar: UIImageView!
    @IBOutlet weak var label_username: UILabel!
    @IBOutlet weak var textView_introduction: UITextView!
    
    @IBOutlet weak var label_dateOfBirth: UILabel!
    @IBOutlet weak var label_careerAge: UILabel!
    @IBOutlet weak var label_position: UILabel!
    @IBOutlet weak var label_height: UILabel!
    @IBOutlet weak var label_weight: UILabel!
    @IBOutlet weak var label_gender: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Appearance.customizeAvatarImage(self.imageView_avatar)
        Toolbox.removeBottomShadowOfNavigationBar(self.navigationController!.navigationBar)
        
        // Set this in the root view controller so that the back button displays back instead of the root view controller name
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        // load user avatar asynchronously
        Toolbox.loadAvatarImage(self.userObject!.userId, toImageView: self.imageView_avatar, avatarType: AvatarType.user)
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
        
        // if this user has already been invited, or if this user has already applied for membership, hide and disable the button to send invitation
        if self.potentialMemberType == .invited {
            self.button_sendInvitation?.isEnabled = false
            self.button_sendInvitation?.isHidden = true
        } else if self.potentialMemberType == .applied {
            self.button_sendInvitation?.isEnabled = false
            self.button_sendInvitation?.isHidden = true
            // this user has sent an application to join this team, the captain could either approve or reject the application
            // add right button in navigation bar programmatically
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: UIImage(named: "more"),
                style: .plain,
                target: self,
                action: #selector(VTScannedOrSearchedUserProfileTableViewController.showAcceptOrRejectApplicationActionSheet)
            )
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section != 3 {
            return DefaultTableSectionFooterHeight
        } else {
            // current user can invite this user if the following 3 conditions met:
            // 1. current user is a captain for a team
            // 2. the user has NOT been applied by this team
            // 3. the user has NOT been invited by this team
            if Toolbox.isStringValueValid(Singleton_UserOwnedTeam.sharedInstance.teamId) && self.potentialMemberType != .invited && self.potentialMemberType != .applied {
                return TableSectionFooterHeightWithButton
            } else {
                return DefaultTableSectionFooterHeight
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section != 3 {
            return UIView(frame: CGRect.zero)
        } else {
            let footerView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: TableSectionFooterHeightWithButton))
            // current user can invite this user if the following 3 conditions met:
            // 1. current user is a captain for a team
            // 2. the user has NOT been applied by this team
            // 3. the user has NOT been invited by this team
            if Toolbox.isStringValueValid(Singleton_UserOwnedTeam.sharedInstance.teamId) && self.potentialMemberType != .invited && self.potentialMemberType != .applied {
                // add send invitation button
                self.button_sendInvitation = Appearance.setupTableFooterButtonWithTitle("发送邀请", backgroundColor: ColorSettledGreen)
                self.button_sendInvitation?.addTarget(self, action: #selector(VTScannedOrSearchedUserProfileTableViewController.showSendInvitationView), for: .touchUpInside)
                footerView.addSubview(self.button_sendInvitation!)
            }
            return footerView
        }
    }
    
    func showSendInvitationView() {
        self.performSegue(withIdentifier: "sendInvitationSegue", sender: self)
    }
    
    func showAcceptOrRejectApplicationActionSheet() {
        let acceptApplication = "同意加入"
        let rejectApplication = "拒绝申请"
        let cancelTitle = "取消"
        
        let actionSheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: cancelTitle, destructiveButtonTitle: rejectApplication, otherButtonTitles: acceptApplication)
        actionSheet.show(in: self.view)
    }
    
    func actionSheet(_ actionSheet: UIActionSheet, clickedButtonAt buttonIndex: Int) {
        if buttonIndex == 1 {   // user pressed cancel
            return
        }
        let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        let selectedTeamId = UserDefaults.standard.string(forKey: "teamIdSelectedInTeamsList")
        let databaseResult = dbManager?.loadData(
            fromDB: "select messageId from messages where type=? and status=? and senderId=? and teamReceiverId=?",
            parameters: [
                MessageType.application.rawValue,
                MessageStatus.unread.rawValue,
                self.userObject!.userId,
                selectedTeamId!
            ]
        )
        actionSheet.dismiss(withClickedButtonIndex: buttonIndex, animated: true)
        
        let correspondingApplicationMessageId = databaseResult[0] as? NSArray
        if correspondingApplicationMessageId != nil {
            self.applicationMessageId = "\(correspondingApplicationMessageId![0])"
        }
        
        var resp: ApplicationResponse = .accept
        var postParamString = ""
        if buttonIndex == 0 {   // captain rejected the user's application
            postParamString = "messageId=\(self.applicationMessageId!)"
            resp = .reject
        } else if buttonIndex == 2 {    // captain accepted the user's application
            postParamString = "messageId=\(self.applicationMessageId!)&isAccepted=true"
            resp = .accept
        }
        let connection = Toolbox.asyncHttpPostToURL(URLHandleRequest, parameters: postParamString, delegate: self)
        if connection == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            self.HUD = MBProgressHUD(view: self.navigationController?.view)
            self.HUD?.show(true)
            self.currentApplicationResponse = resp
        }

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "用户资料")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "sendInvitationSegue" {
            let destinationViewController = segue.destination as! VTSendInvitationViewController
            destinationViewController.receiverUserObject = self.userObject
            destinationViewController.fromTeamId = Singleton_UserOwnedTeam.sharedInstance.teamId
        } else if segue.identifier == "statsSegue" {
            let destinationViewController = segue.destination as! VTUserStatsTableViewController
            destinationViewController.userObject = self.userObject
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func connection(_ connection: NSURLConnection, didReceive data: Data) {
        self.responseData?.append(data)
    }
    
    func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        self.HUD?.hide(true)
        self.HUD = nil
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "接收/拒绝申请失败")
        self.currentApplicationResponse = nil
        
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        self.HUD?.hide(true)
        self.HUD = nil
        
        let responseStr = NSString(data: self.responseData! as Data, encoding: String.Encoding.utf8.rawValue)
        var status: Int?
        if responseStr == "OK" {    // accept/reject application succeeded
            if self.currentApplicationResponse == .accept {
                status = MessageStatus.accepted.rawValue
            } else if self.currentApplicationResponse == .reject {
                status = MessageStatus.rejected.rawValue
            }
            let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
            dbManager?.modifyData(inDB: "update messages set status=? where messageId=?", parameters: [status!, self.applicationMessageId!])
            // notify VTMainTabBarViewController that the number of total unread messages should decrease by dbManager.affectedRows
            NotificationCenter.default.post(
                name: Notification.Name(rawValue: "totalNumOfUnreadMessagesChanged"),
                object: [
                    "action": "-",
                    "quantity": "\(Int((dbManager?.affectedRows)!))"
                ]
            )
            // notify VTGroupsOfMessagesTableViewController that the number of unread messages for specific message group should be updated
            NotificationCenter.default.post(
                name: Notification.Name(rawValue: "numOfUnreadMessagesInOneMessageGroupChanged"),
                object: "\(MessageGroupIndex.request.rawValue))"
            )
            self.performSegue(withIdentifier: "unwindToMembersContainerSegue", sender: self)
        } else {    // accept/reject application failed with error message
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "接收/拒绝申请失败")
        }
        
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    deinit {
        self.userObject = nil
        self.HUD = nil
        self.currentApplicationResponse = nil
        self.responseData = nil
        self.applicationMessageId = nil
    }

}
