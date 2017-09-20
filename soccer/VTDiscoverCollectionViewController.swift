//
//  VTDiscoverCollectionViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/10/6.
//  Copyright © 2015年 VisionTech. All rights reserved.
//

import UIKit

private let reuseIdentifier = "discoverOptionCell"

class VTDiscoverCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, NSURLConnectionDataDelegate, NSURLConnectionDelegate, LocationServiceDelegate {
    
    enum SearchingType {
        case rankingOfTeams
        case rankingOfUsers
        case teams
        case users
        case matches
        case grounds
    }
    
    var HUD: MBProgressHUD?
    var responseData: NSMutableData? = NSMutableData()
    var locationService: LocationService?
    var currentUserCoordinate: CLLocationCoordinate2D?
    var currentlySearching: SearchingType?
    
    var totalNearbyTeams: Int?
    var nearbyTeams: [Team]? = [Team]()
    var totalNearbyGrounds: Int?
    var nearbyGrounds: [Ground]? = [Ground]()
    var totalNearbyUsers: Int?
    var nearbyUsers: [User]? = [User]()
    var totalNearbyMatches: Int?
    var nearbyMatches: [Activity]? = [Activity]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
         self.clearsSelectionOnViewWillAppear = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        Appearance.customizeNavigationBar(self, title: "发现")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        if self.nearbyTeams != nil {
            self.nearbyTeams?.removeAll()
            self.nearbyTeams = nil
        }
        self.totalNearbyTeams = nil
        
        if self.nearbyUsers != nil {
            self.nearbyUsers?.removeAll()
            self.nearbyUsers = nil
        }
        self.totalNearbyUsers = nil
        
        if self.nearbyMatches != nil {
            self.nearbyMatches?.removeAll()
            self.nearbyMatches = nil
        }
        self.totalNearbyMatches = nil
        
        if self.nearbyGrounds != nil {
            self.nearbyGrounds?.removeAll()
            self.nearbyGrounds = nil
        }
        self.totalNearbyGrounds = nil
    }
    
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 5
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        } else {
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        // set up the spacing/margin between collection cells
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        // set up insets/paddings inside the collection view cells
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if (indexPath as NSIndexPath).section == 0 {
            return CGSize(width: ScreenSize.width / 2, height: DiscoverOptionCellHeight)
        } else {
            return CGSize(width: ScreenSize.width, height: DiscoverOptionCellHeight)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        cell.backgroundColor = ColorBiege
        
        let icon = cell.contentView.viewWithTag(1) as? UIImageView
        let label = cell.contentView.viewWithTag(2) as? UILabel
        if (indexPath as NSIndexPath).section == 0 && (indexPath as NSIndexPath).item == 0 {
            icon?.image = UIImage(named: "team_ranking")
            label?.text = "球队排行榜"
            cell.contentView.frame.size.width = ScreenSize.width / 2
            cell.contentView.frame.size.height = DiscoverOptionCellHeight

            Appearance.setupViewBorder(cell.contentView, borderWidth: 1, borderColor: UIColor.white, hasTopBorder: true, hasLeftBorder: true, hasBottomBorder: true, hasRightBorder: true)
        } else if (indexPath as NSIndexPath).section == 0 && (indexPath as NSIndexPath).item == 1 {
            icon?.image = UIImage(named: "player_ranking")
            label?.text = "球员积分榜"
            cell.contentView.frame.size.width = ScreenSize.width / 2
            cell.contentView.frame.size.height = DiscoverOptionCellHeight

            Appearance.setupViewBorder(cell.contentView, borderWidth: 1, borderColor: UIColor.white, hasTopBorder: true, hasLeftBorder: true, hasBottomBorder: true, hasRightBorder: true)
        } else if (indexPath as NSIndexPath).section == 1 && (indexPath as NSIndexPath).item == 0 {
            cell.contentView.frame.size.width = ScreenSize.width
            cell.contentView.frame.size.height = DiscoverOptionCellHeight

            icon?.image = UIImage(named: "discover_team")
            label?.text = "加入球队"
            Appearance.setupViewBorder(cell.contentView, borderWidth: 1, borderColor: UIColor.white, hasTopBorder: true, hasLeftBorder: true, hasBottomBorder: true, hasRightBorder: true)
        } else if (indexPath as NSIndexPath).section == 2 && (indexPath as NSIndexPath).item == 0 {
            cell.contentView.frame.size.width = ScreenSize.width
            cell.contentView.frame.size.height = DiscoverOptionCellHeight

            icon?.image = UIImage(named: "discover_player")
            label?.text = "发现球员"
            Appearance.setupViewBorder(cell.contentView, borderWidth: 1, borderColor: UIColor.white, hasTopBorder: true, hasLeftBorder: true, hasBottomBorder: true, hasRightBorder: true)
        } else if (indexPath as NSIndexPath).section == 3 && (indexPath as NSIndexPath).item == 0 {
            cell.contentView.frame.size.width = ScreenSize.width
            cell.contentView.frame.size.height = DiscoverOptionCellHeight

            icon?.image = UIImage(named: "discover_match")
            label?.text = "附近比赛"
            Appearance.setupViewBorder(cell.contentView, borderWidth: 1, borderColor: UIColor.white, hasTopBorder: true, hasLeftBorder: true, hasBottomBorder: true, hasRightBorder: true)
        } else if (indexPath as NSIndexPath).section == 4 && (indexPath as NSIndexPath).item == 0 {
            cell.contentView.frame.size.width = ScreenSize.width
            cell.contentView.frame.size.height = DiscoverOptionCellHeight
            
            icon?.image = UIImage(named: "discover_stadium")
            label?.text = "附近球场"
            Appearance.setupViewBorder(cell.contentView, borderWidth: 1, borderColor: UIColor.white, hasTopBorder: true, hasLeftBorder: true, hasBottomBorder: true, hasRightBorder: true)
        }
        
        return cell
    }

    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).section == 0 {
            if (indexPath as NSIndexPath).item == 0 {    // get team points ranking
                self.currentlySearching = .rankingOfTeams
            } else if (indexPath as NSIndexPath).item == 1 { // get user points ranking
                self.currentlySearching = .rankingOfUsers
            }
        } else if (indexPath as NSIndexPath).section == 1 {
            self.currentlySearching = .teams
        } else if (indexPath as NSIndexPath).section == 2 {
            self.currentlySearching = .users
        } else if (indexPath as NSIndexPath).section == 3 {
            self.currentlySearching = .matches
        } else if (indexPath as NSIndexPath).section == 4 {
            self.currentlySearching = .grounds
        }

        if self.currentUserCoordinate == nil {
            self.locationService = LocationService()
            self.locationService?.delegate = self
            // just get user's current geocoordinates, no user address needed
            self.locationService?.shouldGetReverseGeoCode = false
            self.locationService?.launchLocationService()
        } else {
            self.startHttpRequestToQueryCorrespondingModels()
        }
    }
    
    func didStartToLocate() {
        // show loading spinner HUD to indicate that searching nearby teams is in progress
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
    
    // Finished getting user current geo coordinates, now should submit the request to server to find related models
    func didGetUserCoordinates(_ coordinate: CLLocationCoordinate2D) {
        self.currentUserCoordinate = coordinate
        self.startHttpRequestToQueryCorrespondingModels()
    }
    
    func startHttpRequestToQueryCorrespondingModels() {
        if self.locationService != nil {
            self.locationService?.delegate = nil
            self.locationService = nil
        }
        if self.HUD == nil {
            self.HUD = MBProgressHUD(view: self.navigationController?.view)
            self.navigationController?.view.addSubview(self.HUD!)
            self.HUD?.show(true)
        }
        var url = ""
        let generalQueryParams = "?latitude=\(self.currentUserCoordinate!.latitude)&longitude=\(self.currentUserCoordinate!.longitude)&page=1"
        // submit request to server with current user location coordinate to search for nearby whatevers
        if self.currentlySearching == .rankingOfTeams {
            self.HUD?.labelText = "获取球队排名中..."
            url = "\(URLGetNearbyTeamsForUser)\(generalQueryParams)&sortedByPoints=1"
        } else if self.currentlySearching == .rankingOfUsers {
            self.HUD?.labelText = "获取球员积分榜中..."
            url = "\(URLGetNearbyUsersForTeam)\(generalQueryParams)&sortedByPoints=1"
        } else if self.currentlySearching == .teams {
            self.HUD?.labelText = "搜索附近球队中..."
            url = "\(URLGetNearbyTeamsForUser)\(generalQueryParams)"
        } else if self.currentlySearching == .users {
            self.HUD?.labelText = "搜索附近球员中..."
            url = "\(URLGetNearbyUsersForTeam)\(generalQueryParams)"
        } else if self.currentlySearching == .matches {
            self.HUD?.labelText = "搜索附近比赛中..."
            url = "\(URLGetRecentMatchesNearAround)\(generalQueryParams)"
        } else if self.currentlySearching == .grounds {
            self.HUD?.labelText = "搜索附近场馆中..."
            url = "\(URLGetNearbyGrounds)\(generalQueryParams)"
        }
        let connection = Toolbox.asyncHttpGetFromURL(url, delegate: self)
        if connection == nil {
            self.HUD?.hide(true)
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        }
    }
    
    func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络超时")
        self.HUD?.hide(true)
        self.HUD = nil
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    func connection(_ connection: NSURLConnection, didReceive data: Data) {
        self.responseData?.append(data)
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        self.HUD?.hide(true)
        self.HUD = nil
        
        let responseDictionary = (try? JSONSerialization.jsonObject(with: self.responseData! as Data, options: .mutableLeaves)) as? [String: AnyObject]
        self.responseData = nil
        self.responseData = NSMutableData()

        if responseDictionary == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "查询失败")
            return
        }
        let total = responseDictionary!["total"]?.intValue
        let models = responseDictionary!["models"] as? [[String: AnyObject]]
        if total == 0 || models == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "没有找到相关结果")
            return
        }
        if self.currentlySearching == .teams || self.currentlySearching == .rankingOfTeams {
            self.totalNearbyTeams = total
            self.nearbyTeams?.removeAll()
            for teamModel in models! {
                let teamObject = Team(data: teamModel as [NSObject : AnyObject])
                self.nearbyTeams?.append(teamObject)
            }
            let currentUserOwnedTeam = responseDictionary!["currentUserOwnedTeam"] as? [AnyHashable: Any]
            if currentUserOwnedTeam != nil {
                // save current user owned team in database
                let userOwnedTeamObject = Team(data: currentUserOwnedTeam! as [NSObject : AnyObject])
                userOwnedTeamObject.saveOrUpdateTeamInDatabase()
            } else {
                Singleton_UserOwnedTeam.sharedInstance.resetUserOwnedTeamInfo()
            }
            // segue to nearby teams view controller in another storyboard
            let destinationStoryboard = UIStoryboard(name: StoryboardNames.NearbyTeams.rawValue, bundle: nil)
            let destinationViewController = destinationStoryboard.instantiateInitialViewController() as! VTNearbyTeamsTableViewController
            self.navigationController?.pushViewController(destinationViewController, animated: true)
            
            destinationViewController.userCoordinates = self.currentUserCoordinate!
            destinationViewController.totalNearbyTeams = self.totalNearbyTeams!
            destinationViewController.teamsList = self.nearbyTeams!
            if self.currentlySearching == .teams {
                destinationViewController.sortedType = .sortByDistance
            } else if self.currentlySearching == .rankingOfTeams {
                destinationViewController.sortedType = .sortByPoint
            }
            
        } else if self.currentlySearching == .users || self.currentlySearching == .rankingOfUsers {
            self.totalNearbyUsers = total
            self.nearbyUsers?.removeAll()
            for userModel in models! {
                let userObject = User(data: userModel as [NSObject : AnyObject])
                self.nearbyUsers?.append(userObject)
            }
            let currentUserOwnedTeam = responseDictionary!["currentUserOwnedTeam"] as? [AnyHashable: Any]
            if currentUserOwnedTeam != nil {
                // save current user owned team in database
                let userOwnedTeamObject = Team(data: currentUserOwnedTeam! as [NSObject : AnyObject])
                userOwnedTeamObject.saveOrUpdateTeamInDatabase()
            } else {
                Singleton_UserOwnedTeam.sharedInstance.resetUserOwnedTeamInfo()
            }
            // segue to nearby teams view controller in another storyboard
            let destinationStoryboard = UIStoryboard(name: StoryboardNames.NearbyUsers.rawValue, bundle: nil)
            let destinationViewController = destinationStoryboard.instantiateInitialViewController() as! VTNearbyUsersTableViewController
            self.navigationController?.pushViewController(destinationViewController, animated: true)
            destinationViewController.totalNearbyUsers = self.totalNearbyUsers!
            destinationViewController.usersList = self.nearbyUsers!
            destinationViewController.currentUserCoordinate = self.currentUserCoordinate!
            if self.currentlySearching == .users {
                destinationViewController.sortedType = .sortByDistance
            } else if self.currentlySearching == .rankingOfUsers {
                destinationViewController.sortedType = .sortByPoint
            }
        } else if self.currentlySearching == .matches {
            self.totalNearbyMatches = total
            self.nearbyMatches?.removeAll()
            for matchModel in models! {
                let matchObject = Activity(data: matchModel)
                self.nearbyMatches?.append(matchObject)
            }
            // segue to nearby matches view controller in another storyboard
            let destinationStoryboard = UIStoryboard(name: StoryboardNames.NearbyMatches.rawValue, bundle: nil)
            let destinationViewController = destinationStoryboard.instantiateInitialViewController() as! VTNearbyMatchesTableViewController
            self.navigationController?.pushViewController(destinationViewController, animated: true)
            destinationViewController.totalNearbyMatches = self.totalNearbyMatches!
            destinationViewController.matchesList = self.nearbyMatches!
            destinationViewController.userCoordinates = self.currentUserCoordinate!
        } else if self.currentlySearching == .grounds {
            self.totalNearbyGrounds = total
            self.nearbyGrounds?.removeAll()
            for groundModel in models! {
                let groundObject = Ground(data: groundModel)
                self.nearbyGrounds?.append(groundObject)
            }
            // segue to nearby matches view controller in another storyboard
            let destinationStoryboard = UIStoryboard(name: StoryboardNames.NearbyGrounds.rawValue, bundle: nil)
            let destinationViewController = destinationStoryboard.instantiateInitialViewController() as! VTNearbyGroundsTableViewController
            self.navigationController?.pushViewController(destinationViewController, animated: true)

            destinationViewController.totalNearbyGrounds = self.totalNearbyGrounds!
            destinationViewController.userCoordinates = self.currentUserCoordinate!
            destinationViewController.groundsList = self.nearbyGrounds!
        }
    }
    
    // setup collection view cell highligh and unhighlight effect when tapped
    override func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = self.collectionView!.cellForItem(at: indexPath)
        cell?.contentView.backgroundColor = UIColor.white
    }
    
    override func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let cell = self.collectionView!.cellForItem(at: indexPath)
        
        UIView.animate(withDuration: 0.3, animations: {
            cell?.contentView.backgroundColor = UIColor.clear
        })
    }
    
    deinit {
        self.locationService = nil
        self.HUD = nil
        self.responseData = nil
        self.currentUserCoordinate = nil
        self.currentlySearching = nil
        if self.nearbyTeams != nil {
            self.nearbyTeams?.removeAll()
            self.nearbyTeams = nil
        }
        self.totalNearbyTeams = nil
        
        if self.nearbyUsers != nil {
            self.nearbyUsers?.removeAll()
            self.nearbyUsers = nil
        }
        self.totalNearbyUsers = nil

        if self.nearbyMatches != nil {
            self.nearbyMatches?.removeAll()
            self.nearbyMatches = nil
        }
        self.totalNearbyMatches = nil
        
        if self.nearbyGrounds != nil {
            self.nearbyGrounds?.removeAll()
            self.nearbyGrounds = nil
        }
        self.totalNearbyGrounds = nil
    }

}
