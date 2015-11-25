//
//  VTNearbyGroundsTableViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/10/20.
//  Copyright © 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTNearbyGroundsTableViewController: UITableViewController, NSURLConnectionDataDelegate, NSURLConnectionDelegate {

    var groundsList = [Ground]()
    var currentPage = 1
    var userCoordinates: CLLocationCoordinate2D = CLLocationCoordinate2D()
    var isLoadingNextPage = false
    var totalNearbyGrounds = 0
    var selectedGround: Ground?
    var responseData: NSMutableData? = NSMutableData()
    
    let tableCellIdentifier = "nearbyGroundCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = true
        
        self.setTableFooterView()
        self.tableView.rowHeight = CustomTableRowHeight
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "附近球场")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.groundsList.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = self.tableView.dequeueReusableCellWithIdentifier(self.tableCellIdentifier) as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: self.tableCellIdentifier)
        }
        let groundInCurrentRow = self.groundsList[indexPath.row]
        // set up the ground info labels
        let label_groundName = cell!.contentView.viewWithTag(1) as! UILabel
        let label_groundAddress = cell!.contentView.viewWithTag(2) as! UILabel
        let label_distanceToCurrentUser = cell!.contentView.viewWithTag(3) as! UILabel
        let label_numberOfTeams = cell!.contentView.viewWithTag(4) as! UILabel
        let label_numberOfActivities = cell!.contentView.viewWithTag(5) as! UILabel
        label_groundName.text = groundInCurrentRow.name
        label_groundAddress.text = groundInCurrentRow.address
        label_numberOfTeams.text = groundInCurrentRow.numberOfTeams
        label_numberOfActivities.text = groundInCurrentRow.numberOfActivities
        label_distanceToCurrentUser.text = groundInCurrentRow.distanceToCurrentUser
        
        return cell!
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.selectedGround = self.groundsList[indexPath.row]
        self.performSegueWithIdentifier("groundInfoSegue", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "groundInfoSegue" {
            let destinationViewController = segue.destinationViewController as! VTGroundInfoViewController
            destinationViewController.groundObject = self.selectedGround
        }
    }
    
    func getNextPageOfGrounds() {
        // submit request to get next page of nearby grounds
        let postParamsString = "\(URLGetNearbyGrounds)?latitude=\(self.userCoordinates.latitude)&longitude=\(self.userCoordinates.longitude)&page=\(self.currentPage + 1)"
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
        self.totalNearbyGrounds = responseDictionary!["total"]!.integerValue
        let models = responseDictionary!["models"] as? [[String: AnyObject]]
        if self.totalNearbyGrounds == 0 || models == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "没有找到更多球场")
            return
        }
        self.currentPage++
        for groundModel in models! {
            let groundObject = Ground(data: groundModel)
            self.groundsList.append(groundObject)
            // insert row in table view
            self.tableView.beginUpdates()
            self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.groundsList.count - 1, inSection: 0)], withRowAnimation: .Fade)
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
        self.tableView.tableFooterView = Toolbox.setPaginatedTableFooterView(self.totalNearbyGrounds, numOfLoaded: self.groundsList.count, isLoadingNextPage: self.isLoadingNextPage, buttonTitle: "更多附近球场", buttonActionSelector: "getNextPageOfGrounds", viewController: self)
    }

    deinit {
        self.groundsList.removeAll()
        self.selectedGround = nil
        self.responseData = nil
    }
    
}
