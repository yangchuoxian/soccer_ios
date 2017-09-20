//
//  VTSelectUserCityTableViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/29.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class VTSelectUserCityTableViewController: UITableViewController {

    var selectedProvinceName: String?
    var cityNames: NSMutableArray?
    var selectedCityName: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.clearsSelectionOnViewWillAppear = true
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)

        let dbManager: DBManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        let cityRecordsForSelectedProvince = dbManager.loadData(
            fromDB: "select name from cities where province=?",
            parameters: [self.selectedProvinceName!]
        )
        
        self.cityNames = NSMutableArray()
        for anyObject in cityRecordsForSelectedProvince! {
            let cityRecord = anyObject as? NSArray
            if cityRecord != nil {
                self.cityNames?.add(cityRecord![0] as! String)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "选择城市")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return TableSectionHeaderHeight
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
            if self.cityNames != nil {
                return self.cityNames!.count
            } else {
                return 0
            }
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var tableCellIdentifier: String?
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
            let label_selectedProvince: UILabel = cell?.contentView.viewWithTag(1) as! UILabel
            label_selectedProvince.text = self.selectedProvinceName
            cell?.selectionStyle = .none
        } else {    // section to display cities in current province
            let label_cityName: UILabel = cell?.contentView.viewWithTag(1) as! UILabel
            label_cityName.text = self.cityNames![(indexPath as NSIndexPath).row] as? String
        }
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if ((indexPath as NSIndexPath).section == 1) {
            self.selectedCityName = self.cityNames![(indexPath as NSIndexPath).row] as? String
            
            self.performSegue(withIdentifier: "userCitySelectedSegue", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // user city selected, go back to user location view controller
        if segue.identifier == "userCitySelectedSegue" {
            let destinationViewController: VTChangeUserLocationTableViewController = segue.destination as! VTChangeUserLocationTableViewController
            destinationViewController.completeLocation = self.selectedProvinceName! + self.selectedCityName!
        }
    }
    
    deinit {
        if self.cityNames != nil {
            if self.cityNames?.count > 0 {
                self.cityNames?.removeAllObjects()
            }
            self.cityNames = nil
        }
        
        self.selectedProvinceName = nil
        self.selectedCityName = nil
    }
    
}
