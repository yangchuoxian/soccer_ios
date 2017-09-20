//
//  VTTeamProfileTableViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/22.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTTeamProfileTableViewController: UITableViewController {
    
    var teamObject: Team!
    
    @IBOutlet weak var imageView_avatar: UIImageView!
    @IBOutlet weak var label_teamName: UILabel!
    @IBOutlet weak var label_numberOfPoints: UILabel!
    @IBOutlet weak var label_wins: UILabel!
    @IBOutlet weak var label_loses: UILabel!
    @IBOutlet weak var label_ties: UILabel!
    
    @IBOutlet weak var view_followersBackground: UIView!
    @IBOutlet weak var view_winsBackground: UIView!
    @IBOutlet weak var view_losesBackground: UIView!
    @IBOutlet weak var view_tiesBackground: UIView!
    
    @IBOutlet weak var label_createdAt: UILabel!
    @IBOutlet weak var label_city: UILabel!
    @IBOutlet weak var label_homeCourt: UILabel!
    @IBOutlet weak var textView_introduction: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false

        Appearance.customizeNavigationBar(self, title: "球队详情")
        Appearance.customizeAvatarImage(self.imageView_avatar)
        self.navigationController!.navigationBar.topItem!.title = ""
        
        Toolbox.removeBottomShadowOfNavigationBar(self.navigationController!.navigationBar)
        
        // make team introductoin textView not editable
        self.textView_introduction.isEditable = false
        
        let verticalSeparatorForFollowersView = UIView(frame: CGRect(x: ScreenSize.width / 4 - 1, y: 6, width: 1, height: 32))
        verticalSeparatorForFollowersView.backgroundColor = ColorBackgroundGray
        verticalSeparatorForFollowersView.alpha = 0.6
        self.view_followersBackground.addSubview(verticalSeparatorForFollowersView)
        
        let verticalSeparatorForWinsView = UIView(frame: CGRect(x: ScreenSize.width / 4 - 1, y: 6, width: 1, height: 32))
        verticalSeparatorForWinsView.backgroundColor = ColorBackgroundGray
        verticalSeparatorForWinsView.alpha = 0.6
        self.view_winsBackground.addSubview(verticalSeparatorForWinsView)
        
        let verticalSeparatorForLosesView = UIView(frame: CGRect(x: ScreenSize.width / 4 - 1, y: 6, width: 1, height: 32))
        verticalSeparatorForLosesView.backgroundColor = ColorBackgroundGray
        verticalSeparatorForLosesView.alpha = 0.6
        self.view_losesBackground.addSubview(verticalSeparatorForLosesView)
        
        let verticalSeparatorForTiesView = UIView(frame: CGRect(x: ScreenSize.width / 4 - 1, y: 6, width: 1, height: 32))
        verticalSeparatorForTiesView.backgroundColor = ColorBackgroundGray
        verticalSeparatorForTiesView.alpha = 0.6
        self.view_tiesBackground.addSubview(verticalSeparatorForTiesView)
        
        // Load team information
        Toolbox.loadAvatarImage(self.teamObject.teamId, toImageView: self.imageView_avatar, avatarType: AvatarType.team)
        
        self.label_numberOfPoints.text = String(self.teamObject.points)
        self.label_wins.text = String(self.teamObject.wins)
        self.label_loses.text = String(self.teamObject.loses)
        self.label_ties.text = String(self.teamObject.ties)
        
        self.label_teamName.text = self.teamObject.teamName
        
        let teamCreationDate = Date(dateTimeString: self.teamObject.createdAt)
        self.label_createdAt.text = teamCreationDate.getDateString()
        
        self.label_city.text = self.teamObject.location
        self.textView_introduction.text = self.teamObject.introduction
        if Toolbox.isStringValueValid(self.teamObject.homeCourt) {
            self.label_homeCourt.text = self.teamObject.homeCourt
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        self.teamObject = nil
    }

}
