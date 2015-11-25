//
//  VTNewActivityTableViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/5.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTNewActivityTableViewController: UITableViewController, UIAlertViewDelegate {
    
    var activityDate: NSDate?
    var dateString: String?
    var timeString: String?
    var selectedActivityType: ActivityType?
    var minimumNumberOfAttendees: Int?
    var rivalTeamId = ""
    var isNewActivityMatchInitiatedFromDiscoverTab = false

    @IBOutlet weak var tableCell_date: UITableViewCell!
    @IBOutlet weak var tableCell_time: UITableViewCell!
    
    @IBOutlet weak var label_date: UILabel!
    @IBOutlet weak var label_time: UILabel!
    @IBOutlet weak var label_minimumNumberOfAttendees: UILabel!
    
    @IBOutlet weak var imageView_typeExerciseSelectedSign: UIImageView!
    @IBOutlet weak var imageView_typeMatchSelectedSign: UIImageView!
    
    var button_nextStep: UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // remove separators of cells for static table view
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        
        if self.activityDate != nil {
            self.label_date.text = self.activityDate!.getDateString()
            self.dateString = self.activityDate!.getDateString()
        }
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Stop, target: self, action: "cancelPublishingNewActivity")
        
        // activity type defaults to exercise
        // otherwise activity type should be match since current user as team captain is trying to initiate a match to a nearby team
        if self.isNewActivityMatchInitiatedFromDiscoverTab == false {
            self.selectedActivityType = .Exercise
        } else {    // the activity is predefined as a match
            self.imageView_typeExerciseSelectedSign.alpha = 0
            self.imageView_typeMatchSelectedSign.alpha = 1
        }
    }
    
    func cancelPublishingNewActivity() {
        if self.isNewActivityMatchInitiatedFromDiscoverTab == true {
            self.performSegueWithIdentifier("unwindToTeamBriefIntroSegue", sender: self)
        } else {
            self.performSegueWithIdentifier("unwindToTeamCalendarSegue", sender: self)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if self.isNewActivityMatchInitiatedFromDiscoverTab == true {
            Appearance.customizeNavigationBar(self, title: "赛事信息")
        } else {
            Appearance.customizeNavigationBar(self, title: "新活动信息")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if indexPath.section == 0 {
            if indexPath.row == 0 { // setting up activity date
                let currentTime = NSDate()
                // set up action sheet picker so user can select the activity date
                var actionSheetDatePicker: ActionSheetDatePicker
                if self.activityDate != nil {
                    actionSheetDatePicker = ActionSheetDatePicker(title: "选择日期", datePickerMode: .Date, selectedDate: self.activityDate!, minimumDate: currentTime, maximumDate: nil, target: self, action: "dateSelected:", origin: self.tableCell_date)
                } else {
                    actionSheetDatePicker = ActionSheetDatePicker(title: "选择日期", datePickerMode: .Date, selectedDate: currentTime, minimumDate: currentTime, maximumDate: nil, target: self, action: "dateSelected:", origin: self.tableCell_date)
                }
                // show cancel button of action sheet picker
                actionSheetDatePicker.hideCancel = false
                actionSheetDatePicker.showActionSheetPicker()
            } else if indexPath.row == 1 {  // setting up activity time
                let currentTime:NSDate = NSDate()
                // if the activityDate is TODAY, the minimum time should be now, meaning that you CANNOT publish a new activity at a past time today;
                // if the activityDate is anoy other date that is later than today, then there should be no such limit
                var minimumTime: NSDate? = nil
                if self.dateString != nil {
                    if NSDate(dateString: self.dateString!).isTheSameDayAs(currentTime) {
                        minimumTime = currentTime
                    }
                }
                
                // set up action sheet picker so user can select the activity time
                let actionSheetTimePicker = ActionSheetDatePicker(title: "选择时间", datePickerMode: .Time, selectedDate: currentTime, minimumDate: minimumTime, maximumDate: nil, target: self, action: "timeSelected:", origin: self.tableCell_time)
                // show cancel button of action sheet picker
                actionSheetTimePicker.hideCancel = false
                actionSheetTimePicker.showActionSheetPicker()
            }
        } else if indexPath.section == 1 {
            if indexPath.row == 0 { // activity type exercise selected
                if self.isNewActivityMatchInitiatedFromDiscoverTab {
                    // the new activity is a match initiated from discover tab, thus one cannot set it as an exercise
                    return
                }
                self.selectedActivityType = .Exercise
                UIView.animateWithDuration(0.1, delay: 0.1, options: .CurveEaseInOut, animations: {
                    self.imageView_typeExerciseSelectedSign.alpha = 1
                    self.imageView_typeMatchSelectedSign.alpha = 0
                    }, completion: nil
                )
            } else {    // activity type match selected
                self.selectedActivityType = .Match
                UIView.animateWithDuration(0.1, delay: 0.1, options: .CurveEaseInOut, animations: {
                    self.imageView_typeExerciseSelectedSign.alpha = 0
                    self.imageView_typeMatchSelectedSign.alpha = 1
                    }, completion: nil
                )
            }
        } else if indexPath.section == 2 {  // setting up minimum number of people to attend the activity
            let numberOfMembers = Singleton_UserOwnedTeam.sharedInstance.numberOfMembers
            if numberOfMembers == 0 {
                Toolbox.showCustomAlertViewWithImage("unhappy", title: "该球队没有成员")
                return
            }
            var options_numberOfAttendees:[String] = []
            for index in 1...numberOfMembers {
                options_numberOfAttendees.append("\(Int(index))")
            }
            ActionSheetStringPicker.showPickerWithTitle("选择最少参加人数",
                rows: options_numberOfAttendees,
                initialSelection: 0,
                doneBlock: {
                    picker, value, index in
                    self.minimumNumberOfAttendees = Int((index as! String))
                    self.label_minimumNumberOfAttendees.text = "\(Int(self.minimumNumberOfAttendees!))"
                    return
                },
                cancelBlock: {
                    picker in return
                },
                origin: self.view
            )
        }
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        var footerView:UIView!
        if section == 2 { // add button to the footer for third table section only
            // get screen size
            footerView = UIView(frame: CGRectMake(0, 0, ScreenSize.width, TableSectionFooterHeightWithButton))
            
            self.button_nextStep = Appearance.setupTableFooterButtonWithTitle("下一步", backgroundColor: ColorSettledGreen)
            
            self.button_nextStep?.addTarget(self, action: "nextStep", forControlEvents: .TouchUpInside)
            footerView.addSubview(self.button_nextStep!)
            
        } else {
            footerView = UIView(frame: CGRectMake(0, 0, ScreenSize.width, DefaultTableSectionFooterHeight))
        }
        
        footerView.tintColor = ColorBackgroundGray

        return footerView
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 2 {   // footer height is 80 for the third section only
            return TableSectionFooterHeightWithButton
        } else {
            return DefaultTableSectionFooterHeight
        }
    }
    
    func nextStep() {
        // Next step to publish new activity
        if !Toolbox.isStringValueValid(self.dateString) {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "请确定活动日期")
            return
        }
        if !Toolbox.isStringValueValid(self.timeString) {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "请确定活动时间")
            return
        }
        if self.selectedActivityType == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "请确定活动类型")
            return
        }
        // if the user has not designate minimum number of attendees for match when submitting this new activity, system provides a hint saying that minimum number of attendees should be designated.
        // NOTE: minimumNumberOfAttendees is ONLY needed if the activity is of type MATCH
        if self.minimumNumberOfAttendees == nil {
            if self.selectedActivityType == .Match {
                Toolbox.showCustomAlertViewWithImage("unhappy", title: "请确定最少参赛人数")
                return
            }
        }
        // next step is establish activity address
        var activityInfo:[String: AnyObject]
        // difference of activity info between exercise and match is that minimumNumberOfAttendees is not mandatory for exercise
        var minimumNumberOfAttendees = 0
        if self.selectedActivityType! == .Match {
            minimumNumberOfAttendees = self.minimumNumberOfAttendees!
        }
        activityInfo = [
            "datetime": "\(self.dateString!) \(self.timeString!)",
            "type": "\(Int(self.selectedActivityType!.rawValue))",
            "minimumNumberOfAttendees": "\(minimumNumberOfAttendees)"
        ]
        // decide whether this activity is initiated from team calendar view, or it is a match initiated from discover tab view
        if self.isNewActivityMatchInitiatedFromDiscoverTab == true {
            activityInfo["idOfTeamB"] = self.rivalTeamId
        }
        // save new activity info for later use
        NSUserDefaults.standardUserDefaults().setObject(activityInfo, forKey: "activityInfo")
        self.performSegueWithIdentifier("establishActivityAddress", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "establishActivityAddress" {
            let destinationViewController = segue.destinationViewController as! VTNewActivityAddressViewController
            destinationViewController.isNewActivityMatchInitiatedFromDiscoverTab = self.isNewActivityMatchInitiatedFromDiscoverTab
        }
    }
    
    func dateSelected(selectedDate: NSDate) {
        self.dateString = selectedDate.getDateString()
        self.label_date.text = self.dateString
    }
    
    func timeSelected(selectedTime: NSDate) {
        self.timeString = selectedTime.getTimeString()
        self.label_time.text = self.timeString
    }
    
    deinit {
        self.activityDate = nil
        self.dateString = nil
        self.timeString = nil
        self.selectedActivityType = nil
        self.minimumNumberOfAttendees = nil
        self.button_nextStep = nil
    }
}
