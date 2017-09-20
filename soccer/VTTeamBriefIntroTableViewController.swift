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
        self.textView_introduction.isEditable = false
        
        let verticalSeparatorForFollowersView = UIView(frame: CGRect(x: ScreenSize.width / 4 - 1, y: 6, width: 1, height: 32))
        verticalSeparatorForFollowersView.backgroundColor = ColorBackgroundGray
        verticalSeparatorForFollowersView.alpha = 0.6
        self.view_followersBackground.addSubview(verticalSeparatorForFollowersView)
        
        let verticalSeparatorForWinsView = UIView(frame: CGRect(x: ScreenSize.width / 4 - 1, y: 6, width: 1, height: 32))
        verticalSeparatorForWinsView.backgroundColor = ColorBackgroundGray
        verticalSeparatorForWinsView.alpha = 0.6
        self.view_winsBackground.addSubview(verticalSeparatorForWinsView)
        
        let verticalSeparatorForLosesView = UIView(frame: CGRect(x: ScreenSize.width / 4 - 1, y: 6, width: 1, height: 32))
        verticalSeparatorForLosesView.backgroundColor = ColorBackgroundGray
        verticalSeparatorForLosesView.alpha = 0.6
        self.view_losesBackground.addSubview(verticalSeparatorForLosesView)
        
        let verticalSeparatorForTiesView = UIView(frame: CGRect(x: ScreenSize.width / 4 - 1, y: 6, width: 1, height: 32))
        verticalSeparatorForTiesView.backgroundColor = ColorBackgroundGray
        verticalSeparatorForTiesView.alpha = 0.6
        self.view_tiesBackground.addSubview(verticalSeparatorForTiesView)
        
        // Load team information
        Toolbox.loadAvatarImage(self.teamObject.teamId, toImageView: self.imageView_avatar, avatarType: AvatarType.team)
        
        self.label_wins.text = String(self.teamObject.wins)
        self.label_loses.text = String(self.teamObject.loses)
        self.label_ties.text = String(self.teamObject.ties)
        self.label_numberOfPoints.text = String(self.teamObject.points)
       
        self.label_teamName.text = self.teamObject.teamName
        
        let teamCreationDate = Date(dateTimeString: self.teamObject.createdAt)
        self.label_createdAt.text = teamCreationDate.getDateString()
        
        self.label_city.text = self.teamObject.location
        self.textView_introduction.text = self.teamObject.introduction
        if Toolbox.isStringValueValid(self.teamObject.homeCourt) {
            self.label_homeCourt.text = self.teamObject.homeCourt
        }
        
        if self.teamInteractionOption == .sendApplication {
            self.label_teamInteractionTitle.text = "申请加入球队"
        } else if self.teamInteractionOption == .sendChallenge {
            self.label_teamInteractionTitle.text = "发起挑战"
        }
        // add notification observer to watch if new match challenge was published
        NotificationCenter.default.addObserver(self, selector: #selector(VTTeamBriefIntroTableViewController.notifyChallengeInitiated(_:)), name: NSNotification.Name(rawValue: "newActivityPublished"), object: nil)
    }
    
    func notifyChallengeInitiated(_ notification: Notification) {
        Toolbox.showCustomAlertViewWithImage("checkmark", title: "比赛邀请发送成功")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "球队详情")
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // if the current user has already applied for membership of this team, the table section that has '申请加入球队' should be hidden
        // also if the current user is a captain of another team, he/she can challenge this team
        let currentUserOwnedTeamId = Singleton_UserOwnedTeam.sharedInstance.teamId
        if self.hasUserAlreadyAppliedThisTeam == false && (Toolbox.isStringValueValid(currentUserOwnedTeamId) && self.teamObject.teamId != currentUserOwnedTeamId) {
            return 3
        } else {
            return 2
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return DefaultTableSectionFooterHeight
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: DefaultTableSectionFooterHeight))
        footerView.backgroundColor = UIColor.clear
        return footerView
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).section == 2 && (indexPath as NSIndexPath).row == 0 {
            // clicked team interaction action, which can be either
            // 1. send application to team, or
            // 2. send challenge to team
            if self.teamInteractionOption == .sendApplication {
                self.performSegue(withIdentifier: "sendApplicationSegue", sender: self)
            } else if self.teamInteractionOption == .sendChallenge {
                self.performSegue(withIdentifier: "initiateMatchSegue", sender: self)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "sendApplicationSegue" {
            let destinationViewController = segue.destination as! VTSendApplicationViewController
            destinationViewController.teamObject = self.teamObject
            destinationViewController.teamCaptainUserId = self.teamObject.captainUserId
        } else if segue.identifier == "initiateMatchSegue" {
            let destinationNavigationViewController = segue.destination as? UINavigationController
            let newActivityTableViewController = destinationNavigationViewController?.viewControllers[0] as? VTNewActivityTableViewController
            newActivityTableViewController?.selectedActivityType = .match
            newActivityTableViewController?.rivalTeamId = self.teamObject.teamId
            newActivityTableViewController?.isNewActivityMatchInitiatedFromDiscoverTab = true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func unwindToTeamBriefIntroView(_ segue: UIStoryboardSegue) {
    }
    
    deinit {
        self.teamObject = nil
        self.teamInteractionOption = nil
    }
    
}
