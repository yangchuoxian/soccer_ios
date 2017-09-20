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
        self.menuPreferredStatusBarStyle = .lightContent
        self.contentViewShadowColor = UIColor.black
        self.contentViewShadowOffset = CGSize(width: 0, height: 0)
        self.contentViewShadowOpacity = 0.6
        self.contentViewShadowRadius = 12
        self.contentViewShadowEnabled = true
        
        let tabTeamStoryboard = UIStoryboard(name: StoryboardNames.TabTeam.rawValue, bundle: nil)
        let teamGeneralInfoStoryboard = UIStoryboard(name: StoryboardNames.TeamGeneralInfo.rawValue, bundle: nil)
        self.contentViewController = teamGeneralInfoStoryboard.instantiateViewController(withIdentifier: "teamGeneralInfoNavigationController")
        self.leftMenuViewController = tabTeamStoryboard.instantiateViewController(withIdentifier: "teamDetailSidebarMenuController")
        self.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.backgroundImage = UIImage(named: "sidebarBackground")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.backgroundImage = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
