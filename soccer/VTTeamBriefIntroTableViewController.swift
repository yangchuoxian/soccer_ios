//
//  VTTeamBriefIntroTableViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/5/16.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

@objc class VTTeamBriefIntroTableViewController: UITableViewController {
    @IBOutlet weak var imageView_avatar: UIImageView!
    @IBOutlet weak var label_teamName: UILabel!
    @IBOutlet weak var label_numberOfPoints: UILabel!
    @IBOutlet weak var label_wins: UILabel!
    @IBOutlet weak var label_loses: UILabel!
    @IBOutlet weak var label_ties: UILabel!
    
    @IBOutlet weak var view_followersBackground: UIView!
    @IBOutlet weak var view_winsBackground: UIView!
    @IBOutlet weak var view_losesBackground: UIView!
    @IBOutlet weak var view_tiesBackground: UIView!
    
    @IBOutlet weak var label_createdAt: UILabel!
    @IBOutlet weak var label_city: UILabel!
    @IBOutlet weak var label_homeCourt: UILabel!
    @IBOutlet weak var textView_introduction: UITextView!
    @IBOutlet weak var label_teamInteractionTitle: UILabel!
    
    var teamObject: Team!
    var hasUserAlreadyAppliedThisTeam = false
    var teamInteractionOption: TeamInteractionType?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Toolbox.removeBottomShadowOfNavigationBar(self.navigationController!.navigationBar)
        
        // make team introduction textView not editable
        self.textView_introduction.editable = false
        
        let verticalSeparatorForFollowersView = UIView(frame: CGRectMake(ScreenSize.width / 4 - 1, 6, 1, 32))
        verticalSeparatorForFollowersView.backgroundColor = ColorBackgroundGray
        verticalSeparatorForFollowersView.alpha = 0.6
        self.view_followersBackground.addSubview(verticalSeparatorForFollowersView)
        
        let verticalSeparatorForWinsView = UIView(frame: CGRectMake(ScreenSize.width / 4 - 1, 6, 1, 32))
        verticalSeparatorForWinsView.backgroundColor = ColorBackgroundGray
        verticalSeparatorForWinsView.alpha = 0.6
        self.view_winsBackground.addSubview(verticalSeparatorForWinsView)
        
        let verticalSeparatorForLosesView = UIView(frame: CGRectMake(ScreenSize.width / 4 - 1, 6, 1, 32))
        verticalSeparatorForLosesView.backgroundColor = ColorBackgroundGray
        verticalSeparatorForLosesView.alpha = 0.6
        self.view_losesBackground.addSubview(verticalSeparatorForLosesView)
        
        let verticalSeparatorForTiesView = UIView(frame: CGRectMake(ScreenSize.width / 4 - 1, 6, 1, 32))
        verticalSeparatorForTiesView.backgroundColor = ColorBackgroundGray
        verticalSeparatorForTiesView.alpha = 0.6
        self.view_tiesBackground.addSubview(verticalSeparatorForTiesView)
        
        // Load team information
        Toolbox.loadAvatarImage(self.teamObject.teamId, toImageView: self.imageView_avatar, avatarType: AvatarType.Team)
        
        self.label_wins.text = String(self.teamObject.wins)
        self.label_loses.text = String(self.teamObject.loses)
        self.label_ties.text = String(self.teamObject.ties)
        self.label_numberOfPoints.text = String(self.teamObject.points)
       
        self.label_teamName.text = self.teamObject.teamName
        
        let teamCreationDate = NSDate(dateTimeString: self.teamObject.createdAt)
        self.label_createdAt.text = teamCreationDate.getDateString()
        
        self.label_city.text = self.teamObject.location
        self.textView_introduction.text = self.teamObject.introduction
        if Toolbox.isStringValueValid(self.teamObject.homeCourt) {
            self.label_homeCourt.text = self.teamObject.homeCourt
        }
        
        if self.teamInteractionOption == .SendApplication {
            self.label_teamInteractionTitle.text = "申请加入球队"
        } else if self.teamInteractionOption == .SendChallenge {
            self.label_teamInteractionTitle.text = "发起挑战"
        }
        // add notification observer to watch if new match challenge was published
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "notifyChallengeInitiated:", name: "newActivityPublished", object: nil)
    }
    
    func notifyChallengeInitiated(notification: NSNotification) {
        Toolbox.showCustomAlertViewWithImage("checkmark", title: "比赛邀请发送成功")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "球队详情")
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // if the current user has already applied for membership of this team, the table section that has '申请加入球队' should be hidden
        // also if the current user is a captain of another team, he/she can challenge this team
        let currentUserOwnedTeamId = Singleton_UserOwnedTeam.sharedInstance.teamId
        if self.hasUserAlreadyAppliedThisTeam == false && (Toolbox.isStringValueValid(currentUserOwnedTeamId) && self.teamObject.teamId != currentUserOwnedTeamId) {
            return 3
        } else {
            return 2
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // if the current user has already applied for membership of this team, the table section that has '申请加入球队' should be hidden
        // if the current user is a team captain and this team is not the team that the current user owns, then he/she can send challenge request to this team
        var rowsInSection = 0
        switch section {
        case 0:
            rowsInSection = 2
            break
        case 1:
            rowsInSection = 4
            break
        case 2:
            let currentUserOwnedTeamId = Singleton_UserOwnedTeam.sharedInstance.teamId
            if self.hasUserAlreadyAppliedThisTeam == false && (Toolbox.isStringValueValid(currentUserOwnedTeamId) && self.teamObject.teamId != currentUserOwnedTeamId) {
                rowsInSection = 1
            } else {
                rowsInSection = 0
            }
            break
        default:
            break
        }
        return rowsInSection
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return DefaultTableSectionFooterHeight
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView(frame: CGRectMake(0, 0, ScreenSize.width, DefaultTableSectionFooterHeight))
        footerView.backgroundColor = UIColor.clearColor()
        return footerView
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 2 && indexPath.row == 0 {
            // clicked team interaction action, which can be either
            // 1. send application to team, or
            // 2. send challenge to team
            if self.teamInteractionOption == .SendApplication {
                self.performSegueWithIdentifier("sendApplicationSegue", sender: self)
            } else if self.teamInteractionOption == .SendChallenge {
                self.performSegueWithIdentifier("initiateMatchSegue", sender: self)
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "sendApplicationSegue" {
            let destinationViewController = segue.destinationViewController as! VTSendApplicationViewController
            destinationViewController.teamObject = self.teamObject
            destinationViewController.teamCaptainUserId = self.teamObject.captainUserId
        } else if segue.identifier == "initiateMatchSegue" {
            let destinationNavigationViewController = segue.destinationViewController as? UINavigationController
            let newActivityTableViewController = destinationNavigationViewController?.viewControllers[0] as? VTNewActivityTableViewController
            newActivityTableViewController?.selectedActivityType = .Match
            newActivityTableViewController?.rivalTeamId = self.teamObject.teamId
            newActivityTableViewController?.isNewActivityMatchInitiatedFromDiscoverTab = true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func unwindToTeamBriefIntroView(segue: UIStoryboardSegue) {
    }
    
    deinit {
        self.teamObject = nil
        self.teamInteractionOption = nil
    }
    
}
