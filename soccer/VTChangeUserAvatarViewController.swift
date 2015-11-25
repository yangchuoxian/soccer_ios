//
//  VTChangeUserAvatarViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/29.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTChangeUserAvatarViewController: UIViewController, UINavigationControllerDelegate,UIImagePickerControllerDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate {
    @IBOutlet weak var imageView_userAvatar: UIImageView!
    @IBOutlet weak var button_chooseImage: UIButton!
    @IBOutlet weak var button_takePhoto: UIButton!

    var picker: UIImagePickerController?
    var userId: String?
    var HUD: MBProgressHUD?
    var responseData: NSMutableData? = NSMutableData()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Toolbox.loadAvatarImage(Singleton_CurrentUser.sharedInstance.userId!, toImageView: self.imageView_userAvatar, avatarType: AvatarType.User)
        Appearance.customizeAvatarImage(self.imageView_userAvatar)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "设置头像")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func chooseImage(sender: AnyObject) {
        // release self.picker memory first
        if self.picker != nil {
            self.picker?.delegate = nil
        }
        self.picker = nil
        
        self.picker = UIImagePickerController()
        self.picker?.delegate = self
        self.picker?.allowsEditing = true
        self.picker?.sourceType = .PhotoLibrary
        self.presentViewController(self.picker!, animated: true, completion: nil)
    }
    
    @IBAction func takePhoto(sender: AnyObject) {
        if self.picker != nil {
            self.picker?.delegate = nil
        }
        self.picker = nil
        
        self.picker = UIImagePickerController()
        self.picker?.delegate = self
        self.picker?.allowsEditing = true
        self.picker?.sourceType = .Camera
        self.presentViewController(self.picker!, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        self.imageView_userAvatar.image = image
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
        self.userId = Singleton_CurrentUser.sharedInstance.userId
        let postParamsDictionary = ["modelId": self.userId!]
        var connection = Toolbox.uploadImageToURL(URLUploadUserAvatar, image: image, parameters: postParamsDictionary, delegate: self)
        if connection == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            self.HUD = MBProgressHUD(view: self.navigationController?.view)
            self.navigationController?.view.addSubview(self.HUD!)
            self.HUD?.show(true)
        }
        connection = nil
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        self.responseData?.appendData(data)
    }
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        self.HUD?.hide(true)
        self.HUD = nil
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "加载失败")
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        self.HUD?.hide(true)
        self.HUD = nil
        // save successfully uploaded user avatar to local app directory
        let saveAvatarLocally = Toolbox.saveAvatarImageLocally(self.imageView_userAvatar.image!, modelId: self.userId!)
        
        if !saveAvatarLocally {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "头像文件本地存储失败")
        } else {
            // send message to notify that user avatar is updated
            let param: NSDictionary = NSDictionary(object: "userAvatar", forKey: "userInfoIndex")
            NSNotificationCenter.defaultCenter().postNotificationName("userInfoUpdated", object: param)
            // unwind segue, go back to previous view controller
            self.navigationController?.popViewControllerAnimated(true)
        }
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    deinit {
        if self.picker != nil {
            self.picker?.delegate = nil
        }
        self.picker = nil
        
        self.HUD = nil
        self.userId = nil
        self.responseData = nil
    }
    
}
