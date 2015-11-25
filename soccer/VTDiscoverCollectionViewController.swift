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
        case RankingOfTeams
        case RankingOfUsers
        case Teams
        case Users
        case Matches
        case Grounds
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
    
    override func viewWillAppear(animated: Bool) {
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

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 5
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        } else {
            return 1
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        // set up the spacing/margin between collection cells
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        // set up insets/paddings inside the collection view cells
        return UIEdgeInsetsZero
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        if indexPath.section == 0 {
            return CGSizeMake(ScreenSize.width / 2, DiscoverOptionCellHeight)
        } else {
            return CGSizeMake(ScreenSize.width, DiscoverOptionCellHeight)
        }
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath)
        cell.backgroundColor = ColorBiege
        
        let icon = cell.contentView.viewWithTag(1) as? UIImageView
        let label = cell.contentView.viewWithTag(2) as? UILabel
        if indexPath.section == 0 && indexPath.item == 0 {
            icon?.image = UIImage(named: "team_ranking")
            label?.text = "球队排行榜"
            cell.contentView.frame.size.width = ScreenSize.width / 2
            cell.contentView.frame.size.height = DiscoverOptionCellHeight

            Appearance.setupViewBorder(cell.contentView, borderWidth: 1, borderColor: UIColor.whiteColor(), hasTopBorder: true, hasLeftBorder: true, hasBottomBorder: true, hasRightBorder: true)
        } else if indexPath.section == 0 && indexPath.item == 1 {
            icon?.image = UIImage(named: "player_ranking")
            label?.text = "球员积分榜"
            cell.contentView.frame.size.width = ScreenSize.width / 2
            cell.contentView.frame.size.height = DiscoverOptionCellHeight

            Appearance.setupViewBorder(cell.contentView, borderWidth: 1, borderColor: UIColor.whiteColor(), hasTopBorder: true, hasLeftBorder: true, hasBottomBorder: true, hasRightBorder: true)
        } else if indexPath.section == 1 && indexPath.item == 0 {
            cell.contentView.frame.size.width = ScreenSize.width
            cell.contentView.frame.size.height = DiscoverOptionCellHeight

            icon?.image = UIImage(named: "discover_team")
            label?.text = "加入球队"
            Appearance.setupViewBorder(cell.contentView, borderWidth: 1, borderColor: UIColor.whiteColor(), hasTopBorder: true, hasLeftBorder: true, hasBottomBorder: true, hasRightBorder: true)
        } else if indexPath.section == 2 && indexPath.item == 0 {
            cell.contentView.frame.size.width = ScreenSize.width
            cell.contentView.frame.size.height = DiscoverOptionCellHeight

            icon?.image = UIImage(named: "discover_player")
            label?.text = "发现球员"
            Appearance.setupViewBorder(cell.contentView, borderWidth: 1, borderColor: UIColor.whiteColor(), hasTopBorder: true, hasLeftBorder: true, hasBottomBorder: true, hasRightBorder: true)
        } else if indexPath.section == 3 && indexPath.item == 0 {
            cell.contentView.frame.size.width = ScreenSize.width
            cell.contentView.frame.size.height = DiscoverOptionCellHeight

            icon?.image = UIImage(named: "discover_match")
            label?.text = "附近比赛"
            Appearance.setupViewBorder(cell.contentView, borderWidth: 1, borderColor: UIColor.whiteColor(), hasTopBorder: true, hasLeftBorder: true, hasBottomBorder: true, hasRightBorder: true)
        } else if indexPath.section == 4 && indexPath.item == 0 {
            cell.contentView.frame.size.width = ScreenSize.width
            cell.contentView.frame.size.height = DiscoverOptionCellHeight
            
            icon?.image = UIImage(named: "discover_stadium")
            label?.text = "附近球场"
            Appearance.setupViewBorder(cell.contentView, borderWidth: 1, borderColor: UIColor.whiteColor(), hasTopBorder: true, hasLeftBorder: true, hasBottomBorder: true, hasRightBorder: true)
        }
        
        return cell
    }

    // MARK: UICollectionViewDelegate
    
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            if indexPath.item == 0 {    // get team points ranking
                self.currentlySearching = .RankingOfTeams
            } else if indexPath.item == 1 { // get user points ranking
                self.currentlySearching = .RankingOfUsers
            }
        } else if indexPath.section == 1 {
            self.currentlySearching = .Teams
        } else if indexPath.section == 2 {
            self.currentlySearching = .Users
        } else if indexPath.section == 3 {
            self.currentlySearching = .Matches
        } else if indexPath.section == 4 {
            self.currentlySearching = .Grounds
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
    func didGetUserCoordinates(coordinate: CLLocationCoordinate2D) {
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
        if self.currentlySearching == .RankingOfTeams {
            self.HUD?.labelText = "获取球队排名中..."
            url = "\(URLGetNearbyTeamsForUser)\(generalQueryParams)&sortedByPoints=1"
        } else if self.currentlySearching == .RankingOfUsers {
            self.HUD?.labelText = "获取球员积分榜中..."
            url = "\(URLGetNearbyUsersForTeam)\(generalQueryParams)&sortedByPoints=1"
        } else if self.currentlySearching == .Teams {
            self.HUD?.labelText = "搜索附近球队中..."
            url = "\(URLGetNearbyTeamsForUser)\(generalQueryParams)"
        } else if self.currentlySearching == .Users {
            self.HUD?.labelText = "搜索附近球员中..."
            url = "\(URLGetNearbyUsersForTeam)\(generalQueryParams)"
        } else if self.currentlySearching == .Matches {
            self.HUD?.labelText = "搜索附近比赛中..."
            url = "\(URLGetRecentMatchesNearAround)\(generalQueryParams)"
        } else if self.currentlySearching == .Grounds {
            self.HUD?.labelText = "搜索附近场馆中..."
            url = "\(URLGetNearbyGrounds)\(generalQueryParams)"
        }
        let connection = Toolbox.asyncHttpGetFromURL(url, delegate: self)
        if connection == nil {
            self.HUD?.hide(true)
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        }
    }
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络超时")
        self.HUD?.hide(true)
        self.HUD = nil
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        self.responseData?.appendData(data)
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        self.HUD?.hide(true)
        self.HUD = nil
        
        let responseDictionary = (try? NSJSONSerialization.JSONObjectWithData(self.responseData!, options: .MutableLeaves)) as? [String: AnyObject]
        self.responseData = nil
        self.responseData = NSMutableData()

        if responseDictionary == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "查询失败")
            return
        }
        let total = responseDictionary!["total"]?.integerValue
        let models = responseDictionary!["models"] as? [[String: AnyObject]]
        if total == 0 || models == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "没有找到相关结果")
            return
        }
        if self.currentlySearching == .Teams || self.currentlySearching == .RankingOfTeams {
            self.totalNearbyTeams = total
            self.nearbyTeams?.removeAll()
            for teamModel in models! {
                let teamObject = Team(data: teamModel)
                self.nearbyTeams?.append(teamObject)
            }
            let currentUserOwnedTeam = responseDictionary!["currentUserOwnedTeam"] as? [NSObject: AnyObject]
            if currentUserOwnedTeam != nil {
                // save current user owned team in database
                let userOwnedTeamObject = Team(data: currentUserOwnedTeam!)
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
            if self.currentlySearching == .Teams {
                destinationViewController.sortedType = .SortByDistance
            } else if self.currentlySearching == .RankingOfTeams {
                destinationViewController.sortedType = .SortByPoint
            }
            
        } else if self.currentlySearching == .Users || self.currentlySearching == .RankingOfUsers {
            self.totalNearbyUsers = total
            self.nearbyUsers?.removeAll()
            for userModel in models! {
                let userObject = User(data: userModel)
                self.nearbyUsers?.append(userObject)
            }
            let currentUserOwnedTeam = responseDictionary!["currentUserOwnedTeam"] as? [NSObject: AnyObject]
            if currentUserOwnedTeam != nil {
                // save current user owned team in database
                let userOwnedTeamObject = Team(data: currentUserOwnedTeam!)
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
            if self.currentlySearching == .Users {
                destinationViewController.sortedType = .SortByDistance
            } else if self.currentlySearching == .RankingOfUsers {
                destinationViewController.sortedType = .SortByPoint
            }
        } else if self.currentlySearching == .Matches {
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
        } else if self.currentlySearching == .Grounds {
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
    override func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
        let cell = self.collectionView!.cellForItemAtIndexPath(indexPath)
        cell?.contentView.backgroundColor = UIColor.whiteColor()
    }
    
    override func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
        let cell = self.collectionView!.cellForItemAtIndexPath(indexPath)
        
        UIView.animateWithDuration(0.3, animations: {
            cell?.contentView.backgroundColor = UIColor.clearColor()
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
