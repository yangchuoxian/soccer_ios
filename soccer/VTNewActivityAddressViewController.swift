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

        self.button_nextStep.hidden = true
        Appearance.dropShadowForView(self.view_searchBar)
        self.view_searchBar.alpha = 0.9
        
        Appearance.dropShadowForView(self.button_locateUser)
        Appearance.dropShadowForView(self.button_zoomIn)
        Appearance.dropShadowForView(self.button_zoomOut)
        
        self.input_groundName.delegate = self
        
        // add right button in navigation bar to cancel new activity publication
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Stop, target: self, action: "cancelPublishingNewActivity")
    }
    
    func cancelPublishingNewActivity() {
        if self.isNewActivityMatchInitiatedFromDiscoverTab == true {
            self.performSegueWithIdentifier("unwindToTeamBriefIntroSegue", sender: self)
        } else {
            self.performSegueWithIdentifier("unwindToTeamCalendarSegue", sender: self)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        Appearance.customizeNavigationBar(self, title: "活动地址")
        
        self.mapView = BMKMapView(frame: CGRectMake(0, 0, ScreenSize.width, ScreenSize.height))
        self.mapView?.zoomLevel = BaiduMapZoomLevel.Default.rawValue
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
        self.view.bringSubviewToFront(self.view_searchBar)
        self.view.bringSubviewToFront(self.button_locateUser)
        self.view.bringSubviewToFront(self.button_zoomIn)
        self.view.bringSubviewToFront(self.button_zoomOut)
        self.view.bringSubviewToFront(self.button_nextStep)
        
        self.mapView?.viewWillAppear()
        self.mapView?.delegate = self
    }
    
    override func viewWillDisappear(animated: Bool) {
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
    
    func mapView(mapView: BMKMapView!, onClickedMapBlank coordinate: CLLocationCoordinate2D) {
        self.input_groundName.resignFirstResponder()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.input_groundName.resignFirstResponder()
        self.launchPOISearchBasedOnUserInputKeyword(self)
        return true
    }
    
    @IBAction func launchPOISearchBasedOnUserInputKeyword(sender: AnyObject) {
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
    func didFinishSearchingPOIResult(poiResult: BMKPoiResult) {
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
            self.mapView?.centerCoordinate = poiInfoList[0].pt
            for element in poiInfoList {
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
    func mapView(mapView: BMKMapView!, didSelectAnnotationView view: BMKAnnotationView!) {
        self.selectedActivityAddress = view.annotation.title!()
        self.selectedCoordinates = view.annotation.coordinate
        
        // show the submit button with animation
        self.button_nextStep.enabled = true
        self.button_nextStep.alpha = 0.0
        self.button_nextStep.hidden = false
        UIView.animateWithDuration(0.2, animations: {
            self.button_nextStep.alpha = 1.0
        })
    }
    
    /**
    this function gets called when any of the poi annotation canceled selection
    
    - parameter mapView: the map view
    - parameter view:    the annotation view
    */
    func mapView(mapView: BMKMapView!, didDeselectAnnotationView view: BMKAnnotationView!) {
        self.selectedActivityAddress = nil
        self.selectedCoordinates = nil
        
        // hide the submit button with animation
        self.button_nextStep.enabled = false
        self.button_nextStep.hidden = true
    }
    
    /**
    Baidu mapView delegate method to generate annotation view, just like tableView cellForRowAtIndex
    
    - parameter mapView:    the baidu map view
    - parameter annotation: the annotation
    
    - returns: the generated annotation view
    */
    func mapView(mapView: BMKMapView!, viewForAnnotation annotation: BMKAnnotation!) -> BMKAnnotationView! {
        if annotation.isKindOfClass(BMKPointAnnotation) {
            let newAnnotationView = BMKPinAnnotationView(annotation: annotation, reuseIdentifier: "POIAnnotation")
            newAnnotationView.animatesDrop = true
            newAnnotationView.canShowCallout = true
            if annotation.subtitle?() == "当前位置" {
                newAnnotationView.image = UIImage(named: "user_location")
                newAnnotationView.animatesDrop = false
            }
            return newAnnotationView
        }
        return nil
    }
    
    @IBAction func locateUser(sender: AnyObject) {
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
    
    func didGetUserCoordinates(coordinate: CLLocationCoordinate2D) {
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
    
    @IBAction func zoomInMap(sender: AnyObject) {
        var currentZoomLevel = self.mapView!.zoomLevel
        if currentZoomLevel < BaiduMapZoomLevel.Max.rawValue {
            currentZoomLevel = currentZoomLevel + 1
            self.mapView?.zoomLevel = currentZoomLevel
        }
        if self.button_zoomOut.enabled == false {
            Toolbox.toggleButton(self.button_zoomOut, enabled: true)
        }
        if currentZoomLevel == BaiduMapZoomLevel.Max.rawValue {
            Toolbox.toggleButton(self.button_zoomIn, enabled: false)
        }
    }
    
    @IBAction func zoomOutMap(sender: AnyObject) {
        var currentZoomLevel = self.mapView!.zoomLevel
        if currentZoomLevel > BaiduMapZoomLevel.Min.rawValue {
            currentZoomLevel = currentZoomLevel - 1
            self.mapView?.zoomLevel = currentZoomLevel - 1
        }
        if self.button_zoomIn.enabled == false {
            Toolbox.toggleButton(self.button_zoomIn, enabled: true)
        }
        if currentZoomLevel == BaiduMapZoomLevel.Min.rawValue {
            Toolbox.toggleButton(self.button_zoomOut, enabled: false)
        }
    }
    
    @IBAction func nextStepOfPublishNewActivity(sender: AnyObject) {
        var activityInfo = NSUserDefaults.standardUserDefaults().objectForKey("activityInfo") as! [String: String]
        // add the activity place and coordinates info and then save back to userDefaults
        let teamCity = Toolbox.removeProvinceNameFromString(Singleton_UserOwnedTeam.sharedInstance.location)
        activityInfo["city"] = teamCity
        activityInfo["groundName"] = self.input_groundName.text
        activityInfo["address"] = self.selectedActivityAddress
        activityInfo["latitude"] = "\(self.selectedCoordinates!.latitude)"
        activityInfo["longitude"] = "\(self.selectedCoordinates!.longitude)"
        NSUserDefaults.standardUserDefaults().setObject(activityInfo, forKey: "activityInfo")
        
        if activityInfo["type"] == "\(ActivityType.Match.rawValue)" && !Toolbox.isStringValueValid(activityInfo["idOfTeamB"]) {
            // new activity is a match and team rival has not been defined, next we should establish the rival of the match
            self.performSegueWithIdentifier("establishRivalSegue", sender: self)
        } else {
            // either the new activity is an exercise, 
            // or the team rival has already been decided,
            // next step would be enter activity note
            self.performSegueWithIdentifier("activityNoteSegue", sender: self)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "activityNoteSegue" {
            let destinationViewController = segue.destinationViewController as! VTActivityNoteViewController
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
