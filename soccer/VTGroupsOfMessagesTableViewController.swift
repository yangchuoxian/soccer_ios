//
//  VTGroupsOfMessagesTableViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/1.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTGroupsOfMessagesTableViewController: UITableViewController, MGSwipeTableCellDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate, UISearchResultsUpdating {
    
    var searchController: AnyObject?
    // filteredTableEntries holds the search results of messages searched by UISearchController,
    // we only search conversation message groups, NO SEARCH WILL BE CAST to notification groups
    var filterdTableEntries = [Message]()
    var conversationGroups = [Message]()
    var notificationGroups = [Message]()    // list to hold all message groups with message type being invitation, activity request and challenge
    var selectedTableCell: IndexPath?
    var shouldShowNetworkUnavailableHintView = false
    var responseData: NSMutableData? = NSMutableData()
    let tableCellIdentifier = "messagesListTableCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = true
        
        // add the UIRefreshControl to tableView
        self.refreshControl = Appearance.setupRefreshControl()
        self.refreshControl!.addTarget(self, action: #selector(VTGroupsOfMessagesTableViewController.refresh), for: .valueChanged)
        self.tableView.addSubview(self.refreshControl!)
        
        // This will remove extra separators from tableview
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.rowHeight = CustomTableRowHeight
        
        self.tableView.separatorColor = UIColor.clear
        
        if #available(iOS 8.0, *) {
            // if under ios version 8.0, no support for search controller at all
            // set up search controller
            self.searchController = UISearchController(searchResultsController: nil)
            (self.searchController as! UISearchController).searchResultsUpdater = self
            (self.searchController as! UISearchController).dimsBackgroundDuringPresentation = false
            (self.searchController as! UISearchController).searchBar.sizeToFit()
            self.tableView.tableHeaderView = (self.searchController as! UISearchController).searchBar
            
            self.definesPresentationContext = true
            
            // search bar appearance
            self.searchController!.searchBar.barTintColor = ColorBackgroundGray
            self.searchController!.searchBar.tintColor = ColorOrange
            self.searchController!.searchBar.layer.borderColor = ColorBackgroundGray.cgColor
            self.searchController!.searchBar.layer.borderWidth = 1
        }
        
        // listen to receivedNewMessageAndSavedInLocalDatabase notification and handles it by updating messagesList in tableView in current view controller
        NotificationCenter.default.addObserver(self, selector: #selector(VTGroupsOfMessagesTableViewController.handleReceivedMessageOrSentMessage(_:)), name: NSNotification.Name(rawValue: "receivedNewMessageAndSavedInLocalDatabase"),  object: nil)
        // listen to sentMessageAndSavedInLocalDatabase notification and handles it by updating messagesList in tableView in current view controller
        NotificationCenter.default.addObserver(self, selector: #selector(VTGroupsOfMessagesTableViewController.handleReceivedMessageOrSentMessage(_:)), name: NSNotification.Name(rawValue: "sentMessageAndSavedInLocalDatabase"), object: nil)
        // listen to numOfUnreadMessagesInOneMessageGroupChanged notification and update the number of unread messages of that particular message group(conversation)
        NotificationCenter.default.addObserver(self, selector: #selector(VTGroupsOfMessagesTableViewController.updateNumOfUnreadMessagesForSpecificMessageGroup(_:)), name: NSNotification.Name(rawValue: "numOfUnreadMessagesInOneMessageGroupChanged"), object:nil)
        // listen to reachable/unreachablie message sent by Reachability
        NotificationCenter.default.addObserver(self, selector: #selector(VTGroupsOfMessagesTableViewController.reachabilityDidChange(_:)), name: NSNotification.Name.reachabilityChanged, object: nil)
        
        // load message list from local database
        self.getMessageGroupsDataFromLocalDatabase()
        
        // programmatically refresh to see if there are any new unread messages while VTMessageGroupsTableViewController is not showing or maybe the app is turned off or been run in background
        self.refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "消息列表")
        if #available(iOS 8.0, *) {
            if self.searchController != nil {
                (self.searchController as! UISearchController).isActive = false
            }
        }
    }
    
    /**
    asks server for all unread messages sent to current user
    */
    func refresh() {
        let urlToGetUnreadMessagesForCurrentUser = URLGetUnreadMessages + "?userId=" + Singleton_CurrentUser.sharedInstance.userId!
        let connection = Toolbox.asyncHttpGetFromURL(urlToGetUnreadMessagesForCurrentUser, delegate: self)
        if connection == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        }
    }
    
    /**
    For each notification type, this funcntion gets the 
    a. latest message in this notification message group and
    b. the number of unread messages in this notification message group
    
    - parameter messageGroupId: the message group id
    
    - returns: the latest message in this message group
    */
    func getNotificationGroupInfoForGroupId(_ messageGroupId: Int) -> Message? {
        let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        /**
        * GET LATEST  MESSAGE IF ANY
        */
        let messagesInGroup = dbManager?.loadData(
            fromDB: "select * from messages where messageGroupId=? and recipientId=? group by messageGroupId",
            parameters: [messageGroupId, Singleton_CurrentUser.sharedInstance.userId!]
        )
        if (messagesInGroup?.count)! > 0 {   // messages exist
            let latestMessage = Message.formatDatabaseRecordToMessageFormat(messagesInGroup[0] as! [String])
            return latestMessage
        }
        return nil
    }
    
    /**
    When view did load, one should invoke this function to retrieve all messages in local database to show in table view
    */
    func getMessageGroupsDataFromLocalDatabase() {
        
        // Get latest request message if any
        let latestRequest = self.getNotificationGroupInfoForGroupId(MessageGroupIndex.request.rawValue)
        if latestRequest != nil {
            self.notificationGroups.append(latestRequest!)
        }
        // Get latest system notification if any
        let latestSystemNotification = self.getNotificationGroupInfoForGroupId(MessageGroupIndex.systemMessage.rawValue)
        if latestSystemNotification != nil {
            self.notificationGroups.append(latestSystemNotification!)
        }
        
        // GET CONVERSATION MESSAGE GROUPS
        let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        let conversations = dbManager?.loadData(
            fromDB: "select * from messages where messageGroupId not in (?, ?) group by messageGroupId order by createdAt desc",
            parameters: [
                MessageGroupIndex.request.rawValue,
                MessageGroupIndex.systemMessage.rawValue,
            ]
        )
        if conversations.count > 0 {
            for conversation in conversations {
                let latestMessageInThisConversation = Message.formatDatabaseRecordToMessageFormat(conversation as! [String])
                self.conversationGroups.append(latestMessageInThisConversation)
            }
        }
        self.tableView.reloadData()
    }
    
    /**
    Show or hide the hint that says network unavailable when network accessibility changed
    
    - parameter notification: reachability changed notification object
    */
    func reachabilityDidChange(_ notification: Notification) {
        let reachability = notification.object as! Reachability
        if !reachability.isReachable() {
            self.tableView.beginUpdates()
            self.shouldShowNetworkUnavailableHintView = true
            self.tableView.endUpdates()
        } else {
            self.tableView.beginUpdates()
            for subview in self.tableView.subviews {
                if subview.tag == TagValue.tableHeaderHint.rawValue {    // the subview is the network unavailable hint view
                    subview.removeFromSuperview()
                    break
                }
            }
            self.shouldShowNetworkUnavailableHintView = false
            self.tableView.endUpdates()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateNumOfUnreadMessagesForSpecificMessageGroup(_ notification: Notification) {
        let messageGroupId = (notification.object! as AnyObject).intValue
        var listToBeUpdated: [Message]
        var sectionIndex: Int
        if messageGroupId == MessageGroupIndex.request.rawValue || messageGroupId == MessageGroupIndex.systemMessage.rawValue {
            listToBeUpdated = self.notificationGroups
            sectionIndex = MessageGroupTableSectionIndex.notification.rawValue
        } else {
            listToBeUpdated = self.conversationGroups
            sectionIndex = MessageGroupTableSectionIndex.conversation.rawValue
        }
        
        // find the message group in self.messagesList based on the passed in paramter messageGroupId
        let theMessageGroup = listToBeUpdated.filter{$0.messageGroupId == messageGroupId}
        
        if theMessageGroup.count > 0 {  // the corresponding message group FOUND in self.messagesList
            let indexOfMessageGroupToBeUpdated = listToBeUpdated.index(of: theMessageGroup[0])
            let latestMessageInThisGroup = listToBeUpdated[indexOfMessageGroupToBeUpdated!]
            latestMessageInThisGroup.numOfUnreadMessagesInTheGroup = Message.getNumberOfUnreadMessagesForMessageGroup(messageGroupId)
            
            listToBeUpdated[indexOfMessageGroupToBeUpdated!] = latestMessageInThisGroup    // update related entry in self.notificationGroups or self.conversationGroups to update data showing in tableView
            // update table view data, just that specific row, NOT the whole table
            let indexPath = IndexPath(row: indexOfMessageGroupToBeUpdated!, section: sectionIndex)
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
   
    func handleReceivedMessageOrSentMessage(_ notification: Notification) {
        let message = notification.object as! Message
        self.showNewMessageInTableView(message)
    }
    
    /**
    After receiving new messages, one should invoke this function to update table view to show new messages. messages can be received:
    a. via socket or
    b. after user manually pull to refresh this view
    
    - parameter message: the new message
    */
    func showNewMessageInTableView(_ message: Message) {
        var listToBeUpdate: [Message]
        var sectionIndex: Int
        let messageGroupId = message.messageGroupId
        if messageGroupId == MessageGroupIndex.request.rawValue || messageGroupId == MessageGroupIndex.systemMessage.rawValue {
            listToBeUpdate = self.notificationGroups
            sectionIndex = MessageGroupTableSectionIndex.notification.rawValue
        } else {
            listToBeUpdate = self.conversationGroups
            sectionIndex = MessageGroupTableSectionIndex.conversation.rawValue
        }
        let messageGroupToBeUpdated = listToBeUpdate.filter{
            $0.messageGroupId == message.messageGroupId
        }
        if messageGroupToBeUpdated.count > 0 {  // the received message belongs to a message group existed locally(in app database)
            let indexOfMessageGroupToBeUpdated = listToBeUpdate.index(of: messageGroupToBeUpdated[0])
            // update related entry in self.notificationGroups or self.conversationGroups to update data showing in tableView
            if sectionIndex == MessageGroupTableSectionIndex.notification.rawValue {
                self.notificationGroups[indexOfMessageGroupToBeUpdated!] = message
            } else {
                self.conversationGroups[indexOfMessageGroupToBeUpdated!] = message
            }
            // update table view data, just that specific row, NOT the whole table
            let indexPath = IndexPath(row: indexOfMessageGroupToBeUpdated!, section: sectionIndex)
            self.tableView.reloadRows(at: [indexPath], with: .none)
        } else {                    // the received message started a new message group
            // insert this message (group) in front of the first message group as a new message group to self.conversationGroups or self.notificationGroups to show in tableView
            if sectionIndex == MessageGroupTableSectionIndex.notification.rawValue {
                self.notificationGroups.insert(message, at: 0)
            } else {
                self.conversationGroups.insert(message, at: 0)
            }
            // insert a new row as the first row into tableView with animation
            let indexPath = IndexPath(row: 0, section: sectionIndex)
            self.tableView.insertRows(at: [indexPath], with: .top)
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == MessageGroupTableSectionIndex.notification.rawValue {
            if self.shouldShowNetworkUnavailableHintView {
                return TableSectionHeaderHeight
            } else {
                return 0.0
            }
        }
        return 0.0
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == MessageGroupTableSectionIndex.notification.rawValue {
            if self.notificationGroups.count == 0 {
                return 0.0
            } else {
                return TableSectionFooterHeight
            }
        }
        return 0.0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == MessageGroupTableSectionIndex.notification.rawValue {
            if self.shouldShowNetworkUnavailableHintView {
                let headerView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: 0))
                headerView.backgroundColor = ColorOrange
                
                let crossIcon = UIImageView(image: UIImage(named: "cross"))
                crossIcon.frame = CGRect(x: 10, y: 11, width: 10, height: 10)
                headerView.addSubview(crossIcon)
                
                let hintTextLabel = UILabel(frame: CGRect(x: 30, y: 0, width: ScreenSize.width - 35, height: TableSectionHeaderHeight))
                hintTextLabel.textColor = UIColor.white
                hintTextLabel.text = "网络无法连接"
                hintTextLabel.font = UIFont.systemFont(ofSize: 14.0)
                hintTextLabel.textAlignment = .center
                
                headerView.addSubview(hintTextLabel)
                headerView.tag = TagValue.tableHeaderHint.rawValue
                
                return headerView
            } else {
                return nil
            }
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == MessageGroupTableSectionIndex.notification.rawValue {
            let footerView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: 0))
            footerView.backgroundColor = UIColor.clear
            
            return footerView
        }
        return nil
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // Display a message and an image when the table is empty
        let emptyTableBackgroundView = UIView(frame: CGRect(x: 0, y: self.tableView.frame.origin.y, width: self.tableView.frame.size.width, height: self.tableView.frame.size.height))
        emptyTableBackgroundView.tag = TagValue.emptyTableBackgroundView.rawValue
        let image = UIImageView(image: UIImage(named: "empty"))
        image.frame = CGRect(
            x: ScreenSize.width / 2 - 55,
            y: ScreenSize.height / 2 - 110,
            width: 110,
            height: 110
        )
        
        let messageLabel = UILabel(frame: CGRect(x: ScreenSize.width / 2 - 55, y: ScreenSize.height / 2, width: self.tableView.bounds.size.width, height: 50))
        
        messageLabel.text = "暂时没有新消息"
        messageLabel.textColor = EmptyImageColor
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.sizeToFit()
        
        emptyTableBackgroundView.addSubview(image)
        emptyTableBackgroundView.addSubview(messageLabel)
        if self.conversationGroups.count > 0 || self.notificationGroups.count > 0 {
            self.tableView.backgroundView = nil
            for subView in self.tableView.subviews {
                if subView.tag == TagValue.emptyTableBackgroundView.rawValue {    // the subview is the emptyTableBackgroundView
                    subView.removeFromSuperview()
                }
            }
        } else {
            self.tableView.addSubview(emptyTableBackgroundView)
            self.tableView.sendSubview(toBack: emptyTableBackgroundView)
        }
        
        // Return the number of sections
        if #available(iOS 8.0, *) {
            if self.searchController != nil {
                if (self.searchController as! UISearchController).isActive {  // search controller showing
                    return 1
                }
            }
        }
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if #available(iOS 8.0, *) {
            if self.searchController != nil {
                if (self.searchController as! UISearchController).isActive {  // search controller showing
                    return self.filterdTableEntries.count
                }
            }
        }
        if section == MessageGroupTableSectionIndex.notification.rawValue { // notification list section
            return self.notificationGroups.count
        } else {            // conversation list section
            return self.conversationGroups.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = self.tableView.dequeueReusableCell(withIdentifier: self.tableCellIdentifier) as? MGSwipeTableCell
        if cell == nil {
            cell = MGSwipeTableCell(style: .default, reuseIdentifier: self.tableCellIdentifier)
        }
        var messageInCurrentRow: Message
        if (indexPath as NSIndexPath).section == MessageGroupTableSectionIndex.notification.rawValue {
            messageInCurrentRow = self.notificationGroups[(indexPath as NSIndexPath).row]
        } else {
            messageInCurrentRow = self.conversationGroups[(indexPath as NSIndexPath).row]
        }
        if #available(iOS 8.0, *) {
            if self.searchController != nil {
                if (self.searchController as! UISearchController).isActive {
                    messageInCurrentRow = self.filterdTableEntries[(indexPath as NSIndexPath).row]
                }
            }
        }
        // displaying message group for conversations, i.e. messages with one-to-one message type
        if messageInCurrentRow.messageGroupId != MessageGroupIndex.request.rawValue &&
            messageInCurrentRow.messageGroupId != MessageGroupIndex.systemMessage.rawValue {
            // set up message sender's avatar
            let avatar = cell?.contentView.viewWithTag(1) as! UIImageView
            avatar.layer.cornerRadius = 2.0
            avatar.layer.masksToBounds = true
            
            // set up the second user's username in this conversation
            let label_username = cell?.contentView.viewWithTag(2) as! UILabel
            
            // for each message group showing in table view, always display the other user's avatar and username
            // WILL NEVER display current logged in user's avatar and username
            var userIdToGetAvatarAndUsername: String
            if Singleton_CurrentUser.sharedInstance.userId == messageInCurrentRow.from {    // current user is the sender of the latest message in this conversation
                userIdToGetAvatarAndUsername = messageInCurrentRow.to
                label_username.text = messageInCurrentRow.receiverName
            } else {    //current user is the recipient of the latest message in this conversation
                userIdToGetAvatarAndUsername = messageInCurrentRow.from
                label_username.text = messageInCurrentRow.senderName
            }
            // load current user avatar
            Toolbox.loadAvatarImage(userIdToGetAvatarAndUsername, toImageView:avatar, avatarType: AvatarType.user)
            
            // set up message content
            let label_messageContent = cell?.contentView.viewWithTag(3) as! UILabel
            label_messageContent.text = messageInCurrentRow.content
        } else {
            // set up message group icon
            let messageGroupIcon = cell!.contentView.viewWithTag(1) as! UIImageView
            // set up the message group name
            let label_messageGroupName = cell!.contentView.viewWithTag(2) as! UILabel
            
            switch messageInCurrentRow.messageGroupId {
            case MessageGroupIndex.request.rawValue:
                messageGroupIcon.image = UIImage(named: "person_add")
                label_messageGroupName.text = "请求通知"
                break
            case MessageGroupIndex.systemMessage.rawValue:
                messageGroupIcon.image = UIImage(named: "system_message")
                label_messageGroupName.text = "系统消息"
                break
            default:
                break
            }
        }
        
        let label_time = cell!.contentView.viewWithTag(4) as! UILabel
        label_time.text = Toolbox.formatTimeString(messageInCurrentRow.createdAt, shouldGetHourAndMinute: true)
        
        let label_numOfUnreads = cell!.contentView.viewWithTag(5) as! UILabel
        label_numOfUnreads.layer.cornerRadius = 12.0
        label_numOfUnreads.clipsToBounds = true
        if messageInCurrentRow.numOfUnreadMessagesInTheGroup == 0 {
            label_numOfUnreads.isHidden = true
        } else {
            label_numOfUnreads.isHidden = false
            if messageInCurrentRow.numOfUnreadMessagesInTheGroup < 10 {
                label_numOfUnreads.text = String(messageInCurrentRow.numOfUnreadMessagesInTheGroup)
            } else {
                label_numOfUnreads.text = "..."
            }
        }
        cell!.delegate = self
        
        // configure left buttons
        if messageInCurrentRow.messageGroupId != MessageGroupIndex.request.rawValue {
            // for invitations, challenges or activity requests that require user to respond, user cannot mark the whole group as read
            if messageInCurrentRow.numOfUnreadMessagesInTheGroup > 0 {    // has unread message(s) in this message group
                cell!.leftButtons = [MGSwipeButton(title: "标记为已读", backgroundColor: ColorDarkerBlue)]
            } else {
                cell!.leftButtons = nil
            }
        } else {
            cell!.leftButtons = nil
        }
        
        // configure right buttons
        cell!.rightButtons = [MGSwipeButton(title: "删除", backgroundColor: UIColor.red)]
        
        if (indexPath as NSIndexPath).row != 0 {   // if the cell is not the first row of its section, add a separatorLine
            let separatorLineView = UIView(frame: CGRect(x: 15, y: 0, width: ScreenSize.width, height: 1))
            separatorLineView.backgroundColor = ColorBackgroundGray
            
            cell!.contentView.addSubview(separatorLineView)
        }
        
        return cell!
    }
    
    @available(iOS 8.0, *)
    func updateSearchResults(for searchController: UISearchController) {
        self.filterdTableEntries.removeAll(keepingCapacity: false)
        self.filterdTableEntries = self.conversationGroups.filter{
            $0.senderName.range(of: self.searchController!.searchBar.text!) != nil
        }
        self.tableView.reloadData()
    }
    
    /**
    When one of the table cell is tapped, its indexPath will be recorded
    so that messageGroupId of the corresponding message in that table cell
    can be passed to conversationViewController
    
    - parameter tableView: current table view
    - parameter indexPath: selected table cell indexPath
    */
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        self.selectedTableCell = indexPath
        if (indexPath as NSIndexPath).section == MessageGroupTableSectionIndex.conversation.rawValue {
            self.performSegue(withIdentifier: "messagesSegue", sender: self)
        } else {
            let messageInCurrentRow = self.notificationGroups[(indexPath as NSIndexPath).row]
            if messageInCurrentRow.messageGroupId == MessageGroupIndex.systemMessage.rawValue {
                self.performSegue(withIdentifier: "systemMessagesSegue", sender: self)
            } else if messageInCurrentRow.messageGroupId == MessageGroupIndex.request.rawValue {
                self.performSegue(withIdentifier: "requestsSegue", sender: self)
            }
        }
    }
    
    /**
    Called when the user clicks a swipe button or when a expandable button is automatically triggered
    @return YES to autohide the current swipe buttons
    
    - parameter cell:          the table cell been swiped
    - parameter index:         tapped button index
    - parameter direction:     swipe direction
    - parameter fromExpansion: whether from expansion or not
    
    - returns: boolean
    */
    func swipeTableCell(_ cell: MGSwipeTableCell!, tappedButtonAt index: Int, direction: MGSwipeDirection, fromExpansion: Bool) -> Bool {
        let indexPath = self.tableView.indexPath(for: cell)
        let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        
        var listToBeUpdate: [Message]
        if (indexPath! as NSIndexPath).section == MessageGroupTableSectionIndex.notification.rawValue {
            listToBeUpdate = self.notificationGroups
        } else {
            listToBeUpdate = self.conversationGroups
        }
        let messageToBeChanged = listToBeUpdate[(indexPath! as NSIndexPath).row]
        
        if direction == .leftToRight {   // swipe left to right, left button: mark as read tapped
            // get messageId of all unread messages in this message group
            let messageIdsResult = dbManager?.loadData(
                fromDB: "select messageId from messages where messageGroupId=? and status=?",
                parameters: [
                    messageToBeChanged.messageGroupId,
                    MessageStatus.unread.rawValue
                ]
            )
            var messageIds = [String]()
            for anyObject in messageIdsResult {
                let messageId = anyObject as? NSArray
                if messageId != nil {
                    messageIds.append(messageId![0] as! String)
                }
            }
            Message.changeMessagesStatus(messageIds, status: MessageStatus.read.rawValue)
            messageToBeChanged.numOfUnreadMessagesInTheGroup = 0
            // update table view data, just that specific row, NOT the whole table
            self.tableView.reloadRows(at: [indexPath!], with: .none)
        } else {                // swipe right to left, right button: delete tapped
            // delete all messages in the same message group in database
            dbManager?.modifyData(
                inDB: "delete from messages where messageGroupId=?",
                parameters: [messageToBeChanged.messageGroupId]
            )
            if dbManager?.affectedRows != 0 {  // database execution succeeded
                // notify VTMainTabBarViewController that some unread messages have been deleted and total number of unread messages should be updated
                NotificationCenter.default.post(
                    name: Notification.Name(rawValue: "totalNumOfUnreadMessagesChanged"),
                    object: [
                        "action": "-",
                        "quantity": String(messageToBeChanged.numOfUnreadMessagesInTheGroup)
                    ]
                )
            }
            // remove the message group in self.conversationGroups or self.notificationGroups and reload tableView
            if (indexPath! as NSIndexPath).section == MessageGroupTableSectionIndex.notification.rawValue {
                self.notificationGroups.remove(at: (indexPath! as NSIndexPath).row)
            } else {
                self.conversationGroups.remove(at: (indexPath! as NSIndexPath).row)
            }
            self.tableView.deleteRows(at: [indexPath!], with: .top)
        }
        return true
    }
    
    func connection(_ connection: NSURLConnection, didReceive data: Data) {
        self.responseData?.append(data)
    }
    
    func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        self.refreshControl?.endRefreshing()
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络超时")
        // clear responseData
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        if self.refreshControl != nil {
            self.refreshControl?.endRefreshing()
        }
        // http response for getting unread messages from server
        let receivedUnreadMessages = (try? JSONSerialization.jsonObject(with: self.responseData! as Data, options: .mutableLeaves)) as? [AnyObject]
        if receivedUnreadMessages != nil {
            if receivedUnreadMessages!.count > 0 {
                let numOfReceivedUnreadMessages = receivedUnreadMessages!.count
                
                for i in 0...(numOfReceivedUnreadMessages - 1) {
                    // save the received message into database if such message does NOT exist in database yet
                    let message = Message(messageInfo: receivedUnreadMessages![i] as! [String : AnyObject])
                    Message.saveMessageInDatabase(message)
                }
            }
        } else {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "获取消息失败")
        }
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var messageInSelectedTableCell: Message
        if segue.identifier == "messagesSegue" {
            messageInSelectedTableCell = self.conversationGroups[(self.selectedTableCell! as NSIndexPath).row]
            
            let conversationViewController = segue.destination as! VTConversationCollectionViewController
            conversationViewController.messageGroupId = messageInSelectedTableCell.messageGroupId
        } else if segue.identifier == "requestsSegue" {
            messageInSelectedTableCell = self.notificationGroups[(self.selectedTableCell! as NSIndexPath).row]
            
            let requestViewController = segue.destination as! VTRequestGroupViewController
            requestViewController.messageGroupId = messageInSelectedTableCell.messageGroupId
        } else if segue.identifier == "systemMessagesSegue" {
            messageInSelectedTableCell = self.notificationGroups[(self.selectedTableCell! as NSIndexPath).row]
            
            let systemMessageViewController = segue.destination as! VTSystemMessageGroupViewController
            systemMessageViewController.messageGroupId = messageInSelectedTableCell.messageGroupId
        }
    }
    
    deinit {
        if self.conversationGroups.count > 0 {
            self.conversationGroups.removeAll(keepingCapacity: false)
        }
        if self.notificationGroups.count > 0 {
            self.notificationGroups.removeAll(keepingCapacity: false)
        }
        if self.filterdTableEntries.count > 0 {
            self.filterdTableEntries.removeAll(keepingCapacity: false)
        }
        self.responseData = nil
        self.selectedTableCell = nil
        if #available(iOS 8.0, *) {
            if self.searchController != nil {
                (self.searchController as! UISearchController).searchResultsUpdater = nil
                self.searchController = nil
            }
        }
        
        NotificationCenter.default.removeObserver(self)
    }
    
}
