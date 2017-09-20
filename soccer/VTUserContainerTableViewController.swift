//
//  VTUserContainerTableViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/9/23.
//  Copyright © 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTUserContainerTableViewController: UITableViewController {

    @IBOutlet weak var imageView_avatar: UIImageView!
    @IBOutlet weak var label_username: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = false
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        Toolbox.removeBottomShadowOfNavigationBar(self.navigationController!.navigationBar)
        
        Appearance.customizeAvatarImage(self.imageView_avatar)
        
        let currentUser = Singleton_CurrentUser.sharedInstance
        Toolbox.loadAvatarImage(currentUser.userId!, toImageView: self.imageView_avatar, avatarType: AvatarType.user)
        self.label_username.text = currentUser.username!
        
        NotificationCenter.default.addObserver(self, selector: #selector(VTUserContainerTableViewController.updateUserInfo(_:)), name: NSNotification.Name(rawValue: "userInfoUpdated"), object: nil)
    }
    
    func updateUserInfo(_ notification: Notification) {
        let nameOfUpdatedUserInfo = (notification.object as! NSDictionary).object(forKey: "userInfoIndex") as! String
        let currentUser = Singleton_CurrentUser.sharedInstance
        if nameOfUpdatedUserInfo == "userAvatar" {
            let avatarFilePath = Toolbox.getAvatarImagePathForModelId(currentUser.userId!)
            self.imageView_avatar.image = UIImage(contentsOfFile: avatarFilePath!)
        } else if nameOfUpdatedUserInfo == "username" {
            self.label_username.text = currentUser.username
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "个人资料")
        let selectedIndexPath = self.tableView.indexPathForSelectedRow
        if selectedIndexPath != nil {
            self.tableView.deselectRow(at: selectedIndexPath!, animated: true)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).row == 0 {
            Toolbox.navigationToViewControllerInDifferentStoryboard(
                self.navigationController,
                storyboardIdentifier: StoryboardNames.UserInfo.rawValue,
                destinationViewControllerIdentifier: nil
            )
        }
    }
    
    @IBAction func showSocialMediaOptions(_ sender: AnyObject) {
        UMSocialSnsService.presentSnsIconSheetView(self,
            appKey: ApiKeys.UMeng.rawValue,
            shareText: "分享文字",
            shareImage: UIImage(named: "appIcon"),
            shareToSnsNames: [
                UMShareToWechatTimeline,
                UMShareToWechatSession,
                UMShareToSina,
                UMShareToTencent,
                UMShareToQzone,
                UMShareToQQ,
                UMShareToRenren,
                UMShareToDouban
            ],
            delegate: nil)
    }

}
