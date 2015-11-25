//
//  Singleton_SocketManager.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/1.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class Singleton_SocketManager: NSObject {
    
    var intentionallyDisconnected = false
    let socket = SocketIOClient(socketURL: "\(BaseUrl)")

    static let sharedInstance = Singleton_SocketManager()
    
    func connectToSocket() {
        self.intentionallyDisconnected = false
        // connect to server socket.io and subscribe to message event
        if self.socket.status == .Connected { // if already connected, do nothing
            return
        }
        let currentUser = Singleton_CurrentUser.sharedInstance
        if currentUser.userId == nil {  // user has not logged in yet, cannot connect to socket until user logged in
            return
        }
        // NOTE: when connecting to socket, it is MANDATORY to attach userId with it, 
        // so that when a new message is generated, by looking up to the recipient's userId in databse, 
        // server can also retrieve its corresponding socket/socketId to send the message through
        
        // When connected to server socket, the server will emit an event called 'newSocketID' with the socket id as parameter
        // When client receives this event, it posts the current user id and socket id to server 
        // so that server could save the user's current socket id in mongodb database
        self.socket.on("newSocketID", callback: {
            data, ack in
            // remember when dealing with http post, Toolbox.asyncHttpPostToURL 
            // automatically adds current user id and loginToken as post parameters
            Toolbox.asyncHttpPostToURL(URLSubmitUserIdAndSocketId, parameters: "socketId=\(data[0])", delegate: nil)
        })
        // handling message event
        self.socket.on("message", callback: {
            data, ack in
            // received a new message, save it to local database
            let messageInfo = data[0] as! [String: AnyObject]
            let message = Message(messageInfo: messageInfo)
            Message.saveMessageInDatabase(message)
            // handles system message and send local notification to update corresponding view controllers
            Message.sendLocalNotificationRegardingSystemMessage(messageInfo)
        })
        // handle system force logout event
        self.socket.on("logout", callback: {
            data, ack in
            // received command from server that tells frontend to logout the user since the user has logged in from another device
            Singleton_CurrentUser.sharedInstance.forcedLogout()
        })
        // handle socket disconnect
        self.socket.on("disconnect", callback: {
            data, ack in
            // socket disconnected
            // NOTE: socket will be disconnected INTENTIONALLY for the following circumstances:
            // a. Current user logged out
            // b. app goes to background
            // c. app goes to inactive
            if !self.intentionallyDisconnected {
                // if socket disconnected UNINTENTIONALLY, try to connect  to server socket again
                self.socket.connect()
            }
        })
        self.socket.connect()
    }

}
