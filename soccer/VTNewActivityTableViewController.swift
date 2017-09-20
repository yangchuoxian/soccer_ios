//
//  VTNewActivityTableViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/5.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTNewActivityTableViewController: UITableViewController, UIAlertViewDelegate {
    
    var activityDate: Date?
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
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        if self.activityDate != nil {
            self.label_date.text = self.activityDate!.getDateString()
            self.dateString = self.activityDate!.getDateString()
        }
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(VTNewActivityTableViewController.cancelPublishingNewActivity))
        
        // activity type defaults to exercise
        // otherwise activity type should be match since current user as team captain is trying to initiate a match to a nearby team
        if self.isNewActivityMatchInitiatedFromDiscoverTab == false {
            self.selectedActivityType = .exercise
        } else {    // the activity is predefined as a match
            self.imageView_typeExerciseSelectedSign.alpha = 0
            self.imageView_typeMatchSelectedSign.alpha = 1
        }
    }
    
    func cancelPublishingNewActivity() {
        if self.isNewActivityMatchInitiatedFromDiscoverTab == true {
            self.performSegue(withIdentifier: "unwindToTeamBriefIntroSegue", sender: self)
        } else {
            self.performSegue(withIdentifier: "unwindToTeamCalendarSegue", sender: self)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
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
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        
        if (indexPath as NSIndexPath).section == 0 {
            if (indexPath as NSIndexPath).row == 0 { // setting up activity date
                let currentTime = Date()
                // set up action sheet picker so user can select the activity date
                var actionSheetDatePicker: ActionSheetDatePicker
                if self.activityDate != nil {
                    actionSheetDatePicker = ActionSheetDatePicker(title: "选择日期", datePickerMode: .date, selectedDate: self.activityDate!, minimumDate: currentTime, maximumDate: nil, target: self, action: #selector(VTNewActivityTableViewController.dateSelected(_:)), origin: self.tableCell_date)
                } else {
                    actionSheetDatePicker = ActionSheetDatePicker(title: "选择日期", datePickerMode: .date, selectedDate: currentTime, minimumDate: currentTime, maximumDate: nil, target: self, action: #selector(VTNewActivityTableViewController.dateSelected(_:)), origin: self.tableCell_date)
                }
                // show cancel button of action sheet picker
                actionSheetDatePicker.hideCancel = false
                actionSheetDatePicker.show()
            } else if (indexPath as NSIndexPath).row == 1 {  // setting up activity time
                let currentTime:Date = Date()
                // if the activityDate is TODAY, the minimum time should be now, meaning that you CANNOT publish a new activity at a past time today;
                // if the activityDate is anoy other date that is later than today, then there should be no such limit
                var minimumTime: Date? = nil
                if self.dateString != nil {
                    if Date(dateString: self.dateString!).isTheSameDayAs(currentTime) {
                        minimumTime = currentTime
                    }
                }
                
                // set up action sheet picker so user can select the activity time
                let actionSheetTimePicker = ActionSheetDatePicker(title: "选择时间", datePickerMode: .time, selectedDate: currentTime, minimumDate: minimumTime, maximumDate: nil, target: self, action: #selector(VTNewActivityTableViewController.timeSelected(_:)), origin: self.tableCell_time)
                // show cancel button of action sheet picker
                actionSheetTimePicker?.hideCancel = false
                actionSheetTimePicker?.show()
            }
        } else if (indexPath as NSIndexPath).section == 1 {
            if (indexPath as NSIndexPath).row == 0 { // activity type exercise selected
                if self.isNewActivityMatchInitiatedFromDiscoverTab {
                    // the new activity is a match initiated from discover tab, thus one cannot set it as an exercise
                    return
                }
                self.selectedActivityType = .exercise
                UIView.animate(withDuration: 0.1, delay: 0.1, options: UIViewAnimationOptions(), animations: {
                    self.imageView_typeExerciseSelectedSign.alpha = 1
                    self.imageView_typeMatchSelectedSign.alpha = 0
                    }, completion: nil
                )
            } else {    // activity type match selected
                self.selectedActivityType = .match
                UIView.animate(withDuration: 0.1, delay: 0.1, options: UIViewAnimationOptions(), animations: {
                    self.imageView_typeExerciseSelectedSign.alpha = 0
                    self.imageView_typeMatchSelectedSign.alpha = 1
                    }, completion: nil
                )
            }
        } else if (indexPath as NSIndexPath).section == 2 {  // setting up minimum number of people to attend the activity
            let numberOfMembers = Singleton_UserOwnedTeam.sharedInstance.numberOfMembers
            if numberOfMembers == 0 {
                Toolbox.showCustomAlertViewWithImage("unhappy", title: "该球队没有成员")
                return
            }
            var options_numberOfAttendees:[String] = []
            for index in 1...numberOfMembers {
                options_numberOfAttendees.append("\(Int(index))")
            }
            ActionSheetStringPicker.show(withTitle: "选择最少参加人数",
                rows: options_numberOfAttendees,
                initialSelection: 0,
                doneBlock: {
                    picker, value, index in
                    self.minimumNumberOfAttendees = Int((index as! String))
                    self.label_minimumNumberOfAttendees.text = "\(Int(self.minimumNumberOfAttendees!))"
                    return
                },
                cancel: {
                    picker in return
                },
                origin: self.view
            )
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        var footerView:UIView!
        if section == 2 { // add button to the footer for third table section only
            // get screen size
            footerView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: TableSectionFooterHeightWithButton))
            
            self.button_nextStep = Appearance.setupTableFooterButtonWithTitle("下一步", backgroundColor: ColorSettledGreen)
            
            self.button_nextStep?.addTarget(self, action: #selector(VTNewActivityTableViewController.nextStep), for: .touchUpInside)
            footerView.addSubview(self.button_nextStep!)
            
        } else {
            footerView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: DefaultTableSectionFooterHeight))
        }
        
        footerView.tintColor = ColorBackgroundGray

        return footerView
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
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
            if self.selectedActivityType == .match {
                Toolbox.showCustomAlertViewWithImage("unhappy", title: "请确定最少参赛人数")
                return
            }
        }
        // next step is establish activity address
        var activityInfo:[String: AnyObject]
        // difference of activity info between exercise and match is that minimumNumberOfAttendees is not mandatory for exercise
        var minimumNumberOfAttendees = 0
        if self.selectedActivityType! == .match {
            minimumNumberOfAttendees = self.minimumNumberOfAttendees!
        }
        activityInfo = [
            "datetime": "\(self.dateString!) \(self.timeString!)" as AnyObject,
            "type": "\(Int(self.selectedActivityType!.rawValue))" as AnyObject,
            "minimumNumberOfAttendees": "\(minimumNumberOfAttendees)" as AnyObject
        ]
        // decide whether this activity is initiated from team calendar view, or it is a match initiated from discover tab view
        if self.isNewActivityMatchInitiatedFromDiscoverTab == true {
            activityInfo["idOfTeamB"] = self.rivalTeamId as AnyObject?
        }
        // save new activity info for later use
        UserDefaults.standard.set(activityInfo, forKey: "activityInfo")
        self.performSegue(withIdentifier: "establishActivityAddress", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "establishActivityAddress" {
            let destinationViewController = segue.destination as! VTNewActivityAddressViewController
            destinationViewController.isNewActivityMatchInitiatedFromDiscoverTab = self.isNewActivityMatchInitiatedFromDiscoverTab
        }
    }
    
    func dateSelected(_ selectedDate: Date) {
        self.dateString = selectedDate.getDateString()
        self.label_date.text = self.dateString
    }
    
    func timeSelected(_ selectedTime: Date) {
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
