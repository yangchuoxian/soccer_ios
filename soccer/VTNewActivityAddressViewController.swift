//
//  VTNewActivityAddressViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/10/18.
//  Copyright © 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTNewActivityAddressViewController: UIViewController, UITextFieldDelegate, BMKMapViewDelegate, LocationServiceDelegate {

//    var homeCourt: String?
//    var teamLocation: String?
//    var teamCity: String?
//    var latitude: String?
//    var longitude: String?
//    var teamId: String?
    var HUD: MBProgressHUD?
    var mapView: BMKMapView?
    var locationService: LocationService?
    var responseData: NSMutableData? = NSMutableData()
    var poiAnnotations: [BMKPointAnnotation]? = [BMKPointAnnotation]()
    var currentLocationAnnotation: BMKPointAnnotation?
    var selectedActivityAddress: String?
    var selectedCoordinates: CLLocationCoordinate2D?
    var isNewActivityMatchInitiatedFromDiscoverTab = false
    
    @IBOutlet weak var input_groundName: UITextField!
    @IBOutlet weak var view_searchBar: UIView!
    @IBOutlet weak var button_locateUser: UIButton!
    @IBOutlet weak var button_zoomIn: UIButton!
    @IBOutlet weak var button_zoomOut: UIButton!
    @IBOutlet weak var button_nextStep: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.button_nextStep.isHidden = true
        Appearance.dropShadowForView(self.view_searchBar)
        self.view_searchBar.alpha = 0.9
        
        Appearance.dropShadowForView(self.button_locateUser)
        Appearance.dropShadowForView(self.button_zoomIn)
        Appearance.dropShadowForView(self.button_zoomOut)
        
        self.input_groundName.delegate = self
        
        // add right button in navigation bar to cancel new activity publication
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(VTNewActivityAddressViewController.cancelPublishingNewActivity))
    }
    
    func cancelPublishingNewActivity() {
        if self.isNewActivityMatchInitiatedFromDiscoverTab == true {
            self.performSegue(withIdentifier: "unwindToTeamBriefIntroSegue", sender: self)
        } else {
            self.performSegue(withIdentifier: "unwindToTeamCalendarSegue", sender: self)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        Appearance.customizeNavigationBar(self, title: "活动地址")
        
        self.mapView = BMKMapView(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: ScreenSize.height))
        self.mapView?.zoomLevel = BaiduMapZoomLevel.default.rawValue
        let userOwnedTeam = Singleton_UserOwnedTeam.sharedInstance
        if Toolbox.isStringValueValid(userOwnedTeam.latitude) && Toolbox.isStringValueValid(userOwnedTeam.longitude) {
            let teamCoordinate = CLLocationCoordinate2D(latitude: Double(userOwnedTeam.latitude)!, longitude: Double(userOwnedTeam.longitude)!)
            self.mapView?.centerCoordinate = teamCoordinate
            
            // if the home court is already set up previously, add a point annotation of the previously set home court on map view
            if Toolbox.isStringValueValid(userOwnedTeam.homeCourt) {
                let poiAnnotation = BMKPointAnnotation()
                poiAnnotation.title = userOwnedTeam.homeCourt
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
        self.view.bringSubview(toFront: self.button_nextStep)
        
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
        self.input_groundName.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.input_groundName.resignFirstResponder()
        self.launchPOISearchBasedOnUserInputKeyword(self)
        return true
    }
    
    @IBAction func launchPOISearchBasedOnUserInputKeyword(_ sender: AnyObject) {
        let searchKeyword = self.input_groundName.text
        if searchKeyword?.characters.count == 0 || searchKeyword == nil {
            return
        }
        if self.locationService == nil {
            self.locationService = LocationService()
            self.locationService?.delegate = self
        }
        let teamCity = Toolbox.removeProvinceNameFromString(Singleton_UserOwnedTeam.sharedInstance.location)
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
        self.selectedActivityAddress = view.annotation.title!()
        self.selectedCoordinates = view.annotation.coordinate
        
        // show the submit button with animation
        self.button_nextStep.isEnabled = true
        self.button_nextStep.alpha = 0.0
        self.button_nextStep.isHidden = false
        UIView.animate(withDuration: 0.2, animations: {
            self.button_nextStep.alpha = 1.0
        })
    }
    
    /**
    this function gets called when any of the poi annotation canceled selection
    
    - parameter mapView: the map view
    - parameter view:    the annotation view
    */
    func mapView(_ mapView: BMKMapView!, didDeselect view: BMKAnnotationView!) {
        self.selectedActivityAddress = nil
        self.selectedCoordinates = nil
        
        // hide the submit button with animation
        self.button_nextStep.isEnabled = false
        self.button_nextStep.isHidden = true
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
    
    @IBAction func locateUser(_ sender: AnyObject) {
        if self.locationService == nil {
            self.locationService = LocationService()
            self.locationService?.delegate = self
        }
        self.locationService?.shouldGetReverseGeoCode = false
        self.locationService?.launchLocationService()
    }
    
    /**
    LocationService delegate method to indicate that POI searching failed
    */
    func didFailToSearchPOI() {
        self.HUD?.hide(true)
        self.HUD = nil
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "查询地址失败")
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
    
    @IBAction func nextStepOfPublishNewActivity(_ sender: AnyObject) {
        var activityInfo = UserDefaults.standard.object(forKey: "activityInfo") as! [String: String]
        // add the activity place and coordinates info and then save back to userDefaults
        let teamCity = Toolbox.removeProvinceNameFromString(Singleton_UserOwnedTeam.sharedInstance.location)
        activityInfo["city"] = teamCity
        activityInfo["groundName"] = self.input_groundName.text
        activityInfo["address"] = self.selectedActivityAddress
        activityInfo["latitude"] = "\(self.selectedCoordinates!.latitude)"
        activityInfo["longitude"] = "\(self.selectedCoordinates!.longitude)"
        UserDefaults.standard.set(activityInfo, forKey: "activityInfo")
        
        if activityInfo["type"] == "\(ActivityType.match.rawValue)" && !Toolbox.isStringValueValid(activityInfo["idOfTeamB"]) {
            // new activity is a match and team rival has not been defined, next we should establish the rival of the match
            self.performSegue(withIdentifier: "establishRivalSegue", sender: self)
        } else {
            // either the new activity is an exercise, 
            // or the team rival has already been decided,
            // next step would be enter activity note
            self.performSegue(withIdentifier: "activityNoteSegue", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "activityNoteSegue" {
            let destinationViewController = segue.destination as! VTActivityNoteViewController
            destinationViewController.isNewActivityMatchInitiatedFromDiscoverTab = self.isNewActivityMatchInitiatedFromDiscoverTab
        }
    }
    
    deinit {
        self.HUD = nil
        if self.mapView != nil {
            self.mapView?.delegate = nil
            self.mapView = nil
        }
        if self.locationService != nil {
            self.locationService?.delegate = nil
            self.locationService = nil
        }
        self.responseData = nil
        if self.poiAnnotations != nil {
            self.poiAnnotations?.removeAll()
            self.poiAnnotations = nil
        }
        self.currentLocationAnnotation = nil
        self.selectedActivityAddress = nil
        self.selectedCoordinates = nil
    }
    
}
