//
//  VTTeamsTableViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/3.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTTeamsTableViewController: UITableViewController, NSURLConnectionDelegate, NSURLConnectionDataDelegate, LocationServiceDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UITextFieldDelegate {

    enum HttpRequest {
        case GetNearbyTeams
        case SearchTeamsByName
        case GetTeamsForUser
    }
    
    let tableCellIdentifier = "teamsListTableCell"
    
    var teamsList = [Team]()
    var applyingTeamsList = [Team]()
    
    var HUD: MBProgressHUD?
    var indexOfCurrentHttpRequest: HttpRequest?
    var numberOfTotalTeamResults: Int?
    var paginatedTeamResults: [[NSObject: AnyObject]]?
    var locationService: LocationService?
    var userCoordinates: CLLocationCoordinate2D?
    var selectedApplyingTeam: Team?
    var resultsType: TeamResultsType?
    var searchKeyword = ""
    var responseData: NSMutableData? = NSMutableData()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.clearsSelectionOnViewWillAppear = true
        // add the UIRefreshControl to tableView
        self.refreshControl = Appearance.setupRefreshControl()
        self.refreshControl?.addTarget(self, action: "refresh", forControlEvents: .ValueChanged)
        self.tableView.addSubview(self.refreshControl!)
        
        // setup teamsList and load user team list from local database
        let currentUser = Singleton_CurrentUser.sharedInstance
        
        let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        let teams = dbManager.loadDataFromDB(
            "select * from teams where forUserId=?",
            parameters: [currentUser.userId!]
        )
        if teams.count > 0 {    // current logged in user belongs to some teams and these teams are store in local database
            for team in teams {
                let teamObject = Team.formatDatabaseRecordToTeamFormat(team as! [AnyObject])
                self.teamsList.append(teamObject)
            }
        }
        
        // This will remove extra separators from tableview
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        self.tableView.rowHeight = CustomTableRowHeight
        self.tableView.separatorColor = UIColor.clearColor()
        // liten to teamRecordSavedOrUpdated message and handles it by updating teamsList in current view controller
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleNewOrUpdatedTeam:", name: "teamRecordSavedOrUpdated", object: nil)
        // listen to teamDeletedLocally message and handles it by deleting corresponding team from self.teamsList and removing corresponding entry in self.tableView
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "deleteTeamEntries:", name: "teamsDeletedLocally", object: nil)
        // listen to userQuitOrDimissedTeam notification and handles it by deleting corresponding team from self.teamsList and removing correspond entry in self.tableView
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "showQuitOrDismissTeamSucceededHintMessageBox:", name: "userQuittedOrDismissedTeam", object: nil)
        // once team captain changed, teams table should also be updated
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleTeamWhichHasCaptainChanged:", name: "teamCaptainChangedOnServer", object: nil)
        // once team member removed from team, the number of members for that team in tableView should also be updated
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateNumberOfMembersAfterMemberRemovedFromTeam:", name: "teamMemberDeletedOnServer", object: nil)
        // if current user has sent an application to a team, the team should show up in this tableView as a team that the user has sent application to
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "addTeamThatUserIsApplyingFor:", name: "applicationSentSuccessfully", object: nil)
        // programmatically refresh to see if there are any new unread messages while VTMessageGroupsTableViewController is not showing or maybe the app is turned off or been run in background
        self.refresh()
        
        /** 
         * system message notification handler
         */
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshTeamsData", name: "receivedSystemMessage_teamMemberRemoved", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshTeamsData", name: "receivedSystemMessage_teamCaptainChanged", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshTeamsData", name: "receivedSystemMessage_teamDismissed", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshTeamsData", name: "receivedSystemMessage_newMemberJoined", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshTeamsData", name: "receivedSystemMessage_requestRefused", object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        Appearance.customizeNavigationBar(self, title: "我的球队")
    }
    
    func refreshTeamsData() {
        self.refresh()
    }
    
    // Current user has sent an application to a team, this team should be added in the second section of teams tableView
    func addTeamThatUserIsApplyingFor(notification: NSNotification) {
        let appliedTeam = notification.object as! Team
        // add the team in self.applyingTeamsList
        self.applyingTeamsList.append(appliedTeam)
        // reload the applying teams list section
        self.tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Top)
    }
    
    // Current user is no longer captain of the team selected, thus the star that represents the current user being captain for the team should be removed or hided
    func handleTeamWhichHasCaptainChanged(notification: NSNotification) {
        let newCaptainUserId = notification.object as! String
        // retrieve the corresponding team id
        let selectedTeamId = NSUserDefaults.standardUserDefaults().objectForKey("teamIdSelectedInTeamsList") as! String
        
        // find out the table cell that contains the corresponding team
        let searchedTeams = self.teamsList.filter{
            $0.teamId == selectedTeamId
        }
        if searchedTeams.count > 0 {
            let indexOfCorrespondingTeam = self.teamsList.indexOf(searchedTeams[0])
            // update the captain id for that Team object in self.teamsList
            let teamObject = self.teamsList[indexOfCorrespondingTeam!]
            teamObject.captainUserId = newCaptainUserId
            
            // reload corresponding tableView cell to remove that star
            self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: indexOfCorrespondingTeam!, inSection: 0)], withRowAnimation: .None)
        } else {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "球队没找到")
        }
    }
    
    /**
     * Team member deleted on server side and number of member for that team in local database has updated as well, now need to update numer of members in teams table view
     */
    func updateNumberOfMembersAfterMemberRemovedFromTeam(notification: NSNotification) {
        let teamInfoAfterDeletingTeamMember = notification.object as! [NSObject: AnyObject]
        // retrieve the corresponding team id
        let selectedTeamId = NSUserDefaults.standardUserDefaults().stringForKey("teamIdSelectedInTeamsList")
        // find out the table cell that contains the corresponding team
        let searchedTeams = self.teamsList.filter{
            $0.teamId == selectedTeamId
        }
        if searchedTeams.count > 0 {
            let indexOfCorrespondingTeam = self.teamsList.indexOf(searchedTeams[0])
            self.teamsList[indexOfCorrespondingTeam!].numberOfMembers = teamInfoAfterDeletingTeamMember["newNumberOfMembers"]!.integerValue
            self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: indexOfCorrespondingTeam!, inSection: 0)], withRowAnimation: .None)
        } else {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "球队没找到")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "我的球队")
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if self.locationService != nil {
            self.locationService?.delegate = nil
            self.locationService = nil
        }
        if self.HUD != nil {
            self.HUD?.hide(true)
            self.HUD = nil
        }
    }
    
    func handleNewOrUpdatedTeam(notification: NSNotification) {
        let teamInvolved = notification.object as! Team
        // try to find the team in self.teamsList based on teamId
        let existedTeams = self.teamsList.filter{
            $0.teamId == teamInvolved.teamId
        }
        if existedTeams.count > 0 { // the team exists already, database instruction is an update
            let indexOfTeamToBeUpdated = self.teamsList.indexOf(existedTeams[0])
            // update related entry in self.teamsList to update data showing in tableView
            self.teamsList[indexOfTeamToBeUpdated!] = teamInvolved
            // update table view data, just thta specific row, NOT the whole table
            let indexPath = NSIndexPath(forRow: indexOfTeamToBeUpdated!, inSection: 0)
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
        } else {    // the team does NOT exist, database instruction is adding a new team record
            self.teamsList.insert(teamInvolved, atIndex: 0)  // insert this team in front of the first team as a new team to self.teamList to show in tableView
            // insert a new row as the first row into tableView with animation
            let indexPath = NSIndexPath(forRow: 0, inSection: 0)
            self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Top)
        }
    }
    
    func removeTeamInTableViewEntry(teamIdToDelete: String) {
        let teamsToDelete = self.teamsList.filter{
            $0.teamId == teamIdToDelete
        }
        if teamsToDelete.count > 0 {   // the team to delete is currently still in self.teamsList
            let indexOfTeamToDelete = self.teamsList.indexOf(teamsToDelete[0])
            self.teamsList.removeAtIndex(indexOfTeamToDelete!)
            
            // delete the corresponding table rows with animation
            self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: indexOfTeamToDelete!, inSection: 0)], withRowAnimation: .Top)
        }
    }
    
    /**
     * Team(s) already deleted in local database,
     * now remove them from self.teamsList and self.tableView
     */
    func deleteTeamEntries(notification: NSNotification) {
        let deletedTeamIds = notification.object as! [String]
        for deletedTeamId in deletedTeamIds {
            // remove corresponding team entry in self.tableView and self.teamsList
            self.removeTeamInTableViewEntry(deletedTeamId)
        }
    }
    
    /**
     * Received user quit or dismiss team notification
     * Now remove the corresponding team for current user in local database
     * Also remove the corresponding entry in self.teamsList and self.tableView
     */
    func showQuitOrDismissTeamSucceededHintMessageBox(notification: NSNotification) {
        let quitOrDismissTeamNotificationDictionary = notification.object as! [NSObject: AnyObject]
        let reasonUserNoLongerBelongsToTeam = quitOrDismissTeamNotificationDictionary["reasonUserNoLongerBelongsToTeam"] as! String
        if reasonUserNoLongerBelongsToTeam == "dismiss" {
            Toolbox.showCustomAlertViewWithImage("checkmark", title: "球队解散成功")
        } else if reasonUserNoLongerBelongsToTeam == "quit" {
            Toolbox.showCustomAlertViewWithImage("checkmark", title: "退出球队成功")
        }
    }
    
    func didStartToLocate() {
        // show loading spinner HUD to indicate that searching nearby teams is in process
        self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: "正在定位...")
    }
    
    func didFailToLocateUser() {
        self.HUD?.hide(true)
        self.HUD = nil
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "定位失败")
    }
    
    // Finished getting user current geo coordinates, now should submit the geo coordinates to server to find out nearby teams
    func didGetUserCoordinates(coordinate: CLLocationCoordinate2D) {
        self.submitRequestToSearchNearByTeamsWithCurrentUserLocation(coordinate)
    }
    
    /**
     * User current location found, now submit current user location to server to search for near by teams
     */
    func submitRequestToSearchNearByTeamsWithCurrentUserLocation(coordinate: CLLocationCoordinate2D) {
        self.userCoordinates = coordinate
        let urlToGetNearbyTeams = "\(URLGetNearbyTeamsForUser)?latitude=\(coordinate.latitude)&longitude=\(coordinate.longitude)&page=1"
        let connection = Toolbox.asyncHttpGetFromURL(urlToGetNearbyTeams, delegate: self)
        if connection == nil {
            self.HUD?.hide(true)
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            self.HUD?.labelText = "搜索附近球队中..."
            self.indexOfCurrentHttpRequest = .GetNearbyTeams
        }
    }

    /**
     * Submit http request to search teams by name
     */
    func submitRequestToSearchTeamsByName(searchKeyword: String) {
        self.searchKeyword = searchKeyword
        let urlToSearchTeamsByName = URLSearchTeamsForUser + "?keyword=" + searchKeyword + "&page=1"
        let connection = Toolbox.asyncHttpGetFromURL(urlToSearchTeamsByName, delegate: self)
        if connection == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            self.indexOfCurrentHttpRequest = .SearchTeamsByName
            // show loading spinner HUD to indicate that searching teams is in process
            self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: "搜索中...")
        }
    }
    
    @IBAction func showAlertControllerToSearchOrCreateTeam(sender: AnyObject) {
        if #available(iOS 8.0, *) {
            let createNewTeamOrJoinExistedTeamAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            let createNewTeam = UIAlertAction(title: "创建新球队", style: .Default, handler: {
                action in
                // checks if current user is already captain of a team
                var isCurrentUserAlreadyATeamCaptain = false
                for teamObject in self.teamsList {
                    if Singleton_CurrentUser.sharedInstance.userId == teamObject.captainUserId {
                        isCurrentUserAlreadyATeamCaptain = true
                        break
                    }
                }
                if isCurrentUserAlreadyATeamCaptain {
                    Toolbox.showCustomAlertViewWithImage("unhappy", title: "您只能担任一支球队的队长")
                } else {
                    self.performSegueWithIdentifier("createNewTeamSegue", sender: self)
                }
                return
            })
            let showNearbyTeam = UIAlertAction(title: "查看附近球队", style: .Default, handler: {
                action in
                self.locationService = LocationService()
                self.locationService?.delegate = self
                // no need to get current address, just geo coordinates are fine
                self.locationService?.shouldGetReverseGeoCode = false
                self.locationService?.launchLocationService()
                return
            })
            let searchTeam = UIAlertAction(title: "搜索球队", style: .Default, handler: {
                action in
                let searchAlertController = UIAlertController(title: "", message: "请输入球队名称", preferredStyle: .Alert)
                let ok = UIAlertAction(title: "搜索", style: .Default, handler: {
                    action in
                    let searchTeamKeyword = (searchAlertController.textFields?.first as UITextField!).text
                    if searchTeamKeyword!.characters.count > 0 {
                        self.submitRequestToSearchTeamsByName(searchTeamKeyword!)
                    } else {
                        searchAlertController.dismissViewControllerAnimated(true, completion: nil)
                    }
                    return
                })
                let cancel = UIAlertAction(title: "取消", style: .Default, handler: {
                    action in
                    searchAlertController.dismissViewControllerAnimated(true, completion: nil)
                    return
                })
                
                searchAlertController.addAction(cancel)
                searchAlertController.addAction(ok)
                searchAlertController.addTextFieldWithConfigurationHandler({
                    textField in
                    textField.placeholder = "球队名称"
                    textField.keyboardType = .Default
                    self.presentViewController(searchAlertController, animated: true, completion: nil)
                    return
                })
            })
            let cancel = UIAlertAction(title: "取消", style: .Cancel, handler: {
                action in
                createNewTeamOrJoinExistedTeamAlertController.dismissViewControllerAnimated(true, completion: nil)
                return
            })
            createNewTeamOrJoinExistedTeamAlertController.addAction(createNewTeam)
            createNewTeamOrJoinExistedTeamAlertController.addAction(showNearbyTeam)
            createNewTeamOrJoinExistedTeamAlertController.addAction(searchTeam)
            createNewTeamOrJoinExistedTeamAlertController.addAction(cancel)
            self.presentViewController(createNewTeamOrJoinExistedTeamAlertController, animated: true, completion: nil)
        } else {
            let createNewTeamOrJoinExistedTeamAction = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: nil, destructiveButtonTitle: nil, otherButtonTitles: "创建新球队", "查看附近球队", "搜索球队", "取消")
            createNewTeamOrJoinExistedTeamAction.showFromTabBar(self.tabBarController!.tabBar)
        }
    }
    
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        actionSheet.dismissWithClickedButtonIndex(buttonIndex, animated: true)
        if buttonIndex == 0 {   // create new team
            // checks if current user is already captain of a team
            var isCurrentUserAlreadyATeamCaptain = false
            for teamObject in self.teamsList {
                if Singleton_CurrentUser.sharedInstance.userId == teamObject.captainUserId {
                    isCurrentUserAlreadyATeamCaptain = true
                    break
                }
            }
            if isCurrentUserAlreadyATeamCaptain {
                Toolbox.showCustomAlertViewWithImage("unhappy", title: "您只能担任一支球队的队长")
            } else {
                self.performSegueWithIdentifier("createNewTeamSegue", sender: self)
            }
        } else if buttonIndex == 1 {    // search nearby teams
            self.locationService = LocationService()
            self.locationService?.delegate = self
            self.locationService?.launchLocationService()
        } else if buttonIndex == 2 {    // search teams by name
            Appearance.showAlertViewWithInput("请输入球队名称", delegate: self)
        }
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        self.searchKeyword = textField.text!
    }
    
    /**
    alert view delegate method for search team with keyword
    
    - parameter alertView:   the search team alert view
    - parameter buttonIndex: button index, whether user clicked yes or cancel
    */
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        alertView.dismissWithClickedButtonIndex(buttonIndex, animated: true)
        if buttonIndex == 1 {
            if self.searchKeyword.characters.count > 0 {
                self.submitRequestToSearchTeamsByName(self.searchKeyword)
            }
        }
    }

    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if self.applyingTeamsList.count == 0 {
            return 0
        } else {
            if section == 0 {
                if self.teamsList.count == 0 {
                    return 0
                } else {
                    return TableSectionHeaderHeight
                }
            }
            return TableSectionHeaderHeight
        }
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRectMake(0, 0, ScreenSize.width, TableSectionHeaderHeight))
        if self.applyingTeamsList.count > 0 {
            if section == 0 {     // section that contains teams that the user belongs to
                headerView.addSubview(Appearance.setupTableSectionHeaderTitle(" 现有球队"))
            } else {                // section that contains teams that the user is applying for yet hasn't been either approved or rejected
                headerView.addSubview(Appearance.setupTableSectionHeaderTitle(" 申请加入的球队"))
            }
        }
        return headerView
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Display a message and an image when the table is empty
        let emptyTableBackgroundView = UIView(frame: CGRectMake(0, self.tableView.frame.origin.y, self.tableView.frame.size.width, self.tableView.frame.size.height))
        emptyTableBackgroundView.tag = TagValue.EmptyTableBackgroundView.rawValue
        let image = UIImageView(image: UIImage(named: "no_team"))
        image.frame = CGRectMake(ScreenSize.width / 2 - 55, ScreenSize.height / 2 - 110 - ToolbarHeight, 110, 110)
        
        let messageLabel = UILabel(frame: CGRectMake(ScreenSize.width / 2 - 60, ScreenSize.height / 2, ScreenSize.width, 50))
        
        messageLabel.text = "暂未加入任何球队"
        messageLabel.textColor = EmptyImageColor
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .Center
        messageLabel.sizeToFit()
        emptyTableBackgroundView.addSubview(image)
        emptyTableBackgroundView.addSubview(messageLabel)
        if self.teamsList.count > 0 || self.applyingTeamsList.count > 0 {
            self.tableView.backgroundView = nil
            for subView in self.tableView.subviews {
                if subView.tag == TagValue.EmptyTableBackgroundView.rawValue { // the subview is the emptyTableBackgroundView
                    (subView ).removeFromSuperview()
                }
            }
        } else {
            self.tableView.addSubview(emptyTableBackgroundView)
            self.tableView.sendSubviewToBack(emptyTableBackgroundView)
        }
        // return the number of sections
        return 2
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = self.tableView.dequeueReusableCellWithIdentifier(self.tableCellIdentifier) as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: self.tableCellIdentifier)
        }
        // set up team avatar image view
        let avatar = cell?.contentView.viewWithTag(1) as! UIImageView
        avatar.layer.cornerRadius = 2.0
        avatar.layer.masksToBounds = true
        
        // set up label to display team name
        let label_teamName = cell?.contentView.viewWithTag(2) as! UILabel
        // set up label to display the number of members in this team
        let label_numberOfMembers = cell?.contentView.viewWithTag(3) as! UILabel
        // set up imageView to mark this team if the team captain is current logged user
        let image_captainMark = cell?.contentView.viewWithTag(4) as! UIImageView
        
        var teamInCurrentRow: Team
        if indexPath.section == 0 {
            teamInCurrentRow = self.teamsList[indexPath.row]
        } else {
            teamInCurrentRow = self.applyingTeamsList[indexPath.row]
        }
        // load team avatar
        Toolbox.loadAvatarImage(teamInCurrentRow.teamId, toImageView: avatar, avatarType: AvatarType.Team)
        label_teamName.text = teamInCurrentRow.teamName
        label_numberOfMembers.text = "\(teamInCurrentRow.numberOfMembers)人"
        
        // current logged user is the captain of this team
        if teamInCurrentRow.captainUserId == Singleton_CurrentUser.sharedInstance.userId {
            image_captainMark.hidden = false
        } else {
            image_captainMark.hidden = true
        }
        // add a separatorLine for each row/cell
        let separatorLineView = UIView(frame: CGRectMake(15, 0, ScreenSize.width, 1))
        separatorLineView.backgroundColor = ColorBackgroundGray // set color as you want.
        cell?.contentView.addSubview(separatorLineView)
        
        return cell!
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if indexPath.section == 0 {   // selected a team that the user belongs to
            let selectedTeamObject = self.teamsList[indexPath.row]
            // save selected team id in userDefaults for later use
            NSUserDefaults.standardUserDefaults().setObject(selectedTeamObject.teamId, forKey: "teamIdSelectedInTeamsList")
            self.performSegueWithIdentifier("teamDetailsSegue", sender: self)
        } else {        // selected a team that the user is applying for
            self.selectedApplyingTeam = self.applyingTeamsList[indexPath.row]
            self.performSegueWithIdentifier("appliedTeamBriefIntroSegue", sender: self)
        }
    }
    
    func refresh() {
        // send async http get request to get teams that the current user belongs to and the teams that the user is applying for
        let urlToGetTeamsForUser = URLGetTeamsForUser + "?userId=" + Singleton_CurrentUser.sharedInstance.userId!
        let connection = Toolbox.asyncHttpGetFromURL(urlToGetTeamsForUser, delegate: self)
        if connection == nil {
            // Inform the user that the connection failed
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        }
        self.indexOfCurrentHttpRequest = .GetTeamsForUser
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        self.responseData?.appendData(data)
    }
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络超时")
        self.HUD?.hide(true)
        self.HUD = nil
        self.refreshControl?.endRefreshing()
        
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        self.HUD?.hide(true)
        self.HUD = nil
        
        if self.indexOfCurrentHttpRequest == .GetTeamsForUser {
            let userTeamsInfo = (try? NSJSONSerialization.JSONObjectWithData(self.responseData!, options: .MutableLeaves)) as? [NSObject: AnyObject]
            if userTeamsInfo != nil {   // http request to get teams succeeded
                let teamDictionariesUserBelongsTo = userTeamsInfo!["belongedTeams"] as! [[NSObject: AnyObject]]
                let teamDictionariesUserIsApplyingFor = userTeamsInfo!["applyingTeams"] as! [[NSObject: AnyObject]]
                
                var teamsUserBelongsTo = [Team]()
                for dictionary in teamDictionariesUserBelongsTo {
                    let team = Team(data: dictionary)
                    teamsUserBelongsTo.append(team)
                    // iterate through all the teams received and save each one of them in local database if  it is not yet in local database
                    team.saveOrUpdateTeamInDatabase()
                }
                // check to see if any team(s) has removed current user as its member
                Team.checkUserMembershipInTeams(teamsUserBelongsTo)
                self.applyingTeamsList.removeAll(keepCapacity: false)
                for dictionary in teamDictionariesUserIsApplyingFor {
                    let applyingTeamObject = Team(data: dictionary)
                    self.applyingTeamsList.append(applyingTeamObject)
                }
                // after the list data for applying teams is ready, reload the second section of the tableView
                self.tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: UITableViewRowAnimation.Automatic)
            } else {    // http request to get teams failed
                let responseStr = NSString(data: self.responseData!, encoding: NSUTF8StringEncoding)
                Toolbox.showCustomAlertViewWithImage("unhappy", title: responseStr as! String)
            }
            self.refreshControl?.endRefreshing()
        } else if self.indexOfCurrentHttpRequest == .GetNearbyTeams || self.indexOfCurrentHttpRequest == .SearchTeamsByName {
            let responseDictionary = (try? NSJSONSerialization.JSONObjectWithData(self.responseData!, options: .MutableLeaves)) as? [NSObject: AnyObject]
            self.numberOfTotalTeamResults = responseDictionary!["total"]!.integerValue
            self.paginatedTeamResults = responseDictionary!["models"] as? [[NSObject: AnyObject]]
            
            if self.numberOfTotalTeamResults == 0 {
                Toolbox.showCustomAlertViewWithImage("unhappy", title: "没有找到球队")
            } else {
                if self.indexOfCurrentHttpRequest == .GetNearbyTeams {
                    self.resultsType = .NearbyTeams
                } else {
                    self.resultsType = .SearchByName
                }
                self.performSegueWithIdentifier("teamSearchResultsSegue", sender: self)
            }
        }
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "teamSearchResultsSegue" {
            let destinationViewController = segue.destinationViewController as! VTTeamSearchResultsTableViewController
            if self.resultsType == .NearbyTeams {
                destinationViewController.resultsType = .NearbyTeams
                destinationViewController.userCoordinates = self.userCoordinates
            } else {
                destinationViewController.resultsType = .SearchByName
                destinationViewController.searchTeamKeyword = self.searchKeyword
            }
            destinationViewController.numberOfTotalResults = self.numberOfTotalTeamResults!
            destinationViewController.teamSearchResults = [Team]()
            for teamDictionary in self.paginatedTeamResults! {
                let teamObject = Team(data: teamDictionary)
                destinationViewController.teamSearchResults.append(teamObject)
            }
        } else if segue.identifier == "appliedTeamBriefIntroSegue" {
            let destinationViewController = segue.destinationViewController as! VTTeamBriefIntroTableViewController
            destinationViewController.teamObject = self.selectedApplyingTeam
            destinationViewController.hasUserAlreadyAppliedThisTeam = true
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return self.teamsList.count
        } else {
            return self.applyingTeamsList.count
        }
    }
    
    deinit {
        self.responseData = nil
        self.teamsList.removeAll(keepCapacity: false)
        self.applyingTeamsList.removeAll(keepCapacity: false)
        self.selectedApplyingTeam = nil
        self.HUD = nil
        self.paginatedTeamResults?.removeAll(keepCapacity: false)
        self.paginatedTeamResults = nil
        if self.locationService != nil {
            self.locationService?.delegate = nil
            self.locationService = nil
        }
        self.indexOfCurrentHttpRequest = nil
        self.numberOfTotalTeamResults = nil
        self.resultsType = nil
        self.userCoordinates = nil
    }
    
    @IBAction func unwindToTeamListTableView(segue: UIStoryboardSegue) {
    }

}
