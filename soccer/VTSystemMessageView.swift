//
//  VTSystemMessageView.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/15.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTSystemMessageView: UIView {

    var viewHeight: CGFloat?
    var label_createTime: UILabel?
    var label_messageContent: UILabel?
    var icon_messageType: UIImageView?

    var messageBodyView: UIView?
    
    init(message: Message, topOffset: CGFloat) {
        super.init(frame: CGRect(x: 0, y: topOffset, width: ScreenSize.width, height: UndecidedVariable))
        self.label_createTime = UILabel(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: SingleLineLabelHeight))
        self.messageBodyView = UIView(frame: CGRect(x: GeneralPadding, y: SingleLineLabelHeight, width: ScreenSize.width - GeneralPadding * 2, height: UndecidedVariable))
        self.icon_messageType = UIImageView(frame: CGRect(x: GeneralPadding, y: GeneralPadding, width: MessageTypeIconSize, height: MessageTypeIconSize))
        self.label_messageContent = UILabel(frame: CGRect(x: MessageTypeIconSize + 2 * GeneralPadding, y: GeneralPadding, width: ScreenSize.width - 5 * GeneralPadding, height: UndecidedVariable))

        self.label_createTime?.text = Toolbox.formatTimeString(message.createdAt, shouldGetHourAndMinute: true)
        self.label_createTime?.textColor = UIColor.lightGrayColor()
        self.label_createTime?.font = UIFont.systemFontOfSize(14.0)
        self.label_createTime?.textAlignment = .Center
        self.addSubview(self.label_createTime!)
        
        self.label_messageContent?.text = message.content
        self.label_messageContent?.textColor = UIColor.whiteColor()
        self.label_messageContent?.font = UIFont.systemFontOfSize(15.0)
        self.label_messageContent?.adjustsFontSizeToFitWidth = false
        self.label_messageContent?.numberOfLines = 0
        self.label_messageContent?.sizeToFit()
        self.messageBodyView!.addSubview(self.label_messageContent!)
        
        let messageContentLabelHeight = self.label_messageContent!.frame.size.height
        let messageBodyViewHeight = messageContentLabelHeight + 2 * GeneralPadding 
        self.messageBodyView?.frame.size.height = messageBodyViewHeight
        
        self.viewHeight = messageBodyViewHeight + self.label_createTime!.frame.height + GeneralPadding
        self.frame.size.height = self.viewHeight!
        
        self.messageBodyView?.layer.masksToBounds = true
        self.messageBodyView?.layer.cornerRadius = 5

        switch message.type {
        case MessageType.TeamMemberRemoved.rawValue:
            self.icon_messageType?.image = UIImage(named: "remove_player")
            self.messageBodyView?.backgroundColor = ColorOrange
            break
        case MessageType.NewTeamMemberJoined.rawValue:
            self.icon_messageType?.image = UIImage(named: "new_player")
            self.messageBodyView?.backgroundColor = ColorGreen
            break
        case MessageType.TeamCaptainChanged.rawValue:
            self.icon_messageType?.image = UIImage(named: "statue")
            self.messageBodyView?.backgroundColor = ColorGreen
            break
        case MessageType.TeamDismissed.rawValue:
            self.icon_messageType?.image = UIImage(named: "delete_team")
            self.messageBodyView?.backgroundColor = ColorOrange
            break
        case MessageType.RequestRefused.rawValue:
            self.icon_messageType?.image = UIImage(named: "hand")
            self.messageBodyView?.backgroundColor = ColorOrange
            break
        case MessageType.UserFeedback.rawValue:
            self.icon_messageType?.image = UIImage(named: "feedback")
            self.messageBodyView?.backgroundColor = UIColor.darkGrayColor()
            break
        default:
            break
        }
        self.messageBodyView!.addSubview(self.icon_messageType!)
        self.addSubview(self.messageBodyView!)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    deinit {
        self.viewHeight = nil
        self.label_createTime = nil
        self.label_messageContent = nil
        if self.icon_messageType != nil {
            self.icon_messageType?.image = nil
            self.icon_messageType = nil
        }
        self.messageBodyView = nil
    }
    
}
