//
//  QRCodeScanViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/3.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

protocol QRScanViewControllerDelegate {
    func scanViewController(viewController: QRCodeScanViewController, didTapToFocusOnPoint aPoint: CGPoint)
    func scanViewController(viewController: QRCodeScanViewController, didSuccessfullyScan aScannedValue: String)
}

class QRCodeScanViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var delegate: QRScanViewControllerDelegate?
    var touchToFocusEnabled: Bool = false
    var scannedValue: String = ""
    
    var device: AVCaptureDevice?
    var input: AVCaptureDeviceInput?
    var output: AVCaptureMetadataOutput?
    var session: AVCaptureSession?
    var preview: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(),
            forBarMetrics: .Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = true
        
        if self.isCameraAvailable() {
            self.setupScanner()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if !self.isCameraAvailable() {
            self.setupNoCameraView()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .Portrait
    }
    
    override func shouldAutorotate() -> Bool {
        return UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation)
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        let con = self.preview?.connection
        if UIDevice.currentDevice().orientation == .LandscapeLeft {
            con?.videoOrientation = .LandscapeRight
        } else {
            con?.videoOrientation = .LandscapeLeft;
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if self.touchToFocusEnabled {
            let touch = touches.first as UITouch?
            let point = touch?.locationInView(self.view)
            self.focus(point!)
        }
    }
    
    func setupScanner() {
        self.device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        self.input = (try? AVCaptureDeviceInput(device: self.device))
        
        self.session = AVCaptureSession()
        
        self.output = AVCaptureMetadataOutput()
        self.session?.addOutput(self.output)
        self.session?.addInput(self.input)
        
        self.output?.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
        self.output?.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        
        self.preview = AVCaptureVideoPreviewLayer(session: self.session)
        self.preview?.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.preview?.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)
        
        let con = self.preview?.connection
        con?.videoOrientation = .Portrait
        self.view.layer.insertSublayer(self.preview!, atIndex: 0)
        
        self.startScanning()
    }
    
    func focus(aPoint: CGPoint) {
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        if device.focusPointOfInterestSupported && device.isFocusModeSupported(.AutoFocus) {
            let screenRect = UIScreen.mainScreen().bounds
            let screenWidth = screenRect.size.width
            let screenHeight = screenRect.size.height
            let focus_x = aPoint.x / screenWidth
            let focus_y = aPoint.y / screenHeight
            
            do {
                try device.lockForConfiguration()
                self.delegate?.scanViewController(self, didTapToFocusOnPoint: aPoint)
                device.focusPointOfInterest = CGPoint(x: focus_x, y: focus_y)
                device.focusMode = .AutoFocus
               
                if device.isExposureModeSupported(.AutoExpose) {
                    device.exposureMode = .AutoExpose
                }
                device.unlockForConfiguration()
            } catch _ {
            }
        }
    }
    
    func isCameraAvailable() -> Bool {
        let videoDevices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        return videoDevices.count > 0
    }
    
    func startScanning() {
        self.session?.startRunning()
    }
    
    func stopScanning() {
        self.session?.stopRunning()
    }
    
    func setTorch(aStatus: Bool) {
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        do {
            try device.lockForConfiguration()
        } catch _ {
        }
        if device.hasTorch {
            if aStatus {
                device.torchMode = .On
            } else {
                device.torchMode = .Off
            }
        }
        device.unlockForConfiguration()
    }
    
    func setupNoCameraView() {
        let labelNoCam = UILabel()
        labelNoCam.text = "摄像头不可用"
        labelNoCam.textColor = UIColor.whiteColor()
        self.view.addSubview(labelNoCam)
        labelNoCam.sizeToFit()
        labelNoCam.center = self.view.center
    }
    
    @IBAction func closeScannerWindow(sender: AnyObject) {
        self.stopScanning()
        self.performSegueWithIdentifier("unwindToMembersContainerSegue", sender: self)
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        for current in metadataObjects {
            if let readableCode = current as? AVMetadataMachineReadableCodeObject {
                self.scannedValue = readableCode.stringValue
                self.stopScanning()
                self.performSegueWithIdentifier("unwindToMembersContainerSegue", sender: self)
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "unwindToMembersContainerSegue" {
            if Toolbox.isStringValueValid(self.scannedValue) {
                let destinationViewController = segue.destinationViewController as! VTMembersContainerViewController
                destinationViewController.QRCodeScannedValue = self.scannedValue
            }
        }
    }

}
