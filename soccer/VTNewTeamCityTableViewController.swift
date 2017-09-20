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
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        Appearance.customizeNavigationBar(self, title: "选择城市")
        
        let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        
        let cityRecordsForSelectedProvince = dbManager?.loadData(
            fromDB: "select name from cities where province=?",
            parameters: [self.selectedProvinceName!])
        
        for anyObject in cityRecordsForSelectedProvince! {
            let cityRecord = anyObject as? NSArray
            if cityRecord != nil {
                self.cityNames.append(cityRecord![0] as! String)
            }
        }
        // add right button in navigation bar programmatically
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(VTNewTeamCityTableViewController.cancelNewTeamCreation))
    }
    
    func cancelNewTeamCreation() {
        // close modal view and all its related navigation controller to go back to teams list table view
        self.performSegue(withIdentifier: "cancelNewTeamCreationFromTeamCityViewControllerSegue", sender: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return TableSectionHeaderHeight
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: TableSectionHeaderHeight))
        if section == 0 {
            headerView.addSubview(Appearance.setupTableSectionHeaderTitle("  已选择省份"))
        } else {
            headerView.addSubview(Appearance.setupTableSectionHeaderTitle("选择城市"))
        }
        return headerView
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return self.cityNames.count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var tableCellIdentifier: String
        if (indexPath as NSIndexPath).section == 0 {
            tableCellIdentifier = self.provinceTableCellIdentifier
        } else {
            tableCellIdentifier = self.cityTableCellIdentifier
        }
        var cell = self.tableView.dequeueReusableCell(withIdentifier: tableCellIdentifier) as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: tableCellIdentifier)
        }
        
        if (indexPath as NSIndexPath).section == 0 {   // section to display selected province name
            let label_selectedProvince = cell?.contentView.viewWithTag(1) as! UILabel
            label_selectedProvince.text = self.selectedProvinceName
            
            // make this table cell NOT selectable
            cell?.selectionStyle = .none
        } else {    // section to display cities in current province
            let label_cityName = cell?.contentView.viewWithTag(1) as! UILabel
            label_cityName.text = self.cityNames[(indexPath as NSIndexPath).row]
        }
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).section == 1 {
            self.selectedCityName = self.cityNames[(indexPath as NSIndexPath).row]
            self.performSegue(withIdentifier: "newTeamCitySelectedSegue", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // new team city selected, go back to new team location view controller
        if segue.identifier == "newTeamCitySelectedSegue" {
            let destinationViewController = segue.destination as! VTNewTeamLocationTableViewController
            destinationViewController.completeLocation = self.selectedProvinceName! + "" + self.selectedCityName!
        }
    }
    
    deinit {
        self.selectedProvinceName = nil
        self.selectedCityName = nil
        self.cityNames.removeAll(keepingCapacity: false)
    }

}
