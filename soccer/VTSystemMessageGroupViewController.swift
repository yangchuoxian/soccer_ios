//
//  VTSystemMessageGroupViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/15.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTSystemMessageGroupViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!

    var messageGroupId = -1
    var systemMessages = [Dictionary<String, AnyObject>]()
    var numberOfTotalSystemMessages = 0
    var isLoadingMessageFromLocalDatabase = false
    var topActivityIndicator: UIActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // listen to the system notificatoin that says new message received
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleSavedMessageInDatabase:", name: "receivedNewMessageAndSavedInLocalDatabase", object: nil)
        
        self.scrollView.userInteractionEnabled = true
        self.scrollView.exclusiveTouch = true
        self.scrollView.canCancelContentTouches = true
        self.scrollView.delaysContentTouches = true
        self.scrollView.delegate = self

        self.topActivityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        self.topActivityIndicator?.frame = CGRectMake(ScreenSize.width / 2 - 10, 0, 20, 20)
        self.topActivityIndicator?.hidesWhenStopped = true
        self.scrollView.addSubview(self.topActivityIndicator!)
        
        // start activityIndicator animation indicating fetcing database and rendering UI in progress
        self.topActivityIndicator!.hidden = false
        self.topActivityIndicator!.startAnimating()
        
        let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        let countTotalMessagesInThisGroup = dbManager.loadDataFromDB(
            "select count(id) from messages where messageGroupId=? and recipientId=?", parameters: [self.messageGroupId, Singleton_CurrentUser.sharedInstance.userId!])
        self.numberOfTotalSystemMessages = countTotalMessagesInThisGroup[0][0].integerValue
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "系统消息")
    }
    
    func handleSavedMessageInDatabase(notification: NSNotification) {
        let newSystemMessage = notification.object as! Message
        if self.messageGroupId == newSystemMessage.messageGroupId {
            // play message receive sound
            JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
            self.addSystemMessageSequentially(newSystemMessage)
            // recalculate and setup scroll view height
            self.setScrollViewHeight()
            if self.scrollView.contentSize.height > self.view.frame.size.height {
                self.makeScrollViewScrollToBottom()
            }
            self.numberOfTotalSystemMessages = self.numberOfTotalSystemMessages + 1
            
            // mark these messages as read in local database and server database
            Message.changeMessagesStatus([newSystemMessage.messageId], status: MessageStatus.Read.rawValue)
            // notify VTMessageGroupsTableViewController that the number of unread messages for this message group should be updated
            NSNotificationCenter.defaultCenter().postNotificationName(
                "numOfUnreadMessagesInOneMessageGroupChanged",
                object: String(self.messageGroupId)
            )
        }
    }
    
    func addSystemMessageSequentially(message: Message) {
        let currentSystemMessageIndex = self.systemMessages.count
        let systemMessageView = self.addMessageView(message, index: currentSystemMessageIndex)
        // add the message and its view height together as a dictionary object into requests
        let systemMessageInfo = [
            "message": message,
            "systemMessageView": systemMessageView
        ]
        self.systemMessages.append(systemMessageInfo)
    }
    
    func addMessageView(message: Message, index: Int) -> VTSystemMessageView {
        var topOffset = ActivityIndicatorViewHeight
        // calculate the top offset. i.e. the vertical position where this request view should be added
        var existingSystemMessageView: VTSystemMessageView?
        if index > 0 {
            for i in 0...(index - 1) {
                existingSystemMessageView = self.systemMessages[i]["systemMessageView"] as? VTSystemMessageView
                topOffset = topOffset + existingSystemMessageView!.viewHeight! + RequestViewVerticalMargin
            }
        }
        let systemMessageView = VTSystemMessageView(message: message, topOffset: topOffset)
        self.scrollView.addSubview(systemMessageView)
        return systemMessageView
    }
    
    func loadPaginatedMessages() {
        self.isLoadingMessageFromLocalDatabase = true
        let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        // get messages from database based on message group index
        let paginatedMessageResults = dbManager.loadDataFromDB(
            "select * from messages where messageGroupId=? and recipientId=? order by createdAt desc limit ? offset ?",
            parameters: [
                self.messageGroupId,
                Singleton_CurrentUser.sharedInstance.userId!,
                Pagination.NumOfMessagesPerPage.rawValue,
                self.systemMessages.count
            ]
        )
        var unreadMessageIds = [String]()
        var tempSystemMessages = [Message]()
        for messageDatabaseRecord in Array(paginatedMessageResults.reverse()) {    // iterate the paginatedMessagesResults REVERSELY
            let currentMessage = Message.formatDatabaseRecordToMessageFormat(messageDatabaseRecord as! [String])
            tempSystemMessages.append(currentMessage)
            
            // add the unread message id into unreadMessageIds
            // since these unread messages are now read
            // and should be marked as READ in both local database and server database
            if currentMessage.status == MessageStatus.Unread.rawValue {
                unreadMessageIds.append(currentMessage.messageId)
            }
        }
        if unreadMessageIds.count > 0 {
            // mark these messages as read in local database and server database
            Message.changeMessagesStatus(unreadMessageIds, status: MessageStatus.Read.rawValue)
            // notify VTGroupsOfMessagesTableViewController taht the number of unread messages for specific message group should be updated
            NSNotificationCenter.defaultCenter().postNotificationName(
                "numOfUnreadMessagesInOneMessageGroupChanged",
                object: String(self.messageGroupId)
            )
        }
        
        // add paginated messages to self.systemMessages
        if self.systemMessages.count == 0 { // first page results from database
            for tempSystemMessage in tempSystemMessages {
                self.addSystemMessageSequentially(tempSystemMessage)
            }
            self.setScrollViewHeight()
            if self.scrollView.contentSize.height > self.view.frame.size.height {
                self.makeScrollViewScrollToBottom()
            }
        } else {
            // not first page results from database,
            // i.e. there are already some requests and requestViews,
            // inserting the new fetched message results
            // before the existing ones in REVERSE order
            var totalOffset = -NavigationbarHeight - ToolbarHeight
            for tempSystemMessage in Array(tempSystemMessages.reverse()) {
                // show the system message
                let systemMessageView = self.addMessageView(tempSystemMessage, index: 0)
                let systemMessageInfo = [
                    "message": tempSystemMessage,
                    "systemMessageView": systemMessageView
                ]
                self.systemMessages.insert(systemMessageInfo, atIndex: 0)
                totalOffset = totalOffset + systemMessageView.viewHeight! + RequestViewVerticalMargin
                
                // move down the existing request views with the calculated offset
                var existingSystemMessageView: VTSystemMessageView?
                for i in 1...(self.systemMessages.count - 1) {
                    existingSystemMessageView = self.systemMessages[i]["systemMessageView"] as? VTSystemMessageView
                    existingSystemMessageView!.frame = CGRectMake(
                        existingSystemMessageView!.frame.origin.x,
                        existingSystemMessageView!.frame.origin.y + systemMessageView.viewHeight! + RequestViewVerticalMargin,
                        existingSystemMessageView!.frame.size.width,
                        existingSystemMessageView!.frame.size.height
                    )
                }
            }
            self.setScrollViewHeight()
            if self.scrollView.contentSize.height > self.view.frame.size.height {
                self.scrollView.setContentOffset(CGPoint(x: 0, y: totalOffset), animated: false)
            }
        }
        self.isLoadingMessageFromLocalDatabase = false
    }
    
    /**
     * If new request view has been added into the scrollView, its height needs to be recalculated and setup
     */
    func setScrollViewHeight() {
        // calculate the total height of request views and its top margins
        var totalHeight = RequestViewVerticalMargin + ActivityIndicatorViewHeight
        var existingSystemMessageView: VTSystemMessageView?
        for i in 0...(self.systemMessages.count - 1) {
            existingSystemMessageView = self.systemMessages[i]["systemMessageView"] as? VTSystemMessageView
            totalHeight = totalHeight + existingSystemMessageView!.viewHeight! + RequestViewVerticalMargin
        }
        if self.scrollView.contentSize.height < totalHeight {
            self.scrollView.contentSize = CGSizeMake(ScreenSize.width, totalHeight)
        }
    }
    
    func makeScrollViewScrollToBottom() {
        let bottomOffset = CGPoint(x: 0, y: self.scrollView.contentSize.height - self.scrollView.bounds.size.height)
        self.scrollView.setContentOffset(bottomOffset, animated: true)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView.contentOffset.y == (-NavigationbarHeight - ToolbarHeight) && !self.isLoadingMessageFromLocalDatabase {
            // scrollView has scrolled to top AND not currently FETCHING messages from database/render UI
            if self.systemMessages.count < self.numberOfTotalSystemMessages {  // still more earlier messages
                self.loadPaginatedMessages()
            } else {
                self.topActivityIndicator?.stopAnimating()
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        if self.scrollView != nil {
            self.scrollView.delegate = nil
        }
        self.systemMessages.removeAll(keepCapacity: false)
        self.topActivityIndicator = nil
    }

}
