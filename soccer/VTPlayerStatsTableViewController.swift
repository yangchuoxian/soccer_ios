//
//  VTPlayerStatsTableViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/9/22.
//  Copyright © 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTPlayerStatsTableViewController: UITableViewController {
    
    @IBOutlet weak var label_numOfTeams: UILabel!
    @IBOutlet weak var label_numOfActivities: UILabel!
    @IBOutlet weak var label_presencePercentage: UILabel!
    @IBOutlet weak var label_bailPercentage: UILabel!
    @IBOutlet weak var label_numOfReviewsOnConscious: UILabel!
    @IBOutlet weak var label_scoreOfConscious: UILabel!
    @IBOutlet weak var label_numOfReviewsOnCooperation: UILabel!
    @IBOutlet weak var label_scoreOfCooperation: UILabel!
    @IBOutlet weak var label_numOfReviewsOnPersonality: UILabel!
    @IBOutlet weak var label_scoreOfPersonality: UILabel!
    @IBOutlet weak var label_numOfReviewsOnAverageAbility: UILabel!
    @IBOutlet weak var label_scoreOfAverageAbility: UILabel!
    @IBOutlet weak var label_numOfReviewsOnSpeed: UILabel!
    @IBOutlet weak var label_scoreOfSpeed: UILabel!
    @IBOutlet weak var label_numOfReviewsOnJump: UILabel!
    @IBOutlet weak var label_scoreOfJump: UILabel!
    @IBOutlet weak var label_numOfReviewsOnExplosive: UILabel!
    @IBOutlet weak var label_scoreOfExplosive: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        
        // set up data showing up
        let currentUser = Singleton_CurrentUser.sharedInstance
        
        self.label_scoreOfConscious.text = currentUser.conscious
        self.label_numOfReviewsOnConscious.text = "\(currentUser.numToReviewOnConscious!)次评分"
        Toolbox.setLabelColorBasedOnAttributeValue(self.label_scoreOfConscious)
        
        self.label_scoreOfCooperation.text = currentUser.cooperation
        self.label_numOfReviewsOnCooperation.text = "\(currentUser.numToReviewOnCooperation!)次评分"
        Toolbox.setLabelColorBasedOnAttributeValue(self.label_scoreOfPersonality)
        
        self.label_scoreOfPersonality.text = currentUser.personality
        self.label_numOfReviewsOnPersonality.text = "\(currentUser.numToReviewOnPersonality!)次评分"
        Toolbox.setLabelColorBasedOnAttributeValue(self.label_scoreOfCooperation)
        
        self.label_numOfReviewsOnAverageAbility.text = "\(currentUser.numToReviewOnAverageAbility!)次评分"
        self.label_scoreOfAverageAbility.text = currentUser.averageAbility
        Toolbox.setLabelColorBasedOnAttributeValue(self.label_scoreOfAverageAbility)
        
        self.label_numOfReviewsOnSpeed.text = "\(currentUser.numToReviewOnSpeed!)次评分"
        self.label_scoreOfSpeed.text = currentUser.speed
        Toolbox.setLabelColorBasedOnAttributeValue(self.label_scoreOfSpeed)
        
        self.label_numOfReviewsOnJump.text = "\(currentUser.numToReviewOnJumpAbility!)次评分"
        self.label_scoreOfJump.text = currentUser.jumpAbility
        Toolbox.setLabelColorBasedOnAttributeValue(self.label_scoreOfJump)
        
        self.label_numOfReviewsOnExplosive.text = "\(currentUser.numToReviewOnExplosiveForceAbility!)次评分"
        self.label_scoreOfExplosive.text = currentUser.explosiveForceAbility
        Toolbox.setLabelColorBasedOnAttributeValue(self.label_scoreOfExplosive)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "统计数据")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: DefaultTableSectionFooterHeight))
        footerView.backgroundColor = UIColor.clearColor()
        return footerView
    }
    
}
