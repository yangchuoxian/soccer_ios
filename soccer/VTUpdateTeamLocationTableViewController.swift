//
//  VTUpdateTeamLocationTableViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/20.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTUpdateTeamLocationTableViewController: UITableViewController, NSURLConnectionDataDelegate, NSURLConnectionDelegate, LocationServiceDelegate {

    var provinceNames = [String]()
    var selectedProvinceName: String?
    var completeLocation: String?
    var HUD: MBProgressHUD?
    var button_submitTeamLocation: UIButton?
    var locationService: LocationService?
    var teamId: String?
    var responseData: NSMutableData? = NSMutableData()
    var isLocationHandPickedByUser: Bool?
    var teamLocationCoordinate: CLLocationCoordinate2D?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Appearance.customizeNavigationBar(self, title: "球队所在地")
        self.teamId = NSUserDefaults.standardUserDefaults().stringForKey("teamIdSelectedInTeamsList")
        let dbManager:DBManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        let provinceRecords = dbManager.loadDataFromDB("select name from provinces", parameters: nil)
        
        for anyObject in provinceRecords {
            let provinceRecord = anyObject as? NSArray
            if provinceRecord != nil {
                self.provinceNames.append(provinceRecord![0] as! String)
            }
        }
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        self.clearsSelectionOnViewWillAppear = true
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
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if self.completeLocation != nil {   // user has manually select the team city
            // update the complete location
            let potentialLocationSectionRow = NSIndexPath(forItem: 0, inSection: 0)
            self.tableView.reloadRowsAtIndexPaths([potentialLocationSectionRow], withRowAnimation: .Fade)
            Toolbox.toggleButton(self.button_submitTeamLocation!, enabled: true)
            
            self.isLocationHandPickedByUser = true
        } else {    // first try to locate user current city automatically
            self.locationService = LocationService()
            self.locationService?.delegate = self
            self.locationService?.launchLocationService()
            
            self.isLocationHandPickedByUser = false
        }
    }
    
    func didStartToLocate() {
        // Show loading spinner HUD to indicate that locating user is in process
        self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: "正在定位...")
    }
    
    func didFailToLocateUser() {
        self.HUD?.hide(true)
        self.HUD = nil
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "定位失败")
    }
    
    func didFinishFindingLocationAndAddress(locationInfo: [NSObject : AnyObject]) {
        let geoResult:BMKReverseGeoCodeResult? = locationInfo["geoCodeResult"] as? BMKReverseGeoCodeResult
        self.HUD?.hide(true)
        if geoResult != nil {
            if Toolbox.isStringValueValid(geoResult?.address) {
                if geoResult!.addressDetail.province == geoResult?.addressDetail.city {
                    // city name equals province name, such as 北京，上海，重庆，香港，台湾 and so on
                    let locatedProvinceName = Toolbox.removeSuffixOfProvinceAndCity(geoResult!.addressDetail.province)
                    self.completeLocation = locatedProvinceName
                    // update the complete location
                    let potentialLocationSectionRow = NSIndexPath(forRow: 0, inSection: 0)
                    self.tableView.reloadRowsAtIndexPaths([potentialLocationSectionRow], withRowAnimation: .Fade)
                } else {
                    let locatedProvinceName = Toolbox.removeSuffixOfProvinceAndCity(geoResult!.addressDetail.province)
                    let locatedCityName = Toolbox.removeSuffixOfProvinceAndCity(geoResult!.addressDetail.city)
                    
                    self.completeLocation = "\(locatedProvinceName)" + "\(locatedCityName)"
                    // update the complete location
                    let potentialLocationSectionRow = NSIndexPath(forRow: 0, inSection: 0)
                    self.tableView.reloadRowsAtIndexPaths([potentialLocationSectionRow], withRowAnimation: .Fade)
                }
                Toolbox.toggleButton(self.button_submitTeamLocation!, enabled: true)
                // retrieve user current locatoin coordinate
                let userLocation = locationInfo["locationObject"] as! BMKUserLocation
                self.teamLocationCoordinate = userLocation.location.coordinate
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
            self.teamLocationCoordinate?.latitude = result!.location.latitude
            self.teamLocationCoordinate?.longitude = result!.location.longitude
            let postDataParameters = "id=\(self.teamId!)&location=\(self.completeLocation!)&latitude=\(Double(result!.location.latitude))&longitude=\(Double(result!.location.longitude))"
            let connection = Toolbox.asyncHttpPostToURL(URLChangeTeamLocation, parameters: postDataParameters, delegate: self)
            if connection == nil {
                // inform the user that the connection failed
                Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
            } else {
                self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: nil)
            }
        } else {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "找不到对应的位置信息")
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return TableSectionFooterHeight
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 {   // for the first section, there is a create new team button that needs to be added to its footer
            return TableSectionFooterHeightWithButton
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: TableSectionHeaderHeight))
        if section == 1 {
            headerView.addSubview(Appearance.setupTableSectionHeaderTitle(" 选择省份"))
        }
        return headerView
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 0 {   //add button to the footer for third table section only
            let footerView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: 70))
            self.button_submitTeamLocation = Appearance.setupTableFooterButtonWithTitle("提交", backgroundColor: ColorSettledGreen)
            self.button_submitTeamLocation?.addTarget(self, action: "submitTeamLocation", forControlEvents: .TouchUpInside)
            if !Toolbox.isStringValueValid(self.completeLocation) {
                Toolbox.toggleButton(self.button_submitTeamLocation!, enabled: false)
            }
            footerView.addSubview(self.button_submitTeamLocation!)
            
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
        var tableCellIdentifier = ""
        if indexPath.section == 0 {
            tableCellIdentifier = "teamLocationCell"
        } else {
            tableCellIdentifier = "provinceNameCell"
        }
        var cell = self.tableView.dequeueReusableCellWithIdentifier(tableCellIdentifier) as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: tableCellIdentifier)
        }
        if indexPath.section == 0 { // section to display current location or selected province/city by user
            // current location or user selected location label
            let label_potentialTeamLocation = cell?.contentView.viewWithTag(1) as! UILabel
            label_potentialTeamLocation.text = self.completeLocation
            // make this table cell NOT selectable
            cell?.selectionStyle = .None
        } else if indexPath.section == 1 {  // section to display Chinese province list
            let label_provinceName = cell?.contentView.viewWithTag(1) as! UILabel
            label_provinceName.text = self.provinceNames[indexPath.row]
        }
        return cell!
    }
    
    @IBAction func unwindToChangeTeamLocationTableView(segue: UIStoryboardSegue) {
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 1 {
            self.selectedProvinceName = self.provinceNames[indexPath.row]
            let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
            let cityRecordsForSelectedProvince = dbManager.loadDataFromDB(
                "select name from cities where province=?",
                parameters: [self.selectedProvinceName!]
            )
            if cityRecordsForSelectedProvince.count > 1 {   // if there is only one city in selected province, there is NO NEED to make user select city, provinces with this situation are 北京，上海，天津，重庆，香港 and so on
                self.performSegueWithIdentifier("setTeamCitySegue", sender: self)
            } else {
                // remove the cell selection style effect
                self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
                self.completeLocation = self.selectedProvinceName
                // update the complete location
                let potentialLocationSectionRow:NSIndexPath = NSIndexPath(forRow: 0, inSection: 0)
                self.tableView.reloadRowsAtIndexPaths([potentialLocationSectionRow], withRowAnimation: .Fade)
                Toolbox.toggleButton(self.button_submitTeamLocation!, enabled: true)
                
                self.isLocationHandPickedByUser = true
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "setTeamCitySegue" {
            let destinationViewController = segue.destinationViewController as! VTUpdateTeamCityTableViewController
            destinationViewController.selectedProvinceName = self.selectedProvinceName
        }
    }
    
    func submitTeamLocation() {
        if !Toolbox.isStringValueValid(self.completeLocation) {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "请确定球队所在地")
            return
        }
        if self.isLocationHandPickedByUser! == true {   // user locationcity hand picked by user himself/herself
            self.locationService = LocationService()
            self.locationService?.delegate = self
            self.locationService?.startToFindGeoCodeResultBasedOnAddress(self.completeLocation!)
        } else {    // located user automatically
            let postDataParameters = "id=\(self.teamId!)&location=\(self.completeLocation!)&latitude=\(Double(self.teamLocationCoordinate!.latitude))&longitude=\(Double(self.teamLocationCoordinate!.longitude))"
            let connection = Toolbox.asyncHttpPostToURL(URLChangeTeamLocation, parameters: postDataParameters, delegate: self)
            if connection == nil {
                // inform the user that the connection failed
                Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
            } else {
                self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: nil)
            }
        }
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        self.responseData?.appendData(data)
    }
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        self.HUD?.hide(true)
        self.HUD = nil
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络超时")
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        self.HUD?.hide(true)
        self.HUD = nil
        let responseStr:NSString = NSString(data: self.responseData!, encoding: NSUTF8StringEncoding)!
        
        if responseStr == "OK" {    // team location update successfully
            // update the team location in local database
            let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
            let correspondingTeams = dbManager.loadDataFromDB(
                "select * from teams where teamId=?",
                parameters: [self.teamId!]
            )
            if correspondingTeams.count > 0 {   // team with such team id found in local database
                let team = Team.formatDatabaseRecordToTeamFormat(correspondingTeams[0] as! [AnyObject])
                // update team name in dictionary and then save it in local database
                team.location = self.completeLocation!
                team.latitude = "\(self.teamLocationCoordinate!.latitude)"
                team.longitude = "\(self.teamLocationCoordinate!.longitude)"
                
                // save the updated team in local database
                team.saveOrUpdateTeamInDatabase()
                
                // unwind navigation controller to the previous view controller
                self.navigationController?.popViewControllerAnimated(true)
            } else {    // team with the team id NOT found in local database
                Toolbox.showCustomAlertViewWithImage("unhappy", title: "本地球队不存在")
            }
        } else {    // team location update failed
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "所在地更新失败")
        }
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    deinit {
        self.responseData = nil
        self.provinceNames.removeAll(keepCapacity: false)
        if self.button_submitTeamLocation != nil {
            self.button_submitTeamLocation?.removeTarget(nil, action: nil, forControlEvents: .AllEvents)
            self.button_submitTeamLocation = nil
        }
        self.selectedProvinceName = nil
        self.completeLocation = nil
        self.HUD = nil
        self.teamId = nil
        if self.locationService != nil {
            self.locationService?.delegate = nil
            self.locationService = nil
        }
        self.teamLocationCoordinate = nil
        self.isLocationHandPickedByUser = nil
    }
    
}
