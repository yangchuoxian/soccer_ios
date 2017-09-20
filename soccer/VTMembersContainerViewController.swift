//
//  VTMembersContainerViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/11.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTMembersContainerViewController: UIViewController, UIActionSheetDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate, LocationServiceDelegate {
    
    enum HttpRequest {
        case getScannedUserInfo
        case getNearbyUsersForTeam
    }
    
    @IBOutlet weak var view_addNewMemberButtonContainer: UIView!
    @IBOutlet weak var membersTableBottomConstraint: NSLayoutConstraint!
    
    var HUD: MBProgressHUD?
    var indexOfCurrentHttpRequest: HttpRequest?
    var locationService: LocationService?
    var nearbyUsers = [User]()
    var totalNearbyUsers: Int?
    var currentUserCoordinate: CLLocationCoordinate2D?
    var captainUserIdOfCurrentSelectedTeam: String?
    var QRCodeScannedValue: String?
    var teamId: String?
    var scannedUser: User?
    var responseData: NSMutableData? = NSMutableData()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController!.navigationBar.topItem!.title = ""
        
        // add right button in navigation bar programmatically
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "menu"), style: .bordered, target: self, action: #selector(UIViewController.presentLeftMenuViewController(_:)))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(VTMembersContainerViewController.goBackToTeamsTableView))

        self.teamId = UserDefaults.standard.string(forKey: "teamIdSelectedInTeamsList")
        //retrieve captain user id of current selected team
        self.captainUserIdOfCurrentSelectedTeam = Team.retrieveCaptainIdFromLocalDatabaseWithTeamId(self.teamId!)
        if Singleton_CurrentUser.sharedInstance.userId == self.captainUserIdOfCurrentSelectedTeam {
            self.membersTableBottomConstraint.constant = 60
            self.view_addNewMemberButtonContainer.isHidden = false
        } else {
            self.membersTableBottomConstraint.constant = 0
            self.view_addNewMemberButtonContainer.isHidden = true
        }
        // listen to teamCaptainChangedOnServer
        NotificationCenter.default.addObserver(self, selector: #selector(VTMembersContainerViewController.teamCaptainChanged(_:)), name: NSNotification.Name(rawValue: "teamCaptainChangedOnServer"), object: nil)
    }
    
    func goBackToTeamsTableView() {
        self.performSegue(withIdentifier: "unwindToTeamListSegue", sender: self)
    }
    
    func teamCaptainChanged(_ notification: Notification) {
        self.captainUserIdOfCurrentSelectedTeam = notification.object as? String
        if self.captainUserIdOfCurrentSelectedTeam == Singleton_CurrentUser.sharedInstance.userId {
            self.membersTableBottomConstraint.constant = 60
            self.view_addNewMemberButtonContainer.isHidden = false
        } else {
            self.membersTableBottomConstraint.constant = 0
            self.view_addNewMemberButtonContainer.isHidden = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Appearance.customizeNavigationBar(self, title: "球队成员")
        self.scannedUser = nil
        // if qr code scanning view controller has scanned a value and come back to this view controller,
        // we should navigate to the users search result view controller
        if Toolbox.isStringValueValid(self.QRCodeScannedValue) {
            // get user based on the scanned value which should be the string of user id
            let connection = Toolbox.asyncHttpGetFromURL(URLGetScannedUserForTeam + "?scannedUserId=\(self.QRCodeScannedValue!)&teamId=\(self.teamId!)", delegate: self)
            if connection == nil {
                // inform the user that the connection failed
                Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
            } else {
                self.indexOfCurrentHttpRequest = .getScannedUserInfo
                self.QRCodeScannedValue = nil
                self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: nil)
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if self.locationService != nil {
            self.locationService?.delegate = nil
            self.locationService = nil
        }
        if self.HUD != nil {
            self.HUD?.hide(true)
            self.HUD = nil
        }
    }
    
    @IBAction func showRecruitOptions(_ sender: AnyObject) {
        let searchNearbyUsers = "查找附近球员"
        let scanQRCodeOfUser = "扫描球员二维码"
        let cancelTitle = "取消"
        let actionSheet = UIActionSheet(
            title: nil,
            delegate: self,
            cancelButtonTitle: cancelTitle,
            destructiveButtonTitle: nil,
            otherButtonTitles: searchNearbyUsers, scanQRCodeOfUser
        )
        actionSheet.show(in: self.view)
    }
    
    func actionSheet(_ actionSheet: UIActionSheet, clickedButtonAt buttonIndex: Int) {
        actionSheet.dismiss(withClickedButtonIndex: 0, animated: true)
        if buttonIndex == 1 {     // search nearby users
            self.locationService = LocationService()
            self.locationService?.delegate = self
            self.locationService?.launchLocationService()
        } else if buttonIndex == 2 {  // scan user QR code
            // navigate to QR code scanning view controller
            self.performSegue(withIdentifier: "QRCodeScanSegue", sender: self)
        }
    }
    
    func didStartToLocate() {
        // show loading spinner HUD to indicate that searching nearby teams is in process
        self.HUD = MBProgressHUD(view: self.navigationController?.view)
        self.HUD?.labelText = "正在定位..."
        self.navigationController?.view.addSubview(self.HUD!)
        self.HUD?.show(true)
    }
    
    func didFailToLocateUser() {
        self.HUD?.hide(true)
        self.HUD = nil
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "定位失败")
    }
    
    func didFinishFindingLocationAndAddress(_ locationInfo: [AnyHashable: Any]) {
        let userLocation = locationInfo["locationObject"] as? BMKUserLocation
        self.currentUserCoordinate = userLocation?.location.coordinate
        self.HUD?.labelText = "搜索附近球员中..."
        
        self.locationService?.delegate = nil
        self.locationService = nil
        // submit request to server with current user location coordinate to search for nearby users
        self.submitRequestToSearchNearbyUsersWithCoordinate(userLocation!.location.coordinate)
        
    }
    
    func submitRequestToSearchNearbyUsersWithCoordinate(_ coordinate: CLLocationCoordinate2D) {
        // submit request to search nearby users after getting current user location coordinate
        let connection = Toolbox.asyncHttpGetFromURL(URLGetNearbyUsersForTeam + "?latitude=\(self.currentUserCoordinate!.latitude)&longitude=\(self.currentUserCoordinate!.longitude)&page=1&teamId=" + self.teamId!, delegate: self)
        if connection == nil {
            // inform the user that the connection failed
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            self.indexOfCurrentHttpRequest = .getNearbyUsersForTeam
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
        if self.indexOfCurrentHttpRequest == .getScannedUserInfo {
            let userInfoJSON = (try? JSONSerialization.jsonObject(with: self.responseData! as Data, options: .mutableLeaves)) as? [AnyHashable: Any]
            if userInfoJSON != nil {    // get scanned user info succeeded
                // the scanned user has to be a stranger, neither a team member or a invited user or an applied user
                self.scannedUser = User(data: userInfoJSON! as [NSObject : AnyObject])
                self.performSegue(withIdentifier: "scannedStrangerProfileSegue", sender: self)
            } else {    // failed with error message
                let responseStr = NSString(data: self.responseData! as Data, encoding:String.Encoding.utf8.rawValue)
                Toolbox.showCustomAlertViewWithImage("unhappy", title: responseStr as! String)
            }
        } else if self.indexOfCurrentHttpRequest == .getNearbyUsersForTeam {
            let nearbyUsersPaginatedInfo = (try? JSONSerialization.jsonObject(with: self.responseData! as Data, options: .mutableLeaves)) as? [AnyHashable: Any]
            if nearbyUsersPaginatedInfo != nil {    // http request succeeded
                let paginatedNearbyUsers = nearbyUsersPaginatedInfo!["models"] as! [AnyObject]
                self.totalNearbyUsers = (nearbyUsersPaginatedInfo!["total"]! as AnyObject).intValue
                if paginatedNearbyUsers.count == 0 {
                    Toolbox.showCustomAlertViewWithImage("unhappy", title: "没有找到附近球员")
                } else {
                    // dealloc self.nearbyUsers first before alloc'ing it again
                    if self.nearbyUsers.count > 0 {
                        self.nearbyUsers.removeAll(keepingCapacity: false)
                    }
                    // initialize each user dictionary received in array and add it to self.nearbyUsers
                    var nearbyUserObject: User
                    for nearbyUserDictionary in paginatedNearbyUsers {
                        nearbyUserObject = User(data: nearbyUserDictionary as! [AnyHashable: Any] as [NSObject : AnyObject])
                        self.nearbyUsers.append(nearbyUserObject)
                    }
                    self.performSegue(withIdentifier: "showNearbyUsersSegue", sender: self)
                }
            }
        }
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showNearbyUsersSegue" {
            let destinationViewController = segue.destination as! VTNearbyUsersTableViewController
            destinationViewController.totalNearbyUsers = self.totalNearbyUsers!
            destinationViewController.usersList = self.nearbyUsers
            destinationViewController.currentUserCoordinate = self.currentUserCoordinate!
            destinationViewController.sortedType = .sortByDistance
        } else if segue.identifier == "scannedStrangerProfileSegue" {
            let destinationViewController = segue.destination as! VTScannedOrSearchedUserProfileTableViewController
            destinationViewController.userObject = self.scannedUser
        }
    }
    
    @IBAction func unwindToMembersContainerView(_ segue: UIStoryboardSegue) {
    }
    
    deinit {
        self.HUD = nil
        self.indexOfCurrentHttpRequest = nil
        self.locationService = nil
        self.nearbyUsers.removeAll(keepingCapacity: false)
        self.totalNearbyUsers = nil
        self.currentUserCoordinate = nil
        self.captainUserIdOfCurrentSelectedTeam = nil
        self.QRCodeScannedValue = nil
        self.teamId = nil
        self.scannedUser = nil
        self.responseData = nil
    }
    
}
