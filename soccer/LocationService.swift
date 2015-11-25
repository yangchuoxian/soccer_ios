//
//  LocationService.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/4.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

@objc protocol LocationServiceDelegate {
    optional func didStartToLocate()
    optional func didFailToLocateUser()
    optional func didFailToSearchPOI()
    optional func didFinishFindingLocationAndAddress(locationInfo: [NSObject: AnyObject])
    optional func didFinishFindingGeoCodeResult(geoCodeInfo: [NSObject: AnyObject])
    optional func didFinishSearchingPOIResult(poiResult: BMKPoiResult)
    optional func didGetUserCoordinates(coordinate: CLLocationCoordinate2D)
}

class LocationService: NSObject, UIAlertViewDelegate, CLLocationManagerDelegate, BMKGeoCodeSearchDelegate, BMKLocationServiceDelegate, BMKPoiSearchDelegate {
    
    var baiduLocationService: BMKLocationService?
    var baiduGeoCodeSearch: BMKGeoCodeSearch?
    var baiduPOISearch: BMKPoiSearch?
    var locationManager: CLLocationManager?
    var userLocation: BMKUserLocation?
    var delegate: LocationServiceDelegate?
    /// after user geoCoordinates has been decided, this boolean value decides whether to get the location address based on the geoCoordinates or not, defaults to true
    var shouldGetReverseGeoCode = true
   
    override init () {
        super.init()
        // initialize baidu location service
        self.baiduLocationService = BMKLocationService()
        self.baiduLocationService?.delegate = self
        // initialize baidu geoCode
        self.baiduGeoCodeSearch = BMKGeoCodeSearch()
        self.baiduGeoCodeSearch?.delegate = self
    }
    
    /**
    First checks if the system location service is available.
    1. If it is, then start to locate current user location
    2. If it is not, prompt user that system geolocation is unavailable and tells the user to open system location service in settings
    */
    func launchLocationService() {
        let isDeviceGeolocationEnabled = CLLocationManager.locationServicesEnabled()
        let appGeolocationAuthorizationStatus = CLLocationManager.authorizationStatus()
        // location service is disabled system wide
        if !isDeviceGeolocationEnabled {
            let alert = UIAlertView(title: "系统定位服务已经关闭", message: "前往设置->隐私->定位服务进行设置", delegate: self, cancelButtonTitle: "确定")
            alert.show()
            return
        }
        // check app-wide location service authorization status provided by user
        if appGeolocationAuthorizationStatus == .NotDetermined {
            // user has NOT determined whether to allow or deny location service authorization for this app,
            // this is mostly happening for the first time the app is running and user asks for location service, so we ask for location service permission
            self.locationManager = CLLocationManager()
            self.locationManager?.delegate = self
            if #available(iOS 8.0, *) {
                    self.locationManager?.requestWhenInUseAuthorization()
            } else {
                // start to find out user current location
                self.baiduLocationService?.startUserLocationService()
            }
        } else if appGeolocationAuthorizationStatus == .Denied {
            let alert = UIAlertView(
                title: "定位服务已经关闭",
                message: "请前往设置打开",
                delegate: self,
                cancelButtonTitle: "确定"
            )
            alert.show()
            return
        }
        if #available(iOS 8.0, *) {
            if appGeolocationAuthorizationStatus == .AuthorizedAlways || appGeolocationAuthorizationStatus == .AuthorizedWhenInUse {
                self.startToFindUserLocation()
            }
        } else {
            if appGeolocationAuthorizationStatus == .Authorized {
                self.startToFindUserLocation()
            }
        }
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        switch buttonIndex {
        case 0:     // cancel button clicked, do nothing
            break
        case 1:
            // go to settings to turn on location service
            if #available(iOS 8.0, *) {
                UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
            } else {
                // Fallback on earlier versions
            }
            break
        default:
            break
        }
    }
    
    // user changed location service authorization status
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        // user allows location service authorization
        if #available(iOS 8.0, *) {
            if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
                // find user location now
                self.startToFindUserLocation()
            }
        } else {
            if status == .Authorized {
                // find user location now
                self.startToFindUserLocation()
            }
        }
    }
    
    func startToFindUserLocation() {
        // start to find out user current location
        self.baiduLocationService?.startUserLocationService()
        // delegate callback to notify the locating process has started
        self.delegate?.didStartToLocate!()
    }
    
    func didFailToLocateUserWithError(error: NSError!) {
        // stop baidu location service
        self.baiduLocationService?.stopUserLocationService()
        self.delegate?.didFailToLocateUser!()
    }
    
    // Geolocation finished, user location latitude and longitude has been decided
    func didUpdateBMKUserLocation(userLocation: BMKUserLocation!) {
        self.baiduLocationService?.stopUserLocationService() // stop user location service
        if self.shouldGetReverseGeoCode == true {
            // proceed to find user address /reverse geocode
            // setup geoCode option and start to find human readable address based on user location coordinate
            let option = BMKReverseGeoCodeOption()
            option.reverseGeoPoint = userLocation.location.coordinate
            self.userLocation = userLocation
            let success = self.baiduGeoCodeSearch?.reverseGeoCode(option)
            if success == false {
                self.delegate?.didFailToLocateUser!()
            }
        } else {
            // no need to get user reverse geocode, just return the user coordinates now
            self.delegate?.didGetUserCoordinates!(userLocation.location.coordinate)
        }
    }
    
    // Get location address based on latitude/longitude coordinate finished
    func onGetReverseGeoCodeResult(searcher: BMKGeoCodeSearch!, result: BMKReverseGeoCodeResult!, errorCode error: BMKSearchErrorCode) {
        if error.rawValue != 0 {
            self.delegate?.didFailToLocateUser!()
            return
        }
        let userLocationInfo = [
            "locationObject": self.userLocation!,
            "geoCodeResult": result
        ]
        // delegate callback to handle found location and address or show error message
        self.delegate?.didFinishFindingLocationAndAddress!(userLocationInfo)
    }
    
    // Start to get latitude/longitude coordinates based on location address
    func startToFindGeoCodeResultBasedOnAddress(address: String) {
        let geocodeSearchOption = BMKGeoCodeSearchOption()
        geocodeSearchOption.address = address
        let success = self.baiduGeoCodeSearch?.geoCode(geocodeSearchOption)
        if success == false {
            self.delegate?.didFailToLocateUser!()
        }
    }
    
    // Get latitude/longitude coordinates based on location address finished
    func onGetGeoCodeResult(searcher: BMKGeoCodeSearch!, result: BMKGeoCodeResult!, errorCode error: BMKSearchErrorCode) {
        // release memory
        self.baiduGeoCodeSearch?.delegate = nil
        self.baiduGeoCodeSearch = nil
        if error.rawValue != 0 {
            self.delegate?.didFailToLocateUser!()
            return
        }
        let geoCodeInfo = [
            "geoCodeResult": result,
            "error": "\(error)"
        ]
        self.delegate?.didFinishFindingGeoCodeResult!(geoCodeInfo)
    }
    
    /**
    Search POI based on the user input address
    */
    func startToSearchPOIBasedOnAddress(address: String, city: String) {
        // should search in team city
        let citySearchOption = BMKCitySearchOption()
        citySearchOption.keyword = address
        citySearchOption.city = city
        self.baiduPOISearch = BMKPoiSearch()
        self.baiduPOISearch?.delegate = self
        self.baiduPOISearch?.poiSearchInCity(citySearchOption)
    }
    
    /**
    Finished searching poi
    
    - parameter searcher:  the POI searcher
    - parameter poiResult: poi result that contains poiInfoList
    - parameter errorCode: error code
    */
    func onGetPoiResult(searcher: BMKPoiSearch!, result poiResult: BMKPoiResult!, errorCode: BMKSearchErrorCode) {
        self.baiduPOISearch?.delegate = nil
        self.baiduPOISearch = nil
        if errorCode == BMK_SEARCH_NO_ERROR {
            self.delegate?.didFinishSearchingPOIResult!(poiResult)
        } else {
            self.delegate?.didFailToSearchPOI!()
        }
    }
    
    deinit {
        if self.baiduLocationService != nil {
            self.baiduLocationService?.delegate = nil
            self.baiduLocationService = nil
        }
        if self.baiduGeoCodeSearch != nil {
            self.baiduGeoCodeSearch?.delegate = nil
            self.baiduGeoCodeSearch = nil
        }
        if self.baiduPOISearch != nil {
            self.baiduPOISearch?.delegate = nil
            self.baiduPOISearch = nil
        }
        if self.locationManager != nil {
            self.locationManager?.delegate = nil
            self.locationManager = nil
        }
        self.userLocation = nil
    }
}
