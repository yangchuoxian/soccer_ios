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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.sortedType == .sortByDistance {
            Appearance.customizeNavigationBar(self, title: "附近球队")
        } else if self.sortedType == .sortByPoint {
            Appearance.customizeNavigationBar(self, title: "球队排名")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func getNextPageOfTeamResults() {
        // submit request to get next page of team results
        var urlToGetNextPageOfTeamResults = ""
        if self.sortedType == .sortByDistance {
            urlToGetNextPageOfTeamResults = "\(URLGetNearbyTeamsForUser)?latitude=\(self.userCoordinates.latitude)&longitude=\(self.userCoordinates.longitude)&page=\(self.currentPage + 1)"
        } else if self.sortedType == .sortByPoint {
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

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return teamsList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = self.tableView.dequeueReusableCell(withIdentifier: "searchedTeamCell") as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "searchedTeamCell")
        }
        let teamInCurrentRow = self.teamsList[(indexPath as NSIndexPath).row]
        
        // set up team avatar image view
        let imageView_avatar = cell?.contentView.viewWithTag(1) as! UIImageView
        imageView_avatar.layer.cornerRadius = 2.0
        imageView_avatar.layer.masksToBounds = true
        // load avatar image asynchronously
        Toolbox.loadAvatarImage(teamInCurrentRow.teamId, toImageView: imageView_avatar, avatarType: AvatarType.team)
        
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedTeam = self.teamsList[(indexPath as NSIndexPath).row]
        self.performSegue(withIdentifier: "teamInfoSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "teamInfoSegue" {
            let destinationViewController = segue.destination as! VTTeamBriefIntroTableViewController
            destinationViewController.teamObject = self.selectedTeam
            destinationViewController.hasUserAlreadyAppliedThisTeam = false
            if self.sortedType == .sortByDistance {
                // if the teams are sorted by distance, you can only send application to these teams, and remember those teams that current user cannot send application to has already been excluded when fetching teams list in server
                destinationViewController.teamInteractionOption = .sendApplication
            } else if self.sortedType == .sortByPoint {
                // if the teams are sorted by point, you can only send challenge to one of team, given that team is not the team current user is the captain
                destinationViewController.teamInteractionOption = .sendChallenge
            }
        }
    }

    func setTableFooterView() {
        self.tableView.tableFooterView = Toolbox.setPaginatedTableFooterView(self.totalNearbyTeams, numOfLoaded: self.teamsList.count, isLoadingNextPage: self.isLoadingNextPage, buttonTitle: "更多球队", buttonActionSelector: "getNextPageOfTeamResults", viewController: self)
    }
    
    func connection(_ connection: NSURLConnection, didReceive data: Data) {
        self.responseData?.append(data)
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        let responseDictionary = (try? JSONSerialization.jsonObject(with: self.responseData! as Data, options: .mutableLeaves)) as? [AnyHashable: Any]
        if responseDictionary != nil {  // successfully loaded next page
            self.totalNearbyTeams = (responseDictionary!["total"]! as AnyObject).intValue
            let teams = responseDictionary!["models"] as? [[AnyHashable: Any]]
            for teamDictionary in teams! {
                let teamObject = Team(data: teamDictionary as [NSObject : AnyObject])
                self.teamsList.append(teamObject)
                // insert row in table view
                self.tableView.beginUpdates()
                self.tableView.insertRows(at: [IndexPath(row: self.teamsList.count - 1, section: 0)], with: .fade)
                self.tableView.endUpdates()
            }
            self.currentPage += 1
        }
        self.isLoadingNextPage = false
        self.setTableFooterView()
        
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        self.isLoadingNextPage = false
        self.setTableFooterView()
        
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    @IBAction func unwindToTeamListTableView(_ segue: UIStoryboardSegue) {
    }
    
    deinit {
        self.teamsList.removeAll()
        self.selectedTeam = nil
        self.sortedType = nil
    }
}
