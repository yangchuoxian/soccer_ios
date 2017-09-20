//
//  VTNewTeamLocationTableViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/3.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTNewTeamLocationTableViewController: UITableViewController, NSURLConnectionDelegate, NSURLConnectionDataDelegate, LocationServiceDelegate {
    
    var provinceNames = [String]()
    var selectedProvinceName: String?
    var completeLocation: String?
    var button_submitNewTeam: UIButton?
    var HUD: MBProgressHUD?
    var locationService: LocationService?
    var teamName: String?
    var isLocationHandPickedByUser: Bool?
    var teamLocationCoordinate: CLLocationCoordinate2D?
    var responseData: NSMutableData? = NSMutableData()
    
    let locationTableCellIdenfitier = "teamLocationCell"
    let provinceTableCellIdenfitier = "provinceNameCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.clearsSelectionOnViewWillAppear = true
        Appearance.customizeNavigationBar(self, title: "选择所在地")
        
        let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        let provinceRecords = dbManager?.loadData(
            fromDB: "select name from provinces",
            parameters:nil
        )
        for anyObject in provinceRecords! {
            let provinceRecord = anyObject as? NSArray
            if provinceRecord != nil {
                self.provinceNames.append(provinceRecord![0] as! String)
            }
        }
        // Set this in every view controller so that the back button displays back instead of the root view controller name
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        // add right button in navigation bar programmatically
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .stop,
            target: self,
            action: #selector(VTNewTeamLocationTableViewController.cancelNewTeamCreation)
        )
    }
    
    func cancelNewTeamCreation() {
    // close modal view and all its related navigation controller to go back to teams list table view
    self.performSegue(withIdentifier: "cancelNewTeamCreationFromTeamLocationViewControllerSegue", sender: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if Toolbox.isStringValueValid(self.completeLocation) {    // user has manually select the team city
            // update the complete location
            let potentialLocationSectionRow = IndexPath(row: 0, section: 0)
            self.tableView.reloadRows(at: [potentialLocationSectionRow], with: .fade)
            Toolbox.toggleButton(self.button_submitNewTeam!, enabled: true)
            
            self.isLocationHandPickedByUser = true
        } else {    // first try to locate user current city automatically
            self.locationService = LocationService()
            self.locationService?.delegate = self
            self.locationService?.launchLocationService()
            
            self.isLocationHandPickedByUser = false
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
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
        // show loading spinner HUD to indicate that searching nearby teams is in process
        self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: "正在定位...")
    }
    
    func didFailToLocateUser() {
        self.HUD?.hide(true)
        self.HUD = nil
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "定位失败")
    }
    
    func didFinishFindingLocationAndAddress(_ locationInfo: [AnyHashable: Any]) {
        let geoResult = locationInfo["geoCodeResult"] as? BMKReverseGeoCodeResult
        
        self.HUD?.hide(true)
        self.HUD = nil
        
        if geoResult != nil {
            if Toolbox.isStringValueValid(geoResult?.address) {
                if geoResult?.addressDetail.province == geoResult?.addressDetail.city {
                    // city name equals province name, such as 北京，上海，重庆，香港，台湾 and so on
                    let locatedProvinceName = Toolbox.removeSuffixOfProvinceAndCity(geoResult!.addressDetail.province)
                    self.completeLocation = locatedProvinceName
                    // update the complete location
                    let potentialLocationSectionRow = IndexPath(row: 0, section: 0)
                    self.tableView.reloadRows(at: [potentialLocationSectionRow], with: .fade)
                } else {
                    let locatedProvinceName = Toolbox.removeSuffixOfProvinceAndCity(geoResult!.addressDetail.province)
                    let locatedCityName = Toolbox.removeSuffixOfProvinceAndCity(geoResult!.addressDetail.city)
                    
                    self.completeLocation = "" + locatedProvinceName + "" + locatedCityName
                    // update the complete location
                    let potentialLocationSectionRow = IndexPath(row: 0, section: 0)
                    self.tableView.reloadRows(at: [potentialLocationSectionRow], with: .fade)
                }
                Toolbox.toggleButton(self.button_submitNewTeam!, enabled: true)
                // retrieve user current location coordinate
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
    
    func didFinishFindingGeoCodeResult(_ geoCodeInfo: [AnyHashable: Any]) {
        // hide spinner to indicate geoSearch is done
        self.HUD?.hide(true)
        self.HUD = nil
        
        let result = geoCodeInfo["geoCodeResult"] as? BMKGeoCodeResult
        if (geoCodeInfo["error"] as AnyObject).intValue == 0 {
            let postDataDictionary = [
                "name": self.teamName!,
                "location": self.completeLocation!,
                "latitude": "\(Double(result!.location.latitude))",
                "longitude": "\(Double(result!.location.longitude))"
            ]
            let postDataParameters = "team=" + Toolbox.convertDictionaryOrArrayToJSONString(postDataDictionary)
            let connection = Toolbox.asyncHttpPostToURL(URLSubmitNewTeam, parameters: postDataParameters, delegate: self)
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

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return TableSectionHeaderHeight
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 {     // for the first section, there's a create new team button that needs to be added to its footer
            return TableSectionFooterHeightWithButton
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: TableSectionHeaderHeight))
        if section == 1 {
            headerView.addSubview(Appearance.setupTableSectionHeaderTitle(" 选择省份"))
        }
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 0 {     // add button to the footer for third table section only
            let footerView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: TableSectionFooterHeightWithButton))
            
            // initialize button_recruiteNewMember and set up its appearance
            self.button_submitNewTeam = Appearance.setupTableFooterButtonWithTitle("创建球队", backgroundColor: ColorSettledGreen)
            self.button_submitNewTeam!.addTarget(
                self,
                action: #selector(VTNewTeamLocationTableViewController.submitNewTeam),
                for: .touchUpInside
            )
            footerView.addSubview(self.button_submitNewTeam!)
            if !Toolbox.isStringValueValid(self.completeLocation) {
                Toolbox.toggleButton(self.button_submitNewTeam!, enabled: false)
            }
            
            return footerView
        }
        return nil
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return self.provinceNames.count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var tableCellIdenfitier: String
        if (indexPath as NSIndexPath).section == 0 {
            tableCellIdenfitier = self.locationTableCellIdenfitier
        } else {
            tableCellIdenfitier = self.provinceTableCellIdenfitier
        }
        var cell = self.tableView.dequeueReusableCell(withIdentifier: tableCellIdenfitier) as UITableViewCell?
        
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: tableCellIdenfitier)
        }
        
        if (indexPath as NSIndexPath).section == 0 {   // section to display current location or selected province/city by user
            // current location or user selected location label
            let label_potentialTeamLocation = cell?.contentView.viewWithTag(1) as! UILabel
            label_potentialTeamLocation.text = self.completeLocation
            
            // make this table cell NOT selectable
            cell?.selectionStyle = .none
        } else if (indexPath as NSIndexPath).section == 1 {    // section to display Chinese province list
            let label_provinceName = cell?.contentView.viewWithTag(1) as! UILabel
            label_provinceName.text = self.provinceNames[(indexPath as NSIndexPath).row]
        }
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // remove the cell selection style effect
        self.tableView.deselectRow(at: indexPath, animated: true)
        
        if (indexPath as NSIndexPath).section == 1 {
            self.selectedProvinceName = self.provinceNames[(indexPath as NSIndexPath).row]
            
            let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
            
            let cityRecordsForSelectedProvince = dbManager?.loadData(
                fromDB: "select name from cities where province=?",
                parameters: [self.selectedProvinceName!]
            )
            
            if (cityRecordsForSelectedProvince?.count)! > 1 {     // if there is only one city in selected province, there is NO NEED to make user select city, provinces with this situation are 北京，上海，天津，重庆，香港 and so on
                self.performSegue(withIdentifier: "teamCitySegue", sender: self)
            } else {
                self.completeLocation = self.selectedProvinceName
                // update the complete location
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
                Toolbox.toggleButton(self.button_submitNewTeam!, enabled: true)
                
                self.isLocationHandPickedByUser = true
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "teamCitySegue" {
            let destinationViewController = segue.destination as! VTNewTeamCityTableViewController
            destinationViewController.selectedProvinceName = self.selectedProvinceName
        }
    }
    
    @IBAction func unwindToNewTeamLocationTableView(_ segue: UIStoryboardSegue) {
    }
    
    func submitNewTeam() {
        if !Toolbox.isStringValueValid(self.completeLocation) {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "请确定球队所在地")
            return
        }
        if self.isLocationHandPickedByUser! == true {   // user location/city hand picked by user himself/herself
            self.locationService = LocationService()
            self.locationService?.delegate = self
            self.locationService?.startToFindGeoCodeResultBasedOnAddress(self.completeLocation!)
        } else {    // located user automatically
            let postDataDictionary = [
                "name": self.teamName!,
                "location": self.completeLocation!,
                "latitude": "\(Double(self.teamLocationCoordinate!.latitude))",
                "longitude": "\(Double(self.teamLocationCoordinate!.longitude))"
            ]
            let postDataParameters = "team=" + Toolbox.convertDictionaryOrArrayToJSONString(postDataDictionary)
            let connection = Toolbox.asyncHttpPostToURL(URLSubmitNewTeam, parameters: postDataParameters, delegate: self)
            if connection == nil {
                // inform the user that the connection failed
                Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
            } else {
                self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: nil)
            }
        }
    }
    
    func connection(_ connection: NSURLConnection, didReceive data: Data) {
        self.responseData?.append(data)
    }
    
    func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        self.HUD?.hide(true)
        self.HUD = nil
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络超时")
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        self.HUD?.hide(true)
        self.HUD = nil
        
        // if creating new team succeeded, response from server should be team info JSON data, so retrieve team name from this JSON data to see if team creation is successful
        let teamInfoJSON = (try? JSONSerialization.jsonObject(with: self.responseData! as Data, options: .mutableLeaves)) as? [AnyHashable: Any]
        if teamInfoJSON?["name"] != nil {    // submit new team succeeded
            // save the new team to local database
            Team(data: teamInfoJSON! as [NSObject : AnyObject]).saveOrUpdateTeamInDatabase()
            // close modal view and all its related navigation controller to go back to teams list table view
            self.performSegue(withIdentifier: "cancelNewTeamCreationFromTeamLocationViewControllerSegue", sender: self)
        } else {    // submit new team failed, prompt user with error message
            let responseStr = NSString(data: self.responseData! as Data, encoding: String.Encoding.utf8.rawValue)
            Toolbox.showCustomAlertViewWithImage("unhappy", title: (responseStr as! String))
        }
        
        self.responseData = nil
        self.responseData = NSMutableData()
    }

    deinit {
        self.provinceNames.removeAll(keepingCapacity: false)
        self.selectedProvinceName = nil
        self.completeLocation = nil
        if self.button_submitNewTeam != nil {
            self.button_submitNewTeam?.removeTarget(nil, action: nil, for: .allEvents)
            self.button_submitNewTeam = nil
        }
        self.HUD = nil
        self.locationService = nil
        self.teamName = nil
        self.responseData = nil
        self.teamLocationCoordinate = nil
        self.isLocationHandPickedByUser = nil
    }
    
}
