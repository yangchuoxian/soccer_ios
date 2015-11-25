//
//  VTTeamSearchResultsTableViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/20.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTTeamSearchResultsTableViewController: UITableViewController, NSURLConnectionDataDelegate, NSURLConnectionDelegate {
    
    var teamSearchResults = [Team]()
    var numberOfTotalResults: Int = 0
    var userCoordinates: CLLocationCoordinate2D?
    var searchTeamKeyword: String?
    var isLoadingNextPage = false
    var currentPage = 1
    var selectedTeam: Team?
    var responseData: NSMutableData? = NSMutableData()
    var resultsType: TeamResultsType?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.isLoadingNextPage = false
        
        self.setTableFooterView()
        self.tableView.rowHeight = CustomTableRowHeight
        self.clearsSelectionOnViewWillAppear = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.resultsType == .SearchByName {
            Appearance.customizeNavigationBar(self, title: "搜索球队结果")
        } else {
            Appearance.customizeNavigationBar(self, title: "附近球队")
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.teamSearchResults.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = self.tableView.dequeueReusableCellWithIdentifier("searchedTeamCell") as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: "searchedTeamCell")
        }
        let teamInCurrentRow = self.teamSearchResults[indexPath.row]
        
        // set up team avatar image view
        let imageView_avatar = cell?.contentView.viewWithTag(1) as! UIImageView
        imageView_avatar.layer.cornerRadius = 2.0
        imageView_avatar.layer.masksToBounds = true
        // load avatar image asynchronously
        Toolbox.loadAvatarImage(teamInCurrentRow.teamId, toImageView: imageView_avatar, avatarType: AvatarType.Team)
        
        // set up label to display team name
        let label_teamName = cell?.contentView.viewWithTag(2) as! UILabel
        label_teamName.text = teamInCurrentRow.teamName
        // set up label to display the number of members in this team
        let label_numberOfMembers = cell?.contentView.viewWithTag(3) as! UILabel
        label_numberOfMembers.text = "\(Int(teamInCurrentRow.numberOfMembers))人"
        // set up the distance label
        let label_distance = cell?.contentView.viewWithTag(4) as! UILabel
        if self.resultsType == .SearchByName {
            label_distance.hidden = true
        } else {
            label_distance.text = "\(teamInCurrentRow.distanceToCurrentUser) km"
        }
        
        return cell!
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.selectedTeam = self.teamSearchResults[indexPath.row]
        self.performSegueWithIdentifier("teamBriefIntroSegue", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "teamBriefIntroSegue" {
            let destinationViewController = segue.destinationViewController as! VTTeamBriefIntroTableViewController
            destinationViewController.teamObject = self.selectedTeam
            destinationViewController.hasUserAlreadyAppliedThisTeam = false
            destinationViewController.teamInteractionOption = .SendApplication
        }
    }
    
    func getNextPageOfTeamResults() {
        // submit request to get next page of team results
        var urlToGetNextPageOfTeamResults: String
        if self.resultsType == .NearbyTeams {
            urlToGetNextPageOfTeamResults = "\(URLGetNearbyTeamsForUser)?latitude=\(self.userCoordinates!.latitude)&longitude=\(self.userCoordinates!.longitude)&page=\(self.currentPage + 1)"
        } else {    // team results are searched by team name
            urlToGetNextPageOfTeamResults = "\(URLSearchTeamsForUser)?keyword=\(self.searchTeamKeyword!)&page=\(self.currentPage + 1)"
        }
        
        let connection = Toolbox.asyncHttpGetFromURL(urlToGetNextPageOfTeamResults, delegate: self)
        if connection == nil {
            // inform the user that the connection failed
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            self.isLoadingNextPage = true
            // set tableView footer to replace next page button with an activity indicator
            self.setTableFooterView()
        }
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        self.responseData?.appendData(data)
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        let responseDictionary = (try? NSJSONSerialization.JSONObjectWithData(self.responseData!, options: .MutableLeaves)) as? [NSObject: AnyObject]
        if responseDictionary != nil {  // successfully loaded next page
            self.numberOfTotalResults = responseDictionary!["total"]!.integerValue
            let teams = responseDictionary!["models"] as? [[NSObject: AnyObject]]
            for teamDictionary in teams! {
                let teamObject = Team(data: teamDictionary)
                self.teamSearchResults.append(teamObject)
                // insert row in table view
                self.tableView.beginUpdates()
                self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.teamSearchResults.count - 1, inSection: 0)], withRowAnimation: .Fade)
                self.tableView.endUpdates()
            }
            self.currentPage++
        }
        self.isLoadingNextPage = false
        self.setTableFooterView()
        
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        self.isLoadingNextPage = false
        self.setTableFooterView()

        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    /**
    set table footer view to be:
    a. empty view if no more models can be loaded
    b. view contains a next page button if it is NOT currently loading next page and there are more models that can be loaded
    c. view contains an activity indicator if it IS currently loading next page
    */
    func setTableFooterView() {
        self.tableView.tableFooterView = Toolbox.setPaginatedTableFooterView(self.numberOfTotalResults, numOfLoaded: self.teamSearchResults.count, isLoadingNextPage: self.isLoadingNextPage, buttonTitle: "更多球队", buttonActionSelector: "getNextPageOfTeamResults", viewController: self)
    }
    
    deinit {
        self.responseData = nil
        if self.teamSearchResults.count > 0 {
            self.teamSearchResults.removeAll(keepCapacity: false)
        }
        self.searchTeamKeyword = nil
        self.selectedTeam = nil
        self.userCoordinates = nil
    }
}
