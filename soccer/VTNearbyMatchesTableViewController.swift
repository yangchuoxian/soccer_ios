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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "近期赛事")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.matchesList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = self.tableView.dequeueReusableCell(withIdentifier: self.tableCellIdentifier) as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: self.tableCellIdentifier)
        }
        let matchInCurrentRow = self.matchesList[(indexPath as NSIndexPath).row]
        // set up the match info labels and team avatars
        let imageView_teamAAvatar = cell!.contentView.viewWithTag(1) as! UIImageView
        let label_teamAName = cell!.contentView.viewWithTag(2) as! UILabel
        let imageView_teamBAvatar = cell!.contentView.viewWithTag(3) as! UIImageView
        let label_teamBName = cell!.contentView.viewWithTag(4) as! UILabel
        label_teamAName.text = matchInCurrentRow.nameOfA
        label_teamBName.text = matchInCurrentRow.nameOfB
 
        Toolbox.loadAvatarImage(matchInCurrentRow.idOfA!, toImageView: imageView_teamAAvatar, avatarType: .team)
        Toolbox.loadAvatarImage(matchInCurrentRow.idOfB, toImageView: imageView_teamBAvatar, avatarType: .team)
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedMatch = self.matchesList[(indexPath as NSIndexPath).row]
        self.performSegue(withIdentifier: "matchInfoSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "matchInfoSegue" {
            let destinationViewController = segue.destination as! VTUserActivityInfoTableViewController
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
        self.totalNearbyMatches = (responseDictionary!["total"]! as AnyObject).intValue
        let models = responseDictionary!["models"] as? [[String: AnyObject]]
        if self.totalNearbyMatches == 0 || models == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "没有找到更多比赛")
            return
        }
        self.currentPage += 1
        for matchModel in models! {
            let matchObject = Activity(data: matchModel)
            self.matchesList.append(matchObject)
            // insert row in table view
            self.tableView.beginUpdates()
            self.tableView.insertRows(at: [IndexPath(row: self.matchesList.count - 1, section: 0)], with: .fade)
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
