//
//  VTConversationCollectionViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/31.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTConversationCollectionViewController: JSQMessagesViewController, NSURLConnectionDelegate, NSURLConnectionDataDelegate, UIAlertViewDelegate {
    
    enum HttpRequestIndex {
        case SendMessage
        case GetTappedUserInfo
    }
    
    // start with an invalid value
    var messageGroupId: Int = -1
    // the id of the other user in this conversation, other than the current logged in user
    var secondUserId: String?
    var messages = [JSQMessage]()
    var avatars = [String: JSQMessagesAvatarImage]()
    var usernames = [String: String]()
    
    var receiverUsername: String?
    var currentTappedMessageIndexPath: NSIndexPath?
    var currentSendingMessage: JSQMessage?
    // database page index, used for database pagination
    var numOfTotalMessagesInThisGroup: Int?
    var isLoadingMessageFromLocalDababase: Bool?
    
    var outgoingBubbleImageData: JSQMessagesBubbleImage?
    var incomingBubbleImageData: JSQMessagesBubbleImage?
    
    var indexOfCurrentHttpRequest: HttpRequestIndex?
    var HUD: MBProgressHUD?
    var tappedUserObject: User?
    var responseData: NSMutableData? = NSMutableData()

    override func viewDidLoad() {
        super.viewDidLoad()
        // listen to receivedNewMessageAndSavedInLocalDatabase message and handles it by updating messagesList in tableView in current view controller
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleSavedMessageInDatabase:", name: "receivedNewMessageAndSavedInLocalDatabase", object: nil)
        /**
         *  Create message bubble images objects.
         *  Be sure to create your bubble images one time and reuse them for good performance.
         */
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        self.outgoingBubbleImageData = bubbleFactory.outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
        self.incomingBubbleImageData = bubbleFactory.incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleGreenColor())
 
        // disable and hide the attachment button for now
        // TO-DO: add function to send image, video and audio
        self.inputToolbar!.contentView!.leftBarButtonItem = nil
        
        // set my senderId and senderDisplayName
        let currentUser = Singleton_CurrentUser.sharedInstance
        self.senderId = currentUser.userId
        self.senderDisplayName = currentUser.username
        
        // add current user username and avatar to self.avatars and self.usernames array
        self.usernames[currentUser.userId!] = currentUser.username!
        let currentUserAvatarPath = Toolbox.getAvatarImagePathForModelId(currentUser.userId!)
        var currentUserAvatar: UIImage?
        if currentUserAvatarPath != nil {    // current user avatar image file exists locally
            currentUserAvatar = UIImage(contentsOfFile: currentUserAvatarPath!)
        } else {                        // current user avatar image file not exists, load it from url
            // set the current user avatar to local default avatar,
            // in the mean time, start to download the avatar asynchronously
            currentUserAvatar = UIImage(named: "avatar")
            Toolbox.asyncDownloadAvatarImageForModelId(currentUser.userId!, avatarType: AvatarType.User, completionBlock: {
                succeeded, image in
                if succeeded {
                    let asyncDownloadedAvatar = JSQMessagesAvatarImageFactory.avatarImageWithImage(image, diameter: UInt(kJSQMessagesCollectionViewAvatarSizeDefault))
                    self.avatars[currentUser.userId!] = asyncDownloadedAvatar
                }
                return
            })
        }
        let avatar = JSQMessagesAvatarImageFactory.avatarImageWithImage(currentUserAvatar, diameter: UInt(kJSQMessagesCollectionViewAvatarSizeDefault))
        self.avatars[currentUser.userId!] = avatar
 
        let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        let countTotalMessagesInThisGroup = dbManager.loadDataFromDB(
            "select count(id) from messages where messageGroupId=?",
            parameters: [self.messageGroupId]
        )
        self.numOfTotalMessagesInThisGroup = countTotalMessagesInThisGroup[0][0].integerValue
        self.loadPaginatedMessages()
        if (self.messages.count == 0) {     // No message has been loaded for this conversation from local database, meaning that this is a new conversation and the current logged in user is trying to start a new conversation by sending message to his/her team members
            self.usernames[self.secondUserId!] = self.receiverUsername!
            /**
            *  Create avatar images once.
            *  Be sure to create your avatars one time and reuse them for good performance.
            */
            let receiverAvatarPath = Toolbox.getAvatarImagePathForModelId(self.secondUserId!)
            
            var receiverAvatar: UIImage?
            if (receiverAvatarPath != nil) {    // current user avatar image file exists locally
                receiverAvatar = UIImage(contentsOfFile: receiverAvatarPath!)
            } else {                        // current user avatar image file not exists, load it from url
                // set the user avatar to local default avatar,
                // in the mean time, start to download the avatar asynchronously
                receiverAvatar = UIImage(named: "avatar")
                // download the image asynchronously
                Toolbox.asyncDownloadAvatarImageForModelId(self.secondUserId!, avatarType: AvatarType.User, completionBlock: {
                    succeeded, image in
                    if succeeded {
                        let asyncDownloadedReceivedAvatar = JSQMessagesAvatarImageFactory.avatarImageWithImage(image, diameter: UInt(kJSQMessagesCollectionViewAvatarSizeDefault))
                        self.avatars[self.secondUserId!] = asyncDownloadedReceivedAvatar
                        
                    }
                    return
                })
            }
            let JSQAvatar = JSQMessagesAvatarImageFactory.avatarImageWithImage(receiverAvatar, diameter: UInt(kJSQMessagesCollectionViewAvatarSizeDefault))
            self.avatars[self.secondUserId!] = JSQAvatar
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "对话列表")
    }
    
    func loadPaginatedMessages() {
        self.isLoadingMessageFromLocalDababase = true
        let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        // get messages from database based on messageGroupId
        let paginatedMessagesResults = dbManager.loadDataFromDB(
            "select * from messages where messageGroupId=? order by createdAt desc limit ? offset ?",
            parameters: [self.messageGroupId, Pagination.NumOfMessagesPerPage.rawValue, self.messages.count]
        )
        
        var unreadMessageIds = [String]()
        var tempMessages = [JSQMessage]()
        
        for anyObject in Array(paginatedMessagesResults.reverse()) {   // iterate the paginatedMessagesResults REVERSELY
            let messageDatabaseRecord = anyObject as? NSArray
            if messageDatabaseRecord != nil {
                let messageCreateDate = NSDate(dateTimeString: messageDatabaseRecord![MessageTableIndex.CreatedAt.rawValue] as! String)
                // put all the retrieved messages in tempMessages for display
                let message = JSQMessage(
                    senderId: messageDatabaseRecord![MessageTableIndex.From.rawValue] as! String,
                    senderDisplayName: messageDatabaseRecord![MessageTableIndex.SenderName.rawValue] as! String,
                    date: messageCreateDate,
                    text: messageDatabaseRecord![MessageTableIndex.Content.rawValue] as! String
                )
                
                tempMessages.append(message)
                
                var senderOrReceiverUserId: String?
                if ((messageDatabaseRecord![MessageTableIndex.To.rawValue] as! String) == self.senderId) {  // this message is sent TO me
                    senderOrReceiverUserId = messageDatabaseRecord![MessageTableIndex.From.rawValue] as? String
                    
                    // add the unread message id into unreadMessageIds
                    // since these unread messages are now read
                    // and should be marked as READ in both local database and server database
                    if messageDatabaseRecord![MessageTableIndex.Status.rawValue].integerValue == MessageStatus.Unread.rawValue {
                        unreadMessageIds.append(messageDatabaseRecord![MessageTableIndex.MessageId.rawValue] as! String)
                    }
                } else {    // this message is sent BY me, the current logged user is the sender
                    senderOrReceiverUserId = messageDatabaseRecord![MessageTableIndex.To.rawValue] as? String
                }
                
                if self.usernames[senderOrReceiverUserId!] == nil { // the sender username and avatar haven't been added, add them here
                    // set the second user id
                    self.secondUserId = senderOrReceiverUserId
                    self.usernames[senderOrReceiverUserId!] = messageDatabaseRecord![MessageTableIndex.SenderName.rawValue] as? String
                    /**
                    *  Create avatar images once.
                    *  Be sure to create your avatars one time and reuse them for good performance.
                    */
                    let userAvatarPath = Toolbox.getAvatarImagePathForModelId(senderOrReceiverUserId!)
                    var userAvatar: UIImage?
                    if (userAvatarPath != nil) {    // current user avatar image file exists locally
                        userAvatar = UIImage(contentsOfFile: userAvatarPath!)
                    } else {                        // current user avatar image file not exists, load it from url
                        // set the user avatar to local default avatar,
                        // in the mean time, start to download the avatar asynchronously
                        userAvatar = UIImage(named: "avatar")
                        // download the image asynchronously
                        Toolbox.asyncDownloadAvatarImageForModelId(senderOrReceiverUserId!, avatarType: AvatarType.User, completionBlock: {
                            succeeded, image in
                            if succeeded {
                                let asyncDownloadedAvatar = JSQMessagesAvatarImageFactory.avatarImageWithImage(image, diameter: UInt(kJSQMessagesCollectionViewAvatarSizeDefault))
                                self.avatars[senderOrReceiverUserId!] = asyncDownloadedAvatar
                            }
                            return
                        })
                    }
                    let avatar = JSQMessagesAvatarImageFactory.avatarImageWithImage(userAvatar, diameter: UInt(kJSQMessagesCollectionViewAvatarSizeDefault))
                    self.avatars[senderOrReceiverUserId!] = avatar
                }
            }
        }
        if unreadMessageIds.count > 0 {
            // mark these messages as read in local database and server database
            Message.changeMessagesStatus(unreadMessageIds, status: MessageStatus.Read.rawValue)
            // notify VTGroupsOfMessagesTableViewController that the number of unread messages for specific message group should be updated
            NSNotificationCenter.defaultCenter().postNotificationName(
                "numOfUnreadMessagesInOneMessageGroupChanged",
                object: String(self.messageGroupId)
            )
        }
        
        // add paginagted messages to self.messages
        if self.messages.count == 0 {
            for message in tempMessages {
                self.messages.append(message)
            }
        } else {
            var arrayWithIndexPaths = [NSIndexPath]()
            self.messages = tempMessages + self.messages
            for index in 0...(tempMessages.count - 1) {
                arrayWithIndexPaths.append(NSIndexPath(forRow: index, inSection: 0))
            }
            self.collectionView!.insertItemsAtIndexPaths(arrayWithIndexPaths)
        }
        if self.messages.count >= self.numOfTotalMessagesInThisGroup { // no more earlier messages in this conversation
            self.showLoadEarlierMessagesHeader = false
        } else {
            self.showLoadEarlierMessagesHeader = true
        }
        self.isLoadingMessageFromLocalDababase = false
    }
    
    func handleSavedMessageInDatabase(notification: NSNotification) {
        let message = notification.object as! Message
        if self.senderId == message.to && self.messageGroupId == message.messageGroupId {
            // a. This new saved message in database is sent TO me, NOT sent BY me, i.e. I'm the receiver AND
            // b. This new saved message belongs to this group
            
            // play message receive sound
            JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
            
            // mark these messages as read in local database and server database
            Message.changeMessagesStatus([message.messageId], status: MessageStatus.Read.rawValue)
            // notify VTMessageGroupsTableViewController that the number of unread messages for this message group should be updated
            NSNotificationCenter.defaultCenter().postNotificationName(
                "numOfUnreadMessagesInOneMessageGroupChanged",
                object: String(self.messageGroupId)
            )
            
            self.messages.append(JSQMessage(
                senderId: message.from,
                senderDisplayName: message.senderName,
                date: NSDate(dateTimeString: message.createdAt),
                text: message.content
                )
            )
            self.finishReceivingMessageAnimated(true)
            self.numOfTotalMessagesInThisGroup = self.numOfTotalMessagesInThisGroup! + 1
        }
    }
    
    /**
    Sending a message.
    1. Play sound (optional)
    2. Add new id<JSQMessageData> object to your data source
    3. Call `finishSendingMessage`
    
    - parameter button:            the button pressed
    - parameter text:              message text
    - parameter senderId:          the sender id
    - parameter senderDisplayName: the sender name that should be displayed
    - parameter date:              dateTime sending the message
    */
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        self.currentSendingMessage = JSQMessage(
            senderId: senderId,
            senderDisplayName: senderDisplayName,
            date: date, text: text
        )
        self.currentSendingMessage?.sendStatus = MessageSendStatus.Sending.rawValue
        
        // add sent message to collectionView
        self.messages.append(self.currentSendingMessage!)
        self.finishSendingMessageAnimated(true)
        
        let connection = Toolbox.asyncHttpPostToURL(URLSendMessage, parameters: "recipientId=\(self.secondUserId!)&messageContent=\(text)&type=\(MessageType.OneToOneMessage.rawValue)", delegate: self)
        if (connection == nil) {
            // Inform the user that the connection failed.
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            self.indexOfCurrentHttpRequest = .SendMessage
        }
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        self.responseData?.appendData(data)
    }
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        if self.indexOfCurrentHttpRequest == .SendMessage {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "发送失败")
            self.currentSendingMessage?.sendStatus = MessageSendStatus.Failed.rawValue
            self.finishSendingMessageAnimated(true)
        } else if self.indexOfCurrentHttpRequest == .GetTappedUserInfo {
            self.HUD?.hide(true)
            self.HUD = nil
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "获取用户信息失败")
        }
        
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        if self.indexOfCurrentHttpRequest == .SendMessage {  // server response after sending message
            // save the sent message in local database
            let jsonDictionary = (try? NSJSONSerialization.JSONObjectWithData(self.responseData!, options: .MutableLeaves)) as? [NSObject: AnyObject]
            let sentMessageDictionary = [
                "from": self.senderId,
                "to": self.secondUserId!,
                "type": "\(MessageType.OneToOneMessage.rawValue)",
                "content": self.currentSendingMessage!.text,
                "status": "\(MessageStatus.Read.rawValue)",
                "senderName": self.senderDisplayName!,
                "receiverName": self.usernames[self.secondUserId!]!,
                "createdAt": jsonDictionary?["createdAt"] as! String,
                "id": jsonDictionary?["newMessageId"] as! String
            ]
            let sentMessage = Message(messageInfo: sentMessageDictionary)
            Message.saveMessageInDatabase(sentMessage)
            self.numOfTotalMessagesInThisGroup = self.numOfTotalMessagesInThisGroup! + 1
            // play system sound of sending message
            JSQSystemSoundPlayer.jsq_playMessageSentSound()
            self.currentSendingMessage = nil
        } else if self.indexOfCurrentHttpRequest == .GetTappedUserInfo {
            self.HUD?.hide(true)
            self.HUD = nil
            let userInfoJSON = (try? NSJSONSerialization.JSONObjectWithData(self.responseData!, options: .MutableLeaves)) as? [NSObject : AnyObject]
            if userInfoJSON != nil {
                self.tappedUserObject = User(data: userInfoJSON!)
                self.performSegueWithIdentifier("userProfileSegue", sender: self)
            } else {
                Toolbox.showCustomAlertViewWithImage("unhappy", title: "没有找到用户")
            }
        }
        
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    override func didPressAccessoryButton(sender: UIButton!) {
        // VT-TO-DO: will add function to send image, video and audio as message
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return self.messages[indexPath.item]
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let messageInCell = self.messages[indexPath.item]
        
        if messageInCell.senderId == self.senderId {
            return self.outgoingBubbleImageData
        }
        return self.incomingBubbleImageData
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        let messageInCell = self.messages[indexPath.item]
        
        return self.avatars[messageInCell.senderId]
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        /**
         *  Show a timestamp for every 3rd message
         */
        if indexPath.item % 3 == 0 {
            let messageInCell = self.messages[indexPath.item]

            return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(messageInCell.date)
        }
        return nil
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        
        let messageInCell = self.messages[indexPath.item]
        /**
         *  iOS7-style sender name labels
         */
        if messageInCell.senderId == self.senderId {
            return nil
        }
        
        if indexPath.item - 1 > 0 {
            let previousMessage = self.messages[indexPath.item - 1]
            if previousMessage.senderId == messageInCell.senderId {
                return nil
            }
        }
        
        /**
         *  Don't specify attributes to use the defaults.
         */
        return NSAttributedString(string: messageInCell.senderDisplayName)
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        let messageInCell = self.messages[indexPath.item]

        if messageInCell.sendStatus == MessageSendStatus.Failed.rawValue {
            return 20.0
        }
        return 0
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let messageInCell = self.messages[indexPath.item]

        if messageInCell.sendStatus == MessageSendStatus.Failed.rawValue {
            return NSAttributedString(string: "发送失败")
        }
        return nil
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        let messageInCell = self.messages[indexPath.item]
        if !messageInCell.isMediaMessage {
            if messageInCell.senderId == self.senderId {
                cell.textView!.textColor = UIColor.blackColor()
            } else {
                cell.textView!.textColor = UIColor.whiteColor()
            }
            cell.cellBottomLabel!.textColor = ColorOrange
            
            cell.textView!.linkTextAttributes = [NSForegroundColorAttributeName: cell.textView!.textColor!, NSUnderlineStyleAttributeName: 1]
        }
        return cell
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        /* Show a timestamp for every 3rd message */
        if indexPath.item % 3 == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        return 0
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        let messageInCell = self.messages[indexPath.item]
        if messageInCell.senderId == self.senderId {
            return 0
        }
        if indexPath.item - 1 > 0 {
            let previousMessage = self.messages[indexPath.item - 1]
            if previousMessage.senderId == messageInCell.senderId {
                return 0
            }
        }
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, atIndexPath indexPath: NSIndexPath!) {
        let messageInCell = self.messages[indexPath.item]
        if messageInCell.senderId != Singleton_CurrentUser.sharedInstance.userId {  // if user tapped the other user in this conversation list, other than the  current user, show the tapped user profile view controller
            if self.tappedUserObject != nil {
                self.performSegueWithIdentifier("userProfileSegue", sender: self)
            } else {
                let connection = Toolbox.asyncHttpGetFromURL(URLGetUserInfo + "?id=" + messageInCell.senderId, delegate: self)
                if connection == nil {
                    Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
                } else {
                    self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: nil)
                    self.indexOfCurrentHttpRequest = .GetTappedUserInfo
                }
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "userProfileSegue" {
            let destinationViewController = segue.destinationViewController as! VTUserProfileTableViewController
            destinationViewController.userObject = self.tappedUserObject
        }
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAtIndexPath indexPath: NSIndexPath!) {
        let messageInCell = self.messages[indexPath.item]
        if messageInCell.sendStatus == MessageSendStatus.Failed.rawValue {  // message bubble tapped, if this message sent failed, should resned it
            let alertView = UIAlertView(title: "", message: "是否重新发送消息？", delegate: self, cancelButtonTitle: "否", otherButtonTitles: "是")
            alertView.show()
            
            self.currentSendingMessage = messageInCell
            self.currentTappedMessageIndexPath = indexPath
        }
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        switch buttonIndex {
        case 0: // No pressed, user does not want to resend message that previously failed delivering
            self.currentSendingMessage = nil
            break
        case 1: // Yes pressed, user want to resend
            self.currentSendingMessage?.sendStatus = MessageSendStatus.Sending.rawValue
            // change the sending message in self.messages
            self.messages[self.currentTappedMessageIndexPath!.item] = self.currentSendingMessage!
            
            self.finishSendingMessageAnimated(true)
            
            let connection = Toolbox.asyncHttpPostToURL(URLSendMessage, parameters: "recipientId=\(self.secondUserId!)&messageContent=\(self.currentSendingMessage!.text)&type=\(MessageType.OneToOneMessage.rawValue)", delegate: self)
            if connection == nil {
                Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
            }
            self.indexOfCurrentHttpRequest = .SendMessage
            self.currentTappedMessageIndexPath = nil
            break
        default:
            break
        }
    }
    
    /**
     Event when load earlier messages button is tapped
     
     - parameter collectionView: the collection view
     - parameter headerView:     the header view that contains the load earlier messages button
     - parameter sender:         the button itself
     */
    override func collectionView(collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        self.loadPaginatedMessages()
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapCellAtIndexPath indexPath: NSIndexPath!, touchLocation: CGPoint) {
    }
    
    deinit {
        if self.messages.count > 0 {
            self.messages.removeAll(keepCapacity: false)
        }
        self.responseData = nil
    }
    
}
