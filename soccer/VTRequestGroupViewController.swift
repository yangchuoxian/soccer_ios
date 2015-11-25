//
//  VTRequestGroupViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/31.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTRequestGroupViewController: UIViewController, UIScrollViewDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate {
    
    enum HttpRequest {
        case AcceptOrRejectRequest
        case GetTappedTeamInfo
        case GetTappedUserInfo
    }

    @IBOutlet weak var scrollView: UIScrollView!
    
    var messageGroupId = -1
    var requests = [Dictionary<String, AnyObject>]()
    var numberOfTotalRequestsInThisGroup = 0
    var isLoadingMessageFromLocalDababase = false
    var topActivityIndicator: UIActivityIndicatorView?
    var HUD: MBProgressHUD?
    var responseData: NSMutableData? = NSMutableData()
    /* record which accept/refuse button in the array has been tapped and whether it's accept button or refuse button */
    var currentActionInfo = [String: AnyObject]()
    var indexOfCurrentHttpRequest: HttpRequest?
    var tappedTeamObject: Team?
    var tappedUserObject: User?

    override func viewDidLoad() {
        super.viewDidLoad()
        // listen to the system notification that says new message received
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleSavedMessageInDatabase:", name: "receivedNewMessageAndSavedInLocalDatabase", object: nil)
        // listen to notification that says team avatar in notification view tapped, should show team info view controller now
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "getTappedTeamOrUserProfile:", name: "avatarTappedInRequestCardView", object:nil)
        
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
            "select count(id) from messages where messageGroupId=? and recipientId=?",
            parameters: [self.messageGroupId, Singleton_CurrentUser.sharedInstance.userId!]
        )
        
        self.numberOfTotalRequestsInThisGroup = countTotalMessagesInThisGroup[0][0].integerValue
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "请求通知")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func getTappedTeamOrUserProfile(notification: NSNotification) {
        let info = notification.object as! [NSObject: AnyObject]
        let tappedModelId = info["modelId"] as! String
        let messageType = info["messageType"] as! Int
        // get tapped team or user info from server
        var urlToGetModelInfo: String
        if messageType == MessageType.Application.rawValue {    // tapped avatar is a user
            urlToGetModelInfo = URLGetUserInfo + "?id=\(tappedModelId)"
        } else {    // tapped avatar is a team
            urlToGetModelInfo = URLGetTeamInfo + "?id=\(tappedModelId)"
        }
        var connection = Toolbox.asyncHttpGetFromURL(urlToGetModelInfo, delegate:self)
        if connection == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: nil)
            if messageType == MessageType.Application.rawValue {
                self.indexOfCurrentHttpRequest = .GetTappedUserInfo
            } else {
                self.indexOfCurrentHttpRequest = .GetTappedTeamInfo
            }
        }
        // releases the allocated memory
        connection = nil
    }
    
    func handleSavedMessageInDatabase(notification: NSNotification) {
        let newRequest = notification.object as! Message
        if self.messageGroupId == newRequest.messageGroupId {
            // play message receive sound
            JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
            self.addRequestSequentially(newRequest)
            // recalculate and setup scroll view height
            self.setScrollViewHeight()
            if self.scrollView.contentSize.height > self.view.frame.size.height {
                self.makeScrollViewScrollToBottom()
            }
            self.numberOfTotalRequestsInThisGroup = self.numberOfTotalRequestsInThisGroup + 1
        }
    }
    
    func addRequestSequentially(message: Message) {
        let currentRequestIndex = self.requests.count
        let requestView = self.addMessageView(message, index: currentRequestIndex)
        // add the message and its view height together as a dictionary object into requests
        let requestInfo = [
            "message": message,
            "requestView": requestView
        ]
        self.requests.append(requestInfo)
    }
    
    func addMessageView(message: Message, index: Int) -> VTRequestView {
        var topOffset = RequestViewVerticalMargin + ActivityIndicatorViewHeight
        // calculate the top offset. i.e. the vertical position where this request view should be added
        var existingRequestView: VTRequestView?
        if index > 0 {
            for i in 0...(index - 1) {
                existingRequestView = self.requests[i]["requestView"] as? VTRequestView
                topOffset = topOffset + existingRequestView!.viewHeight! + RequestViewVerticalMargin
            }
        }
        
        let requestView = VTRequestView(message: message, topOffset: topOffset)
        
        // to differentiate which accept/refuse button is tapped, set their tag to be the index of their requestView in self.requests
        requestView.button_accept?.tag = index
        requestView.button_refuse?.tag = index
        
        requestView.button_accept?.addTarget(self, action: "acceptRequest:", forControlEvents: .TouchUpInside)
        requestView.button_refuse?.addTarget(self, action: "refuseRequest:", forControlEvents: .TouchUpInside)
        
        self.scrollView.addSubview(requestView)
        
        return requestView
    }
    
    func loadPaginatedMessages() {
        self.isLoadingMessageFromLocalDababase = true
        
        let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        // get messages from database based on message group index
        let paginatedMessagesResults = dbManager.loadDataFromDB(
            "select * from messages where messageGroupId=? and recipientId=? order by createdAt desc limit ? offset ?",
            parameters: [
                self.messageGroupId,
                Singleton_CurrentUser.sharedInstance.userId!,
                Pagination.NumOfRequestsPerPage.rawValue,
                self.requests.count
            ]
        )
        
        var tempRequests = [Message]()
        for messageDatabaseRecord in Array(paginatedMessagesResults.reverse()) {   // iterate the paginatedMessagesResults REVERSELY
            // put all the retrieved messages in tempMessages for display
            let currentMessage = Message.formatDatabaseRecordToMessageFormat(messageDatabaseRecord as! [String])
            
            tempRequests.append(currentMessage)
        }
        
        // add paginagted messages to self.requests
        if self.requests.count == 0 {  // first page results from database
            for tempRequest in tempRequests {
                self.addRequestSequentially(tempRequest)
            }
            self.setScrollViewHeight()
            if self.scrollView.contentSize.height > self.view.frame.size.height {
                self.makeScrollViewScrollToBottom()
            }
        } else {
            // not first pgae results from database,
            // i.e. there are already some requests and requestViews,
            // inserting the new fetched message results
            // before the existing ones in REVERSE order
            var totalOffset = -NavigationbarHeight - ToolbarHeight
            for tempRequest in Array(tempRequests.reverse()) {
                // show the request
                let requestView = self.addMessageView(tempRequest, index: 0)
                // add the message and its view height together as a dictionary object into requests
                let requestInfo = [
                    "message": tempRequest,
                    "requestView": requestView
                ]
                self.requests.insert(requestInfo, atIndex: 0)
                totalOffset = totalOffset + requestView.viewHeight! + RequestViewVerticalMargin
                // move down the existing request views with the calculated offset
                var existingRequestView: VTRequestView?
                for i in 1...(self.requests.count - 1) {
                    existingRequestView = self.requests[i]["requestView"] as? VTRequestView
                    existingRequestView?.frame = CGRectMake(
                        existingRequestView!.frame.origin.x,
                        existingRequestView!.frame.origin.y + requestView.viewHeight! + RequestViewVerticalMargin,
                        existingRequestView!.frame.size.width,
                        existingRequestView!.frame.size.height
                    )
                    // the index of the existing request view in self.requests has changed, so we need to update its button_accept and button_refuse tag value as well
                    if existingRequestView?.button_accept != nil && existingRequestView?.button_refuse != nil {
                        existingRequestView!.button_accept!.tag = existingRequestView!.button_accept!.tag + 1
                        existingRequestView!.button_refuse!.tag = existingRequestView!.button_refuse!.tag + 1
                    }
                }
            }
            self.setScrollViewHeight()
            if (self.scrollView.contentSize.height > self.view.frame.size.height) {
                self.scrollView.setContentOffset(CGPoint(x: 0, y: totalOffset), animated: false)
            }
        }
        
        self.isLoadingMessageFromLocalDababase = false
    }
    
    func acceptRequest(sender: AnyObject) {
        let senderButton = sender as! UIButton
        let requestsIndex = senderButton.tag
        
        let correspondingMessage = self.requests[requestsIndex]["message"] as! Message
        let postParamString = "messageId=" + correspondingMessage.messageId + "&isAccepted=true"
        
        let connection = Toolbox.asyncHttpPostToURL(URLHandleRequest, parameters:postParamString, delegate: self)
        if connection == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            // set up action info so that in async http response, it knows which button is tapped
            self.currentActionInfo = [
                "index": requestsIndex,
                "action": "accepted"
            ]
            self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: nil)
            self.indexOfCurrentHttpRequest = .AcceptOrRejectRequest
        }
    }
    
    func refuseRequest(sender: AnyObject) {
        let senderButton = sender as! UIButton
        
        let requestsIndex = senderButton.tag
        let correspondingMessage = self.requests[requestsIndex]["message"] as! Message
        let postParamString = "messageId=" + correspondingMessage.messageId
        
        let connection = Toolbox.asyncHttpPostToURL(URLHandleRequest, parameters:postParamString, delegate: self)
        if connection == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            // set up action info so that in async http response, it knows which button is tapped
            self.currentActionInfo = [
                "index": requestsIndex,
                "action": "refused"
            ]
            self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: nil)
            self.indexOfCurrentHttpRequest = .AcceptOrRejectRequest
        }
    }
    
    /**
     * If new request view has been added into the scrollView, its height needs to be recalculated and setup
     */
    func setScrollViewHeight() {
        // calculate the total height of request views and its top margins
        var totalHeight = RequestViewVerticalMargin + ActivityIndicatorViewHeight
        var existingRequestView: VTRequestView?
        for i in 0...(self.requests.count - 1) {
            existingRequestView = self.requests[i]["requestView"] as? VTRequestView
            totalHeight = totalHeight + existingRequestView!.viewHeight! + RequestViewVerticalMargin
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
        if scrollView.contentOffset.y == (-NavigationbarHeight - ToolbarHeight) && !self.isLoadingMessageFromLocalDababase {
            // scrollView has scrolled to top AND not currently FETCHING messages from database/render UI
            if self.requests.count < self.numberOfTotalRequestsInThisGroup {  // still more earlier messages
                self.loadPaginatedMessages()
            } else {
                self.topActivityIndicator?.stopAnimating()
            }
        }
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        self.responseData?.appendData(data)
    }
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        self.HUD?.hide(true)
        self.HUD = nil
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "接收/拒绝通知失败")
        self.currentActionInfo.removeAll(keepCapacity: false)
        
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        self.HUD?.hide(true)
        self.HUD = nil
        
        let responseStr = NSString(data: self.responseData!, encoding: NSUTF8StringEncoding)
        if self.indexOfCurrentHttpRequest == .AcceptOrRejectRequest {
            let actionIndex = self.currentActionInfo["index"] as! Int
            let requestView = self.requests[actionIndex]["requestView"] as! VTRequestView
            let correspondingMessage = self.requests[actionIndex]["message"] as! Message
            var status: Int?

            if responseStr == "OK" {  // accept or reject request succeeded
                if (self.currentActionInfo["action"] as! String) == "accepted" {
                    requestView.updateAppearanceForMessageStatusChange("已接受", backgroundColor: ColorSettledGreen)
                    status = MessageStatus.Accepted.rawValue
                } else {    // the original action is to refuse the request
                    requestView.updateAppearanceForMessageStatusChange("已拒绝", backgroundColor: ColorOrange)
                    status = MessageStatus.Rejected.rawValue
                }
            } else {    // the accepted or rejected request is an invalidated request message
                Toolbox.showCustomAlertViewWithImage("unhappy", title: responseStr as! String)
                requestView.updateAppearanceForMessageStatusChange("已失效", backgroundColor: ColorBackgroundGray)
                status = MessageStatus.Invalidated.rawValue
            }
            let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
            dbManager.modifyDataInDB(
                "update messages set status=? where messageId=?",
                parameters:[
                    status!,
                    correspondingMessage.messageId
                ]
            )
            // notify VTMainTabBarViewController that the number of total unread messages should decrease by dbManager.affectedRows
            NSNotificationCenter.defaultCenter().postNotificationName(
                "totalNumOfUnreadMessagesChanged",
                object: [
                    "action": "-",
                    "quantity": "\(Int(dbManager.affectedRows))"
                ]
            )
            // notify VTGroupsOfMessagesTableViewController that the number of unread messages for specific message group should be updated
            NSNotificationCenter.defaultCenter().postNotificationName(
                "numOfUnreadMessagesInOneMessageGroupChanged",
                object: "\(Int(self.messageGroupId))"
            )
        } else if self.indexOfCurrentHttpRequest == .GetTappedTeamInfo {    // get tapped team info
            let teamDictionary = (try? NSJSONSerialization.JSONObjectWithData(self.responseData!, options: .MutableLeaves)) as? NSDictionary
            if teamDictionary != nil {  // http request to get tapped team info succeeded
                self.tappedTeamObject = Team(data: teamDictionary! as [NSObject : AnyObject])
                self.performSegueWithIdentifier("teamProfileSegue", sender: self)
            } else {        // http request to get tapped team info failed
                Toolbox.showCustomAlertViewWithImage("unhappy", title:"获取球队信息失败")
            }
        } else {    // get tapped user info
            let userJSON = (try? NSJSONSerialization.JSONObjectWithData(self.responseData!, options: .MutableLeaves)) as? [NSObject: AnyObject]
            if userJSON != nil {    // http request to get tapped user info succeeded
                self.tappedUserObject = User(data: userJSON!)
                self.performSegueWithIdentifier(
                    "fromRequestGroupViewToUserProfileSegue", sender: self)
            } else {    // http request to get tapped team info failed
                Toolbox.showCustomAlertViewWithImage("unhappy", title: "获取用户信息失败")
            }
        }
        
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "teamProfileSegue" {
            let destinationViewController = segue.destinationViewController as! VTTeamProfileTableViewController
            destinationViewController.teamObject = self.tappedTeamObject
        } else if segue.identifier == "fromRequestGroupViewToUserProfileSegue" {
            let destinationViewController = segue.destinationViewController as! VTUserProfileTableViewController
            destinationViewController.userObject = self.tappedUserObject
        }
    }
    
    deinit {
        self.HUD = nil
        self.responseData = nil
        self.currentActionInfo.removeAll(keepCapacity: false)
        self.indexOfCurrentHttpRequest = nil
        
        self.scrollView.delegate = nil
        self.topActivityIndicator = nil
        
        self.requests.removeAll(keepCapacity: false)
        self.tappedTeamObject = nil
        self.tappedUserObject = nil
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
}
