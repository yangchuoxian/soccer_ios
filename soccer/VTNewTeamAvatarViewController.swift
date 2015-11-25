//
//  VTNewTeamAvatarViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/3.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTNewTeamAvatarViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate {
    
    @IBOutlet weak var button_nextStep: UIButton!
    @IBOutlet weak var image_teamAvatar: UIImageView!
    
    var picker: UIImagePickerController?
    var HUD: MBProgressHUD?
    var responseData: NSMutableData? = NSMutableData()

    override func viewDidLoad() {
        super.viewDidLoad()

        Appearance.customizeNavigationBar(self, title: "选择队徽")
        Appearance.customizeAvatarImage(self.image_teamAvatar)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func nextStepOfCreatingNewTeam(sender: AnyObject) {
        self.performSegueWithIdentifier("setNewTeamNameSegue", sender: self)
    }
    
    @IBAction func chooseImage(sender: AnyObject) {
        if self.picker != nil {
            self.picker?.delegate = nil
            self.picker = nil
        }
        self.picker = UIImagePickerController()
        self.picker?.delegate = self
        self.picker?.allowsEditing = true
        self.picker?.sourceType = .PhotoLibrary
        self.presentViewController(self.picker!, animated: true, completion: nil)
    }
    
    @IBAction func takePhoto(sender: AnyObject) {
        if self.picker != nil {
            self.picker?.delegate = nil
            self.picker = nil
        }
        
        self.picker = UIImagePickerController()
        self.picker?.delegate = self
        self.picker?.allowsEditing = true
        self.picker?.sourceType = .Camera
        self.presentViewController(self.picker!, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        self.image_teamAvatar.image = image
        self.uploadAvatar(image)
        picker.dismissViewControllerAnimated(true, completion: nil)
        self.picker?.delegate = nil
        self.picker = nil
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
        self.picker?.delegate = nil
        self.picker = nil
    }
    
    func uploadAvatar(image: UIImage) {
        let connection = Toolbox.uploadImageToURL(URLUploadTeamAvatar, image: image, parameters: nil, delegate: self)
        if connection == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            self.HUD = MBProgressHUD(view: self.navigationController?.view)
            self.navigationController?.view.addSubview(self.HUD!)
            self.HUD?.show(true)
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
        
        // response for team avatar upload
        let responseStr = NSString(data: self.responseData!, encoding: NSUTF8StringEncoding)
        if responseStr != "OK" {    // upload avatar failed with error message
            Toolbox.showCustomAlertViewWithImage("unhappy", title: responseStr as! String)
        }
        
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    deinit {
        if self.image_teamAvatar != nil {
            self.image_teamAvatar.image = nil
        }
        if self.picker != nil {
            self.picker?.delegate = nil
            self.picker = nil
        }
        self.HUD = nil
        self.responseData = nil
    }
    
}
