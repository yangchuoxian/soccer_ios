//
//  VTUpdateTeamAvatarViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/20.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTUpdateTeamAvatarViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate {
    
    var teamId: String?
    var HUD: MBProgressHUD?
    var picker: UIImagePickerController?
    var responseData: NSMutableData? = NSMutableData()

    @IBOutlet weak var imageView_teamAvatar: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Appearance.customizeNavigationBar(self, title: "更改队徽")
        Appearance.customizeAvatarImage(self.imageView_teamAvatar)
        
        self.teamId = NSUserDefaults.standardUserDefaults().stringForKey("teamIdSelectedInTeamsList")
        
        Toolbox.loadAvatarImage(self.teamId!, toImageView: self.imageView_teamAvatar, avatarType: AvatarType.Team)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func choosePicture(sender: AnyObject) {
        // release self.picker memory first
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
        // release self.picker memory first
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
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        let chosenImage:UIImage = info[UIImagePickerControllerEditedImage] as! UIImage
        self.imageView_teamAvatar.image = chosenImage
        self.uploadAvatar(chosenImage)
        
        picker.dismissViewControllerAnimated(true, completion: nil)
        
        // release picker memory
        self.picker?.delegate = nil
        self.picker = nil
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
        // release picker memory
        self.picker?.delegate = nil
        self.picker = nil
    }
    
    func uploadAvatar(image:UIImage) {
        var postParamsDictionary: [NSObject: AnyObject]?
        if Toolbox.isStringValueValid(self.teamId) {    // self.teamId defined, meaning team avatar is already uploaded, this time it is to update another avatar image
            postParamsDictionary = ["modelId": self.teamId!]
        }
        var connection = Toolbox.uploadImageToURL(URLUploadTeamAvatar, image: image, parameters: postParamsDictionary, delegate: self)
        if connection == nil {
            // inform the user that the connection failed
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
        // response for team avatar upload
        // retrieve teamId from json data
        var jsonArray = (try? NSJSONSerialization.JSONObjectWithData(self.responseData!, options: .MutableLeaves)) as? [NSObject: AnyObject]
        if jsonArray?["modelId"] != nil {   // upload avatar succeeded
            self.teamId = jsonArray?["modelId"] as? String
            // save successfully uploaded user avatar to local app directory
            Toolbox.saveAvatarImageLocally(self.imageView_teamAvatar.image!, modelId: self.teamId!)
            
            // prepare the team dictioanry for notification parameter
            let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
            let relatedTeams = dbManager.loadDataFromDB(
                "select * from teams where teamId=?",
                parameters: [self.teamId!]
            )
            let teamObject = Team.formatDatabaseRecordToTeamFormat(relatedTeams[0] as! [AnyObject])
            // notify that team has updated
            NSNotificationCenter.defaultCenter().postNotificationName(
                "teamRecordSavedOrUpdated", object: teamObject)
            
            // unwind navigation controller to the previous view controller
            self.navigationController?.popViewControllerAnimated(true)
        }
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    deinit {
        self.teamId = nil
        self.imageView_teamAvatar.image = nil
        self.imageView_teamAvatar = nil
        
        if self.picker != nil {
            self.picker?.delegate = nil
            self.picker = nil
        }
        self.HUD = nil
        self.responseData = nil
    }
    
}
