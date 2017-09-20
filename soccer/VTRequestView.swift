//
//  VTNotificationView.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/31.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTRequestView: UIView {
    
    var viewHeight: CGFloat?
    var label_createdTimeAndRequestType: UILabel?
    var label_messageContent: UILabel?
    var cardView: UIView?
    var avatarImageView: UIImageView?
    var label_teamName: UILabel?
    var icon_messageType: UIImageView?
    var button_accept: UIButton?
    var button_refuse: UIButton?
    var messageStatusBar: UILabel?
    
    var fromModelId: String?
    var messageType: Int?
    
    init(message: Message, topOffset: CGFloat) {
        super.init(frame: CGRect(x: 0, y: topOffset, width: ScreenSize.width, height: UndecidedVariable))
        
        self.label_createdTimeAndRequestType = UILabel(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: SingleLineLabelHeight))
        self.label_createdTimeAndRequestType?.textColor = UIColor.lightGray
        self.label_createdTimeAndRequestType?.font = UIFont.systemFont(ofSize: 14.0)
        self.label_createdTimeAndRequestType?.textAlignment = .center
        
        self.addSubview(self.label_createdTimeAndRequestType!)
        
        // since message content can be short or quite long, we need to calculate the height
        // of label_messageContent first in order to decide the height of cardView
        self.label_messageContent = UILabel(frame:
            CGRect(
                x: CardViewHorizontalMargin + GeneralPadding + AvatarSize,
                y: GeneralPadding + AvatarSize / 2 + GeneralPadding,
                width: ScreenSize.width - (CardViewHorizontalMargin * 2 + GeneralPadding * 2 + AvatarSize + GeneralPadding),
                height: UndecidedVariable
            )
        )
        self.label_messageContent?.text = message.content
        self.label_messageContent?.textColor = UIColor.lightGray
        self.label_messageContent?.font = UIFont.systemFont(ofSize: 15.0)
        self.label_messageContent?.adjustsFontSizeToFitWidth = false
        self.label_messageContent?.numberOfLines = 0
        self.label_messageContent?.sizeToFit()
        
        let messageContentLabelHeight = self.label_messageContent?.frame.size.height
        
        var cardViewHeight: CGFloat
        if (messageContentLabelHeight! + GeneralPadding) <= AvatarSize / 2 {     // if the height of label_messageContent plus its upper margin is smaller than half of the self.avatarImageView height
            cardViewHeight = GeneralPadding + AvatarSize + GeneralPadding + ButtonHeight
        } else {
            let tempResult = GeneralPadding + AvatarSize / 2 + GeneralPadding + GeneralPadding
            cardViewHeight = tempResult + messageContentLabelHeight! + GeneralPadding + ButtonHeight
        }
        
        self.viewHeight = cardViewHeight + SingleLineLabelHeight
        self.frame = CGRect(x: 0, y: topOffset, width: ScreenSize.width, height: self.viewHeight!)
        
        self.cardView = UIView(frame:
            CGRect(
                x: CardViewHorizontalMargin,
                y: SingleLineLabelHeight,
                width: ScreenSize.width - CardViewHorizontalMargin * 2,
                height: cardViewHeight
            )
        )
        self.cardView!.backgroundColor = UIColor.white
        
        // team avatar
        self.avatarImageView = UIImageView(frame: CGRect(x: GeneralPadding, y: GeneralPadding, width: AvatarSize, height: AvatarSize))
        
        if message.type != MessageType.application.rawValue {
            // of 4 types of requests in this messageGroup, invitation, challenged and activity request are sent from team
            Toolbox.loadAvatarImage(message.fromTeam, toImageView: self.avatarImageView!, avatarType: AvatarType.team)
        } else {
            // yet application is sent by user
            Toolbox.loadAvatarImage(message.from, toImageView: self.avatarImageView!, avatarType: AvatarType.user)
        }
        self.avatarImageView?.layer.cornerRadius = AvatarSize / 2
        self.avatarImageView?.layer.borderWidth = 2.0
        self.avatarImageView?.layer.borderColor = UIColor.white.cgColor
        self.avatarImageView?.clipsToBounds = true
        
        self.messageType = message.type
        if self.messageType != MessageType.application.rawValue {   // message is invitation, activity request or challenge, sent by team
            self.fromModelId = message.fromTeam
        } else {    // message is an application, sent by user
            self.fromModelId = message.from
        }
        
        // set up avatar tap gesture, when tapped, team info view controller should show up
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(VTRequestView.avatarTapped))
        singleTap.numberOfTapsRequired = 1
        self.avatarImageView?.isUserInteractionEnabled = true
        self.avatarImageView?.addGestureRecognizer(singleTap)
        
        self.cardView?.addSubview(self.avatarImageView!)
        
        // team name label
        self.label_teamName = UILabel(frame:
            CGRect(
                x: GeneralPadding * 2 + AvatarSize,
                y: GeneralPadding,
                width: 100,
                height: SingleLineLabelHeight
            )
        )
        self.label_teamName?.text = message.senderName
        self.self.label_teamName?.textColor = UIColor.darkGray
        self.self.label_teamName?.font = UIFont.systemFont(ofSize: 20.0)
        
        self.cardView?.addSubview(self.label_teamName!)
        
        // message/notification type
        self.icon_messageType = UIImageView(frame:
            CGRect(
                x: self.cardView!.frame.size.width - (MessageTypeIconSize + GeneralPadding),
                y: GeneralPadding,
                width: MessageTypeIconSize,
                height: MessageTypeIconSize
            )
        )
        let timeText = Toolbox.formatTimeString(message.createdAt, shouldGetHourAndMinute: true)
        switch (message.type) {
        case MessageType.activityRequest.rawValue:
            self.icon_messageType!.image = UIImage(named: "calendar")
            self.label_createdTimeAndRequestType?.text = timeText + " 活动通知"
            break
        case MessageType.application.rawValue:
            self.icon_messageType!.image = UIImage(named: "person_add")
            self.label_createdTimeAndRequestType?.text = timeText + " 入队申请"
            break
        case MessageType.invitation.rawValue:
            self.icon_messageType!.image = UIImage(named: "handshake")
            self.label_createdTimeAndRequestType?.text = timeText + " 组队邀请"
            break
        case MessageType.challenge.rawValue:
            self.icon_messageType!.image = UIImage(named: "trophy")
            self.label_createdTimeAndRequestType?.text = timeText + " 挑战书"
            break
        default:
            break
        }
        
        self.cardView!.addSubview(self.icon_messageType!)
        
        // message content
        self.label_messageContent!.frame = CGRect(
            x: GeneralPadding * 2 + AvatarSize,
            y: GeneralPadding * 2 + AvatarSize / 2,
            width: self.cardView!.frame.size.width - (GeneralPadding * 3 + AvatarSize),
            height: messageContentLabelHeight!
        )
        self.cardView!.addSubview(self.label_messageContent!)
        
        if message.status == MessageStatus.unread.rawValue {
            // accept button
            self.button_accept = UIButton(type: .system)
            
            self.button_accept?.frame = CGRect(
                x: 0,
                y: cardViewHeight - ButtonHeight,
                width: self.cardView!.frame.size.width / 2,
                height: ButtonHeight
            )
            self.button_accept?.tintColor = UIColor.white
            self.button_accept?.setTitle("接受", for: UIControlState())
            self.button_accept?.backgroundColor = ColorSettledGreen
            
            self.cardView?.addSubview(self.button_accept!)
            
            // refuse button
            self.button_refuse = UIButton(type: .system)
            self.button_refuse?.frame = CGRect(
                x: self.cardView!.frame.size.width / 2 + 1,
                y: cardViewHeight - ButtonHeight,
                width: self.cardView!.frame.size.width / 2 - 1,
                height: ButtonHeight
            )
            self.button_refuse?.tintColor = UIColor.white
            self.button_refuse?.setTitle("拒绝", for: UIControlState())
            self.button_refuse?.backgroundColor = ColorOrange
            
            self.cardView?.addSubview(self.button_refuse!)
        } else {
            self.messageStatusBar = UILabel(frame:
                CGRect(
                    x: 0,
                    y: cardViewHeight - ButtonHeight,
                    width: self.cardView!.frame.size.width,
                    height: ButtonHeight
                )
            )
            if message.status == MessageStatus.accepted.rawValue {
                self.messageStatusBar?.backgroundColor = ColorSettledGreen
                self.messageStatusBar?.text = "已接受"
            } else {
                self.messageStatusBar?.backgroundColor = ColorYellow
                self.messageStatusBar?.text = "已拒绝"
            }
            self.messageStatusBar?.textColor = UIColor.white
            self.messageStatusBar?.font = UIFont.systemFont(ofSize: 15.0)
            self.messageStatusBar?.textAlignment = .center
            
            self.cardView?.addSubview(self.messageStatusBar!)
        }
        self.addSubview(self.cardView!)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func avatarTapped() {
        NotificationCenter.default.post(
            name: Notification.Name(rawValue: "avatarTappedInRequestCardView"),
            object: [
                "modelId": self.fromModelId!,
                "messageType": self.messageType!
            ]
        )
    }
    
    func updateAppearanceForMessageStatusChange(_ statusString: String, backgroundColor: UIColor) {
        self.button_accept?.removeFromSuperview()
        self.button_accept = nil
        
        self.button_refuse?.removeFromSuperview()
        self.button_refuse = nil
        
        self.messageStatusBar = UILabel(
            frame: CGRect(
                x: 0,
                y: self.cardView!.frame.size.height - ButtonHeight,
                width: self.cardView!.frame.size.width,
                height: ButtonHeight
            )
        )
        
        self.messageStatusBar?.backgroundColor = backgroundColor
        self.messageStatusBar?.text = statusString
        self.messageStatusBar?.textColor = UIColor.white
        self.messageStatusBar?.font = UIFont.systemFont(ofSize: 15.0)
        self.messageStatusBar?.textAlignment = .center
        
        self.cardView!.addSubview(self.messageStatusBar!)
    }
    
    deinit {
        self.label_createdTimeAndRequestType = nil
        self.label_messageContent = nil
        
        if self.avatarImageView != nil {
            self.avatarImageView?.image = nil
            self.avatarImageView = nil
        }
        
        if self.icon_messageType != nil {
            self.icon_messageType?.image = nil
            self.icon_messageType = nil
        }
        
        self.label_teamName = nil
        if self.button_accept != nil {
            self.button_accept?.removeTarget(nil, action: nil, for: .allEvents)
            self.button_accept = nil
        }
        if self.button_refuse != nil {
            self.button_refuse?.removeTarget(nil, action: nil, for: .allEvents)
            self.button_refuse = nil
        }
        
        self.messageStatusBar = nil
        self.cardView = nil
        self.fromModelId = nil
    }
}
