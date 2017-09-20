//
//  QRCodeScanViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/3.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

protocol QRScanViewControllerDelegate {
    func scanViewController(_ viewController: QRCodeScanViewController, didTapToFocusOnPoint aPoint: CGPoint)
    func scanViewController(_ viewController: QRCodeScanViewController, didSuccessfullyScan aScannedValue: String)
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
            for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        if self.isCameraAvailable() {
            self.setupScanner()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !self.isCameraAvailable() {
            self.setupNoCameraView()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var shouldAutorotate : Bool {
        return UIDeviceOrientationIsLandscape(UIDevice.current.orientation)
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        let con = self.preview?.connection
        if UIDevice.current.orientation == .landscapeLeft {
            con?.videoOrientation = .landscapeRight
        } else {
            con?.videoOrientation = .landscapeLeft;
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.touchToFocusEnabled {
            let touch = touches.first as UITouch?
            let point = touch?.location(in: self.view)
            self.focus(point!)
        }
    }
    
    func setupScanner() {
        self.device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        self.input = (try? AVCaptureDeviceInput(device: self.device))
        
        self.session = AVCaptureSession()
        
        self.output = AVCaptureMetadataOutput()
        self.session?.addOutput(self.output)
        self.session?.addInput(self.input)
        
        self.output?.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        self.output?.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        
        self.preview = AVCaptureVideoPreviewLayer(session: self.session)
        self.preview?.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.preview?.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        
        let con = self.preview?.connection
        con?.videoOrientation = .portrait
        self.view.layer.insertSublayer(self.preview!, at: 0)
        
        self.startScanning()
    }
    
    func focus(_ aPoint: CGPoint) {
        let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        if (device?.isFocusPointOfInterestSupported)! && (device?.isFocusModeSupported(.autoFocus))! {
            let screenRect = UIScreen.main.bounds
            let screenWidth = screenRect.size.width
            let screenHeight = screenRect.size.height
            let focus_x = aPoint.x / screenWidth
            let focus_y = aPoint.y / screenHeight
            
            do {
                try device?.lockForConfiguration()
                self.delegate?.scanViewController(self, didTapToFocusOnPoint: aPoint)
                device?.focusPointOfInterest = CGPoint(x: focus_x, y: focus_y)
                device?.focusMode = .autoFocus
               
                if (device?.isExposureModeSupported(.autoExpose))! {
                    device?.exposureMode = .autoExpose
                }
                device?.unlockForConfiguration()
            } catch _ {
            }
        }
    }
    
    func isCameraAvailable() -> Bool {
        let videoDevices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
        return videoDevices!.count > 0
    }
    
    func startScanning() {
        self.session?.startRunning()
    }
    
    func stopScanning() {
        self.session?.stopRunning()
    }
    
    func setTorch(_ aStatus: Bool) {
        let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        do {
            try device?.lockForConfiguration()
        } catch _ {
        }
        if (device?.hasTorch)! {
            if aStatus {
                device?.torchMode = .on
            } else {
                device?.torchMode = .off
            }
        }
        device?.unlockForConfiguration()
    }
    
    func setupNoCameraView() {
        let labelNoCam = UILabel()
        labelNoCam.text = "摄像头不可用"
        labelNoCam.textColor = UIColor.white
        self.view.addSubview(labelNoCam)
        labelNoCam.sizeToFit()
        labelNoCam.center = self.view.center
    }
    
    @IBAction func closeScannerWindow(_ sender: AnyObject) {
        self.stopScanning()
        self.performSegue(withIdentifier: "unwindToMembersContainerSegue", sender: self)
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        for current in metadataObjects {
            if let readableCode = current as? AVMetadataMachineReadableCodeObject {
                self.scannedValue = readableCode.stringValue
                self.stopScanning()
                self.performSegue(withIdentifier: "unwindToMembersContainerSegue", sender: self)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "unwindToMembersContainerSegue" {
            if Toolbox.isStringValueValid(self.scannedValue) {
                let destinationViewController = segue.destination as! VTMembersContainerViewController
                destinationViewController.QRCodeScannedValue = self.scannedValue
            }
        }
    }

}
