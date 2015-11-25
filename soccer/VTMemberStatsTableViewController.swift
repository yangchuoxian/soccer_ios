//
//  VTMemberStatsTableViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/9/24.
//  Copyright © 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTMemberStatsTableViewController: UITableViewController, NSURLConnectionDataDelegate, NSURLConnectionDelegate {
    
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
    
    var userObject: User?
    var HUD: MBProgressHUD?
    var responseData: NSMutableData? = NSMutableData()
    var currentReviewingAttributeIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        
        if Singleton_CurrentUser.sharedInstance.userId == self.userObject?.userId {
            // if the selected team member is the current user himself/herself, he/she cannot score/review him/herself, thus the table cell of scores should be disabled
            for sectionIndex in 0...(self.tableView.numberOfSections - 1) {
                for rowIndex in 0...(self.tableView.numberOfRowsInSection(sectionIndex)) {
                    let tableCell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: rowIndex, inSection: sectionIndex))
                    tableCell?.userInteractionEnabled = false
                    tableCell?.selectionStyle = .None
                }
            }
        }
        
        // set up data showing up
        Toolbox.setLabelColorBasedOnAttributeValue(self.label_scoreOfConscious)
        Toolbox.setLabelColorBasedOnAttributeValue(self.label_scoreOfPersonality)
        Toolbox.setLabelColorBasedOnAttributeValue(self.label_scoreOfCooperation)
        
        self.label_numOfReviewsOnAverageAbility.text = "\(self.userObject!.numToReviewOnAverageAbility)次评分"
        self.label_scoreOfAverageAbility.text = self.userObject!.averageAbility
        Toolbox.setLabelColorBasedOnAttributeValue(self.label_scoreOfAverageAbility)
        
        self.label_numOfReviewsOnSpeed.text = "\(self.userObject!.numToReviewOnSpeed)次评分"
        self.label_scoreOfSpeed.text = self.userObject!.speed
        Toolbox.setLabelColorBasedOnAttributeValue(self.label_scoreOfSpeed)
        
        self.label_numOfReviewsOnJump.text = "\(self.userObject!.numToReviewOnJumpAbility)次评分"
        self.label_scoreOfJump.text = self.userObject!.jumpAbility
        Toolbox.setLabelColorBasedOnAttributeValue(self.label_scoreOfJump)
        
        self.label_numOfReviewsOnExplosive.text = "\(self.userObject!.numToReviewOnExplosiveForceAbility)次评分"
        self.label_scoreOfExplosive.text = self.userObject!.explosiveForceAbility
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
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let label_attributeName = self.tableView.cellForRowAtIndexPath(indexPath)?.contentView.viewWithTag(2) as! UILabel
        let selectedAttribute = label_attributeName.text

        if selectedAttribute == PlayerAttributeNames.AverageAbility.rawValue {
            self.currentReviewingAttributeIndex = PlayerAttributeIndexes.AverageAbility.rawValue
        } else if selectedAttribute == PlayerAttributeNames.Speed.rawValue {
            self.currentReviewingAttributeIndex = PlayerAttributeIndexes.Speed.rawValue
        } else if selectedAttribute == PlayerAttributeNames.JumpAbility.rawValue {
            self.currentReviewingAttributeIndex = PlayerAttributeIndexes.JumpAbility.rawValue
        } else if selectedAttribute == PlayerAttributeNames.ExplosiveAbility.rawValue {
            self.currentReviewingAttributeIndex = PlayerAttributeIndexes.ExplosiveAbility.rawValue
        } else if selectedAttribute == PlayerAttributeNames.Conscious.rawValue {
            self.currentReviewingAttributeIndex = PlayerAttributeIndexes.Conscious.rawValue
        } else if selectedAttribute == PlayerAttributeNames.Cooperation.rawValue {
            self.currentReviewingAttributeIndex = PlayerAttributeIndexes.Cooperation.rawValue
        } else if selectedAttribute == PlayerAttributeNames.Personality.rawValue {
            self.currentReviewingAttributeIndex = PlayerAttributeIndexes.Personality.rawValue
        }
        self.showScoreUserActionSheet()
    }
    
    func showScoreUserActionSheet() {
        var actionSheetPickerTitle = ""
        switch self.currentReviewingAttributeIndex {
        case PlayerAttributeIndexes.AverageAbility.rawValue:
            actionSheetPickerTitle = "球员综合能力评分"
            break
        case PlayerAttributeIndexes.Speed.rawValue:
            actionSheetPickerTitle = "球员速度评分"
            break
        case PlayerAttributeIndexes.JumpAbility.rawValue:
            actionSheetPickerTitle = "球员弹跳能力评分"
            break
        case PlayerAttributeIndexes.ExplosiveAbility.rawValue:
            actionSheetPickerTitle = "球员爆发力评分"
            break
        case PlayerAttributeIndexes.Conscious.rawValue:
            actionSheetPickerTitle = "球员意识评分"
            break
        case PlayerAttributeIndexes.Cooperation.rawValue:
            actionSheetPickerTitle = "球员配合评分"
        case PlayerAttributeIndexes.Personality.rawValue:
            actionSheetPickerTitle = "球员人品评分"
        default:
            break
        }
        
        var scoreOptionsList = [String]()
        for i in 1...10 {
            scoreOptionsList.append(String(i))
        }
        ActionSheetStringPicker.showPickerWithTitle(
            actionSheetPickerTitle,
            rows: scoreOptionsList,
            initialSelection: 0,
            doneBlock: {
                picker, index, value in
                let postParametersString = "userId=" + self.userObject!.userId + "&indexOfScore=\(self.currentReviewingAttributeIndex)&scoreValue=" + (value as! String)
                let connection = Toolbox.asyncHttpPostToURL(URLScoreUserAbility, parameters: postParametersString, delegate: self)
                if connection == nil {
                    Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
                } else {
                    self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: nil)
                }
                return
            }, cancelBlock: {
                picker in return
            }, origin: self.view
        )
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
        let responseStr = NSString(data: self.responseData!, encoding: NSUTF8StringEncoding)
        
        // succeeded http request to score user ability
        // there are 4 possible user abilities that the current user is scoring
        let scoreJson = (try? NSJSONSerialization.JSONObjectWithData(self.responseData!, options: .MutableLeaves)) as? [NSObject: AnyObject]
        if scoreJson != nil {
            let newScore = scoreJson!["newScore"] as! Float
            let numOfScores = scoreJson!["numOfScores"] as! Int
            if self.currentReviewingAttributeIndex == PlayerAttributeIndexes.AverageAbility.rawValue {
                self.label_scoreOfAverageAbility.text = "\(newScore)"
                self.label_numOfReviewsOnAverageAbility.text = "\(numOfScores)次"
            } else if self.currentReviewingAttributeIndex == PlayerAttributeIndexes.Speed.rawValue {
                self.label_scoreOfSpeed.text = "\(newScore)"
                self.label_numOfReviewsOnSpeed.text = "\(numOfScores)次"
            } else if self.currentReviewingAttributeIndex == PlayerAttributeIndexes.JumpAbility.rawValue {
                self.label_scoreOfJump.text = "\(newScore)"
                self.label_numOfReviewsOnJump.text = "\(numOfScores)次"
            } else if self.currentReviewingAttributeIndex == PlayerAttributeIndexes.ExplosiveAbility.rawValue {
                self.label_scoreOfExplosive.text = "\(newScore)"
                self.label_numOfReviewsOnExplosive.text = "\(numOfScores)次"
            } else if self.currentReviewingAttributeIndex == PlayerAttributeIndexes.Conscious.rawValue {
                self.label_scoreOfConscious.text = "\(newScore)"
                self.label_numOfReviewsOnConscious.text = "\(numOfScores)次"
            } else if self.currentReviewingAttributeIndex == PlayerAttributeIndexes.Cooperation.rawValue {
                self.label_scoreOfCooperation.text = "\(newScore)"
                self.label_numOfReviewsOnCooperation.text = "\(numOfScores)次"
            } else if self.currentReviewingAttributeIndex == PlayerAttributeIndexes.Conscious.rawValue {
                self.label_scoreOfConscious.text = "\(newScore)"
                self.label_numOfReviewsOnConscious.text = "\(numOfScores)次"
            } else if self.currentReviewingAttributeIndex == PlayerAttributeIndexes.Personality.rawValue {
                self.label_scoreOfPersonality.text = "\(newScore)"
                self.label_numOfReviewsOnPersonality.text = "\(numOfScores)次"
            }
        } else {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: responseStr as! String)
        }
        
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    deinit {
        self.userObject = nil
        self.responseData = nil
        self.HUD = nil
    }

}
