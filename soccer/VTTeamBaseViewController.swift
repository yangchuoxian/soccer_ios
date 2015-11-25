//
//  VTTeamBaseViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/9/21.
//  Copyright © 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTTeamBaseViewController: RESideMenu, RESideMenuDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func awakeFromNib() {
        // Do any additional setup after loading the view.
        self.menuPreferredStatusBarStyle = .LightContent
        self.contentViewShadowColor = UIColor.blackColor()
        self.contentViewShadowOffset = CGSizeMake(0, 0)
        self.contentViewShadowOpacity = 0.6
        self.contentViewShadowRadius = 12
        self.contentViewShadowEnabled = true
        
        let tabTeamStoryboard = UIStoryboard(name: StoryboardNames.TabTeam.rawValue, bundle: nil)
        let teamGeneralInfoStoryboard = UIStoryboard(name: StoryboardNames.TeamGeneralInfo.rawValue, bundle: nil)
        self.contentViewController = teamGeneralInfoStoryboard.instantiateViewControllerWithIdentifier("teamGeneralInfoNavigationController")
        self.leftMenuViewController = tabTeamStoryboard.instantiateViewControllerWithIdentifier("teamDetailSidebarMenuController")
        self.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.backgroundImage = UIImage(named: "sidebarBackground")
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.backgroundImage = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
