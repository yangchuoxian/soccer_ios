//
//  VTTeamGeneralTableViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/21.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTTeamGeneralTableViewController: UITableViewController, UIAlertViewDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate {

    var teamId: String?
    var teamObject: Team?
    var isCurrentUserCaptainOfThisTeam: Bool?
    var quitOrDismissTeamAlertView: UIAlertView?
    var HUD: MBProgressHUD?
    var indexOfCurrentHttpRequest: HttpRequestIndex?
    var responseData: NSMutableData? = NSMutableData()
    
    @IBOutlet weak var imageView_teamAvatar: UIImageView!
    @IBOutlet weak var label_createTime: UILabel!
    @IBOutlet weak var label_location: UILabel!
    @IBOutlet weak var label_numberOfPoints: UILabel!
    @IBOutlet weak var label_wins: UILabel!
    @IBOutlet weak var label_loses: UILabel!
    @IBOutlet weak var label_ties: UILabel!
    @IBOutlet weak var button_teamName: UIButton!
    @IBOutlet weak var imageView_locationDetailSign: UIImageView!
    @IBOutlet weak var imageView_homeCourtSign: UIImageView!
    @IBOutlet weak var imageView_introDetailSign: UIImageView!
    @IBOutlet weak var textView_teamIntroduction: UITextView!
    @IBOutlet weak var label_quitOrDismissTeam: UILabel!
    @IBOutlet weak var label_homeCourt: UILabel!
    @IBOutlet weak var switch_isRecruiting: UISwitch!
    
    @IBOutlet weak var view_followersBackground: UIView!
    @IBOutlet weak var view_winsBackground: UIView!
    @IBOutlet weak var view_losesBackground: UIView!
    @IBOutlet weak var view_tiesBackground: UIView!
    
    enum HttpRequestIndex {
        case dismissOrQuitTeam
        case changeRecruitingStatus
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = true

        Appearance.customizeAvatarImage(self.imageView_teamAvatar)
        self.navigationController!.navigationBar.topItem!.title = ""
        
        Toolbox.removeBottomShadowOfNavigationBar(self.navigationController!.navigationBar)
        
        // add right button in navigation bar programmatically
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "menu"), style: .bordered, target: self, action: #selector(UIViewController.presentLeftMenuViewController(_:)))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(VTTeamGeneralTableViewController.goBackToTeamsTableView))
        
        // make team introduction textView not editable
        self.textView_teamIntroduction.isEditable = false
        
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
 
        self.teamId = UserDefaults.standard.string(forKey: "teamIdSelectedInTeamsList")
        
        self.loadTeamInfoFromDatabase()
        
        // listen to teamRecordSavedOrUpdated message and handles it by updating team info in current view controller
        NotificationCenter.default.addObserver(self, selector: #selector(VTTeamGeneralTableViewController.showUpdatedTeamInfo), name: NSNotification.Name(rawValue: "teamRecordSavedOrUpdated"), object: nil)
        
        if self.isCurrentUserCaptainOfThisTeam! == true {    // if current user is captain of this team, he/she can change team avatar, otherwise, he/she CANNOT
            // add tap gesture event to image_avatar, when image_avatar is tapped, user will be provided with options to whether select image or shoot a photo as avatar to upload
            let singleTap:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(VTTeamGeneralTableViewController.avatarImageTapped))
            singleTap.numberOfTapsRequired = 1
            self.imageView_teamAvatar.isUserInteractionEnabled = true
            self.imageView_teamAvatar.addGestureRecognizer(singleTap)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "球队详情")
    }
    
    func goBackToTeamsTableView() {
        self.performSegue(withIdentifier: "unwindToTeamListSegue", sender: self)
    }
    
    func avatarImageTapped() {
        self.performSegue(withIdentifier: "changeTeamAvatarSegue", sender: self)
    }
    
    func showUpdatedTeamInfo() {
        Toolbox.showCustomAlertViewWithImage("checkmark", title: "球队信息更新成功")
        self.loadTeamInfoFromDatabase()
    }
    
    func loadTeamInfoFromDatabase() {
        // get team info from local database
        let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        let teams = dbManager?.loadData(fromDB: "select * from teams where teamId=?", parameters: [self.teamId!])
        if (teams?.count)! > 0 {
            // asynchronously load team avatar image
            Toolbox.loadAvatarImage(self.teamId!, toImageView: self.imageView_teamAvatar, avatarType: AvatarType.team)
            // show team info
            self.teamObject = Team.formatDatabaseRecordToTeamFormat(teams[0] as! [AnyObject])

            let currentUser = Singleton_CurrentUser.sharedInstance
            if self.teamObject?.captainUserId == currentUser.userId {   // current user is captain of this team
                self.isCurrentUserCaptainOfThisTeam = true
            } else {
                self.isCurrentUserCaptainOfThisTeam = false
            }
            self.label_createTime.text = self.teamObject?.createdAt
            self.label_location.text = self.teamObject?.location
            self.button_teamName.setTitle(self.teamObject?.teamName, for: UIControlState())
            if Toolbox.isStringValueValid(self.teamObject?.homeCourt) {
                if self.teamObject?.homeCourt != "EMPTY" {
                    self.label_homeCourt.text = self.teamObject?.homeCourt
                }
            }
            if self.isCurrentUserCaptainOfThisTeam == false {   // current user is NOT captain of this team, thus he/she has no right to change team name
                self.button_teamName.setImage(nil, for: UIControlState())
                self.button_teamName.isEnabled = false
            }
            self.textView_teamIntroduction.text = self.teamObject?.introduction
            self.label_numberOfPoints.text = String(self.teamObject!.points)
            self.label_wins.text = String(self.teamObject!.wins)
            self.label_loses.text = String(self.teamObject!.loses)
            self.label_ties.text = String(self.teamObject!.ties)
            if self.teamObject?.isRecruiting == RecruitStatus.IsRecruiting.rawValue {
                self.switch_isRecruiting.setOn(true, animated: false)
            } else {
                self.switch_isRecruiting.setOn(false, animated: false)
            }
        } else {    // no team found with such teamId
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "没有找到球队")
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // access statically created table cells
        let cell:UITableViewCell? = super.tableView(tableView, cellForRowAt: indexPath)
        // make cells in the first section non-selectable
        if (indexPath as NSIndexPath).section == 0 {
            cell?.selectionStyle = .none
        } else if (indexPath as NSIndexPath).section == 1 {
            if (indexPath as NSIndexPath).row == 0 {
                cell?.selectionStyle = .none
            } else if (indexPath as NSIndexPath).row == 1 {  // the cell of team location
                // only team captain can make change to team location
                if self.isCurrentUserCaptainOfThisTeam! == false {
                    self.imageView_locationDetailSign.isHidden = true
                    cell?.selectionStyle = .none
                }
            } else if (indexPath as NSIndexPath).row == 2 {  // the cell of team home court
                // only team captain can make change to team home court
                // for non captain members, he/she can select home court row to see home court address showing in a mapview
                if !Toolbox.isStringValueValid(self.teamObject?.homeCourt) {
                    // if the team home court is NOT set up yet, the non captain member still CANNOT see the home court in map view
                    self.imageView_homeCourtSign.isHidden = true
                    cell?.selectionStyle = .none
                }
            } else if (indexPath as NSIndexPath).row == 3 {
                if self.isCurrentUserCaptainOfThisTeam! == false {
                    self.switch_isRecruiting.isEnabled = false
                }
                cell?.selectionStyle = .none
            } else if (indexPath as NSIndexPath).row == 4 {  // the cell of team introduction
                // only team captain can make change to team introduction
                if self.isCurrentUserCaptainOfThisTeam! == false {
                    self.imageView_introDetailSign.isHidden = true
                    cell?.selectionStyle = .none
                }
            }
            // add a separatorLine for each row/cell in the second section
            let separatorLineView = UIView(frame: CGRect(x: 15, y: 0, width: ScreenSize.width, height: 1))
            separatorLineView.backgroundColor = ColorBackgroundGray
            cell?.contentView.addSubview(separatorLineView)
        } else if (indexPath as NSIndexPath).section == 2 {
            // if current user is captain of this team, button title should be "解散球队"
            // otherwise, button title is by default "退出球队"
            if self.isCurrentUserCaptainOfThisTeam! == true {
                self.label_quitOrDismissTeam.text = "解散球队"
            }
        }
        
        return cell!
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return TableSectionFooterHeight
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView:UIView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: 70))
        
        return footerView
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        // Only team captain is allowed to change team info
        if (indexPath as NSIndexPath).section == 1 {
            if (indexPath as NSIndexPath).row == 1 && self.isCurrentUserCaptainOfThisTeam! == true {
                // change team location cell tapped, only team captain can change team location
                self.performSegue(withIdentifier: "changeTeamLocationSegue", sender: self)
            } else if (indexPath as NSIndexPath).row == 2 {  // change or view team home court address
                if self.isCurrentUserCaptainOfThisTeam! == true {   // team captain can change home court address
                    self.performSegue(withIdentifier: "changeTeamHomeCourtSegue", sender: self)
                } else {    // non captain member can check home court address in map view but CANNOT change it
                    if Toolbox.isStringValueValid(self.teamObject?.homeCourt) {
                        // if the home court is set up, non captain member is allowed to see it in mapView
                        self.performSegue(withIdentifier: "homeCourtAddressSegue", sender: self)
                    }
                }
            } else if (indexPath as NSIndexPath).row == 3 && self.isCurrentUserCaptainOfThisTeam! == true {  // change team recruiting status
            } else if (indexPath as NSIndexPath).row == 4 && self.isCurrentUserCaptainOfThisTeam! == true {  // change team introduction
                self.performSegue(withIdentifier: "teamIntroductionSegue", sender: self)
            }
        } else if (indexPath as NSIndexPath).section == 2 {
            // quit or dismiss team cell tapped, remove the cell selection style effect
            self.tableView.deselectRow(at: indexPath, animated: true)
            self.quitOrDismissCurrentTeam()
        }
    }
    
    @IBAction func toggleRecruitingStatus(_ sender: AnyObject) {
        var isRecruiting = RecruitStatus.NotRecruiting.rawValue // default recruiting string set to not recruiting
        if self.switch_isRecruiting.isOn == true {    // recruiting switch set to is recruiting status
            isRecruiting = RecruitStatus.IsRecruiting.rawValue
        }
        let connection = Toolbox.asyncHttpPostToURL(URLUpdateTeamRecruitingStatus, parameters: "teamId=\(self.teamId!)&isRecruiting=\(isRecruiting)", delegate: self)
        if connection == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            self.indexOfCurrentHttpRequest = .changeRecruitingStatus
            self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "changeTeamNameSegue" {
            let destinationViewController = segue.destination as! VTUpdateTeamNameViewController
            destinationViewController.teamName = self.teamObject?.teamName
        } else if segue.identifier == "changeTeamHomeCourtSegue" {
            let destinationViewController = segue.destination as! VTUpdateTeamHomeCourtViewController
            destinationViewController.homeCourt = self.teamObject?.homeCourt
            destinationViewController.teamLocation = self.teamObject?.location
            destinationViewController.latitude = self.teamObject?.latitude
            destinationViewController.longitude = self.teamObject?.longitude
        } else if segue.identifier == "homeCourtAddressSegue" {
            let destinationViewController = segue.destination as! VTGroundInfoViewController
            let groundObject = Ground(data: [
                "latitude": "\(self.teamObject!.latitude)" as AnyObject,
                "longitude": "\(self.teamObject!.longitude)" as AnyObject,
                "address": "\(self.teamObject!.homeCourt)" as AnyObject
            ])
            destinationViewController.groundObject = groundObject
        } else if segue.identifier == "teamIntroductionSegue" {
            let destinationViewController = segue.destination as! VTUpdateTeamIntroductionViewController
            destinationViewController.introduction = self.teamObject?.introduction
        }
    }
    
    func quitOrDismissCurrentTeam() {
        if self.isCurrentUserCaptainOfThisTeam! == true {   // current logged in user is the captain of this team, now dismiss/delete this team
            self.quitOrDismissTeamAlertView = UIAlertView(title: "确定解散球队", message: "是否确定解散球队吗？", delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "确定")
            self.quitOrDismissTeamAlertView?.show()
            self.quitOrDismissTeamAlertView?.delegate = self
        } else {    // current logged in user is just a member of this team, now quit this team
            self.quitOrDismissTeamAlertView = UIAlertView(title: "确定退出球队", message: "是否确定退出球队吗？", delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "确定")
            self.quitOrDismissTeamAlertView?.show()
            self.quitOrDismissTeamAlertView?.delegate = self
        }
    }
    
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        if buttonIndex == 1 {   // establish button clicked, execute the action to dismiss team or quit team
            var postDataParameters:String?
            var urlToPostRequestTo:String?
            if self.isCurrentUserCaptainOfThisTeam! == true {   // current user is captain, dismiss team
                // convert team id to array then a json string since server accepts array with team ids as http request parameters
                let teamIdJSONData = try! JSONSerialization.data(withJSONObject: [self.teamId!], options: .prettyPrinted)
                let teamIDJSONString = NSString(data: teamIdJSONData, encoding: String.Encoding.utf8.rawValue)!
                
                postDataParameters = "ids=" + (teamIDJSONString as String)
                urlToPostRequestTo = URLDismissTeam
            } else {    // current user is just a member NOT a captain, now quit team
                let currentUser = Singleton_CurrentUser.sharedInstance
                postDataParameters = "userId=\(currentUser.userId!)&teamId=\(self.teamId!)"
                urlToPostRequestTo = URLQuitTeam
            }
            
            let connection = Toolbox.asyncHttpPostToURL(urlToPostRequestTo!, parameters: postDataParameters!, delegate: self)
            if connection == nil {
                Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
            } else {
                self.indexOfCurrentHttpRequest = .dismissOrQuitTeam
                self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: nil)
            }
        }
    }
    
    func connection(_ connection: NSURLConnection, didReceive data: Data) {
        self.responseData?.append(data)
    }
    
    func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        self.HUD?.hide(true)
        self.HUD = nil
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络超时")
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        self.HUD?.hide(true)
        self.HUD = nil
        let responseStr = NSString(data: self.responseData! as Data, encoding: String.Encoding.utf8.rawValue)!
        
        if self.indexOfCurrentHttpRequest == .dismissOrQuitTeam {
            if responseStr == "OK" {    // dismiss or quit team succeeded
                var quitOrDismissTeamNotificationDictionary: [AnyHashable: Any]?
                if self.isCurrentUserCaptainOfThisTeam! == true {   // dismiss team succeeded
                    quitOrDismissTeamNotificationDictionary = ["reasonUserNoLongerBelongsToTeam": "dismiss", "teamId": self.teamId!]
                } else {    // quit team succeeded
                    quitOrDismissTeamNotificationDictionary = ["reasonUserNoLongerBelongsToTeam": "quit", "teamId": self.teamId!]
                }
                
                // unwind navigation controller to the previous view controller
                // when unwind to the teams table view, need to delete the table cell that corresponds to the deleted/quitted team
                // remove corresponding team for current user in local database
                Team.deleteTeamsInLocalDatabaseForCurrentUser([self.teamId!])
                NotificationCenter.default.post(
                    name: Notification.Name(rawValue: "userQuittedOrDismissedTeam"), object: quitOrDismissTeamNotificationDictionary)
                self.performSegue(withIdentifier: "unwindToTeamListSegue", sender: self)
            } else {    // dismiss or quit team failed with error message
                Toolbox.showCustomAlertViewWithImage("unhappy", title: responseStr as String)
            }
        } else if self.indexOfCurrentHttpRequest == .changeRecruitingStatus {
            if responseStr == "OK" {    // update team recruiting status  http request succeeded, now update local database
                var updatedRecruitingStatus = RecruitStatus.NotRecruiting.rawValue
                if self.switch_isRecruiting.isOn == true {
                    updatedRecruitingStatus = RecruitStatus.IsRecruiting.rawValue
                }
                let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
                dbManager?.modifyData(inDB: "update teams set isRecruiting=? where teamId=?", parameters: [updatedRecruitingStatus, self.teamId!])
            } else {    // update recruiting status failed with error message
                Toolbox.showCustomAlertViewWithImage("unhappy", title: responseStr as String)
            }
        }
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    deinit {
        self.isCurrentUserCaptainOfThisTeam = nil
        self.responseData = nil
        self.teamId = nil
        self.teamObject = nil
        if self.imageView_teamAvatar != nil {
            self.imageView_teamAvatar.image = nil
        }
        if self.quitOrDismissTeamAlertView != nil {
            self.quitOrDismissTeamAlertView?.delegate = nil
            self.quitOrDismissTeamAlertView = nil
        }
        self.indexOfCurrentHttpRequest = nil
        self.HUD = nil
        NotificationCenter.default.removeObserver(self)
    }

}
