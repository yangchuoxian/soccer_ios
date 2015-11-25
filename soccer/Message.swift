//
//  Message.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/1.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class Message: NSObject {
   
    var from = ""
    var to = ""
    var content = ""
    var messageGroupId: Int
    var type: Int
    var status: Int
    var createdAt = ""
    var senderName = ""
    var receiverName = ""
    var forActivity = ""
    var fromTeam = ""
    var toTeam = ""
    /* the number of unread messages in the group that this message belongs to, depending on the message type, the group can be
     * 1. All invitation messages sent to current user
     * 2. All challenge messages sent to current user
     * 3. All activity request messages sent to current user
     * 4. All application messages sent to current user
     * 5. All messages in a same conversation
     */
    var numOfUnreadMessagesInTheGroup: Int
    var messageId: String
    
    init(messageInfo: [String: AnyObject]) {
        self.content = Toolbox.getValidStringValue(messageInfo["content"])
        self.createdAt = Toolbox.getValidStringValue(messageInfo["createdAt"])
        self.from = Toolbox.getValidStringValue(messageInfo["from"])
        self.to = Toolbox.getValidStringValue(messageInfo["to"])
        self.type = Int((messageInfo["type"] as! String))!
        self.status = Int((messageInfo["status"] as! String))!
        self.fromTeam = Toolbox.getValidStringValue(messageInfo["fromTeam"])
        self.forActivity = Toolbox.getValidStringValue(messageInfo["forActivity"])
        self.senderName = Toolbox.getValidStringValue(messageInfo["senderName"])
        self.receiverName = Toolbox.getValidStringValue(messageInfo["receiverName"])
        if messageInfo["messageId"] != nil {
            self.messageId = messageInfo["messageId"] as! String
        } else {
            self.messageId = messageInfo["id"] as! String
        }
        self.toTeam = Toolbox.getValidStringValue(messageInfo["toTeam"])
        
        // decide the message group id for this message
        if messageInfo["messageGroupId"] == nil {
            self.messageGroupId = Message.decideMessageGroupId(
                self.from,
                receiverUserId: self.to,
                messageType: self.type
            )
        } else {
            self.messageGroupId = Int((messageInfo["messageGroupId"] as! String))!
        }
        // find out how many unread messages in this message group
        self.numOfUnreadMessagesInTheGroup = Message.getNumberOfUnreadMessagesForMessageGroup(self.messageGroupId)
    }
    
    /**
    Given the sender user id and receiver user id of a message, decide the message group id of that message.
    
    - parameter senderUserId:   sender user id
    - parameter receiverUserId: receiver user id
    - parameter messageType:    the message type
    
    - returns: the decided message group id
    */
    static func decideMessageGroupId(senderUserId: String, receiverUserId: String, messageType: Int) -> Int {
        // conversation id starts with 13, bigger than all message type values
        var messageGroupId = MessageType.UserFeedback.rawValue + 1
        
        let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        if messageType == MessageType.OneToOneMessage.rawValue {
            /**
             * Each conversation is a message group and takes a unique message group id
             */
            var secondUserId: String
            if Singleton_CurrentUser.sharedInstance.userId == senderUserId {  // a sent message, sent by current user
                secondUserId = receiverUserId
            } else {    // a received message, sent to current user
                secondUserId = senderUserId
            }
            // one to one message, see if this message belongs to any existing conversation
            let conversationMessage = dbManager.loadDataFromDB(
                "select * from messages where type=? and (senderId=? or recipientId=?) limit 1",
                parameters: [messageType, secondUserId, secondUserId]
            )
            
            if conversationMessage.count > 0 {  // conversation message exists
                messageGroupId = conversationMessage[0][MessageTableIndex.MessageGroupId.rawValue].integerValue
            } else {    // this is a new conversation, try to find the maximum messageGroupId of conversation exists in messages table
                let maxMessageGroupIdResult = dbManager.loadDataFromDB(
                    "select max(messageGroupId) from messages where type=?",
                    parameters: [messageType]
                )
                if maxMessageGroupIdResult.count > 0 {  // max messageGroupId found
                    messageGroupId = maxMessageGroupIdResult[0][0].integerValue + 1
                } else {    // no conversation in messages table yet, set messageGroupId to 8
                    messageGroupId = messageGroupId + 1
                }
            }
        } else if messageType == MessageType.Invitation.rawValue ||
            messageType == MessageType.Application.rawValue ||
            messageType == MessageType.ActivityRequest.rawValue ||
            messageType == MessageType.Challenge.rawValue {
            // request messages that require user response to either accept or reject
            messageGroupId = MessageGroupIndex.Request.rawValue
        } else {
            // system messages just to notify user of something happened
            messageGroupId = MessageGroupIndex.SystemMessage.rawValue
        }
        return messageGroupId
    }
    
    /**
    Save message in local database
    
    - parameter message: the instantiated message object
    
    - returns: 0 for success, database error code for failure
    */
    static func saveMessageInDatabase(message: Message) -> Int {
        // first off, check if such message with the messageId exists in local database already, if so, DO NOT insert it into database, simply return its messageGroupId
        let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        let existedMessage = dbManager.loadDataFromDB(
            "select * from messages where messageId=?",
            parameters: [message.messageId]
        )
        if existedMessage.count > 0 {   // message already exists
            return 0
        }
        dbManager.modifyDataInDB(
            "insert into messages(senderId, recipientId, type, content, status, teamSenderId, forActivityId, senderName, receiverName, createdAt, messageGroupId, messageId, teamReceiverId) values(?,?,?,?,?,?,?,?,?,?,?,?,?)",
            parameters: [
                message.from,
                message.to,
                message.type,
                message.content,
                message.status,
                message.fromTeam,
                message.forActivity,
                message.senderName,
                message.receiverName,
                message.createdAt,
                message.messageGroupId,
                message.messageId,
                message.toTeam
            ]
        )
        if dbManager.affectedRows == 0 {    // query failed, no database row affected
            // get current view controller
            return ErrorCode.LocalDatabaseError.rawValue
        } else {
            if Singleton_CurrentUser.sharedInstance.userId == message.to {    // This new saved message in database is sent TO me, NOT sent BY me, i.e. I'm the receiver
                message.numOfUnreadMessagesInTheGroup = message.numOfUnreadMessagesInTheGroup + 1
                NSNotificationCenter.defaultCenter().postNotificationName(
                    "receivedNewMessageAndSavedInLocalDatabase",
                    object: message
                )
                // notify VTMainTabBarViewController that the number of total unread messages should increase 1
                NSNotificationCenter.defaultCenter().postNotificationName(
                    "totalNumOfUnreadMessagesChanged",
                    object: ["action": "+", "quantity": "1"]
                )
            } else {    // This new saved message in local database was sent BY me, i.e. I'm the sender
                NSNotificationCenter.defaultCenter().postNotificationName(
                    "sentMessageAndSavedInLocalDatabase",
                    object: message
                )
            }
            return 0
        }
    }
    
    /**
    Change the given messages to designated status
    
    - parameter messageIds: ids of messages that needs to change status
    - parameter status:     the status index to change to
    */
    static func changeMessagesStatus(messageIds: [String], status: Int) {
        let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        if messageIds.count == 0 {  // no messages need to be changed
            return
        }
        var queryParams: [AnyObject] = []
        queryParams.append(status)
        var messageIdsDatabaseParamString = ""
        for i in 0...(messageIds.count - 1) {
            messageIdsDatabaseParamString += "?"
            if i != (messageIds.count - 1) {
                messageIdsDatabaseParamString += ","
            }
            queryParams.append(messageIds[i])
        }
        dbManager.modifyDataInDB(
            "update messages set status=? where messageId in (\(messageIdsDatabaseParamString))",
            parameters: queryParams
        )
        // notify VTMainTabBarViewController that the number of total unread messages should decrease by dbManager.affectedRows
        NSNotificationCenter.defaultCenter().postNotificationName(
            "totalNumOfUnreadMessagesChanged",
            object: ["action": "-", "quantity": "\(Int(dbManager.affectedRows))"]
        )
        // ask server to change all messages in this message group to already read
        let postDataParams = "messageIds=" + Toolbox.convertDictionaryOrArrayToJSONString(messageIds) + "&status=\(status)"
        Toolbox.asyncHttpPostToURL(URLChangeStatusOfMessages, parameters: postDataParams, delegate: nil)

    }
    
    /**
    When message records are fetched from database, it is in the form of array, this function converts that array to dictionary form
    
    - parameter databaseRecord: the database record array that contains string value
    
    - returns: the instantiated message object
    */
    static func formatDatabaseRecordToMessageFormat(databaseRecord: [String]) -> Message {
        let messageDictionary = [
            "from": databaseRecord[MessageTableIndex.From.rawValue],
            "to": databaseRecord[MessageTableIndex.To.rawValue],
            "type": databaseRecord[MessageTableIndex.MessageType.rawValue],
            "content": databaseRecord[MessageTableIndex.Content.rawValue],
            "status": databaseRecord[MessageTableIndex.Status.rawValue],
            "fromTeam": databaseRecord[MessageTableIndex.FromTeam.rawValue],
            "forActivity": databaseRecord[MessageTableIndex.ForActivity.rawValue],
            "senderName": databaseRecord[MessageTableIndex.SenderName.rawValue],
            "receiverName": databaseRecord[MessageTableIndex.ReceiverName.rawValue],
            "createdAt": databaseRecord[MessageTableIndex.CreatedAt.rawValue],
            "messageGroupId": databaseRecord[MessageTableIndex.MessageGroupId.rawValue],
            "messageId": databaseRecord[MessageTableIndex.MessageId.rawValue],
            "toTeam": databaseRecord[MessageTableIndex.ToTeam.rawValue]
        ]
        
        return Message(messageInfo: messageDictionary)
    }
    
    /**
    Given a message group id, count the number of unread messages in that message group
    
    - parameter messageGroupId: the message group id
    
    - returns: the count of unread messages in that message group
    */
    static func getNumberOfUnreadMessagesForMessageGroup(messageGroupId: Int) -> Int {
        // count number of unread messages in this message gruop
        let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        let numOfUnreadMessagesInThisMessageGroup = dbManager.loadDataFromDB(
            "select count(id) from messages where messageGroupId=? and status=? and recipientId=?",
            parameters: [messageGroupId, MessageStatus.Unread.rawValue, Singleton_CurrentUser.sharedInstance.userId!]
        )
        return numOfUnreadMessagesInThisMessageGroup[0][0].integerValue
    }
    
    /**
    When receiving a system message from server, this function sends a local notification 
    as broadcast based on the received system message type
    
    - parameter messageInfo: the attached message info comes with the system message
    */
    static func sendLocalNotificationRegardingSystemMessage(messageInfo: [String: AnyObject]) {
        let metaData = messageInfo["metaData"] as? [NSObject: AnyObject]
        let message = Message(messageInfo: messageInfo)
        switch message.type {
        case MessageType.TeamMemberRemoved.rawValue:
            NSNotificationCenter.defaultCenter().postNotificationName(
                "receivedSystemMessage_teamMemberRemoved", object: metaData
            )
            break
        case MessageType.TeamCaptainChanged.rawValue:
            NSNotificationCenter.defaultCenter().postNotificationName(
                "receivedSystemMessage_teamCaptainChanged", object: metaData
            )
            break
        case MessageType.TeamDismissed.rawValue:
            NSNotificationCenter.defaultCenter().postNotificationName(
                "receivedSystemMessage_teamDismissed", object: metaData
            )
            break
        case MessageType.NewTeamMemberJoined.rawValue:
            NSNotificationCenter.defaultCenter().postNotificationName(
                "receivedSystemMessage_newMemberJoined", object: metaData
            )
            break
        case MessageType.RequestRefused.rawValue:
            NSNotificationCenter.defaultCenter().postNotificationName(
                "receivedSystemMessage_requestRefused", object: metaData)
        default:
            break
        }
    }

}
