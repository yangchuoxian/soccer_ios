//
//  VTNearbyMatchesTableViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/10/20.
//  Copyright © 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTNearbyMatchesTableViewController: UITableViewController, NSURLConnectionDelegate, NSURLConnectionDataDelegate {
    
    var matchesList = [Activity]()
    var currentPage = 1
    var userCoordinates: CLLocationCoordinate2D = CLLocationCoordinate2D()
    var isLoadingNextPage = false
    var totalNearbyMatches = 0
    var selectedMatch: Activity?
    var responseData: NSMutableData? = NSMutableData()
    
    let tableCellIdentifier = "nearbyMatchCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = true
        self.tableView.rowHeight = CustomTableRowHeight
        
        self.setTableFooterView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "近期赛事")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.matchesList.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = self.tableView.dequeueReusableCellWithIdentifier(self.tableCellIdentifier) as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: self.tableCellIdentifier)
        }
        let matchInCurrentRow = self.matchesList[indexPath.row]
        // set up the match info labels and team avatars
        let imageView_teamAAvatar = cell!.contentView.viewWithTag(1) as! UIImageView
        let label_teamAName = cell!.contentView.viewWithTag(2) as! UILabel
        let imageView_teamBAvatar = cell!.contentView.viewWithTag(3) as! UIImageView
        let label_teamBName = cell!.contentView.viewWithTag(4) as! UILabel
        label_teamAName.text = matchInCurrentRow.nameOfA
        label_teamBName.text = matchInCurrentRow.nameOfB
 
        Toolbox.loadAvatarImage(matchInCurrentRow.idOfA!, toImageView: imageView_teamAAvatar, avatarType: .Team)
        Toolbox.loadAvatarImage(matchInCurrentRow.idOfB, toImageView: imageView_teamBAvatar, avatarType: .Team)
        
        return cell!
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.selectedMatch = self.matchesList[indexPath.row]
        self.performSegueWithIdentifier("matchInfoSegue", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "matchInfoSegue" {
            let destinationViewController = segue.destinationViewController as! VTUserActivityInfoTableViewController
            destinationViewController.activity = self.selectedMatch
        }
    }
    
    func getNextPageOfMatches() {
        // submit request to get next page of nearby matches
        let postParamsString = "\(URLGetRecentMatchesNearAround)?latitude=\(self.userCoordinates.latitude)&longitude=\(self.userCoordinates.longitude)&page=\(self.currentPage + 1)"
        let connection = Toolbox.asyncHttpGetFromURL(postParamsString, delegate: self)
        if connection == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            self.isLoadingNextPage = true
            self.setTableFooterView()
        }
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        self.responseData?.appendData(data)
    }
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        self.isLoadingNextPage = false
        // set tableView footer to replace activity indicator with next page button
        self.setTableFooterView()
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络超时")
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        self.isLoadingNextPage = false
        let responseDictionary = (try? NSJSONSerialization.JSONObjectWithData(self.responseData!, options: .MutableLeaves)) as? [NSObject: AnyObject]
        self.responseData = nil
        self.responseData = NSMutableData()
        
        if responseDictionary == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "获取失败")
            return
        }
        self.totalNearbyMatches = responseDictionary!["total"]!.integerValue
        let models = responseDictionary!["models"] as? [[String: AnyObject]]
        if self.totalNearbyMatches == 0 || models == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "没有找到更多比赛")
            return
        }
        self.currentPage++
        for matchModel in models! {
            let matchObject = Activity(data: matchModel)
            self.matchesList.append(matchObject)
            // insert row in table view
            self.tableView.beginUpdates()
            self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.matchesList.count - 1, inSection: 0)], withRowAnimation: .Fade)
            self.tableView.endUpdates()
        }
        // set tableView footer to replace activity indicator with next page button
        self.setTableFooterView()
    }
    
    /**
    set table footer view to be:
    a. empty view if no more models can be loaded
    b. view contains a next page button if it is NOT currently loading next page and there are more models that can be loaded
    c. view contains an activity indicator if it IS currently loading next page
    */
    func setTableFooterView() {
        self.tableView.tableFooterView = Toolbox.setPaginatedTableFooterView(self.totalNearbyMatches, numOfLoaded: self.matchesList.count, isLoadingNextPage: self.isLoadingNextPage, buttonTitle: "更多附近比赛", buttonActionSelector: "getNextPageOfMatches", viewController: self)
    }
    
    deinit {
        self.matchesList.removeAll()
        self.selectedMatch = nil
        self.responseData = nil
    }
    
}
