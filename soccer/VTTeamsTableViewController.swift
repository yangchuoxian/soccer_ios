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
        case getNearbyTeams
        case searchTeamsByName
        case getTeamsForUser
    }
    
    let tableCellIdentifier = "teamsListTableCell"
    
    var teamsList = [Team]()
    var applyingTeamsList = [Team]()
    
    var HUD: MBProgressHUD?
    var indexOfCurrentHttpRequest: HttpRequest?
    var numberOfTotalTeamResults: Int?
    var paginatedTeamResults: [[AnyHashable: Any]]?
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
        self.refreshControl?.addTarget(self, action: #selector(VTTeamsTableViewController.refresh), for: .valueChanged)
        self.tableView.addSubview(self.refreshControl!)
        
        // setup teamsList and load user team list from local database
        let currentUser = Singleton_CurrentUser.sharedInstance
        
        let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        let teams = dbManager?.loadData(
            fromDB: "select * from teams where forUserId=?",
            parameters: [currentUser.userId!]
        )
        if (teams?.count)! > 0 {    // current logged in user belongs to some teams and these teams are store in local database
            for team in teams! {
                let teamObject = Team.formatDatabaseRecordToTeamFormat(team as! [AnyObject])
                self.teamsList.append(teamObject)
            }
        }
        
        // This will remove extra separators from tableview
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.rowHeight = CustomTableRowHeight
        self.tableView.separatorColor = UIColor.clear
        // liten to teamRecordSavedOrUpdated message and handles it by updating teamsList in current view controller
        NotificationCenter.default.addObserver(self, selector: #selector(VTTeamsTableViewController.handleNewOrUpdatedTeam(_:)), name: NSNotification.Name(rawValue: "teamRecordSavedOrUpdated"), object: nil)
        // listen to teamDeletedLocally message and handles it by deleting corresponding team from self.teamsList and removing corresponding entry in self.tableView
        NotificationCenter.default.addObserver(self, selector: #selector(VTTeamsTableViewController.deleteTeamEntries(_:)), name: NSNotification.Name(rawValue: "teamsDeletedLocally"), object: nil)
        // listen to userQuitOrDimissedTeam notification and handles it by deleting corresponding team from self.teamsList and removing correspond entry in self.tableView
        NotificationCenter.default.addObserver(self, selector: #selector(VTTeamsTableViewController.showQuitOrDismissTeamSucceededHintMessageBox(_:)), name: NSNotification.Name(rawValue: "userQuittedOrDismissedTeam"), object: nil)
        // once team captain changed, teams table should also be updated
        NotificationCenter.default.addObserver(self, selector: #selector(VTTeamsTableViewController.handleTeamWhichHasCaptainChanged(_:)), name: NSNotification.Name(rawValue: "teamCaptainChangedOnServer"), object: nil)
        // once team member removed from team, the number of members for that team in tableView should also be updated
        NotificationCenter.default.addObserver(self, selector: #selector(VTTeamsTableViewController.updateNumberOfMembersAfterMemberRemovedFromTeam(_:)), name: NSNotification.Name(rawValue: "teamMemberDeletedOnServer"), object: nil)
        // if current user has sent an application to a team, the team should show up in this tableView as a team that the user has sent application to
        NotificationCenter.default.addObserver(self, selector: #selector(VTTeamsTableViewController.addTeamThatUserIsApplyingFor(_:)), name: NSNotification.Name(rawValue: "applicationSentSuccessfully"), object: nil)
        // programmatically refresh to see if there are any new unread messages while VTMessageGroupsTableViewController is not showing or maybe the app is turned off or been run in background
        self.refresh()
        
        /** 
         * system message notification handler
         */
        NotificationCenter.default.addObserver(self, selector: #selector(VTTeamsTableViewController.refreshTeamsData), name: NSNotification.Name(rawValue: "receivedSystemMessage_teamMemberRemoved"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(VTTeamsTableViewController.refreshTeamsData), name: NSNotification.Name(rawValue: "receivedSystemMessage_teamCaptainChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(VTTeamsTableViewController.refreshTeamsData), name: NSNotification.Name(rawValue: "receivedSystemMessage_teamDismissed"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(VTTeamsTableViewController.refreshTeamsData), name: NSNotification.Name(rawValue: "receivedSystemMessage_newMemberJoined"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(VTTeamsTableViewController.refreshTeamsData), name: NSNotification.Name(rawValue: "receivedSystemMessage_requestRefused"), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        Appearance.customizeNavigationBar(self, title: "我的球队")
    }
    
    func refreshTeamsData() {
        self.refresh()
    }
    
    // Current user has sent an application to a team, this team should be added in the second section of teams tableView
    func addTeamThatUserIsApplyingFor(_ notification: Notification) {
        let appliedTeam = notification.object as! Team
        // add the team in self.applyingTeamsList
        self.applyingTeamsList.append(appliedTeam)
        // reload the applying teams list section
        self.tableView.reloadSections(IndexSet(integer: 1), with: .top)
    }
    
    // Current user is no longer captain of the team selected, thus the star that represents the current user being captain for the team should be removed or hided
    func handleTeamWhichHasCaptainChanged(_ notification: Notification) {
        let newCaptainUserId = notification.object as! String
        // retrieve the corresponding team id
        let selectedTeamId = UserDefaults.standard.object(forKey: "teamIdSelectedInTeamsList") as! String
        
        // find out the table cell that contains the corresponding team
        let searchedTeams = self.teamsList.filter{
            $0.teamId == selectedTeamId
        }
        if searchedTeams.count > 0 {
            let indexOfCorrespondingTeam = self.teamsList.index(of: searchedTeams[0])
            // update the captain id for that Team object in self.teamsList
            let teamObject = self.teamsList[indexOfCorrespondingTeam!]
            teamObject.captainUserId = newCaptainUserId
            
            // reload corresponding tableView cell to remove that star
            self.tableView.reloadRows(at: [IndexPath(row: indexOfCorrespondingTeam!, section: 0)], with: .none)
        } else {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "球队没找到")
        }
    }
    
    /**
     * Team member deleted on server side and number of member for that team in local database has updated as well, now need to update numer of members in teams table view
     */
    func updateNumberOfMembersAfterMemberRemovedFromTeam(_ notification: Notification) {
        let teamInfoAfterDeletingTeamMember = notification.object as! [AnyHashable: Any]
        // retrieve the corresponding team id
        let selectedTeamId = UserDefaults.standard.string(forKey: "teamIdSelectedInTeamsList")
        // find out the table cell that contains the corresponding team
        let searchedTeams = self.teamsList.filter{
            $0.teamId == selectedTeamId
        }
        if searchedTeams.count > 0 {
            let indexOfCorrespondingTeam = self.teamsList.index(of: searchedTeams[0])
            self.teamsList[indexOfCorrespondingTeam!].numberOfMembers = (teamInfoAfterDeletingTeamMember["newNumberOfMembers"]! as AnyObject).intValue
            self.tableView.reloadRows(at: [IndexPath(row: indexOfCorrespondingTeam!, section: 0)], with: .none)
        } else {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "球队没找到")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "我的球队")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
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
    
    func handleNewOrUpdatedTeam(_ notification: Notification) {
        let teamInvolved = notification.object as! Team
        // try to find the team in self.teamsList based on teamId
        let existedTeams = self.teamsList.filter{
            $0.teamId == teamInvolved.teamId
        }
        if existedTeams.count > 0 { // the team exists already, database instruction is an update
            let indexOfTeamToBeUpdated = self.teamsList.index(of: existedTeams[0])
            // update related entry in self.teamsList to update data showing in tableView
            self.teamsList[indexOfTeamToBeUpdated!] = teamInvolved
            // update table view data, just thta specific row, NOT the whole table
            let indexPath = IndexPath(row: indexOfTeamToBeUpdated!, section: 0)
            self.tableView.reloadRows(at: [indexPath], with: .none)
        } else {    // the team does NOT exist, database instruction is adding a new team record
            self.teamsList.insert(teamInvolved, at: 0)  // insert this team in front of the first team as a new team to self.teamList to show in tableView
            // insert a new row as the first row into tableView with animation
            let indexPath = IndexPath(row: 0, section: 0)
            self.tableView.insertRows(at: [indexPath], with: .top)
        }
    }
    
    func removeTeamInTableViewEntry(_ teamIdToDelete: String) {
        let teamsToDelete = self.teamsList.filter{
            $0.teamId == teamIdToDelete
        }
        if teamsToDelete.count > 0 {   // the team to delete is currently still in self.teamsList
            let indexOfTeamToDelete = self.teamsList.index(of: teamsToDelete[0])
            self.teamsList.remove(at: indexOfTeamToDelete!)
            
            // delete the corresponding table rows with animation
            self.tableView.deleteRows(at: [IndexPath(row: indexOfTeamToDelete!, section: 0)], with: .top)
        }
    }
    
    /**
     * Team(s) already deleted in local database,
     * now remove them from self.teamsList and self.tableView
     */
    func deleteTeamEntries(_ notification: Notification) {
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
    func showQuitOrDismissTeamSucceededHintMessageBox(_ notification: Notification) {
        let quitOrDismissTeamNotificationDictionary = notification.object as! [AnyHashable: Any]
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
    func didGetUserCoordinates(_ coordinate: CLLocationCoordinate2D) {
        self.submitRequestToSearchNearByTeamsWithCurrentUserLocation(coordinate)
    }
    
    /**
     * User current location found, now submit current user location to server to search for near by teams
     */
    func submitRequestToSearchNearByTeamsWithCurrentUserLocation(_ coordinate: CLLocationCoordinate2D) {
        self.userCoordinates = coordinate
        let urlToGetNearbyTeams = "\(URLGetNearbyTeamsForUser)?latitude=\(coordinate.latitude)&longitude=\(coordinate.longitude)&page=1"
        let connection = Toolbox.asyncHttpGetFromURL(urlToGetNearbyTeams, delegate: self)
        if connection == nil {
            self.HUD?.hide(true)
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            self.HUD?.labelText = "搜索附近球队中..."
            self.indexOfCurrentHttpRequest = .getNearbyTeams
        }
    }

    /**
     * Submit http request to search teams by name
     */
    func submitRequestToSearchTeamsByName(_ searchKeyword: String) {
        self.searchKeyword = searchKeyword
        let urlToSearchTeamsByName = URLSearchTeamsForUser + "?keyword=" + searchKeyword + "&page=1"
        let connection = Toolbox.asyncHttpGetFromURL(urlToSearchTeamsByName, delegate: self)
        if connection == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            self.indexOfCurrentHttpRequest = .searchTeamsByName
            // show loading spinner HUD to indicate that searching teams is in process
            self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: "搜索中...")
        }
    }
    
    @IBAction func showAlertControllerToSearchOrCreateTeam(_ sender: AnyObject) {
        if #available(iOS 8.0, *) {
            let createNewTeamOrJoinExistedTeamAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let createNewTeam = UIAlertAction(title: "创建新球队", style: .default, handler: {
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
                    self.performSegue(withIdentifier: "createNewTeamSegue", sender: self)
                }
                return
            })
            let showNearbyTeam = UIAlertAction(title: "查看附近球队", style: .default, handler: {
                action in
                self.locationService = LocationService()
                self.locationService?.delegate = self
                // no need to get current address, just geo coordinates are fine
                self.locationService?.shouldGetReverseGeoCode = false
                self.locationService?.launchLocationService()
                return
            })
            let searchTeam = UIAlertAction(title: "搜索球队", style: .default, handler: {
                action in
                let searchAlertController = UIAlertController(title: "", message: "请输入球队名称", preferredStyle: .alert)
                let ok = UIAlertAction(title: "搜索", style: .default, handler: {
                    action in
                    let searchTeamKeyword = (searchAlertController.textFields?.first as UITextField!).text
                    if searchTeamKeyword!.characters.count > 0 {
                        self.submitRequestToSearchTeamsByName(searchTeamKeyword!)
                    } else {
                        searchAlertController.dismiss(animated: true, completion: nil)
                    }
                    return
                })
                let cancel = UIAlertAction(title: "取消", style: .default, handler: {
                    action in
                    searchAlertController.dismiss(animated: true, completion: nil)
                    return
                })
                
                searchAlertController.addAction(cancel)
                searchAlertController.addAction(ok)
                searchAlertController.addTextField(configurationHandler: {
                    textField in
                    textField.placeholder = "球队名称"
                    textField.keyboardType = .default
                    self.present(searchAlertController, animated: true, completion: nil)
                    return
                })
            })
            let cancel = UIAlertAction(title: "取消", style: .cancel, handler: {
                action in
                createNewTeamOrJoinExistedTeamAlertController.dismiss(animated: true, completion: nil)
                return
            })
            createNewTeamOrJoinExistedTeamAlertController.addAction(createNewTeam)
            createNewTeamOrJoinExistedTeamAlertController.addAction(showNearbyTeam)
            createNewTeamOrJoinExistedTeamAlertController.addAction(searchTeam)
            createNewTeamOrJoinExistedTeamAlertController.addAction(cancel)
            self.present(createNewTeamOrJoinExistedTeamAlertController, animated: true, completion: nil)
        } else {
            let createNewTeamOrJoinExistedTeamAction = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: nil, destructiveButtonTitle: nil, otherButtonTitles: "创建新球队", "查看附近球队", "搜索球队", "取消")
            createNewTeamOrJoinExistedTeamAction.show(from: self.tabBarController!.tabBar)
        }
    }
    
    func actionSheet(_ actionSheet: UIActionSheet, clickedButtonAt buttonIndex: Int) {
        actionSheet.dismiss(withClickedButtonIndex: buttonIndex, animated: true)
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
                self.performSegue(withIdentifier: "createNewTeamSegue", sender: self)
            }
        } else if buttonIndex == 1 {    // search nearby teams
            self.locationService = LocationService()
            self.locationService?.delegate = self
            self.locationService?.launchLocationService()
        } else if buttonIndex == 2 {    // search teams by name
            Appearance.showAlertViewWithInput("请输入球队名称", delegate: self)
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.searchKeyword = textField.text!
    }
    
    /**
    alert view delegate method for search team with keyword
    
    - parameter alertView:   the search team alert view
    - parameter buttonIndex: button index, whether user clicked yes or cancel
    */
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        alertView.dismiss(withClickedButtonIndex: buttonIndex, animated: true)
        if buttonIndex == 1 {
            if self.searchKeyword.characters.count > 0 {
                self.submitRequestToSearchTeamsByName(self.searchKeyword)
            }
        }
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
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
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: TableSectionHeaderHeight))
        if self.applyingTeamsList.count > 0 {
            if section == 0 {     // section that contains teams that the user belongs to
                headerView.addSubview(Appearance.setupTableSectionHeaderTitle(" 现有球队"))
            } else {                // section that contains teams that the user is applying for yet hasn't been either approved or rejected
                headerView.addSubview(Appearance.setupTableSectionHeaderTitle(" 申请加入的球队"))
            }
        }
        return headerView
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // Display a message and an image when the table is empty
        let emptyTableBackgroundView = UIView(frame: CGRect(x: 0, y: self.tableView.frame.origin.y, width: self.tableView.frame.size.width, height: self.tableView.frame.size.height))
        emptyTableBackgroundView.tag = TagValue.emptyTableBackgroundView.rawValue
        let image = UIImageView(image: UIImage(named: "no_team"))
        image.frame = CGRect(x: ScreenSize.width / 2 - 55, y: ScreenSize.height / 2 - 110 - ToolbarHeight, width: 110, height: 110)
        
        let messageLabel = UILabel(frame: CGRect(x: ScreenSize.width / 2 - 60, y: ScreenSize.height / 2, width: ScreenSize.width, height: 50))
        
        messageLabel.text = "暂未加入任何球队"
        messageLabel.textColor = EmptyImageColor
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.sizeToFit()
        emptyTableBackgroundView.addSubview(image)
        emptyTableBackgroundView.addSubview(messageLabel)
        if self.teamsList.count > 0 || self.applyingTeamsList.count > 0 {
            self.tableView.backgroundView = nil
            for subView in self.tableView.subviews {
                if subView.tag == TagValue.emptyTableBackgroundView.rawValue { // the subview is the emptyTableBackgroundView
                    (subView ).removeFromSuperview()
                }
            }
        } else {
            self.tableView.addSubview(emptyTableBackgroundView)
            self.tableView.sendSubview(toBack: emptyTableBackgroundView)
        }
        // return the number of sections
        return 2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = self.tableView.dequeueReusableCell(withIdentifier: self.tableCellIdentifier) as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: self.tableCellIdentifier)
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
        if (indexPath as NSIndexPath).section == 0 {
            teamInCurrentRow = self.teamsList[(indexPath as NSIndexPath).row]
        } else {
            teamInCurrentRow = self.applyingTeamsList[(indexPath as NSIndexPath).row]
        }
        // load team avatar
        Toolbox.loadAvatarImage(teamInCurrentRow.teamId, toImageView: avatar, avatarType: AvatarType.team)
        label_teamName.text = teamInCurrentRow.teamName
        label_numberOfMembers.text = "\(teamInCurrentRow.numberOfMembers)人"
        
        // current logged user is the captain of this team
        if teamInCurrentRow.captainUserId == Singleton_CurrentUser.sharedInstance.userId {
            image_captainMark.isHidden = false
        } else {
            image_captainMark.isHidden = true
        }
        // add a separatorLine for each row/cell
        let separatorLineView = UIView(frame: CGRect(x: 15, y: 0, width: ScreenSize.width, height: 1))
        separatorLineView.backgroundColor = ColorBackgroundGray // set color as you want.
        cell?.contentView.addSubview(separatorLineView)
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        if (indexPath as NSIndexPath).section == 0 {   // selected a team that the user belongs to
            let selectedTeamObject = self.teamsList[(indexPath as NSIndexPath).row]
            // save selected team id in userDefaults for later use
            UserDefaults.standard.set(selectedTeamObject.teamId, forKey: "teamIdSelectedInTeamsList")
            self.performSegue(withIdentifier: "teamDetailsSegue", sender: self)
        } else {        // selected a team that the user is applying for
            self.selectedApplyingTeam = self.applyingTeamsList[(indexPath as NSIndexPath).row]
            self.performSegue(withIdentifier: "appliedTeamBriefIntroSegue", sender: self)
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
        self.indexOfCurrentHttpRequest = .getTeamsForUser
    }
    
    func connection(_ connection: NSURLConnection, didReceive data: Data) {
        self.responseData?.append(data)
    }
    
    func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络超时")
        self.HUD?.hide(true)
        self.HUD = nil
        self.refreshControl?.endRefreshing()
        
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        self.HUD?.hide(true)
        self.HUD = nil
        
        if self.indexOfCurrentHttpRequest == .getTeamsForUser {
            let userTeamsInfo = (try? JSONSerialization.jsonObject(with: self.responseData! as Data, options: .mutableLeaves)) as? [AnyHashable: Any]
            if userTeamsInfo != nil {   // http request to get teams succeeded
                let teamDictionariesUserBelongsTo = userTeamsInfo!["belongedTeams"] as! [[AnyHashable: Any]]
                let teamDictionariesUserIsApplyingFor = userTeamsInfo!["applyingTeams"] as! [[AnyHashable: Any]]
                
                var teamsUserBelongsTo = [Team]()
                for dictionary in teamDictionariesUserBelongsTo {
                    let team = Team(data: dictionary as [NSObject : AnyObject])
                    teamsUserBelongsTo.append(team)
                    // iterate through all the teams received and save each one of them in local database if  it is not yet in local database
                    team.saveOrUpdateTeamInDatabase()
                }
                // check to see if any team(s) has removed current user as its member
                Team.checkUserMembershipInTeams(teamsUserBelongsTo)
                self.applyingTeamsList.removeAll(keepingCapacity: false)
                for dictionary in teamDictionariesUserIsApplyingFor {
                    let applyingTeamObject = Team(data: dictionary as [NSObject : AnyObject])
                    self.applyingTeamsList.append(applyingTeamObject)
                }
                // after the list data for applying teams is ready, reload the second section of the tableView
                self.tableView.reloadSections(IndexSet(integer: 1), with: UITableViewRowAnimation.automatic)
            } else {    // http request to get teams failed
                let responseStr = NSString(data: self.responseData! as Data, encoding: String.Encoding.utf8.rawValue)
                Toolbox.showCustomAlertViewWithImage("unhappy", title: responseStr as! String)
            }
            self.refreshControl?.endRefreshing()
        } else if self.indexOfCurrentHttpRequest == .getNearbyTeams || self.indexOfCurrentHttpRequest == .searchTeamsByName {
            let responseDictionary = (try? JSONSerialization.jsonObject(with: self.responseData! as Data, options: .mutableLeaves)) as? [AnyHashable: Any]
            self.numberOfTotalTeamResults = (responseDictionary!["total"]! as AnyObject).intValue
            self.paginatedTeamResults = responseDictionary!["models"] as? [[AnyHashable: Any]]
            
            if self.numberOfTotalTeamResults == 0 {
                Toolbox.showCustomAlertViewWithImage("unhappy", title: "没有找到球队")
            } else {
                if self.indexOfCurrentHttpRequest == .getNearbyTeams {
                    self.resultsType = .nearbyTeams
                } else {
                    self.resultsType = .searchByName
                }
                self.performSegue(withIdentifier: "teamSearchResultsSegue", sender: self)
            }
        }
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "teamSearchResultsSegue" {
            let destinationViewController = segue.destination as! VTTeamSearchResultsTableViewController
            if self.resultsType == .nearbyTeams {
                destinationViewController.resultsType = .nearbyTeams
                destinationViewController.userCoordinates = self.userCoordinates
            } else {
                destinationViewController.resultsType = .searchByName
                destinationViewController.searchTeamKeyword = self.searchKeyword
            }
            destinationViewController.numberOfTotalResults = self.numberOfTotalTeamResults!
            destinationViewController.teamSearchResults = [Team]()
            for teamDictionary in self.paginatedTeamResults! {
                let teamObject = Team(data: teamDictionary as [NSObject : AnyObject])
                destinationViewController.teamSearchResults.append(teamObject)
            }
        } else if segue.identifier == "appliedTeamBriefIntroSegue" {
            let destinationViewController = segue.destination as! VTTeamBriefIntroTableViewController
            destinationViewController.teamObject = self.selectedApplyingTeam
            destinationViewController.hasUserAlreadyAppliedThisTeam = true
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return self.teamsList.count
        } else {
            return self.applyingTeamsList.count
        }
    }
    
    deinit {
        self.responseData = nil
        self.teamsList.removeAll(keepingCapacity: false)
        self.applyingTeamsList.removeAll(keepingCapacity: false)
        self.selectedApplyingTeam = nil
        self.HUD = nil
        self.paginatedTeamResults?.removeAll(keepingCapacity: false)
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
    
    @IBAction func unwindToTeamListTableView(_ segue: UIStoryboardSegue) {
    }

}
