//
//  VTUserCalendarViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/2.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

protocol VTUserCalendarViewDelegate {
    func getActivitiesForThisDate(_ activities: [Activity])
}

class VTUserCalendarViewController: UIViewController, JTCalendarDataSource, NSURLConnectionDelegate, NSURLConnectionDataDelegate {
    
    @IBOutlet weak var activityTableView: UIView!
    @IBOutlet weak var calendarMenuView: JTCalendarMenuView!
    @IBOutlet weak var calendarContentView: JTCalendarContentView!
    // when switching between month mode and week mode, the height constraint of calendar content view needs to be adjusted
    @IBOutlet weak var calendarContentViewHeightConstraint: NSLayoutConstraint!
    
    var calendar: JTCalendar!
    var activityList = [Activity]()
    var activityDates = [String]()
    var selectedDate: Date?
    var selectedActivity: Activity?
    var responseData: NSMutableData? = NSMutableData()
    
    var delegate: VTUserCalendarViewDelegate?
    
    // when retrieving activities from server, there's a date range to be specified, generally it is a 3 months period including the previous month, the current month in calendarContentView and the next month, the following 2 variables record this date range
    var startDateOfCurrentBatchOfActivities: Date?
    var endDateOfCurrentBatchOfActivities: Date?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // set up and show JTCalendar
        self.calendar = JTCalendar.init()
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
        // add tap gesture event to calendarMenuView, when single tapped and if the calendar is in week mode, switch it back to month mode
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(VTUserCalendarViewController.switchToMonthMode))
        singleTap.numberOfTapsRequired = 1
        self.calendarMenuView.isUserInteractionEnabled = true
        self.calendarMenuView.addGestureRecognizer(singleTap)
        
        // add notification observer to watch if activity record selected
        NotificationCenter.default.addObserver(self, selector: #selector(VTUserCalendarViewController.showSelectedActivityDetails(_:)), name: NSNotification.Name(rawValue: "userActivitySelected"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "活动日程")
        if self.calendar.calendarAppearance.isWeekMode == true {
            self.calendarContentViewHeightConstraint.constant = CalendarMenuHeightOfWeekMode
        } else {
            self.calendarContentViewHeightConstraint.constant = CalendarMenuHeightOfMonthMode
        }
        self.getActivitiesForRecentMonths(self.calendar.currentDate)
    }
    
    func showSelectedActivityDetails(_ notification: Notification) {
        self.selectedActivity = notification.object as? Activity
        self.performSegue(withIdentifier: "userActivityInfoSegue", sender: self)
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
            // There is at least one activity on this date
            return true
        }
        // No activity on this date
        return false
    }
    
    func calendarDidDateSelected(_ calendar: JTCalendar!, date: Date!) {
        self.selectedDate = date
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
        
        // get all activities for this selected date
        var activitiesOfSelectedDate = [Activity]()
        for activity in self.activityList {
            if activity.date == date.getDateString() {
                activitiesOfSelectedDate.append(activity)
            }
        }
        self.delegate?.getActivitiesForThisDate(activitiesOfSelectedDate)
    }
    
    func loadNewCalendarPageForActivities() {
        let components:DateComponents = (Calendar.current as NSCalendar).components(.weekday, from: self.calendarContentView.currentDate!)
        let weekday = components.weekday
        // when loading previous calendar page, if the calendar is in week mode, in order to reduce http requests, we varify if the new page of week is within the date range of current batch of activities, if so, we don't need to send http request to ask activities data from server
        if self.calendar.calendarAppearance.isWeekMode {
            let timeInterval = 60 * 60 * 24 * -(weekday! - 2)
            let startDateOfCurrentShowingWeek:Date = self.calendarContentView.currentDate!.addingTimeInterval(TimeInterval(timeInterval))
            let endDateOfCurrentShowingWeek:Date = self.calendarContentView.currentDate!.addingTimeInterval(TimeInterval(60 * 60 * 24 * (7 - weekday + 1)))
            
            if startDateOfCurrentShowingWeek.compare(self.startDateOfCurrentBatchOfActivities!) == ComparisonResult.orderedAscending || endDateOfCurrentShowingWeek.compare(self.endDateOfCurrentBatchOfActivities!) == ComparisonResult.orderedDescending {   // current showing week in calendar contains dates that are outside the date range of current batch of activities, so we should send http request to server asking for activities data for a new date range
                self.getActivitiesForRecentMonths(self.calendar.currentDate!)
            }
        } else {    // calendar in month mode, get activities data from server everytime user loads the previous month
            self.getActivitiesForRecentMonths(self.calendar.currentDate!)
        }
    }
    
    func calendarDidLoadPreviousPage() {
        self.loadNewCalendarPageForActivities()
    }
    
    func calendarDidLoadNextPage() {
        self.loadNewCalendarPageForActivities()
    }
    
    func connection(_ connection: NSURLConnection, didReceive data: Data) {
        self.responseData?.append(data)
    }
    
    func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络超时")
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        // received activites from server
        let jsonArray = (try? JSONSerialization.jsonObject(with: self.responseData! as Data, options: .mutableContainers)) as? [AnyObject]
        if jsonArray != nil {   // get activities data for user succeeded
            // clear activityList first if activityList is NOT empty
            self.activityList.removeAll(keepingCapacity: false)
            self.activityDates.removeAll(keepingCapacity: false)
            for object in jsonArray! {
                // dateTime has the format like "2015-03-26T18:10:00.000Z"
                let activity = Activity(data: object as! [String: AnyObject])
                self.activityList.append(activity)
                self.activityDates.append(activity.date!)
            }
            self.calendar.reloadData()
        } else {    // get activities data failed with error
            let errorMessage = NSString(data: self.responseData! as Data, encoding: String.Encoding.utf8.rawValue)!
            Toolbox.showCustomAlertViewWithImage("unhappy", title: errorMessage as String)
        }
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    func getActivitiesForRecentMonths(_ date: Date!) {
        // get activities for the previous month, current month and the next month from server
        let components:DateComponents = (Calendar.current as NSCalendar).components([.day, .month, .year], from: date)
        let month = components.month
        let year = components.year
        
        var startTime:String
        var endTime:String
        if month == 1 {
            // if the current month is January, the last month should be December of the PREVIOUS YEAR
            startTime = "\(Int(year! - 1))-12-01"
            endTime = "\(Int(year!))-" + "\(Int(month! + 1))-28"
        } else if month == 12 {
            // if the current month is December, the next month should be January of the NEXT YEAR
            startTime = "\(Int(year!))-\(Int(month! - 1))-01"
            endTime = "\(Int(year! + 1))-01-28"
        } else {
            startTime = "\(Int(year!))-\(Int(month! - 1))-01"
            endTime = "\(Int(year!))-\(Int(month! + 1))-28"
        }
        
        self.startDateOfCurrentBatchOfActivities = Date(dateString: startTime)
        self.endDateOfCurrentBatchOfActivities = Date(dateString: endTime)
        
        let urlStringToGetActivitiesWithinPeriod:String = "\(URLGetActivities)?userId=\(Singleton_CurrentUser.sharedInstance.userId!)&startTime=\(startTime)&endTime=\(endTime)"
        var connection:NSURLConnection? = Toolbox.asyncHttpGetFromURL(urlStringToGetActivitiesWithinPeriod, delegate: self)
        if connection == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        }
        
        connection = nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "containerOfUserActivitiesForDateSegue" {
            let destinationViewController = segue.destination as! VTUserActivitiesForDateTableViewController
            self.delegate = destinationViewController
        } else if segue.identifier == "userActivityInfoSegue" {
            let destinationViewController = segue.destination as! VTUserActivityInfoTableViewController
            destinationViewController.activity = self.selectedActivity
        }
    }
    
    deinit {
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
        self.selectedDate = nil
        self.selectedActivity = nil
        self.delegate = nil
        self.startDateOfCurrentBatchOfActivities = nil
        self.endDateOfCurrentBatchOfActivities = nil
        self.responseData = nil
        NotificationCenter.default.removeObserver(self)
    }

}
