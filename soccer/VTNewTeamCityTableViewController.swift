//
//  VTNewTeamCityTableViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/3.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTNewTeamCityTableViewController: UITableViewController {
    
    let provinceTableCellIdentifier = "selectedProvinceCell"
    let cityTableCellIdentifier = "cityNameCell"
    
    var cityNames = [String]()
    var selectedProvinceName: String?
    var selectedCityName: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.clearsSelectionOnViewWillAppear = true
        
        // This will remove extra separators from tableview
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        
        Appearance.customizeNavigationBar(self, title: "选择城市")
        
        let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        
        let cityRecordsForSelectedProvince = dbManager.loadDataFromDB(
            "select name from cities where province=?",
            parameters: [self.selectedProvinceName!])
        
        for anyObject in cityRecordsForSelectedProvince {
            let cityRecord = anyObject as? NSArray
            if cityRecord != nil {
                self.cityNames.append(cityRecord![0] as! String)
            }
        }
        // add right button in navigation bar programmatically
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Stop, target: self, action: "cancelNewTeamCreation")
    }
    
    func cancelNewTeamCreation() {
        // close modal view and all its related navigation controller to go back to teams list table view
        self.performSegueWithIdentifier("cancelNewTeamCreationFromTeamCityViewControllerSegue", sender: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return TableSectionHeaderHeight
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRectMake(0, 0, ScreenSize.width, TableSectionHeaderHeight))
        if section == 0 {
            headerView.addSubview(Appearance.setupTableSectionHeaderTitle("  已选择省份"))
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
        var tableCellIdentifier: String
        if indexPath.section == 0 {
            tableCellIdentifier = self.provinceTableCellIdentifier
        } else {
            tableCellIdentifier = self.cityTableCellIdentifier
        }
        var cell = self.tableView.dequeueReusableCellWithIdentifier(tableCellIdentifier) as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: tableCellIdentifier)
        }
        
        if indexPath.section == 0 {   // section to display selected province name
            let label_selectedProvince = cell?.contentView.viewWithTag(1) as! UILabel
            label_selectedProvince.text = self.selectedProvinceName
            
            // make this table cell NOT selectable
            cell?.selectionStyle = .None
        } else {    // section to display cities in current province
            let label_cityName = cell?.contentView.viewWithTag(1) as! UILabel
            label_cityName.text = self.cityNames[indexPath.row]
        }
        return cell!
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 1 {
            self.selectedCityName = self.cityNames[indexPath.row]
            self.performSegueWithIdentifier("newTeamCitySelectedSegue", sender: self)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // new team city selected, go back to new team location view controller
        if segue.identifier == "newTeamCitySelectedSegue" {
            let destinationViewController = segue.destinationViewController as! VTNewTeamLocationTableViewController
            destinationViewController.completeLocation = self.selectedProvinceName! + "" + self.selectedCityName!
        }
    }
    
    deinit {
        self.selectedProvinceName = nil
        self.selectedCityName = nil
        self.cityNames.removeAll(keepCapacity: false)
    }

}
