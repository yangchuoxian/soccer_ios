//
//  VTNearbyTeamsTableViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/10/21.
//  Copyright © 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTNearbyTeamsTableViewController: UITableViewController, NSURLConnectionDataDelegate, NSURLConnectionDelegate {

    var teamsList = [Team]()
    var currentPage = 1
    var userCoordinates: CLLocationCoordinate2D = CLLocationCoordinate2D()
    var isLoadingNextPage = false
    var selectedTeam: Team?
    var totalNearbyTeams = 0
    var responseData: NSMutableData? = NSMutableData()
    var sortedType: SortType?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = true
        
        self.setTableFooterView()
        self.tableView.rowHeight = CustomTableRowHeight
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if self.sortedType == .SortByDistance {
            Appearance.customizeNavigationBar(self, title: "附近球队")
        } else if self.sortedType == .SortByPoint {
            Appearance.customizeNavigationBar(self, title: "球队排名")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func getNextPageOfTeamResults() {
        // submit request to get next page of team results
        var urlToGetNextPageOfTeamResults = ""
        if self.sortedType == .SortByDistance {
            urlToGetNextPageOfTeamResults = "\(URLGetNearbyTeamsForUser)?latitude=\(self.userCoordinates.latitude)&longitude=\(self.userCoordinates.longitude)&page=\(self.currentPage + 1)"
        } else if self.sortedType == .SortByPoint {
            urlToGetNextPageOfTeamResults = "\(URLGetNearbyTeamsForUser)?latitude=\(self.userCoordinates.latitude)&longitude=\(self.userCoordinates.longitude)&page=\(self.currentPage + 1)&sortedByPoints=1"
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
    
    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return teamsList.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = self.tableView.dequeueReusableCellWithIdentifier("searchedTeamCell") as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: "searchedTeamCell")
        }
        let teamInCurrentRow = self.teamsList[indexPath.row]
        
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
        label_distance.text = "\(teamInCurrentRow.distanceToCurrentUser) km"
        
        return cell!
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.selectedTeam = self.teamsList[indexPath.row]
        self.performSegueWithIdentifier("teamInfoSegue", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "teamInfoSegue" {
            let destinationViewController = segue.destinationViewController as! VTTeamBriefIntroTableViewController
            destinationViewController.teamObject = self.selectedTeam
            destinationViewController.hasUserAlreadyAppliedThisTeam = false
            if self.sortedType == .SortByDistance {
                // if the teams are sorted by distance, you can only send application to these teams, and remember those teams that current user cannot send application to has already been excluded when fetching teams list in server
                destinationViewController.teamInteractionOption = .SendApplication
            } else if self.sortedType == .SortByPoint {
                // if the teams are sorted by point, you can only send challenge to one of team, given that team is not the team current user is the captain
                destinationViewController.teamInteractionOption = .SendChallenge
            }
        }
    }

    func setTableFooterView() {
        self.tableView.tableFooterView = Toolbox.setPaginatedTableFooterView(self.totalNearbyTeams, numOfLoaded: self.teamsList.count, isLoadingNextPage: self.isLoadingNextPage, buttonTitle: "更多球队", buttonActionSelector: "getNextPageOfTeamResults", viewController: self)
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        self.responseData?.appendData(data)
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        let responseDictionary = (try? NSJSONSerialization.JSONObjectWithData(self.responseData!, options: .MutableLeaves)) as? [NSObject: AnyObject]
        if responseDictionary != nil {  // successfully loaded next page
            self.totalNearbyTeams = responseDictionary!["total"]!.integerValue
            let teams = responseDictionary!["models"] as? [[NSObject: AnyObject]]
            for teamDictionary in teams! {
                let teamObject = Team(data: teamDictionary)
                self.teamsList.append(teamObject)
                // insert row in table view
                self.tableView.beginUpdates()
                self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.teamsList.count - 1, inSection: 0)], withRowAnimation: .Fade)
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
    
    @IBAction func unwindToTeamListTableView(segue: UIStoryboardSegue) {
    }
    
    deinit {
        self.teamsList.removeAll()
        self.selectedTeam = nil
        self.sortedType = nil
    }
}
