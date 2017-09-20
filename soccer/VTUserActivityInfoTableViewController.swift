//
//  VTUserActivityInfoTableViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/22.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTUserActivityInfoTableViewController: UITableViewController, NSURLConnectionDelegate, NSURLConnectionDataDelegate {
    
    var activity: Activity?
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
    @IBOutlet weak var label_scores: UILabel!
    
    @IBOutlet weak var avatarTeamALeftMarginConstraint: NSLayoutConstraint!
    @IBOutlet weak var textView_note: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = true
        
        // add the UIRefreshControl to tableView
        self.refreshControl = Appearance.setupRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(VTUserActivityInfoTableViewController.refreshActivityDetails), for: .valueChanged)
        self.tableView.addSubview(self.refreshControl!)
        
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        Appearance.customizeAvatarImage(self.imageView_avatarOfTeamA)
        Appearance.customizeAvatarImage(self.imageView_avatarOfTeamB)
        
        // add tap gesture event to imageView_avatar, attendees list for team A of the activity will show up when tapped
        let singleTapOfAvatarTeamA = UITapGestureRecognizer(target: self, action: #selector(VTUserActivityInfoTableViewController.showAttendeesOfTeamA))
        self.imageView_avatarOfTeamA.isUserInteractionEnabled = true
        self.imageView_avatarOfTeamA.addGestureRecognizer(singleTapOfAvatarTeamA)
        
        Toolbox.removeBottomShadowOfNavigationBar(self.navigationController!.navigationBar)
        
        self.showActivityDetails()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "活动详情")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showActivityDetails() {
        // set up the avatar and name of team A
        Toolbox.loadAvatarImage(self.activity!.idOfA! , toImageView: self.imageView_avatarOfTeamA, avatarType: AvatarType.team)
        self.label_nameOfTeamA.text = self.activity!.nameOfA!
        
        if activity?.type == ActivityType.exercise.rawValue {    // activity is an exercise, therefore no team B existed
            self.imageView_avatarOfTeamB.isHidden = true
            self.label_nameOfTeamB.isHidden = true
            // put the avatar and name of team A in the horizontal center of the screen
            self.avatarTeamALeftMarginConstraint.constant = ScreenSize.width / 2 - self.imageView_avatarOfTeamA.frame.width / 2 - 13
        } else {    // activity is a match, set up the avatar and name of team B
            Toolbox.loadAvatarImage(self.activity!.idOfB, toImageView: self.imageView_avatarOfTeamB, avatarType: AvatarType.team)
            
            // add tap gesture event to imageView_avatar, attendees list for team B of the activity will show up when tapped
            let singleTapOfAvatarTeamB:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(VTUserActivityInfoTableViewController.showAttendeesOfTeamB))
            self.imageView_avatarOfTeamB.isUserInteractionEnabled = true
            self.imageView_avatarOfTeamB.addGestureRecognizer(singleTapOfAvatarTeamB)
            self.label_nameOfTeamB.text = self.activity!.nameOfB
        }
        
        // set up activity date and time
        self.label_date.text = self.activity!.date!
        self.label_time.text = self.activity!.time!
        // set up activity address
        self.label_address.text = self.activity!.place
        self.label_address.sizeToFit()
        
        // set up minimum number of attendees of this activity. NOTE: if the activity is an exercise, the minimum number of people does not exist
        if self.activity!.type == ActivityType.match.rawValue {
            self.label_minimumNumberOfAttendees.text = "\(self.activity!.minimumNumberOfPeople)"
        } else {
            self.label_minimumNumberOfAttendees.text = "-"
        }
        
        // set up activity status
        switch self.activity!.status! {
        case ActivityStatus.confirmingTeamAParticipants.rawValue:
            self.label_status.text = "确定参与人员中..."
        case ActivityStatus.waitingForAcceptanceFromCaptainOfTeamB.rawValue:
            self.label_status.text = "等待接受挑战中..."
        case ActivityStatus.rejectedByCaptainOfTeamB.rawValue:
            self.label_status.text = "比赛请求失败"
        case ActivityStatus.confirmingTeamBParticipants.rawValue:
            self.label_status.text = "确定参与人员中..."
        case ActivityStatus.finalized.rawValue:
            self.label_status.text = "即将进行"
        case ActivityStatus.done.rawValue:
            self.label_status.text = "已完成"
        case ActivityStatus.failedPublication.rawValue:
            self.label_status.text = "发起比赛失败"
        case ActivityStatus.ongoing.rawValue:
            self.label_status.text = "正在进行中"
        default:
            self.label_status.text = "未知"
        }
        
        // set up activity note
        self.textView_note.text = self.activity!.note
        // set up activity scores
        if self.activity?.scoreOfA != nil && self.activity?.scoreOfB != nil {
            self.label_scores.text = "\(self.activity!.scoreOfA!) : \(self.activity!.scoreOfB!)"
        }
    }
    
    func refreshActivityDetails() {
        let urlToGetActivityInfo  = URLGetActivityInfo + "?activityId=\(self.activity!.activityId!)"
        let connection = Toolbox.asyncHttpGetFromURL(urlToGetActivityInfo, delegate: self)
        if connection == nil {
            // inform the user that the connection failed
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        }
    }
    
    func showAttendeesOfTeamA() {
        self.tappedTeamId = self.activity!.idOfA!
        self.tappedTeamName = self.activity!.nameOfA!
        
        self.performSegue(withIdentifier: "showAttendeesSegue", sender: self)
    }
    
    func showAttendeesOfTeamB() {
        self.tappedTeamId = self.activity!.idOfB
        self.tappedTeamName = self.activity!.nameOfB
        
        self.performSegue(withIdentifier: "showAttendeesSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showAttendeesSegue" {
            let destinationViewController = segue.destination as! VTAttendeesTableViewController
            destinationViewController.teamId = self.tappedTeamId
            destinationViewController.teamName = self.tappedTeamName
            destinationViewController.activityId = self.activity!.activityId
        } else if segue.identifier == "activityAddressSegue" {
            let destinationViewController = segue.destination as! VTGroundInfoViewController
            let groundObject = Ground(data: [
                "latitude": "\(self.activity!.latitude)" as AnyObject,
                "longitude": "\(self.activity!.longitude)" as AnyObject,
                "address": "\(self.activity!.place!)" as AnyObject
            ])
            destinationViewController.groundObject = groundObject
        }
    }
    
    func connection(_ connection: NSURLConnection, didReceive data: Data) {
        self.responseData?.append(data)
    }
    
    func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        self.refreshControl?.endRefreshing()
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络超时")
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        self.refreshControl?.endRefreshing()
        let activityInfo = (try? JSONSerialization.jsonObject(with: self.responseData! as Data, options: .mutableLeaves)) as? [String: AnyObject]
        if activityInfo != nil {    // http request succeeded
            self.activity = Activity(data: activityInfo!)
            self.showActivityDetails()
        } else {    // http request failed with error
            let errorMessage:NSString = NSString(data: self.responseData! as Data, encoding: String.Encoding.utf8.rawValue)!
            Toolbox.showCustomAlertViewWithImage("unhappy", title: errorMessage as String)
        }
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    deinit {
        self.activity = nil
        self.tappedTeamId = nil
        self.tappedTeamName = nil
        self.responseData = nil
    }

}
