//
//  VTMembersTableViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/3.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTMembersTableViewController: UITableViewController, UIActionSheetDelegate, NSURLConnectionDataDelegate, NSURLConnectionDelegate {
    
    let tableCellIdentifier = "teamMemberCell"
    var captainUserIdOfCurrentSelectedTeam: String?
    var teamId: String?
    var selectedPotentialMemberType: PotentialMemberType?
    var membersList = [User]()
    var invitedUsersList = [User]()
    var appliedUsersList = [User]()
    var HUD: MBProgressHUD?
    var selectedTeamMember: User?
    var selectedPotentialMember: User?
    var isCurrentUserTheCaptainOfThisTeam: Bool?
    var responseData: NSMutableData? = NSMutableData()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.refreshControl = Appearance.setupRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(VTMembersTableViewController.refreshTeamMembers), for: .valueChanged)
        self.tableView.addSubview(self.refreshControl!)
        self.clearsSelectionOnViewWillAppear = true
        self.teamId = UserDefaults.standard.string(forKey: "teamIdSelectedInTeamsList")
        
        // retrieve captain user id of current selected team
        self.captainUserIdOfCurrentSelectedTeam = Team.retrieveCaptainIdFromLocalDatabaseWithTeamId(self.teamId!)
        
        let currentUser = Singleton_CurrentUser.sharedInstance
        if currentUser.userId == self.captainUserIdOfCurrentSelectedTeam {
            self.isCurrentUserTheCaptainOfThisTeam = true
        } else {
            self.isCurrentUserTheCaptainOfThisTeam = false
        }
        
        // This will remove extra separators from tableView
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.rowHeight = CustomTableRowHeight
        
        // get team members from server
        let connection = Toolbox.asyncHttpGetFromURL(URLGetTeamMembers + "?teamId=" +  self.teamId!, delegate: self)
        if connection == nil {
            // inform the user that the connection failed
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: nil)
        }
        // listen to teamCaptainChangedOnServer
        NotificationCenter.default.addObserver(self, selector: #selector(VTMembersTableViewController.updateTeamCaptainLocally(_:)), name: NSNotification.Name(rawValue: "teamCaptainChangedOnServer"), object: nil)
        // listen to teamMemberDeletedOnServer
        NotificationCenter.default.addObserver(self, selector: #selector(VTMembersTableViewController.deleteTeamMemberLocally(_:)), name: NSNotification.Name(rawValue: "teamMemberDeletedOnServer"), object: nil)
        // after invitation sent, the members tableView should display the users who the team captain has sent invitation to as potential member, until the user has either accept or reject the invitation
        NotificationCenter.default.addObserver(self, selector: #selector(VTMembersTableViewController.addUserAsInvitedUser(_:)), name: NSNotification.Name(rawValue: "invitationSentSuccessfully"), object: nil)
        
        /**
        * system message notification handler
        */
        NotificationCenter.default.addObserver(self, selector: #selector(VTMembersTableViewController.refreshCurrentTeamMembers(_:)), name: NSNotification.Name(rawValue: "receivedSystemMessage_teamMemberRemoved"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(VTMembersTableViewController.refreshCurrentTeamMembers(_:)), name: NSNotification.Name(rawValue: "receivedSystemMessage_teamCaptainChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(VTMembersTableViewController.refreshCurrentTeamMembers(_:)), name: NSNotification.Name(rawValue: "receivedSystemMessage_teamDismissed"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(VTMembersTableViewController.refreshCurrentTeamMembers(_:)), name: NSNotification.Name(rawValue: "receivedSystemMessage_newMemberJoined"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(VTMembersTableViewController.refreshCurrentTeamMembers(_:)), name: NSNotification.Name(rawValue: "receivedSystemMessage_requestRefused"), object: nil)
    }
    
    func refreshCurrentTeamMembers(_ notification: Notification) {
        let metaData = notification.object as? [String: String]
        if metaData != nil {
            let teamId = metaData!["teamId"]
            if teamId == self.teamId {
                self.refreshTeamMembers()
            }
        }
    }
    
    func refreshTeamMembers() {
        // get team members from server
        let connection = Toolbox.asyncHttpGetFromURL(URLGetTeamMembers + "?teamId=" +  self.teamId!, delegate: self)
        if connection == nil {
            // inform the user that the connection failed
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // initialize selectedPotentialMemberType with invalid value
        self.selectedPotentialMemberType = nil
        self.selectedTeamMember = nil
    }
    
    func addUserAsInvitedUser(_ notification: Notification) {
        // set up HUD to show that invitation sent successfully
        Toolbox.showCustomAlertViewWithImage("checkmark", title: "发送邀请成功")
        let recipientOfTheInvitation = notification.object as! User
        // before adding the user in self.invitedUsersList, make sure it is NOT already in it
        let existedInvitedUsers = self.invitedUsersList.filter{
            $0.userId == recipientOfTheInvitation.userId
        }
        if existedInvitedUsers.count == 0 {
            self.invitedUsersList.append(recipientOfTheInvitation)
            // reload the potential members list section
            self.tableView.reloadSections(IndexSet(integer: 1), with: .top)
        }
    }
    
    func updateTeamCaptainLocally(_ notification: Notification) {
        let newCaptainUserId = notification.object as! String
        
        // update team captain user id
        Team.changeCaptainTo(newCaptainUserId, forTeam: self.teamId!)
        Toolbox.showCustomAlertViewWithImage("checkmark", title: "已成功更换球队队长")
        self.captainUserIdOfCurrentSelectedTeam = newCaptainUserId
        if self.captainUserIdOfCurrentSelectedTeam != Singleton_CurrentUser.sharedInstance.userId! {
            self.isCurrentUserTheCaptainOfThisTeam = false
        } else {
            self.isCurrentUserTheCaptainOfThisTeam = true
        }
        self.tableView.reloadData()
    }
    
    /**
     * Team member deleted on server side, now need to update team member info in local database and tableView
     * NOTE: the member user ids are NOT stored in local database, but there's a --- numberOfMembers --- that needs to be updated once team member has been deleted.
     */
    func deleteTeamMemberLocally(_ notification: Notification) {
        let teamInfoAfterDeletingTeamMember = notification.object as! [AnyHashable: Any]
        // find out the table cell that contains the deleted member
        let deletedTeamMember = self.membersList.filter{
            $0.userId == (teamInfoAfterDeletingTeamMember["deletedMemberUserId"] as! String)
        }
        
        // update tableView by removing the entry that contains the deleted team member
        let indexOfDeletedTeamMember = self.membersList.index(of: deletedTeamMember[0])
        self.membersList.remove(at: indexOfDeletedTeamMember!)
        
        self.tableView.deleteRows(at: [IndexPath(row: indexOfDeletedTeamMember!, section: 0)], with: .top)
        
        Toolbox.showCustomAlertViewWithImage("checkmark", title: "已成功删除球队成员")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source

    /**
     * There're 3 sections in members tableView
     * First section shows all the existing members of this team
     * Second section shows all the users that haven't respond to invitaion sent from the captain of this team
     * Third section shows all the users that has sent application to this team waiting for approval
     * NOTE:
     * 1. ONLY THE TEAM CAPTAIN IS ALLOWED TO SEE THE SECOND AND THIRD SECTION, for non-captain users, the second and third section are hidden
     * 2. If there's no potential member, the second section and its header will be hidden, the same rule applies to the third section and its header when there's no application received from any user
     */
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        var possibleHeaderHeight: CGFloat = 0
        if self.isCurrentUserTheCaptainOfThisTeam! {
            possibleHeaderHeight = TableSectionHeaderHeight
        }
        if section == 0 {
            return possibleHeaderHeight
        } else if section == 1 {
            if self.invitedUsersList.count > 0 {
                return possibleHeaderHeight
            } else {
                return 0
            }
        } else {
            if self.appliedUsersList.count > 0 {
                return possibleHeaderHeight
            } else {
                return 0
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: TableSectionHeaderHeight))
        headerView.backgroundColor = ColorBackgroundGray
        if section == 0 {         // header for members list section
            headerView.addSubview(Appearance.setupTableSectionHeaderTitle(" 当前成员"))
        } else if section == 1 {  // header for potential members list section
            if self.invitedUsersList.count > 0 && self.isCurrentUserTheCaptainOfThisTeam! == true {
                headerView.addSubview(Appearance.setupTableSectionHeaderTitle(" 已邀请的球员"))
            }
        } else {                    // header for users who sent application to this team
            if self.appliedUsersList.count > 0 && self.isCurrentUserTheCaptainOfThisTeam! == true {
                headerView.addSubview(Appearance.setupTableSectionHeaderTitle(" 申请加入的球员"))
            }
        }
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        var possibleFooterHeight: CGFloat = 0
        // only when the current user is the captain of this team, can he/she recruit new team members
        if self.isCurrentUserTheCaptainOfThisTeam! == true {
            possibleFooterHeight = TableSectionFooterHeightWithButton
        } else {
            possibleFooterHeight = 0
        }
        // always add the button to recruit new members in the footer of the last section
        if section == 0 || section == 1 {
            return 0
        } else {
            return possibleFooterHeight
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: TableSectionFooterHeightWithButton))
        return footerView
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {             // members list section
            return self.membersList.count
        } else if section == 1 {      // potential members list section
            if self.isCurrentUserTheCaptainOfThisTeam! == true {
                return self.invitedUsersList.count
            } else {
                return 0
            }
        } else {                        // applying for membership users list
            if self.isCurrentUserTheCaptainOfThisTeam! == true {
                return self.appliedUsersList.count
            } else {
                return 0
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = self.tableView.dequeueReusableCell(withIdentifier: self.tableCellIdentifier) as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: self.tableCellIdentifier)
        }
        // set up user avatar image view
        let imageView_userAvatar = cell!.contentView.viewWithTag(1) as! UIImageView
        imageView_userAvatar.layer.cornerRadius = 2.0
        imageView_userAvatar.layer.masksToBounds = true
        // set up label to display member user name
        let label_username = cell!.contentView.viewWithTag(2) as! UILabel
        // set up label to display member position
        let label_position = cell!.contentView.viewWithTag(3) as! UILabel
        // set up image view to indicate the captain of the team
        let imageView_captainFlag = cell!.contentView.viewWithTag(4) as! UIImageView
        
        var userInCurrentRow: User
        if (indexPath as NSIndexPath).section == 0 {           // the members list section
            userInCurrentRow = self.membersList[(indexPath as NSIndexPath).row]
        } else if (indexPath as NSIndexPath).section == 1 {    // the potential members list section
            userInCurrentRow = self.invitedUsersList[(indexPath as NSIndexPath).row]
        } else {                                // the users list who applied for membership of this team
            userInCurrentRow = self.appliedUsersList[(indexPath as NSIndexPath).row]
        }
        
        // load user avatar
        Toolbox.loadAvatarImage(userInCurrentRow.userId, toImageView: imageView_userAvatar, avatarType: AvatarType.user)
        label_username.text = userInCurrentRow.username
        label_position.text = userInCurrentRow.position
        
        // if the user in this table cell is NOT captain of the selected team
        if userInCurrentRow.userId != self.captainUserIdOfCurrentSelectedTeam {
            imageView_captainFlag.isHidden = true
        } else {
            imageView_captainFlag.isHidden = false
        }
        
        return cell!
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).section == 0 {   // team member selected
            self.selectedTeamMember = self.membersList[(indexPath as NSIndexPath).row]
            self.performSegue(withIdentifier: "teamMemberProfileSegue", sender: self)
        } else {                        // potential member selected
            if (indexPath as NSIndexPath).section == 1 {   // selected invited user
                self.selectedPotentialMember = self.invitedUsersList[(indexPath as NSIndexPath).row]
                self.selectedPotentialMemberType = .invited
            } else {                        // selected applied user
                self.selectedPotentialMember = self.appliedUsersList[(indexPath as NSIndexPath).row]
                self.selectedPotentialMemberType = .applied
            }
            self.performSegue(withIdentifier: "potentialMemberProfileSegue", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "teamMemberProfileSegue" {
            let destinationViewController = segue.destination as! VTMemberProfileTableViewController
            destinationViewController.userObject = self.selectedTeamMember
        } else if segue.identifier == "potentialMemberProfileSegue" {
            let destinationViewController = segue.destination as! VTScannedOrSearchedUserProfileTableViewController
            destinationViewController.userObject = self.selectedPotentialMember
            if self.selectedPotentialMemberType != nil {    // if selectedPotentialMemberType is some VALID value
                destinationViewController.potentialMemberType = self.selectedPotentialMemberType!
            }
        }
    }
    
    func connection(_ connection: NSURLConnection, didReceive data: Data) {
        self.responseData?.append(data)
    }
    
    func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        self.HUD?.hide(true)
        self.HUD = nil
        self.refreshControl?.endRefreshing()
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络超时")
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        self.HUD?.hide(true)
        self.HUD = nil
        self.refreshControl?.endRefreshing()
        /// response from server is  JSON data that contains the following data:
        /**
         * paginationInfo: {
         * total:totalMembers,
         * currentPage: currentPage,
         * itemsPerPage: sails.config.constants.itemsPerPage
         * },
         * models: users
         * potentialMembers: potentialMembers
         */
        let membersJSON = (try? JSONSerialization.jsonObject(with: self.responseData! as Data, options: .mutableLeaves)) as? [AnyHashable: Any]
        if membersJSON != nil { // http request succeeded
            // clear the old data first
            self.membersList.removeAll(keepingCapacity: false)
            self.invitedUsersList.removeAll(keepingCapacity: false)
            self.appliedUsersList.removeAll(keepingCapacity: false)
            // retrieve member user objects
            let members = membersJSON!["models"] as? [AnyObject]
            for member in members! {
                let memberObject = User(data: member as! [AnyHashable: Any] as [NSObject : AnyObject])
                self.membersList.append(memberObject)
            }
            // retrieve potential member user objects
            let invitedUsers = membersJSON!["invitedUsers"] as? [AnyObject]
            for invitedUserDictionary in invitedUsers! {
                let invitedUserObject = User(data: invitedUserDictionary as! [AnyHashable: Any] as [NSObject : AnyObject])
                self.invitedUsersList.append(invitedUserObject)
            }
            let appliedUsers = membersJSON!["appliedUsers"] as? [AnyObject]
            for appliedUserDictionary in appliedUsers! {
                let appliedUserObject = User(data: appliedUserDictionary as! [AnyHashable: Any] as [NSObject : AnyObject])
                self.appliedUsersList.append(appliedUserObject)
            }
            // data ready, reload tableView
            self.tableView.reloadData()
        } else {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "获取球队成员失败")
        }
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    @IBAction func unwindToTeamMembersTableView(_ segue: UIStoryboardSegue) {
    }
    
    deinit {
        self.teamId = nil
        self.captainUserIdOfCurrentSelectedTeam = nil
        self.selectedPotentialMemberType = nil
        self.selectedPotentialMember = nil
        self.membersList.removeAll(keepingCapacity: false)
        self.invitedUsersList.removeAll(keepingCapacity: false)
        self.appliedUsersList.removeAll(keepingCapacity: false)
        
        self.HUD = nil
        self.selectedTeamMember = nil
        self.isCurrentUserTheCaptainOfThisTeam = nil
        self.responseData = nil
    }

}
