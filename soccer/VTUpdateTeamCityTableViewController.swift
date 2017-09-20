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
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        Appearance.customizeNavigationBar(self, title: "选择城市")
        
        let dbManager:DBManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        let cityRecordsForSelectedProvince:NSArray = dbManager.loadData(
            fromDB: "select name from cities where province=?",
            parameters: [self.selectedProvinceName!]
        ) as NSArray
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
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return TableSectionHeaderHeight
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: TableSectionHeaderHeight))
        
        if section == 0 {
            headerView.addSubview(Appearance.setupTableSectionHeaderTitle(" 已选择省份"))
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
        var tableCellIdentifier:String?
        if (indexPath as NSIndexPath).section == 0 {
            tableCellIdentifier = "selectedProvinceCell"
        } else {
            tableCellIdentifier = "cityNameCell"
        }
        
        var cell = self.tableView.dequeueReusableCell(withIdentifier: tableCellIdentifier!) as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: tableCellIdentifier)
        }
        
        if (indexPath as NSIndexPath).section == 0 { // section to display selected province name
            let label_selectedProvince:UILabel = cell?.contentView.viewWithTag(1) as! UILabel
            label_selectedProvince.text = self.selectedProvinceName
            
            // make this table cell NOT selectable
            cell?.selectionStyle = .none
        } else {    // section to display cities in current province
            let label_cityName:UILabel = cell?.contentView.viewWithTag(1) as! UILabel
            label_cityName.text = self.cityNames[(indexPath as NSIndexPath).row]
        }
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).section == 1 {
            self.selectedCityName = self.cityNames[(indexPath as NSIndexPath).row]
            self.performSegue(withIdentifier: "teamCitySelectedSegue", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // team city selected, go back to team location view controller
        if segue.identifier == "teamCitySelectedSegue" {
            let destinationViewController:VTUpdateTeamLocationTableViewController = segue.destination as! VTUpdateTeamLocationTableViewController
            destinationViewController.completeLocation = "" + self.selectedProvinceName! + "" + self.selectedCityName!
        }
    }
}
