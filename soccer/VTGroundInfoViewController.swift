//
//  VTGroundInfoViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/10/20.
//  Copyright © 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTGroundInfoViewController: UIViewController, BMKMapViewDelegate, LocationServiceDelegate {
    
    var groundObject: Ground?
    var mapView: BMKMapView?
    var HUD: MBProgressHUD?
    var locationService: LocationService?
    var currentLocationAnnotation: BMKPointAnnotation?

    @IBOutlet weak var button_locateUser: UIButton!
    @IBOutlet weak var button_zoomIn: UIButton!
    @IBOutlet weak var button_zoomOut: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Appearance.dropShadowForView(self.button_locateUser)
        Appearance.dropShadowForView(self.button_zoomIn)
        Appearance.dropShadowForView(self.button_zoomOut)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        Appearance.customizeNavigationBar(self, title: "球场地址")
        self.mapView = BMKMapView(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: ScreenSize.height))
        self.mapView?.zoomLevel = BaiduMapZoomLevel.default.rawValue
        let groundCoordinates = CLLocationCoordinate2D(latitude: Double(self.groundObject!.latitude)!, longitude: Double(self.groundObject!.longitude)!)
        self.mapView?.centerCoordinate = groundCoordinates
        
        let groundAddressAnnotation = BMKPointAnnotation()
        groundAddressAnnotation.title = self.groundObject?.address
        groundAddressAnnotation.coordinate = groundCoordinates
        self.mapView?.addAnnotation(groundAddressAnnotation)
        
        self.view.addSubview(self.mapView!)
        self.view.bringSubview(toFront: self.button_locateUser)
        self.view.bringSubview(toFront: self.button_zoomIn)
        self.view.bringSubview(toFront: self.button_zoomOut)
        
        self.mapView?.viewWillAppear()
        self.mapView?.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        self.mapView?.viewWillDisappear()
        self.mapView?.delegate = nil
        self.mapView = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        if self.mapView != nil {
            self.mapView?.delegate = nil
            self.mapView?.removeFromSuperview()
            self.mapView = nil
        }
        if self.locationService != nil {
            self.locationService?.delegate = nil
            self.locationService = nil
        }
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
    
    deinit {
        self.groundObject = nil
        if self.mapView != nil {
            self.mapView?.delegate = nil
            self.mapView = nil
        }
        if self.locationService != nil {
            self.locationService?.delegate = nil
            self.locationService = nil
        }
        self.HUD = nil
        self.currentLocationAnnotation = nil
    }

}
