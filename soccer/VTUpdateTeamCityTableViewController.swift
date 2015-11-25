//
//  VTUpdateTeamCityTableViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/20.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTUpdateTeamCityTableViewController: UITableViewController {

    var selectedProvinceName:String?
    var cityNames = [String]()
    var selectedCityName:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // This will remove extra serparators from tableView
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        
        Appearance.customizeNavigationBar(self, title: "选择城市")
        
        let dbManager:DBManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        let cityRecordsForSelectedProvince:NSArray = dbManager.loadDataFromDB(
            "select name from cities where province=?",
            parameters: [self.selectedProvinceName!]
        )
        for anyObject in cityRecordsForSelectedProvince {
            let cityRecord = anyObject as? NSArray
            self.cityNames.append(cityRecord![0] as! String)
        }
    }
    
    deinit {
        if self.cityNames.count > 0 {
            self.cityNames.removeAll()
        }
        
        self.selectedProvinceName = nil
        self.selectedCityName = nil
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return TableSectionHeaderHeight
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: TableSectionHeaderHeight))
        
        if section == 0 {
            headerView.addSubview(Appearance.setupTableSectionHeaderTitle(" 已选择省份"))
        } else {
            headerView.addSubview(Appearance.setupTableSectionHeaderTitle("选择城市"))
        }
        
        return headerView
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return self.cityNames.count
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var tableCellIdentifier:String?
        if indexPath.section == 0 {
            tableCellIdentifier = "selectedProvinceCell"
        } else {
            tableCellIdentifier = "cityNameCell"
        }
        
        var cell = self.tableView.dequeueReusableCellWithIdentifier(tableCellIdentifier!) as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: tableCellIdentifier)
        }
        
        if indexPath.section == 0 { // section to display selected province name
            let label_selectedProvince:UILabel = cell?.contentView.viewWithTag(1) as! UILabel
            label_selectedProvince.text = self.selectedProvinceName
            
            // make this table cell NOT selectable
            cell?.selectionStyle = .None
        } else {    // section to display cities in current province
            let label_cityName:UILabel = cell?.contentView.viewWithTag(1) as! UILabel
            label_cityName.text = self.cityNames[indexPath.row]
        }
        
        return cell!
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 1 {
            self.selectedCityName = self.cityNames[indexPath.row]
            self.performSegueWithIdentifier("teamCitySelectedSegue", sender: self)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // team city selected, go back to team location view controller
        if segue.identifier == "teamCitySelectedSegue" {
            let destinationViewController:VTUpdateTeamLocationTableViewController = segue.destinationViewController as! VTUpdateTeamLocationTableViewController
            destinationViewController.completeLocation = "" + self.selectedProvinceName! + "" + self.selectedCityName!
        }
    }
}
