//
//  VTTeamCalendarViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/2.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

protocol VTTeamCalendarViewDelegate {
    func getActivitiesForThisDate(_ activities: [Activity])
}

class VTTeamCalendarViewController: UIViewController, JTCalendarDataSource, NSURLConnectionDelegate, NSURLConnectionDataDelegate {
    
    @IBOutlet weak var view_newActivityButtonContainer: UIView!
    @IBOutlet weak var activityTableView: UIView!
    // when switching between month mode and week mode, the height constraint of calendar content view needs to be adjusted
    @IBOutlet weak var calendarContentViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var activityTableViewBottomLayoutConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var calendarMenuView: JTCalendarMenuView!
    @IBOutlet weak var calendarContentView: JTCalendarContentView!
    
    var calendar: JTCalendar!
    var activityList = [Activity]()
    var activityDates = [String]()
    var teamId: String!
    var selectedDate: Date?
    var selectedActivity: Activity?
    var delegate: VTTeamCalendarViewDelegate?
    var HUD: MBProgressHUD?
    var responseData: NSMutableData? = NSMutableData()
    
    // when retrieving activities from server, there's a date range to be specified, generally it is a 3 months period including the previous month, the current month in calendarContentView and the next month, the following 2 variables record this date range
    var startDateOfCurrentBatchOfActivities: Date?
    var endDateOfCurrentBatchOfActivities: Date?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController!.navigationBar.topItem!.title = ""
        
        // add right button in navigation bar programmatically
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "menu"), style: .bordered, target: self, action: #selector(UIViewController.presentLeftMenuViewController(_:)))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(VTTeamCalendarViewController.goBackToTeamsTableView))

        // drop shadow effect for new activity button view
        self.view_newActivityButtonContainer.layer.shadowColor = UIColor.black.cgColor
        self.view_newActivityButtonContainer.layer.shadowOpacity = 0.5
        self.view_newActivityButtonContainer.layer.shadowRadius = 1.5
        self.view_newActivityButtonContainer.layer.shadowOffset = CGSize(width: 1.0, height: 1.0)
        
        // set up and show JTCalendar
        self.calendar = JTCalendar()
        self.calendar.calendarAppearance.ratioContentMenu = 0.5
        self.calendar.menuMonthsView = self.calendarMenuView
        self.calendar.contentView = self.calendarContentView
        // for calendar menu title, show year and month instead of just month by default
        self.calendar.calendarAppearance.monthBlock = {
            date, jtCalendar in
            let dateComponents = date.getDateComponents()
            return "\(dateComponents.year)年\(dateComponents.month)月"
        }
        self.calendar.dataSource = self
        
        // This option makes sure that when a date is selected and week mode is enabled, the corresponding week of that selected date will be shown
        self.calendar.calendarAppearance.focusSelectedDayChangeMode = true
        
        // retrieve selected team id in userDefaults
        self.teamId = UserDefaults.standard.string(forKey: "teamIdSelectedInTeamsList")
        
        // add tap gesture event to calendarMenuView, when single tapped and if the calendar is in week mode, switch it back to month mode
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(VTTeamCalendarViewController.switchToMonthMode))
        singleTap.numberOfTapsRequired = 1
        self.calendarMenuView.isUserInteractionEnabled = true
        self.calendarMenuView.addGestureRecognizer(singleTap)
        
        // add notification observer to watch if new activity was published
        NotificationCenter.default.addObserver(self, selector: #selector(VTTeamCalendarViewController.showNewPublishedActivity(_:)), name: NSNotification.Name(rawValue: "newActivityPublished"), object: nil)
        // add notification observer to watch if activity record selected
        NotificationCenter.default.addObserver(self, selector: #selector(VTTeamCalendarViewController.showSelectedActivityDetails(_:)), name: NSNotification.Name(rawValue: "activitySelected"), object: nil)
    }
    
    func goBackToTeamsTableView() {
        self.performSegue(withIdentifier: "unwindToTeamListSegue", sender: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.getActivitiesForRecentMonths()
        Appearance.customizeNavigationBar(self, title: "球队活动")
    }
    
    func showNewPublishedActivity(_ notification: Notification) {
        Toolbox.showCustomAlertViewWithImage("checkmark", title: "新活动发布成功")
        let publishedActivity = notification.object as! Activity
        
        // add the new published activity into self.activityList and its date string into self.arrayOfActivityTimeIndices
        self.activityList.append(publishedActivity)
        self.activityDates.append(publishedActivity.date!)
        self.calendar.reloadData()
        
        if publishedActivity.date == self.selectedDate?.getDateString() {  // the new published activity is on the same day of currently selected date in calendar, hence the new activity record should be added into container tableView of activities on selected date
                
            // get all activities for this selected date
            var activitiesOfSelectedDate = [Activity]()
            for activity in self.activityList {
                if activity.date == self.selectedDate?.getDateString() {
                    activitiesOfSelectedDate.append(activity)
                }
            }
            self.delegate?.getActivitiesForThisDate(activitiesOfSelectedDate)
        }
    }
    
    func showSelectedActivityDetails(_ notification: Notification) {
        self.selectedActivity = notification.object as? Activity
        self.performSegue(withIdentifier: "activityDetailSegue", sender: self)
    }
    
    func switchToMonthMode() {
        if self.calendar.calendarAppearance.isWeekMode == true {
            // change calendar to week mode
            self.calendar.calendarAppearance.isWeekMode = false
            self.calendar.reloadAppearance()
            
            UIView.animate(withDuration: 0.3, delay: 0.0, options: UIViewAnimationOptions(), animations: {
                self.calendarContentViewHeightConstraint.constant = CalendarMenuHeightOfMonthMode
                var frame:CGRect = self.calendarContentView.frame
                frame.size.height = CalendarMenuHeightOfMonthMode
                self.calendarContentView.frame = frame
                
                // hide the activity list table view
                self.activityTableView.alpha = 0
                // hide the new activity button and its container view
                self.view_newActivityButtonContainer.alpha = 0
            }, completion: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func calendarHaveEvent(_ calendar: JTCalendar!, date: Date!) -> Bool {
        let dateString = date.getDateString()
        if self.activityDates.contains(dateString) {
            // there is at least one activity on this date
            return true
        }
        // No activity on this date
        return false
    }
    
    func calendarDidDateSelected(_ calendar: JTCalendar!, date: Date!) {
        self.selectedDate = date
        let selectedDateString = date.getDateString()
        
        let currentDate = Date()
        let cal = Calendar.current
        // since the time of self.selectedDate is always midnight, so in order to compare the 2 dates(the user selected date and today's date) to see if user wants to publish an activity before TODAY, a date of today with the time being midnight needs to be constructed as well
        var midNightOfCurrentDate:Date?
        (cal as NSCalendar).range(of: .day, start: &midNightOfCurrentDate, interval: nil, for: currentDate)
        
        // if the calendar is NOT YET in week mode, change it to week mode
        if self.calendar.calendarAppearance.isWeekMode == false {
            
            // change calendar to week mode
            self.calendar.calendarAppearance.isWeekMode = true
            self.calendar.reloadAppearance()
            
            UIView.animate(withDuration: 0.3, delay: 0.0, options: UIViewAnimationOptions(), animations: {
                self.calendarContentViewHeightConstraint.constant = CalendarMenuHeightOfWeekMode
                var frame:CGRect = self.calendarContentView.frame
                frame.size.height = CalendarMenuHeightOfWeekMode
                self.calendarContentView.frame = frame
                
                // show the activity list table view
                self.activityTableView.alpha = 1.0
            }, completion: nil)
        }
        
        // Only if
        // a). the current user is the team captain, and
        // b). the selected date is in the future,
        // can he/she publish new activity
        if Singleton_UserOwnedTeam.sharedInstance.teamId == self.teamId && (midNightOfCurrentDate!.compare(self.selectedDate!) == ComparisonResult.orderedAscending || midNightOfCurrentDate!.compare(self.selectedDate!) == ComparisonResult.orderedSame) {
            UIView.animate(withDuration: 0.3, animations: {
                self.view_newActivityButtonContainer.alpha = 1.0
                self.activityTableViewBottomLayoutConstraint.constant = 62
            })
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                self.view_newActivityButtonContainer.alpha = 0
                self.activityTableViewBottomLayoutConstraint.constant = 0
            })
        }
        
        // get all activities for this selected date
        var activitiesOfSelectedDate = [Activity]()
        for activity in self.activityList {
            if activity.date == selectedDateString {
                activitiesOfSelectedDate.append(activity)
            }
        }
        self.delegate?.getActivitiesForThisDate(activitiesOfSelectedDate)
    }
    
    func shouldLoadActivitiesForNewDateRange() -> Bool {
        // when loading previous or next calendar page, if the calendar is in week mode, in order to reduce http requests, we varify if the new page of week is within the date range of current batch of activities, if so, we don't need to send http request to ask activities data from server
        if self.calendar.calendarAppearance.isWeekMode {
            let weekday = self.calendarContentView.currentDate!.getDateComponents().weekday
            let timeInterval = 60 * 60 * 24 * -(weekday - 2)
            let startDateOfCurrentShowingWeek = self.calendarContentView.currentDate!.addingTimeInterval(TimeInterval(timeInterval))
            let endDateOfCurrentShowingWeek = self.calendarContentView.currentDate!.addingTimeInterval(TimeInterval(60 * 60 * 24 * (7 - weekday + 1)))
            
            if startDateOfCurrentShowingWeek.compare(self.startDateOfCurrentBatchOfActivities!) == ComparisonResult.orderedAscending ||
                endDateOfCurrentShowingWeek.compare(self.endDateOfCurrentBatchOfActivities!) == ComparisonResult.orderedDescending {  // current showing week in calendar contains dates that are outside the date range of current batch of activities, so we should send http request to server asking for activities data for a new date range
                    return true
            } else {
                return false
            }
        } else {    // calendar in month mode, get activities data from server everytime user loads the previous month
            return true
        }
    }
    
    func calendarDidLoadPreviousPage() {
        if self.shouldLoadActivitiesForNewDateRange() {
            self.getActivitiesForRecentMonths()
        }
    }
    
    func calendarDidLoadNextPage() {
        if self.shouldLoadActivitiesForNewDateRange() {
            self.getActivitiesForRecentMonths()
        }
    }
    
    func getActivitiesForRecentMonths() {
        // get activities for the previous month, current month and the next month from server
        let date = self.calendar.currentDate!
        let month = date.getDateComponents().month
        let year = date.getDateComponents().year
        
        var startTime: String
        var endTime: String
        if month == 1 {
            // if the current month is January, the last month should be December of the PREVIOUS YEAR
            startTime = "\(Int(year - 1))-12-01"
            endTime = "\(Int(year))-" + "\(Int(month + 1))-28"
        } else if month == 12 {
            // if the current month is December, the next month should be January of the NEXT YEAR
            startTime = "\(Int(year))-\(Int(month - 1))-01"
            endTime = "\(Int(year + 1))-01-28"
        } else {
            startTime = "\(Int(year))-\(Int(month - 1))-01"
            endTime = "\(Int(year))-\(Int(month + 1))-28"
        }
        self.startDateOfCurrentBatchOfActivities = Date(dateString: startTime)
        self.endDateOfCurrentBatchOfActivities = Date(dateString: endTime)
        
        let urlStringToGetActivitiesWithinPeriod = URLGetActivities + "?teamId=\(self.teamId)&startTime=\(startTime)&endTime=\(endTime)"
        let connection = Toolbox.asyncHttpGetFromURL(urlStringToGetActivitiesWithinPeriod, delegate: self)
        if connection == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        }
    }
    
    func connection(_ connection: NSURLConnection, didReceive data: Data) {
        self.responseData?.append(data)
    }
    
    func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络超时")
        // if cannot get activities from server, then get activites from local database
        let dbManager = DBManager(databaseFilename: "soccer_ios.sqlite")
        let activitiesInLocalDatabaseWithinDateRange = dbManager?.loadData(
            fromDB: "select * from activities where forUserId=? and date between ? and ?",
            parameters: [
                Singleton_CurrentUser.sharedInstance.userId!,
                self.startDateOfCurrentBatchOfActivities!.getDateString(),
                self.endDateOfCurrentBatchOfActivities!.getDateString()
            ]
        )
        if activitiesInLocalDatabaseWithinDateRange.count > 0 {
            self.activityList.removeAll(keepingCapacity: false)
            self.activityDates.removeAll(keepingCapacity: false)
            for i in 0...activitiesInLocalDatabaseWithinDateRange.count - 1 {
                let activity = Activity.formatDatabaseRecordToActivity(activitiesInLocalDatabaseWithinDateRange[i] as! [AnyObject])
                self.activityList.append(activity)
                self.activityDates.append(activity.date!)
            }
            self.calendar.reloadData()
        }
        
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        // handle server response and save activities results as a NSMutableDictionary with date as the key and activity JSON info as the object, the date has the format "2000-12-01"
        let jsonArray = (try? JSONSerialization.jsonObject(with: self.responseData! as Data, options: .mutableLeaves)) as? [AnyObject]
        
        if jsonArray != nil {   // get activities data succeeded
            // clear activityList first if activityList is NOT empty
            self.activityList.removeAll(keepingCapacity: false)
            self.activityDates.removeAll(keepingCapacity: false)
            
            for object in jsonArray! {
                let activity = Activity(data: object as! [String: AnyObject])
                activity.saveOrUpdateActivityInDatabase()
                self.activityList.append(activity)
                self.activityDates.append(activity.date!)
            }
            self.calendar.reloadData()
        } else {    // get activities data failed with error
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "获取活动信息失败")
        }

        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    @IBAction func initiateNewActivity(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "newActivitySegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "newActivitySegue" {
            let destinationNavigationController = segue.destination as? UINavigationController
            let newActivityTableViewController = destinationNavigationController?.viewControllers[0] as? VTNewActivityTableViewController
            newActivityTableViewController?.activityDate = self.selectedDate!
        } else if segue.identifier == "containerOfTeamActivitiesForDateSegue" {
            let destinationViewController = segue.destination as! VTTeamActivitiesForDateTableViewController
            self.delegate = destinationViewController
        } else if segue.identifier == "activityDetailSegue" {
            let destinationViewController = segue.destination as! VTTeamActivityInfoTableViewController
            destinationViewController.activityObject = self.selectedActivity
        }
    }
    
    @IBAction func unwindToTeamCalendarView(_ segue: UIStoryboardSegue) {
    }
    
    // Class destructor
    deinit {
        self.HUD = nil
        self.responseData = nil
        if self.calendar != nil {
            if self.calendar.dataSource != nil {
                self.calendar.dataSource = nil
            }
            if self.calendar.contentView != nil {
                self.calendar.contentView = nil
            }
            if self.calendar.menuMonthsView != nil {
                self.calendar.menuMonthsView = nil
            }
            self.calendar = nil
        }
        self.activityList.removeAll(keepingCapacity: false)
        self.activityDates.removeAll(keepingCapacity: false)
        self.selectedActivity = nil
        self.teamId = nil
        self.selectedDate = nil
        self.delegate = nil
        self.startDateOfCurrentBatchOfActivities = nil
        self.endDateOfCurrentBatchOfActivities = nil
        
        NotificationCenter.default.removeObserver(self)
    }
}
