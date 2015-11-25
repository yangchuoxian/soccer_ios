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
    var selectedTableCell: NSIndexPath?
    var shouldShowNetworkUnavailableHintView = false
    var responseData: NSMutableData? = NSMutableData()
    let tableCellIdentifier = "messagesListTableCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = true
        
        // add the UIRefreshControl to tableView
        self.refreshControl = Appearance.setupRefreshControl()
        self.refreshControl!.addTarget(self, action: "refresh", forControlEvents: .ValueChanged)
        self.tableView.addSubview(self.refreshControl!)
        
        // This will remove extra separators from tableview
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        self.tableView.rowHeight = CustomTableRowHeight
        
        self.tableView.separatorColor = UIColor.clearColor()
        
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
            self.searchController!.searchBar.layer.borderColor = ColorBackgroundGray.CGColor
            self.searchController!.searchBar.layer.borderWidth = 1
        }
        
        // listen to receivedNewMessageAndSavedInLocalDatabase notification and handles it by updating messagesList in tableView in current view controller
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleReceivedMessageOrSentMessage:", name: "receivedNewMessageAndSavedInLocalDatabase",  object: nil)
        // listen to sentMessageAndSavedInLocalDatabase notification and handles it by updating messagesList in tableView in current view controller
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleReceivedMessageOrSentMessage:", name: "sentMessageAndSavedInLocalDatabase", object: nil)
        // listen to numOfUnreadMessagesInOneMessageGroupChanged notification and update the number of unread messages of that particular message group(conversation)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateNumOfUnreadMessagesForSpecificMessageGroup:", name: "numOfUnreadMessagesInOneMessageGroupChanged", object:nil)
        // listen to reachable/unreachablie message sent by Reachability
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reachabilityDidChange:", name: kReachabilityChangedNotification, object: nil)
        
        // load message list from local database
        self.getMessageGroupsDataFromLocalDatabase()
        
        // programmatically refresh to see if there are any new unread messages while VTMessageGroupsTableViewController is not showing or maybe the app is turned off or been run in background
        self.refresh()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "消息列表")
        if #available(iOS 8.0, *) {
            if self.searchController != nil {
                (self.searchController as! UISearchController).active = false
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
    func getNotificationGroupInfoForGroupId(messageGroupId: Int) -> Message? {
        let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        /**
        * GET LATEST  MESSAGE IF ANY
        */
        let messagesInGroup = dbManager.loadDataFromDB(
            "select * from messages where messageGroupId=? and recipientId=? group by messageGroupId",
            parameters: [messageGroupId, Singleton_CurrentUser.sharedInstance.userId!]
        )
        if messagesInGroup.count > 0 {   // messages exist
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
        let latestRequest = self.getNotificationGroupInfoForGroupId(MessageGroupIndex.Request.rawValue)
        if latestRequest != nil {
            self.notificationGroups.append(latestRequest!)
        }
        // Get latest system notification if any
        let latestSystemNotification = self.getNotificationGroupInfoForGroupId(MessageGroupIndex.SystemMessage.rawValue)
        if latestSystemNotification != nil {
            self.notificationGroups.append(latestSystemNotification!)
        }
        
        // GET CONVERSATION MESSAGE GROUPS
        let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        let conversations = dbManager.loadDataFromDB(
            "select * from messages where messageGroupId not in (?, ?) group by messageGroupId order by createdAt desc",
            parameters: [
                MessageGroupIndex.Request.rawValue,
                MessageGroupIndex.SystemMessage.rawValue,
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
    func reachabilityDidChange(notification: NSNotification) {
        let reachability = notification.object as! Reachability
        if !reachability.isReachable() {
            self.tableView.beginUpdates()
            self.shouldShowNetworkUnavailableHintView = true
            self.tableView.endUpdates()
        } else {
            self.tableView.beginUpdates()
            for subview in self.tableView.subviews {
                if subview.tag == TagValue.TableHeaderHint.rawValue {    // the subview is the network unavailable hint view
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
    
    func updateNumOfUnreadMessagesForSpecificMessageGroup(notification: NSNotification) {
        let messageGroupId = notification.object!.integerValue
        var listToBeUpdated: [Message]
        var sectionIndex: Int
        if messageGroupId == MessageGroupIndex.Request.rawValue || messageGroupId == MessageGroupIndex.SystemMessage.rawValue {
            listToBeUpdated = self.notificationGroups
            sectionIndex = MessageGroupTableSectionIndex.Notification.rawValue
        } else {
            listToBeUpdated = self.conversationGroups
            sectionIndex = MessageGroupTableSectionIndex.Conversation.rawValue
        }
        
        // find the message group in self.messagesList based on the passed in paramter messageGroupId
        let theMessageGroup = listToBeUpdated.filter{$0.messageGroupId == messageGroupId}
        
        if theMessageGroup.count > 0 {  // the corresponding message group FOUND in self.messagesList
            let indexOfMessageGroupToBeUpdated = listToBeUpdated.indexOf(theMessageGroup[0])
            let latestMessageInThisGroup = listToBeUpdated[indexOfMessageGroupToBeUpdated!]
            latestMessageInThisGroup.numOfUnreadMessagesInTheGroup = Message.getNumberOfUnreadMessagesForMessageGroup(messageGroupId)
            
            listToBeUpdated[indexOfMessageGroupToBeUpdated!] = latestMessageInThisGroup    // update related entry in self.notificationGroups or self.conversationGroups to update data showing in tableView
            // update table view data, just that specific row, NOT the whole table
            let indexPath = NSIndexPath(forRow: indexOfMessageGroupToBeUpdated!, inSection: sectionIndex)
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
        }
    }
   
    func handleReceivedMessageOrSentMessage(notification: NSNotification) {
        let message = notification.object as! Message
        self.showNewMessageInTableView(message)
    }
    
    /**
    After receiving new messages, one should invoke this function to update table view to show new messages. messages can be received:
    a. via socket or
    b. after user manually pull to refresh this view
    
    - parameter message: the new message
    */
    func showNewMessageInTableView(message: Message) {
        var listToBeUpdate: [Message]
        var sectionIndex: Int
        let messageGroupId = message.messageGroupId
        if messageGroupId == MessageGroupIndex.Request.rawValue || messageGroupId == MessageGroupIndex.SystemMessage.rawValue {
            listToBeUpdate = self.notificationGroups
            sectionIndex = MessageGroupTableSectionIndex.Notification.rawValue
        } else {
            listToBeUpdate = self.conversationGroups
            sectionIndex = MessageGroupTableSectionIndex.Conversation.rawValue
        }
        let messageGroupToBeUpdated = listToBeUpdate.filter{
            $0.messageGroupId == message.messageGroupId
        }
        if messageGroupToBeUpdated.count > 0 {  // the received message belongs to a message group existed locally(in app database)
            let indexOfMessageGroupToBeUpdated = listToBeUpdate.indexOf(messageGroupToBeUpdated[0])
            // update related entry in self.notificationGroups or self.conversationGroups to update data showing in tableView
            if sectionIndex == MessageGroupTableSectionIndex.Notification.rawValue {
                self.notificationGroups[indexOfMessageGroupToBeUpdated!] = message
            } else {
                self.conversationGroups[indexOfMessageGroupToBeUpdated!] = message
            }
            // update table view data, just that specific row, NOT the whole table
            let indexPath = NSIndexPath(forRow: indexOfMessageGroupToBeUpdated!, inSection: sectionIndex)
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
        } else {                    // the received message started a new message group
            // insert this message (group) in front of the first message group as a new message group to self.conversationGroups or self.notificationGroups to show in tableView
            if sectionIndex == MessageGroupTableSectionIndex.Notification.rawValue {
                self.notificationGroups.insert(message, atIndex: 0)
            } else {
                self.conversationGroups.insert(message, atIndex: 0)
            }
            // insert a new row as the first row into tableView with animation
            let indexPath = NSIndexPath(forRow: 0, inSection: sectionIndex)
            self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Top)
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == MessageGroupTableSectionIndex.Notification.rawValue {
            if self.shouldShowNetworkUnavailableHintView {
                return TableSectionHeaderHeight
            } else {
                return 0.0
            }
        }
        return 0.0
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == MessageGroupTableSectionIndex.Notification.rawValue {
            if self.notificationGroups.count == 0 {
                return 0.0
            } else {
                return TableSectionFooterHeight
            }
        }
        return 0.0
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == MessageGroupTableSectionIndex.Notification.rawValue {
            if self.shouldShowNetworkUnavailableHintView {
                let headerView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: 0))
                headerView.backgroundColor = ColorOrange
                
                let crossIcon = UIImageView(image: UIImage(named: "cross"))
                crossIcon.frame = CGRect(x: 10, y: 11, width: 10, height: 10)
                headerView.addSubview(crossIcon)
                
                let hintTextLabel = UILabel(frame: CGRect(x: 30, y: 0, width: ScreenSize.width - 35, height: TableSectionHeaderHeight))
                hintTextLabel.textColor = UIColor.whiteColor()
                hintTextLabel.text = "网络无法连接"
                hintTextLabel.font = UIFont.systemFontOfSize(14.0)
                hintTextLabel.textAlignment = .Center
                
                headerView.addSubview(hintTextLabel)
                headerView.tag = TagValue.TableHeaderHint.rawValue
                
                return headerView
            } else {
                return nil
            }
        }
        return nil
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == MessageGroupTableSectionIndex.Notification.rawValue {
            let footerView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: 0))
            footerView.backgroundColor = UIColor.clearColor()
            
            return footerView
        }
        return nil
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Display a message and an image when the table is empty
        let emptyTableBackgroundView = UIView(frame: CGRectMake(0, self.tableView.frame.origin.y, self.tableView.frame.size.width, self.tableView.frame.size.height))
        emptyTableBackgroundView.tag = TagValue.EmptyTableBackgroundView.rawValue
        let image = UIImageView(image: UIImage(named: "empty"))
        image.frame = CGRectMake(
            ScreenSize.width / 2 - 55,
            ScreenSize.height / 2 - 110,
            110,
            110
        )
        
        let messageLabel = UILabel(frame: CGRectMake(ScreenSize.width / 2 - 55, ScreenSize.height / 2, self.tableView.bounds.size.width, 50))
        
        messageLabel.text = "暂时没有新消息"
        messageLabel.textColor = EmptyImageColor
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .Center
        messageLabel.sizeToFit()
        
        emptyTableBackgroundView.addSubview(image)
        emptyTableBackgroundView.addSubview(messageLabel)
        if self.conversationGroups.count > 0 || self.notificationGroups.count > 0 {
            self.tableView.backgroundView = nil
            for subView in self.tableView.subviews {
                if subView.tag == TagValue.EmptyTableBackgroundView.rawValue {    // the subview is the emptyTableBackgroundView
                    subView.removeFromSuperview()
                }
            }
        } else {
            self.tableView.addSubview(emptyTableBackgroundView)
            self.tableView.sendSubviewToBack(emptyTableBackgroundView)
        }
        
        // Return the number of sections
        if #available(iOS 8.0, *) {
            if self.searchController != nil {
                if (self.searchController as! UISearchController).active {  // search controller showing
                    return 1
                }
            }
        }
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if #available(iOS 8.0, *) {
            if self.searchController != nil {
                if (self.searchController as! UISearchController).active {  // search controller showing
                    return self.filterdTableEntries.count
                }
            }
        }
        if section == MessageGroupTableSectionIndex.Notification.rawValue { // notification list section
            return self.notificationGroups.count
        } else {            // conversation list section
            return self.conversationGroups.count
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = self.tableView.dequeueReusableCellWithIdentifier(self.tableCellIdentifier) as? MGSwipeTableCell
        if cell == nil {
            cell = MGSwipeTableCell(style: .Default, reuseIdentifier: self.tableCellIdentifier)
        }
        var messageInCurrentRow: Message
        if indexPath.section == MessageGroupTableSectionIndex.Notification.rawValue {
            messageInCurrentRow = self.notificationGroups[indexPath.row]
        } else {
            messageInCurrentRow = self.conversationGroups[indexPath.row]
        }
        if #available(iOS 8.0, *) {
            if self.searchController != nil {
                if (self.searchController as! UISearchController).active {
                    messageInCurrentRow = self.filterdTableEntries[indexPath.row]
                }
            }
        }
        // displaying message group for conversations, i.e. messages with one-to-one message type
        if messageInCurrentRow.messageGroupId != MessageGroupIndex.Request.rawValue &&
            messageInCurrentRow.messageGroupId != MessageGroupIndex.SystemMessage.rawValue {
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
            Toolbox.loadAvatarImage(userIdToGetAvatarAndUsername, toImageView:avatar, avatarType: AvatarType.User)
            
            // set up message content
            let label_messageContent = cell?.contentView.viewWithTag(3) as! UILabel
            label_messageContent.text = messageInCurrentRow.content
        } else {
            // set up message group icon
            let messageGroupIcon = cell!.contentView.viewWithTag(1) as! UIImageView
            // set up the message group name
            let label_messageGroupName = cell!.contentView.viewWithTag(2) as! UILabel
            
            switch messageInCurrentRow.messageGroupId {
            case MessageGroupIndex.Request.rawValue:
                messageGroupIcon.image = UIImage(named: "person_add")
                label_messageGroupName.text = "请求通知"
                break
            case MessageGroupIndex.SystemMessage.rawValue:
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
            label_numOfUnreads.hidden = true
        } else {
            label_numOfUnreads.hidden = false
            if messageInCurrentRow.numOfUnreadMessagesInTheGroup < 10 {
                label_numOfUnreads.text = String(messageInCurrentRow.numOfUnreadMessagesInTheGroup)
            } else {
                label_numOfUnreads.text = "..."
            }
        }
        cell!.delegate = self
        
        // configure left buttons
        if messageInCurrentRow.messageGroupId != MessageGroupIndex.Request.rawValue {
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
        cell!.rightButtons = [MGSwipeButton(title: "删除", backgroundColor: UIColor.redColor())]
        
        if indexPath.row != 0 {   // if the cell is not the first row of its section, add a separatorLine
            let separatorLineView = UIView(frame: CGRectMake(15, 0, ScreenSize.width, 1))
            separatorLineView.backgroundColor = ColorBackgroundGray
            
            cell!.contentView.addSubview(separatorLineView)
        }
        
        return cell!
    }
    
    @available(iOS 8.0, *)
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        self.filterdTableEntries.removeAll(keepCapacity: false)
        self.filterdTableEntries = self.conversationGroups.filter{
            $0.senderName.rangeOfString(self.searchController!.searchBar.text!) != nil
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
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        self.selectedTableCell = indexPath
        if indexPath.section == MessageGroupTableSectionIndex.Conversation.rawValue {
            self.performSegueWithIdentifier("messagesSegue", sender: self)
        } else {
            let messageInCurrentRow = self.notificationGroups[indexPath.row]
            if messageInCurrentRow.messageGroupId == MessageGroupIndex.SystemMessage.rawValue {
                self.performSegueWithIdentifier("systemMessagesSegue", sender: self)
            } else if messageInCurrentRow.messageGroupId == MessageGroupIndex.Request.rawValue {
                self.performSegueWithIdentifier("requestsSegue", sender: self)
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
    func swipeTableCell(cell: MGSwipeTableCell!, tappedButtonAtIndex index: Int, direction: MGSwipeDirection, fromExpansion: Bool) -> Bool {
        let indexPath = self.tableView.indexPathForCell(cell)
        let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        
        var listToBeUpdate: [Message]
        if indexPath!.section == MessageGroupTableSectionIndex.Notification.rawValue {
            listToBeUpdate = self.notificationGroups
        } else {
            listToBeUpdate = self.conversationGroups
        }
        let messageToBeChanged = listToBeUpdate[indexPath!.row]
        
        if direction == .LeftToRight {   // swipe left to right, left button: mark as read tapped
            // get messageId of all unread messages in this message group
            let messageIdsResult = dbManager.loadDataFromDB(
                "select messageId from messages where messageGroupId=? and status=?",
                parameters: [
                    messageToBeChanged.messageGroupId,
                    MessageStatus.Unread.rawValue
                ]
            )
            var messageIds = [String]()
            for anyObject in messageIdsResult {
                let messageId = anyObject as? NSArray
                if messageId != nil {
                    messageIds.append(messageId![0] as! String)
                }
            }
            Message.changeMessagesStatus(messageIds, status: MessageStatus.Read.rawValue)
            messageToBeChanged.numOfUnreadMessagesInTheGroup = 0
            // update table view data, just that specific row, NOT the whole table
            self.tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: .None)
        } else {                // swipe right to left, right button: delete tapped
            // delete all messages in the same message group in database
            dbManager.modifyDataInDB(
                "delete from messages where messageGroupId=?",
                parameters: [messageToBeChanged.messageGroupId]
            )
            if dbManager.affectedRows != 0 {  // database execution succeeded
                // notify VTMainTabBarViewController that some unread messages have been deleted and total number of unread messages should be updated
                NSNotificationCenter.defaultCenter().postNotificationName(
                    "totalNumOfUnreadMessagesChanged",
                    object: [
                        "action": "-",
                        "quantity": String(messageToBeChanged.numOfUnreadMessagesInTheGroup)
                    ]
                )
            }
            // remove the message group in self.conversationGroups or self.notificationGroups and reload tableView
            if indexPath!.section == MessageGroupTableSectionIndex.Notification.rawValue {
                self.notificationGroups.removeAtIndex(indexPath!.row)
            } else {
                self.conversationGroups.removeAtIndex(indexPath!.row)
            }
            self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Top)
        }
        return true
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        self.responseData?.appendData(data)
    }
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        self.refreshControl?.endRefreshing()
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络超时")
        // clear responseData
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        if self.refreshControl != nil {
            self.refreshControl?.endRefreshing()
        }
        // http response for getting unread messages from server
        let receivedUnreadMessages = (try? NSJSONSerialization.JSONObjectWithData(self.responseData!, options: .MutableLeaves)) as? [AnyObject]
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        var messageInSelectedTableCell: Message
        if segue.identifier == "messagesSegue" {
            messageInSelectedTableCell = self.conversationGroups[self.selectedTableCell!.row]
            
            let conversationViewController = segue.destinationViewController as! VTConversationCollectionViewController
            conversationViewController.messageGroupId = messageInSelectedTableCell.messageGroupId
        } else if segue.identifier == "requestsSegue" {
            messageInSelectedTableCell = self.notificationGroups[self.selectedTableCell!.row]
            
            let requestViewController = segue.destinationViewController as! VTRequestGroupViewController
            requestViewController.messageGroupId = messageInSelectedTableCell.messageGroupId
        } else if segue.identifier == "systemMessagesSegue" {
            messageInSelectedTableCell = self.notificationGroups[self.selectedTableCell!.row]
            
            let systemMessageViewController = segue.destinationViewController as! VTSystemMessageGroupViewController
            systemMessageViewController.messageGroupId = messageInSelectedTableCell.messageGroupId
        }
    }
    
    deinit {
        if self.conversationGroups.count > 0 {
            self.conversationGroups.removeAll(keepCapacity: false)
        }
        if self.notificationGroups.count > 0 {
            self.notificationGroups.removeAll(keepCapacity: false)
        }
        if self.filterdTableEntries.count > 0 {
            self.filterdTableEntries.removeAll(keepCapacity: false)
        }
        self.responseData = nil
        self.selectedTableCell = nil
        if #available(iOS 8.0, *) {
            if self.searchController != nil {
                (self.searchController as! UISearchController).searchResultsUpdater = nil
                self.searchController = nil
            }
        }
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
}
