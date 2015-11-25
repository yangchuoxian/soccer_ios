//
//  VTUserProfileTableViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/31.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTUserProfileTableViewController: UITableViewController {
    
    @IBOutlet weak var imageView_avatar: UIImageView!
    @IBOutlet weak var label_username: UILabel!
    @IBOutlet weak var label_dateOfBirth: UILabel!
    @IBOutlet weak var label_careerAge: UILabel!
    @IBOutlet weak var label_position: UILabel!
    @IBOutlet weak var label_height: UILabel!
    @IBOutlet weak var label_weight: UILabel!
    @IBOutlet weak var label_gender: UILabel!
    @IBOutlet weak var textView_introduction: UITextView!
    @IBOutlet weak var scrollView_playerStats: UIScrollView!
    
    var userObject: User?

    override func viewDidLoad() {
        super.viewDidLoad()

        Toolbox.removeBottomShadowOfNavigationBar(self.navigationController!.navigationBar)
        Appearance.customizeNavigationBar(self, title: "用户资料")
        Appearance.customizeAvatarImage(self.imageView_avatar)
        self.navigationController!.navigationBar.topItem!.title = ""
        self.showUserInfo()
    }

    func showUserInfo() {
        // show user info
        Toolbox.loadAvatarImage(self.userObject!.userId, toImageView: self.imageView_avatar, avatarType: AvatarType.User)
        self.label_username.text = self.userObject?.username
        
        if Toolbox.isStringValueValid(self.userObject?.dateOfBirth) {
            self.label_dateOfBirth.text = self.userObject?.dateOfBirth
        }
        if Toolbox.isStringValueValid(self.userObject?.careerAge) {
            self.label_careerAge.text = self.userObject?.careerAge
        }
        if Toolbox.isStringValueValid(self.userObject?.height) {
            self.label_height.text = self.userObject?.height
        }
        if Toolbox.isStringValueValid(self.userObject?.weight) {
            self.label_weight.text = self.userObject?.weight
        }
        if Toolbox.isStringValueValid(self.userObject?.gender) {
            self.label_gender.text = self.userObject?.gender
        }
        if Toolbox.isStringValueValid(self.userObject?.introduction) {
            self.textView_introduction.text = self.userObject?.introduction
        }
        if Toolbox.isStringValueValid(self.userObject?.position) {
            self.label_position.text = self.userObject?.position
        }
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: CGRectZero)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "statsSegue" {
            let destinationViewController = segue.destinationViewController as! VTUserStatsTableViewController
            destinationViewController.userObject = self.userObject
        }
    }
    
    deinit {
        if self.imageView_avatar != nil {
            self.imageView_avatar.image = nil
        }
        self.userObject = nil
        
    }

}
