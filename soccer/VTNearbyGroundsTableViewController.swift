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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "附近球场")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.groundsList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = self.tableView.dequeueReusableCell(withIdentifier: self.tableCellIdentifier) as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: self.tableCellIdentifier)
        }
        let groundInCurrentRow = self.groundsList[(indexPath as NSIndexPath).row]
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedGround = self.groundsList[(indexPath as NSIndexPath).row]
        self.performSegue(withIdentifier: "groundInfoSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "groundInfoSegue" {
            let destinationViewController = segue.destination as! VTGroundInfoViewController
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
    
    func connection(_ connection: NSURLConnection, didReceive data: Data) {
        self.responseData?.append(data)
    }
    
    func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        self.isLoadingNextPage = false
        // set tableView footer to replace activity indicator with next page button
        self.setTableFooterView()
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络超时")
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        self.isLoadingNextPage = false
        let responseDictionary = (try? JSONSerialization.jsonObject(with: self.responseData! as Data, options: .mutableLeaves)) as? [AnyHashable: Any]
        self.responseData = nil
        self.responseData = NSMutableData()
        
        if responseDictionary == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "获取失败")
            return
        }
        self.totalNearbyGrounds = (responseDictionary!["total"]! as AnyObject).intValue
        let models = responseDictionary!["models"] as? [[String: AnyObject]]
        if self.totalNearbyGrounds == 0 || models == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "没有找到更多球场")
            return
        }
        self.currentPage += 1
        for groundModel in models! {
            let groundObject = Ground(data: groundModel)
            self.groundsList.append(groundObject)
            // insert row in table view
            self.tableView.beginUpdates()
            self.tableView.insertRows(at: [IndexPath(row: self.groundsList.count - 1, section: 0)], with: .fade)
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
