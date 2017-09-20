//
//  VTUpdateTeamHomeCourtViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/20.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTUpdateTeamHomeCourtViewController: UIViewController, NSURLConnectionDelegate, NSURLConnectionDataDelegate, UITextFieldDelegate, BMKMapViewDelegate, LocationServiceDelegate {
    
    var homeCourt: String?
    var teamLocation: String?
    var latitude: String?
    var longitude: String?
    var teamId: String?
    var HUD: MBProgressHUD?
    var mapView: BMKMapView?
    var locationService: LocationService?
    var responseData: NSMutableData? = NSMutableData()
    var poiAnnotations: [BMKPointAnnotation]? = [BMKPointAnnotation]()
    var currentLocationAnnotation: BMKPointAnnotation?
    var selectedHomeCourtAddress: String?
    var selectedCoordinates: CLLocationCoordinate2D?
    
    @IBOutlet weak var view_searchBar: UIView!
    @IBOutlet weak var button_submit: UIButton!
    @IBOutlet weak var input_homeCourtAddress: UITextField!
    @IBOutlet weak var button_locateUser: UIButton!
    @IBOutlet weak var button_zoomIn: UIButton!
    @IBOutlet weak var button_zoomOut: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.teamId = UserDefaults.standard.object(forKey: "teamIdSelectedInTeamsList") as? String

        self.button_submit.isHidden = true

        // setup drop shadow for search bar view
        Appearance.dropShadowForView(self.view_searchBar)
        self.view_searchBar.alpha = 0.9
        
        Appearance.dropShadowForView(self.button_locateUser)
        Appearance.dropShadowForView(self.button_zoomIn)
        Appearance.dropShadowForView(self.button_zoomOut)
        
        self.input_homeCourtAddress.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        Appearance.customizeNavigationBar(self, title: "球队主场")
        
        self.mapView = BMKMapView(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: ScreenSize.height))
        self.mapView?.zoomLevel = BaiduMapZoomLevel.default.rawValue
        if Toolbox.isStringValueValid(self.latitude) && Toolbox.isStringValueValid(self.longitude) {
            let teamCoordinate = CLLocationCoordinate2D(latitude: Double(self.latitude!)!, longitude: Double(self.longitude!)!)
            self.mapView?.centerCoordinate = teamCoordinate
            
            // if the home court is already set up previously, add a point annotation of the previously set home court on map view
            if Toolbox.isStringValueValid(self.homeCourt) {
                let poiAnnotation = BMKPointAnnotation()
                poiAnnotation.title = self.homeCourt
                poiAnnotation.coordinate = teamCoordinate
                self.mapView?.addAnnotation(poiAnnotation)
                self.poiAnnotations?.append(poiAnnotation)
            }
        }
        self.view.addSubview(self.mapView!)
        self.view.bringSubview(toFront: self.view_searchBar)
        self.view.bringSubview(toFront: self.button_locateUser)
        self.view.bringSubview(toFront: self.button_zoomIn)
        self.view.bringSubview(toFront: self.button_zoomOut)
        self.view.bringSubview(toFront: self.button_submit)
        
        self.mapView?.viewWillAppear()
        self.mapView?.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        self.mapView?.viewWillDisappear()
        self.mapView?.delegate = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        if self.mapView != nil {
            self.mapView?.delegate = nil
            self.mapView?.removeFromSuperview()
            self.mapView = nil
        }
        if self.poiAnnotations != nil {
            self.poiAnnotations?.removeAll()
            self.poiAnnotations = nil
        }
        if self.locationService != nil {
            self.locationService?.delegate = nil
            self.locationService = nil
        }
    }
    
    func mapView(_ mapView: BMKMapView!, onClickedMapBlank coordinate: CLLocationCoordinate2D) {
        self.input_homeCourtAddress.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.input_homeCourtAddress.resignFirstResponder()
        self.launchPOISearchBasedOnUserInputKeyword(self)
        return true
    }
    
    @IBAction func updateHomeCourt(_ sender: AnyObject) {
        let newHomeCourt = self.input_homeCourtAddress.text!
        var connection = Toolbox.asyncHttpPostToURL(
            URLChangeTeamHomeCourt,
            parameters: "teamId=\(self.teamId!)&homeCourt=\(newHomeCourt)&address=\(self.selectedHomeCourtAddress!)&latitude=\(self.selectedCoordinates!.latitude)&longitude=\(self.selectedCoordinates!.longitude)", delegate: self
        )
        if connection == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            self.homeCourt = newHomeCourt
            self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: nil)
        }
        // release the allocated memory
        connection = nil
    }
    
    @IBAction func launchPOISearchBasedOnUserInputKeyword(_ sender: AnyObject) {
        let searchKeyword = self.input_homeCourtAddress.text
        if searchKeyword?.characters.count == 0 || searchKeyword == nil {
            return
        }
        let teamCity = Toolbox.removeProvinceNameFromString(self.teamLocation!)
        if self.locationService == nil {
            self.locationService = LocationService()
            self.locationService?.delegate = self
        }
        self.locationService?.startToSearchPOIBasedOnAddress(searchKeyword!, city: teamCity)
        self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: "查找球场中...")
    }
    
    /**
    LocationService delegate method, gets called when poi search finished with results
    
    - parameter poiResult: the poi search result, contains poiList
    */
    func didFinishSearchingPOIResult(_ poiResult: BMKPoiResult) {
        self.HUD?.hide(true)
        self.HUD = nil
        let poiInfoList = poiResult.poiInfoList
        if poiResult.poiInfoList == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "没有找到该地址")
            return
        } else if poiResult.poiInfoList.count == 0 {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "没有找到该地址")
        } else {
            self.mapView?.removeAnnotations(self.poiAnnotations)
            self.poiAnnotations?.removeAll()
            self.mapView?.centerCoordinate = (poiInfoList![0] as AnyObject).pt
            for element in poiInfoList! {
                if let poiInfo = element as? BMKPoiInfo {
                    let poiAnnotation = BMKPointAnnotation()
                    poiAnnotation.title = poiInfo.address
                    poiAnnotation.coordinate = CLLocationCoordinate2D(latitude: poiInfo.pt.latitude, longitude: poiInfo.pt.longitude)
                    self.mapView?.addAnnotation(poiAnnotation)
                    
                    self.poiAnnotations?.append(poiAnnotation)
                }
            }
        }
    }
    
    /**
    this function gets called when one of the poi annotation view is clicked
    
    - parameter mapView: the map view
    - parameter view:    the annotation view
    */
    func mapView(_ mapView: BMKMapView!, didSelect view: BMKAnnotationView!) {
        self.selectedHomeCourtAddress = view.annotation.title!()
        self.selectedCoordinates = view.annotation.coordinate
        
        // show the submit button with animation
        self.button_submit.isEnabled = true
        self.button_submit.alpha = 0.0
        self.button_submit.isHidden = false
        UIView.animate(withDuration: 0.2, animations: {
            self.button_submit.alpha = 1.0
        })
    }
    
    /**
    this function gets called when any of the poi annotation canceled selection
    
    - parameter mapView: the map view
    - parameter view:    the annotation view
    */
    func mapView(_ mapView: BMKMapView!, didDeselect view: BMKAnnotationView!) {
        self.selectedHomeCourtAddress = nil
        self.selectedCoordinates = nil
        
        // hide the submit button with animation
        self.button_submit.isEnabled = false
        self.button_submit.isHidden = true
    }
    
    /**
    Baidu mapView delegate method to generate annotation view, just like tableView cellForRowAtIndex
    
    - parameter mapView:    the baidu map view
    - parameter annotation: the annotation
    
    - returns: the generated annotation view
    */
    func mapView(_ mapView: BMKMapView!, viewFor annotation: BMKAnnotation!) -> BMKAnnotationView! {
        if annotation.isKind(of: BMKPointAnnotation.self) {
            let newAnnotationView = BMKPinAnnotationView(annotation: annotation, reuseIdentifier: "POIAnnotation")
            newAnnotationView?.animatesDrop = true
            newAnnotationView?.canShowCallout = true
            if annotation.subtitle?() == "当前位置" {
                newAnnotationView?.image = UIImage(named: "user_location")
                newAnnotationView?.animatesDrop = false
            }
            return newAnnotationView
        }
        return nil
    }
    
    /**
    LocationService delegate method to indicate that POI searching failed
    */
    func didFailToSearchPOI() {
        self.HUD?.hide(true)
        self.HUD = nil
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "查询地址失败")
    }
    
    @IBAction func locateUser(_ sender: AnyObject) {
        if self.locationService == nil {
            self.locationService = LocationService()
            self.locationService?.delegate = self
        }
        self.locationService?.shouldGetReverseGeoCode = false
        self.locationService?.launchLocationService()
    }
    
    func didStartToLocate() {
        self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: "正在定位中...")
    }
    
    func didGetUserCoordinates(_ coordinate: CLLocationCoordinate2D) {
        self.HUD?.hide(true)
        self.HUD = nil
        self.mapView?.centerCoordinate = coordinate
        
        if self.currentLocationAnnotation != nil {
            self.mapView?.removeAnnotation(self.currentLocationAnnotation)
            self.currentLocationAnnotation = nil
        }
        self.currentLocationAnnotation = BMKPointAnnotation()
        self.currentLocationAnnotation?.coordinate = coordinate
        self.currentLocationAnnotation?.subtitle = "当前位置"
        self.mapView?.addAnnotation(self.currentLocationAnnotation)
    }
    
    func didFailToLocateUser() {
        self.HUD?.hide(true)
        self.HUD = nil
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "定位失败")
    }
    
    @IBAction func zoomInMap(_ sender: AnyObject) {
        var currentZoomLevel = self.mapView!.zoomLevel
        if currentZoomLevel < BaiduMapZoomLevel.max.rawValue {
            currentZoomLevel = currentZoomLevel + 1
            self.mapView?.zoomLevel = currentZoomLevel
        }
        if self.button_zoomOut.isEnabled == false {
            Toolbox.toggleButton(self.button_zoomOut, enabled: true)
        }
        if currentZoomLevel == BaiduMapZoomLevel.max.rawValue {
            Toolbox.toggleButton(self.button_zoomIn, enabled: false)
        }
    }
    
    @IBAction func zoomOutMap(_ sender: AnyObject) {
        var currentZoomLevel = self.mapView!.zoomLevel
        if currentZoomLevel > BaiduMapZoomLevel.min.rawValue {
            currentZoomLevel = currentZoomLevel - 1
            self.mapView?.zoomLevel = currentZoomLevel - 1
        }
        if self.button_zoomIn.isEnabled == false {
            Toolbox.toggleButton(self.button_zoomIn, enabled: true)
        }
        if currentZoomLevel == BaiduMapZoomLevel.min.rawValue {
            Toolbox.toggleButton(self.button_zoomOut, enabled: false)
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
        let responseStr:NSString? = NSString(data: self.responseData! as Data, encoding: String.Encoding.utf8.rawValue)
        
        if responseStr == "OK" {    // team home court updated successfully
            // update the team name in local database
            let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
            let correspondingTeams:NSArray = dbManager!.loadData(
                fromDB: "select * from teams where teamId=?",
                parameters: [self.teamId!]
            ) as NSArray
            if correspondingTeams.count > 0 {   // team with such team id found in local database
                let team = Team.formatDatabaseRecordToTeamFormat(correspondingTeams[0] as! [AnyObject])
                // update team home court in dictionary and then save it in local database
                team.homeCourt = self.homeCourt!
                team.latitude = "\(self.selectedCoordinates!.latitude)"
                team.longitude = "\(self.selectedCoordinates!.longitude)"
                // save the updated team in local database
                team.saveOrUpdateTeamInDatabase()
                
                // unwind navigation controller to the previous view controller
                self.navigationController?.popViewController(animated: true)
            } else {    // team with the team id NOT found in local database
                Toolbox.showCustomAlertViewWithImage("unhappy", title: "本地球队不存在")
            }
        } else {    // team home court update failed with error message
            Toolbox.showCustomAlertViewWithImage("unhappy", title: responseStr as! String)
        }
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    deinit {
        self.homeCourt = nil
        self.teamLocation = nil
        self.teamId = nil
        self.HUD = nil
        self.responseData = nil
        if self.mapView != nil {
            self.mapView?.delegate = nil
            self.mapView = nil
        }
        if self.locationService != nil {
            self.locationService?.delegate = nil
            self.locationService = nil
        }
        if self.poiAnnotations != nil {
            self.poiAnnotations?.removeAll()
            self.poiAnnotations = nil
        }
        self.selectedHomeCourtAddress = nil
        self.selectedCoordinates = nil
        self.currentLocationAnnotation = nil
    }
    
}
