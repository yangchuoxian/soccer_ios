//
//  VTRivalTeamsResultTableViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/7.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTRivalTeamsResultTableViewController: UITableViewController, NSURLConnectionDelegate, NSURLConnectionDataDelegate {
    
    var rowIndexOfLoadingMoreIndicator: Int?
    var rivalsListType: TeamResultsType?
    var rivalsList: [NSDictionary] = []
    var isLoadingNextPage: Bool = false
    var isLoadingFirstPage: Bool = false
    // pagination info
    var currentPage: Int = 1
    var totalEntries: Int?
    var searchKeyword: String?
    var teamId = ""
    var activityInfo: Dictionary<String, String>!
    var selectedCellIndex: Int = -1
    var responseData: NSMutableData? = NSMutableData()
    var HUD: MBProgressHUD?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // remove separators of cells for static table view
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        self.tableView.rowHeight = CustomTableRowHeight
        
        // retrieve current team id and location
        self.teamId = NSUserDefaults.standardUserDefaults().objectForKey("teamIdSelectedInTeamsList") as! String
        
        // retrieve activity info
        self.activityInfo = NSUserDefaults.standardUserDefaults().objectForKey("activityInfo") as! Dictionary<String, String>

        // Uncomment the following line to preserve selection between presentations
         self.clearsSelectionOnViewWillAppear = false
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "searchRivalsByName:", name: "launchSearchRivals", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "getNearbyRivals", name: "getNearbyRivals", object: nil)
    }
    
    func insertRowAtBottom() {
        self.isLoadingNextPage = true
        let delayInSeconds: Int64 = 2
        let popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * Int64(NSEC_PER_SEC))
        dispatch_after(popTime, dispatch_get_main_queue(), {
            [unowned self] in
            self.rowIndexOfLoadingMoreIndicator = self.tableView.numberOfRowsInSection(0)
            self.tableView.beginUpdates()
            self.rivalsList.append(NSDictionary())
            self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.rowIndexOfLoadingMoreIndicator!, inSection: 0)], withRowAnimation: .Automatic)
            self.tableView.endUpdates()
            
            self.currentPage++
            var httpRequestUrl:String = ""
            if self.rivalsListType == .SearchByName {
                httpRequestUrl = URLSearchRivalsForTeam + "?teamId=" + self.teamId + "&keyword=" + self.searchKeyword! + "&currentPage=\(Int(self.currentPage))"
                httpRequestUrl = httpRequestUrl + "&minimumNumberOfAttendees=" + self.activityInfo["minimumNumberOfAttendees"]!
            } else {
                httpRequestUrl = "\(URLGetNearbyRivalsForTeam)?teamId=\(self.teamId)&currentPage=\(Int(self.currentPage))"
                httpRequestUrl = httpRequestUrl + "&minimumNumberOfAttendees=" + self.activityInfo["minimumNumberOfAttendees"]!
            }
            
            if self.initiateHttpRequest(httpRequestUrl) {
                self.isLoadingNextPage = true
                self.tableView.reloadData()
            }
        })
    }
    
    func initiateHttpRequest(urlWithParameters:String) -> Bool {
        var isSucceeded:Bool = false
        
        let connection:NSURLConnection? = Toolbox.asyncHttpGetFromURL(urlWithParameters, delegate: self)
        if connection == nil {
            // inform the user that the connection failed
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
            return isSucceeded
        }
        isSucceeded = true
        return isSucceeded
    }
    
    func searchRivalsByName(notification: NSNotification) {
        // reset selected cell index since new rival list will be loaded
        self.selectedCellIndex = -1
        
        self.currentPage = 1
        self.searchKeyword = notification.object as? String
        var urlToSearchRivalsForTeam = URLSearchRivalsForTeam + "?teamId=" + self.teamId + "&keyword=" + self.searchKeyword!
        urlToSearchRivalsForTeam = urlToSearchRivalsForTeam + "&minimumNumberOfAttendees=" + self.activityInfo["minimumNumberOfAttendees"]! + "&currentPage=\(Int(self.currentPage))"
        
        if self.initiateHttpRequest(urlToSearchRivalsForTeam) {
            self.rivalsList = []
            self.isLoadingFirstPage = true
            // reload table to show activity indicator in table section header
            self.tableView.reloadData()
        }
    }
    
    func getNearbyRivals() {
        // reset selected cell index since new rival list will be loaded
        self.selectedCellIndex = -1
        
        self.currentPage = 1
        var urlToGetNearbyRivalsForTeam = "\(URLGetNearbyRivalsForTeam)?teamId=\(self.teamId)"
        urlToGetNearbyRivalsForTeam = urlToGetNearbyRivalsForTeam + "&minimumNumberOfAttendees=" + self.activityInfo["minimumNumberOfAttendees"]! + "&currentPage=\(Int(self.currentPage))"
        
        if self.initiateHttpRequest(urlToGetNearbyRivalsForTeam) {
            self.rivalsList = []
            self.isLoadingFirstPage = true
            // reload table to show activity indicator in table section header
            self.tableView.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.rivalsList.count
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return TableSectionHeaderHeight
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRectMake(0, 0, ScreenSize.width, TableSectionHeaderHeight))
        headerView.tintColor = ColorBackgroundGray
        
        if self.rivalsList.count > 0 {
            var rivalResultsTypeString:String = ""
            if self.rivalsListType == .SearchByName {
                rivalResultsTypeString = "搜索结果"
            } else {
                rivalResultsTypeString = "附近的球队"
            }
            headerView.addSubview(Appearance.setupTableSectionHeaderTitle(rivalResultsTypeString))
        }
        if self.isLoadingFirstPage == true {
            let activityIndicator:UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
            activityIndicator.frame.origin.x = ScreenSize.width / 2 - activityIndicator.frame.size.width / 2
            activityIndicator.frame.origin.y = TableSectionHeaderHeight / 2 - activityIndicator.frame.size.height / 2
            activityIndicator.startAnimating()
            headerView.addSubview(activityIndicator)
        }
        return headerView
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = self.tableView.dequeueReusableCellWithIdentifier("rivalTeamCell") as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: "rivalTeamCell")
        }
        
        let teamDictionary:NSDictionary = self.rivalsList[indexPath.row]
        
        if teamDictionary.count == 0 {  // this means that this cell is the load more cell
            return cell!
        }
        
        // set up team avatar image view
        let imageView_teamAvatar = cell?.contentView.viewWithTag(1) as! UIImageView
        imageView_teamAvatar.layer.cornerRadius = 2.0
        imageView_teamAvatar.layer.masksToBounds = true
        Toolbox.loadAvatarImage(teamDictionary.objectForKey("id") as! String, toImageView: imageView_teamAvatar, avatarType: AvatarType.Team)
        // set up label to display team name
        let label_teamName:UILabel = cell?.contentView.viewWithTag(2) as! UILabel
        label_teamName.text = teamDictionary.objectForKey("name") as? String
        // set up label to display the number of members of the team
        let label_numberOfMembers:UILabel = cell?.contentView.viewWithTag(3) as! UILabel
        let numberOfMembers = teamDictionary.objectForKey("numberOfMembers") as! Int
        label_numberOfMembers.text = "\(Int(numberOfMembers))人"
        // set up label to display match record of the tema
        let label_matchRecord:UILabel = cell?.contentView.viewWithTag(4) as! UILabel
        let numOfWins = teamDictionary.objectForKey("wins") as! Int
        let numOfLoses = teamDictionary.objectForKey("loses") as! Int
        let numOfTies = teamDictionary.objectForKey("ties") as! Int
        label_matchRecord.text = "\(Int(numOfWins))胜\(Int(numOfLoses))负\(Int(numOfTies))平"
        // set up label to display location of the team
        let label_location:UILabel = cell?.contentView.viewWithTag(5) as! UILabel
        label_location.text = teamDictionary.objectForKey("location") as? String
        // set up the imageView to indicate whether this team has been selected as the rival
        let imageView_signOfSelectedRival = cell?.contentView.viewWithTag(6) as! UIImageView
        if indexPath.row == self.selectedCellIndex {
            imageView_signOfSelectedRival.hidden = false
        } else {
            imageView_signOfSelectedRival.hidden = true
        }
        
        if (indexPath.row != (self.rivalsList.count - 1)) {   // if the cell is not the last row of the section, add a separatorLine
            let separatorLineView:UIView = UIView(frame: CGRectMake(15, 0, ScreenSize.width, 1))
            separatorLineView.backgroundColor = ColorBackgroundGray
            cell!.contentView.addSubview(separatorLineView)
        }
        
        return cell!
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // clears the table cell selection effect
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let teamDictionary:NSDictionary = self.rivalsList[indexPath.row]
        // send notification that rivals has been selected
        NSNotificationCenter.defaultCenter().postNotificationName("selectedRival", object: (teamDictionary.objectForKey("id") as! String))
        
        let originalSelectedCellIndex:Int = self.selectedCellIndex
        self.selectedCellIndex = indexPath.row
        
        self.tableView.beginUpdates()
        self.tableView.reloadRowsAtIndexPaths([
            NSIndexPath(forRow: originalSelectedCellIndex, inSection: 0),
            NSIndexPath(forRow: self.selectedCellIndex, inSection: 0)
            ], withRowAnimation: UITableViewRowAnimation.Automatic)
        self.tableView.endUpdates()
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        self.responseData?.appendData(data)
    }
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络超时")
        if self.isLoadingFirstPage == true {
            self.isLoadingFirstPage = false
            self.tableView.reloadData()
        }
        if self.isLoadingNextPage == true {
            self.isLoadingNextPage = false
            // stop pullToRefresh activity animation
            self.tableView.stopLoadMoreAnimation()
            
            // delete the row that's been added to hold the loading more activity indicator
            self.rivalsList.removeAtIndex(self.rowIndexOfLoadingMoreIndicator!)
            self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: self.rowIndexOfLoadingMoreIndicator!, inSection: 0)], withRowAnimation: .Automatic)

            self.tableView.reloadData()
        }
        
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        if self.isLoadingFirstPage == true {
            self.isLoadingFirstPage = false
            // if this is the first page of pagination, the table data list needs to be cleared before appending received paginated data
            self.rivalsList = []
        }
        if self.isLoadingNextPage == true {
            self.isLoadingNextPage = false
            // stop pullToRefresh activity animation
            self.tableView.stopLoadMoreAnimation()
            
            // loading has completed, delete the row that's been added to hold the loading more activity indicator
            self.rivalsList.removeAtIndex(self.rowIndexOfLoadingMoreIndicator!)
            self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: self.rowIndexOfLoadingMoreIndicator!, inSection: 0)], withRowAnimation: .Automatic)
        }
        
        let rivalsResultPaginatedInfo = (try? NSJSONSerialization.JSONObjectWithData(self.responseData!, options: .MutableLeaves)) as? [NSObject: AnyObject]
        if rivalsResultPaginatedInfo != nil {   // http request succeeded
            self.totalEntries = Int(rivalsResultPaginatedInfo!["total"]!.stringValue)
            if (rivalsResultPaginatedInfo!["resultType"] as! String) == "search" {
                self.rivalsListType = .SearchByName
            } else {
                self.rivalsListType = .NearbyTeams
            }
            
            let paginatedRivals = rivalsResultPaginatedInfo!["models"] as! NSArray
            
            for rivalDictionary:AnyObject in paginatedRivals {
                self.rivalsList.append(rivalDictionary as! NSDictionary)
            }
            if self.totalEntries <= self.rivalsList.count {
                // all entries loaded, remove the load more action handler
                self.tableView.removeLoadMoreActionHandler()
            } else {
                // add load more action handler, when pull up, animation hints loading more is in progress
                self.tableView.addLoadMoreActionHandler({
                    [unowned self] in
                    self.insertRowAtBottom()
                    }, progressImagesGifName: "loading_spinner.gif", loadingImagesGifName: "loading_spinner.gif", progressScrollThreshold: 60)
            }
            // no qualified rivals found or no nearby teams existed
            if self.totalEntries == 0 {
                Toolbox.showCustomAlertViewWithImage("unhappy", title: "没有找到合适的球队")
            }
        } else {    // http request failed with error message
            let errorMessage = NSString(data: self.responseData!, encoding: NSUTF8StringEncoding)!
            Toolbox.showCustomAlertViewWithImage("unhappy", title: errorMessage as String)
        }
        self.tableView.reloadData()
        
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    deinit {
        self.responseData = nil
        self.rowIndexOfLoadingMoreIndicator = nil
        self.rivalsListType = nil
        if self.rivalsList.count > 0 {
            self.rivalsList.removeAll(keepCapacity: false)
        }
        self.totalEntries = nil
        self.searchKeyword = nil
        self.activityInfo.removeAll(keepCapacity: false)
        self.activityInfo = nil
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
