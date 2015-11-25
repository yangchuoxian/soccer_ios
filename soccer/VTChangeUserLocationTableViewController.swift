//
//  VTChangeUserLocationTableViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/29.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTChangeUserLocationTableViewController: UITableViewController, LocationServiceDelegate {

    var provinceNames = [String]()
    var selectedProvinceName: String?
    var completeLocation: String?
    var HUD: MBProgressHUD?
    var button_submitUserLocation: UIButton?
    var locationService: LocationService?
    var userLocationCoordinate: CLLocationCoordinate2D?
    // this flag records whether the user location is located by system geolocation function or hand picked by user
    var isLocationHandPickedByUser: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = true
        
        let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        let provinceRecords = dbManager.loadDataFromDB("select name from provinces", parameters: nil)
        for anyObject in provinceRecords {
            let provinceRecord = anyObject as? NSArray
            if provinceRecord != nil {
                self.provinceNames.append(provinceRecord![0] as! String)
            }
        }
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        // listen to userInfoUpdated message and handles it by unwinding the navigation controller to the previous view controller
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateUserInfo:", name: "userInfoUpdated", object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "用户所在地")
    }
    
    func updateUserInfo(notification: NSNotification) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    deinit {
        if self.provinceNames.count > 0 {
            self.provinceNames.removeAll()
        }
        self.provinceNames.removeAll()
        
        self.selectedProvinceName = nil
        self.completeLocation = nil
        self.HUD = nil
        
        if self.locationService != nil {
            self.locationService?.delegate = nil
        }
        self.locationService = nil
        
        if self.button_submitUserLocation != nil {
            self.button_submitUserLocation?.removeTarget(nil, action: nil, forControlEvents: .AllEvents)
        }
        self.button_submitUserLocation = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if self.completeLocation != nil {  // user has manually select the user city
            // update the complete location
            let potentialLocationSectionRow: NSIndexPath = NSIndexPath(forItem: 0, inSection: 0)
            self.tableView.reloadRowsAtIndexPaths([potentialLocationSectionRow], withRowAnimation: .Fade)
            Toolbox.toggleButton(self.button_submitUserLocation!, enabled: true)
            
            self.isLocationHandPickedByUser = true
        } else {    // first try to locate user current location automatically
            self.locationService = LocationService()
            self.locationService?.delegate = self
            self.locationService?.launchLocationService()
            
            self.isLocationHandPickedByUser = false
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if self.locationService != nil {
            self.locationService?.delegate = nil
            self.locationService = nil
        }
        if self.HUD != nil {
            self.HUD?.hide(true)
            self.HUD = nil
        }
    }
    
    func didStartToLocate() {
        // show loading spinner HUD to indicate that locating user is in process
        self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: "正在定位...")
    }
    
    func didFailToLocateUser() {
        self.HUD?.hide(true)
        self.HUD = nil
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "定位失败")
    }
    
    func didFinishFindingLocationAndAddress(locationInfo: [NSObject : AnyObject]) {
        let geoResult = locationInfo["geoCodeResult"] as? BMKReverseGeoCodeResult
        self.HUD?.hide(true)
        self.HUD = nil
        
        if geoResult != nil {
            if Toolbox.isStringValueValid(geoResult?.address) {
                if geoResult?.addressDetail.province == geoResult?.addressDetail.city {
                    // city name equals province name, such as 北京，上海，重庆，香港，台湾 and so on
                    var locatedProvinceName:String? = Toolbox.removeSuffixOfProvinceAndCity(geoResult!.addressDetail.province)
                    self.completeLocation = locatedProvinceName
                    // update the complete location
                    let potentialLocationSectionRow:NSIndexPath = NSIndexPath(forRow: 0, inSection: 0)
                    self.tableView.reloadRowsAtIndexPaths([potentialLocationSectionRow], withRowAnimation: .Fade)
                    
                    locatedProvinceName = nil
                } else {
                    var locatedProvinceName:String? = Toolbox.removeSuffixOfProvinceAndCity(geoResult!.addressDetail.province)
                    var locatedCityName:String? = Toolbox.removeSuffixOfProvinceAndCity(geoResult!.addressDetail.city)
                    
                    self.completeLocation = "" + locatedProvinceName! + "" + locatedCityName!
                    // update the complete location
                    let potentialLocationSectionRow = NSIndexPath(forRow: 0, inSection: 0)
                    self.tableView.reloadRowsAtIndexPaths([potentialLocationSectionRow], withRowAnimation: .Fade)
                    
                    locatedCityName = nil
                    locatedProvinceName = nil
                }
                Toolbox.toggleButton(self.button_submitUserLocation!, enabled: true)
                // retrieve user current location coordinate
                let userLocation = locationInfo["locationObject"] as! BMKUserLocation
                self.userLocationCoordinate = userLocation.location.coordinate
            } else {
                Toolbox.showCustomAlertViewWithImage("unhappy", title: "位置信息无效")
            }
        } else {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "找不到对应的位置信息")
        }
        
        if self.locationService != nil {
            self.locationService?.delegate = nil
            self.locationService = nil
        }
    }
    
    func didFinishFindingGeoCodeResult(geoCodeInfo: [NSObject : AnyObject]) {
        // hide spinner to indicate geoSearch is done
        self.HUD?.hide(true)
        self.HUD = nil
        
        let result = geoCodeInfo["geoCodeResult"] as? BMKGeoCodeResult
        if geoCodeInfo["error"]?.integerValue == 0 {
            let currentUser = Singleton_CurrentUser.sharedInstance
            let locationInfo = ["latitude": "\(Double(result!.location.latitude))", "longitude": "\(Double(result!.location.longitude))", "location": self.completeLocation!]
            currentUser.updateUserInfo("location", infoValue: locationInfo)
        } else {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "找不到对应的位置信息")
        }
        
        self.locationService?.delegate = nil
        self.locationService = nil
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return TableSectionHeaderHeight
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 {   // for the first section, there is a submit button that needs to be added to its footer
            return TableSectionFooterHeightWithButton
            
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView: UIView? = UIView(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: TableSectionHeaderHeight))
        if section == 1 {
            headerView?.addSubview(Appearance.setupTableSectionHeaderTitle(" 选择省份"))
        }
        return headerView
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 0 {   // add button to the footer for third table section only
            let footerView: UIView? = UIView(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: 70))
            self.button_submitUserLocation = Appearance.setupTableFooterButtonWithTitle("提交", backgroundColor: ColorSettledGreen)
            self.button_submitUserLocation?.addTarget(self, action: "submitUserLocation", forControlEvents: .TouchUpInside)
            footerView?.addSubview(self.button_submitUserLocation!)
            if !Toolbox.isStringValueValid(self.completeLocation) {
                Toolbox.toggleButton(self.button_submitUserLocation!, enabled: false)
            }
            
            return footerView
        }
        return nil
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return self.provinceNames.count
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var tableCellIdentifier: String?
        if indexPath.section == 0 {
            tableCellIdentifier = "userLocationCell"
        } else {
            tableCellIdentifier = "provinceNameCell"
        }
        var cell: UITableViewCell? = self.tableView.dequeueReusableCellWithIdentifier(tableCellIdentifier!) as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: tableCellIdentifier)
        }
        if indexPath.section == 0 { // section to display current location or selected province/city by user
            let label_potentialUserLocation: UILabel = cell?.contentView.viewWithTag(1) as! UILabel
            label_potentialUserLocation.text = self.completeLocation
            
            // make this table cell NOT selectable
            cell?.selectionStyle = .None
        } else if indexPath.section == 1 {  // section to display Chinese province list
            let label_provinceName: UILabel = cell?.contentView.viewWithTag(1) as! UILabel
            label_provinceName.text = self.provinceNames[indexPath.row]
        }
        
        return cell!
    }
    
    @IBAction func unwindToUpdatedUserLocationTableView(segue: UIStoryboardSegue) {
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 1 {
            self.selectedProvinceName = self.provinceNames[indexPath.row]
            
            let dbManager: DBManager = DBManager(databaseFilename: "soccer_ios.sqlite")
            let cityRecordsForSelectedProvince: NSArray = dbManager.loadDataFromDB(
                "select name from cities where province=?",
                parameters: [self.selectedProvinceName!])
            
            if cityRecordsForSelectedProvince.count > 1 {   // if there is only one city in selected province, there is NO NEED to make user select city, provinces with this situation are 北京，上海，天津，重庆，香港 and so on
                
                self.performSegueWithIdentifier("setUserCitySegue", sender: self)
            } else {
                // remove the cell selection style effect
                self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
                self.completeLocation = self.selectedProvinceName
                // update the complete location
                let potentialLocationSectionRow: NSIndexPath = NSIndexPath(forRow: 0, inSection: 0)
                self.tableView.reloadRowsAtIndexPaths([potentialLocationSectionRow], withRowAnimation: .Fade)
                Toolbox.toggleButton(self.button_submitUserLocation!, enabled: true)
                
                self.isLocationHandPickedByUser = true
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "setUserCitySegue" {
            let destinationViewController = segue.destinationViewController as! VTSelectUserCityTableViewController
            destinationViewController.selectedProvinceName = self.selectedProvinceName
        }
    }
    
    func submitUserLocation() {
        if !Toolbox.isStringValueValid(self.completeLocation) {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "请确定用户所在地")
            return
        }
        if self.isLocationHandPickedByUser! == true {
            // user city is han picked by user
            // need to get user latitude/longitude info based on user selected address, so before submitting the user city to server, start a location search to find out the geoCode info of the city
            self.locationService = LocationService()
            self.locationService?.delegate = self
            self.locationService?.startToFindGeoCodeResultBasedOnAddress(self.completeLocation!)
        } else {
            // user location is located by system geolocation function, which means the user current location coordinate is already recorded, we could submit the request to server directly
            let locationInfo: NSDictionary = ["latitude": "\(Double(self.userLocationCoordinate!.latitude))", "longitude": "\(Double(self.userLocationCoordinate!.longitude))", "location": self.completeLocation!]
            Singleton_CurrentUser.sharedInstance.updateUserInfo("location", infoValue: locationInfo)
        }
    }
    
}
