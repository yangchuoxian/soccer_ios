//
//  VTTeamActivityInfoTableViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/21.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTTeamActivityInfoTableViewController: UITableViewController, NSURLConnectionDelegate, NSURLConnectionDataDelegate {
    
    var activityObject: Activity?
    var selectedTeamId: String?
    var idOfTeamA: String?
    var nameOfTeamA: String?
    var idOfTeamB: String?
    var nameOfTeamB: String?
    var tappedTeamId: String?
    var tappedTeamName: String?
    var responseData: NSMutableData? = NSMutableData()
    
    @IBOutlet weak var imageView_avatarOfTeamA: UIImageView!
    @IBOutlet weak var label_nameOfTeamA: UILabel!
    @IBOutlet weak var imageView_avatarOfTeamB: UIImageView!
    @IBOutlet weak var label_nameOfTeamB: UILabel!
    @IBOutlet weak var label_date: UILabel!
    @IBOutlet weak var label_time: UILabel!
    @IBOutlet weak var label_address: UILabel!
    @IBOutlet weak var label_minimumNumberOfAttendees: UILabel!
    @IBOutlet weak var label_status: UILabel!
    @IBOutlet weak var label_nameOfscoreOrType: UILabel!
    @IBOutlet weak var label_valueOfScoreOrType: UILabel!
    @IBOutlet weak var imageView_chevronRightToUpdateScore: UIImageView!
    
    @IBOutlet weak var avatarTeamALeftMarginConstraint: NSLayoutConstraint!
    @IBOutlet weak var textView_note: UITextView!
    
    @IBOutlet weak var cell_updateScore: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add the UIRefreshControl to tableView
        self.refreshControl = Appearance.setupRefreshControl()
        self.refreshControl?.addTarget(self, action: "refreshActivityDetails", forControlEvents: .ValueChanged)
        self.tableView.addSubview(self.refreshControl!)
        
        self.clearsSelectionOnViewWillAppear = true
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        
        Toolbox.removeBottomShadowOfNavigationBar(self.navigationController!.navigationBar)
        
        Appearance.customizeAvatarImage(self.imageView_avatarOfTeamA)
        Appearance.customizeAvatarImage(self.imageView_avatarOfTeamB)
        
        self.selectedTeamId = NSUserDefaults.standardUserDefaults().stringForKey("teamIdSelectedInTeamsList")
        // add tap gesture event to imageView_avatar, attendees list for team A of the activity will show up when tapped
        let singleTapOfAvatarTeamA = UITapGestureRecognizer(target: self, action: "showAttendeesOfTeamA")
        self.imageView_avatarOfTeamA.userInteractionEnabled = true
        self.imageView_avatarOfTeamA.addGestureRecognizer(singleTapOfAvatarTeamA)
        
        // listens to notification that says score updated
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateScore:", name: "scoreUpdated", object: nil)
        
        self.showActivityDetails()
        self.disableUpdateScoreIfNeeded()
    }
    
    func updateScore(notification: NSNotification) {
        let score = notification.object as! String
        // user as one team captain just updated the score for his/her team
        if self.selectedTeamId == self.activityObject?.idOfA {
            self.activityObject!.scoreOfA = Int(score)
        } else {
            self.activityObject!.scoreOfB = Int(score)
        }
        self.label_valueOfScoreOrType.text = self.getScoreString()
        self.disableUpdateScoreIfNeeded()
    }
    
    override func viewWillAppear(animated: Bool) {
        Appearance.customizeNavigationBar(self, title: "活动详情")
        // clear the selection style of previously selected table cell
        let selectedIndexPath = self.tableView.indexPathForSelectedRow
        if selectedIndexPath != nil {
            self.tableView.deselectRowAtIndexPath(selectedIndexPath!, animated: true)
        }
    }
    
    func showActivityDetails() {
        // set up the avatar and name of team A
        self.nameOfTeamA = self.activityObject?.nameOfA
        self.idOfTeamA = self.activityObject?.idOfA
        
        Toolbox.loadAvatarImage(self.idOfTeamA!, toImageView: self.imageView_avatarOfTeamA, avatarType: AvatarType.Team)
        self.label_nameOfTeamA.text = self.nameOfTeamA
        
        if self.activityObject?.type == ActivityType.Exercise.rawValue {    // activity is an exercise, therefore no team B existed
            self.imageView_avatarOfTeamB.hidden = true
            self.label_nameOfTeamB.hidden = true
            // put the avatar and name of team A in the horizontal center of the screen
            self.avatarTeamALeftMarginConstraint.constant = ScreenSize.width / 2 - self.imageView_avatarOfTeamA.frame.width / 2 - 13
        } else {    // activity is a match, set up the avatar and name of team B
            self.nameOfTeamB = self.activityObject?.nameOfB
            self.idOfTeamB = self.activityObject?.idOfB
            Toolbox.loadAvatarImage(self.idOfTeamB!, toImageView: self.imageView_avatarOfTeamB, avatarType: AvatarType.Team)
            // add tap gesture event to imageView_avatar, attendees list for team B of the activity will show up when tapped
            let singleTapOfAvatarTeamB = UITapGestureRecognizer(target: self, action: "showAttendeesOfTeamB")
            self.imageView_avatarOfTeamB.userInteractionEnabled = true
            self.imageView_avatarOfTeamB.addGestureRecognizer(singleTapOfAvatarTeamB)
            
            self.label_nameOfTeamB.text = self.nameOfTeamB
        }
        
        // set up activity date and time
        self.label_date.text = self.activityObject?.date
        self.label_time.text = self.activityObject?.time
        
        // set up activity address
        self.label_address.text = self.activityObject?.place
        
        // set up minimum number of attendees of this activity. NOTE: if the activity is an exercise, the minimum number of people does not exist
        if self.activityObject?.type == ActivityType.Match.rawValue {
            self.label_minimumNumberOfAttendees.text = "\(self.activityObject!.minimumNumberOfPeople)"
        } else {
            self.label_minimumNumberOfAttendees.text = "-"
        }
        
        // set up activity status
        switch self.activityObject!.status! {
        case ActivityStatus.ConfirmingTeamAParticipants.rawValue:
            self.label_status.text = "确定参与人员中..."
        case ActivityStatus.WaitingForAcceptanceFromCaptainOfTeamB.rawValue:
            self.label_status.text = "等待接受挑战中..."
        case ActivityStatus.RejectedByCaptainOfTeamB.rawValue:
            self.label_status.text = "比赛请求失败"
        case ActivityStatus.ConfirmingTeamBParticipants.rawValue:
            self.label_status.text = "确定参与人员中..."
        case ActivityStatus.Finalized.rawValue:
            self.label_status.text = "即将进行"
        case ActivityStatus.Done.rawValue:
            self.label_status.text = "已完成"
        case ActivityStatus.FailedPublication.rawValue:
            self.label_status.text = "发起比赛失败"
        case ActivityStatus.Ongoing.rawValue:
            self.label_status.text = "正在进行中"
        default:
            self.label_status.text = "未知"
        }
        
        // set up activity note
        self.textView_note.text = self.activityObject?.note
        // set up activity score
        if self.activityObject?.type == ActivityType.Match.rawValue {   // activity is a match
            // set up activity scores
            self.label_nameOfscoreOrType.text = "比分"
            self.label_valueOfScoreOrType.text = self.getScoreString()
        } else {
            self.label_nameOfscoreOrType.text = "类型"
            self.label_valueOfScoreOrType.text = "训练"
        }
    }
    
    func getScoreString() -> String {
        var scoreString = ""
        if self.activityObject?.scoreOfA != nil && self.activityObject?.scoreOfB != nil {
            scoreString = "\(self.activityObject!.scoreOfA!) : \(self.activityObject!.scoreOfB!)"
        } else if self.activityObject?.scoreOfA != nil {
            scoreString = "\(self.activityObject!.scoreOfA!) : --"
        } else if self.activityObject?.scoreOfB != nil {
            scoreString = "-- : \(self.activityObject!.scoreOfB!)"
        }
        return scoreString
    }
    
    /**
     * For the several situations, one cannot update activity score:
     * 1. the current user is NOT team captain
     * 2. the activity is NOT a match
     * 3. the activity has NOT finished yet
     * 4. the activity score for current team has already been set
     */
    func disableUpdateScoreIfNeeded() {
        var shouldDisable = false
        let captainIdOfSelectedTeam = Team.retrieveCaptainIdFromLocalDatabaseWithTeamId(self.selectedTeamId!)
        if self.activityObject?.type != ActivityType.Match.rawValue {
            // the activity is not a match
            shouldDisable = true
        } else if captainIdOfSelectedTeam != Singleton_CurrentUser.sharedInstance.userId {
            // current user is not team captain of the selected team, thus he/she have no right to update match score
            shouldDisable = true
        } else if self.activityObject?.status != ActivityStatus.Done.rawValue {
            // the activity has not yet finished yet
            shouldDisable = true
        }
        if self.selectedTeamId == self.activityObject?.idOfA && self.activityObject?.scoreOfA != nil {
            // current team is A and score of A is already set
            shouldDisable = true
        }
        if self.selectedTeamId == self.activityObject?.idOfB &&
            self.activityObject?.scoreOfB != nil {
            // current team is B and score of B is already set
            shouldDisable = true
        }
        
        if shouldDisable == true {
            self.imageView_chevronRightToUpdateScore.hidden = true
            self.cell_updateScore.userInteractionEnabled = false
            self.cell_updateScore.selectionStyle = .None
        }
    }
    
    func refreshActivityDetails() {
        let urlToGetActivityInfo = URLGetActivityInfo + "?activityId=\(self.activityObject!.activityId!)"
        let connection = Toolbox.asyncHttpGetFromURL(urlToGetActivityInfo, delegate:self)
        if connection == nil {
            // inform the user that the connection failed
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        }
    }
    
    func showAttendeesOfTeamA() {
        self.tappedTeamId = self.idOfTeamA
        self.tappedTeamName = self.nameOfTeamA
        self.performSegueWithIdentifier("showAttendeesSegue", sender: self)
    }
    
    func showAttendeesOfTeamB() {
        self.tappedTeamId = self.idOfTeamB
        self.tappedTeamName = self.nameOfTeamB
        self.performSegueWithIdentifier("showAttendeesSegue", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showAttendeesSegue" {
            let destinationViewController = segue.destinationViewController as! VTAttendeesTableViewController
            destinationViewController.teamId = self.tappedTeamId
            destinationViewController.teamName = self.tappedTeamName
            destinationViewController.activityId = self.activityObject?.activityId
            destinationViewController.activityStatus = self.activityObject?.status
        } else if segue.identifier == "updateScoreSegue" {
            let destinationViewController = segue.destinationViewController as! VTUpdateActivityScoreViewController
            destinationViewController.activityId = self.activityObject?.activityId
            destinationViewController.teamId = self.selectedTeamId
        } else if segue.identifier == "activityAddressSegue" {
            let destinationViewController = segue.destinationViewController as! VTGroundInfoViewController
            let groundObject = Ground(data: [
                "latitude": "\(self.activityObject!.latitude)",
                "longitude": "\(self.activityObject!.longitude)",
                "address": "\(self.activityObject!.place!)"
            ])
            destinationViewController.groundObject = groundObject
        }
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        self.responseData?.appendData(data)
    }
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        self.refreshControl?.endRefreshing()
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络超时")
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        self.refreshControl?.endRefreshing()
        let activityInfo = (try? NSJSONSerialization.JSONObjectWithData(self.responseData!, options: NSJSONReadingOptions.MutableLeaves)) as? NSDictionary
        if activityInfo != nil { // http request succeeded
            self.activityObject = Activity(data: activityInfo! as! [String : AnyObject])
            self.activityObject?.saveOrUpdateActivityInDatabase()
            self.showActivityDetails()
        } else {    // http request failed with error
            let errorMessage = NSString(data: self.responseData!, encoding: NSUTF8StringEncoding)!
            Toolbox.showCustomAlertViewWithImage("unhappy", title: errorMessage as String)
        }
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func unwindToActivityInfoTableView(segue: UIStoryboardSegue) {
    }
    
    deinit {
        self.responseData = nil
        self.activityObject = nil
        self.tappedTeamId = nil
        self.idOfTeamA = nil
        self.idOfTeamB = nil
        self.nameOfTeamA = nil
        self.nameOfTeamB = nil
        self.tappedTeamName = nil
    }
    
}