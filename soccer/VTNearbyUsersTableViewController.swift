//
//  VTNearbyUsersTableViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/3.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTNearbyUsersTableViewController: UITableViewController, NSURLConnectionDataDelegate, NSURLConnectionDelegate {
    
    var usersList = [User]()
    var currentPage = 1
    var currentUserCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D()
    var isLoadingNextPage = false
    var totalNearbyUsers = 0
    var selectedUser: User?
    var responseData: NSMutableData? = NSMutableData()
    var sortedType: SortType?
    
    let tableCellIdentifier = "searchedUserCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = true
        self.tableView.rowHeight = CustomTableRowHeight
        
        self.setTableFooterView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if sortedType == .SortByDistance {
            Appearance.customizeNavigationBar(self, title: "附近球员")
        } else if sortedType == .SortByPoint {
            Appearance.customizeNavigationBar(self, title: "球员积分排名")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.usersList.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = self.tableView.dequeueReusableCellWithIdentifier(self.tableCellIdentifier) as UITableViewCell?
        
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: self.tableCellIdentifier)
        }
        // set up user avatar image view
        let imageView_userAvatar = cell!.contentView.viewWithTag(1) as! UIImageView
        imageView_userAvatar.layer.cornerRadius = 2.0
        imageView_userAvatar.layer.masksToBounds = true
        // set up label to display user name
        let label_username = cell!.contentView.viewWithTag(2) as! UILabel
        // set up label to display user position
        let label_position = cell!.contentView.viewWithTag(3) as! UILabel
        // set up label to display user's distance to current user
        let label_distance = cell!.contentView.viewWithTag(4) as! UILabel
        
        let userInCurrentRow = self.usersList[indexPath.row]
        // load user avatar
        Toolbox.loadAvatarImage(userInCurrentRow.userId, toImageView: imageView_userAvatar, avatarType: AvatarType.User)
        label_username.text = userInCurrentRow.username
        label_position.text = userInCurrentRow.position
        label_distance.text = "\(userInCurrentRow.distanceToCurrentUser) km"
        
        return cell!
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.selectedUser = self.usersList[indexPath.row]
        self.performSegueWithIdentifier("nearbyStrangerProfileSegue", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "nearbyStrangerProfileSegue" {
            let destinationViewController = segue.destinationViewController as! VTScannedOrSearchedUserProfileTableViewController
            destinationViewController.userObject = self.selectedUser
        }
    }
    
    func getNextPageOfUsersSearchResult() {
        // submit request to get next page of nearby users
        let coordinateString = "?latitude=\(self.currentUserCoordinate.latitude)&longitude=\(self.currentUserCoordinate.longitude)"
        var url = ""
        if self.sortedType == .SortByDistance {
            url = "\(URLGetNearbyUsersForTeam)\(coordinateString)&page=\(self.currentPage + 1)"
        } else if self.sortedType == .SortByPoint {
            url = "\(URLGetNearbyUsersForTeam)\(coordinateString)&page=\(self.currentPage + 1)&sortedByPoints=1"
        }
        let connection = Toolbox.asyncHttpGetFromURL(url, delegate: self)
        
        if connection == nil {
            // inform the user that the connection failed
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
        
        let nearbyUsersPaginatedInfo = (try? NSJSONSerialization.JSONObjectWithData(self.responseData!, options: .MutableLeaves)) as? [NSObject: AnyObject]
        
        let paginatedNearbyUsers = nearbyUsersPaginatedInfo!["models"] as? [[String: AnyObject]]
        self.totalNearbyUsers = nearbyUsersPaginatedInfo!["total"]!.integerValue
        self.currentPage = self.currentPage + 1
        
        // initialize each user dictionary received in array and add it to self.usersList
        var nearbyUserObject: User
        for nearbyUserDictionary in paginatedNearbyUsers! {
            nearbyUserObject = User(data: nearbyUserDictionary)
            self.usersList.append(nearbyUserObject)
            // insert row in table view
            self.tableView.beginUpdates()
            self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.usersList.count - 1, inSection: 0)], withRowAnimation: .Fade)
            self.tableView.endUpdates()
        }
        // set tableView footer to replace activity indicator with next page button
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
        self.tableView.tableFooterView = Toolbox.setPaginatedTableFooterView(self.totalNearbyUsers, numOfLoaded: self.usersList.count, isLoadingNextPage: self.isLoadingNextPage, buttonTitle: "更多附近球员", buttonActionSelector: "getNextPageOfUsersSearchResult", viewController: self)
    }

    @IBAction func unwindToMembersContainerView(segue: UIStoryboardSegue) {
    }
    
    deinit {
        self.usersList.removeAll(keepCapacity: false)
        self.responseData = nil
        self.selectedUser = nil
        self.sortedType = nil
    }
    
}
