//
//  NSDateExtension.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/17.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

extension NSDate {
    /**
     * NSDate customized initializer to intialize NSDate object from string with format "2015-07-17"
     */
    convenience init(dateString: String) {
        let dateStringFormatter = NSDateFormatter()
        dateStringFormatter.dateFormat = "yyyy-MM-dd"
        let d = dateStringFormatter.dateFromString(dateString)!
        self.init(timeInterval:0, sinceDate: d)
    }
    
    /**
     * NSDate customized initializer to intialize NSDate object from string with format "2015-07-29T03:32:00.000Z"
     */
    convenience init(dateTimeString: String) {
        let dateTimeStringFormatter = NSDateFormatter()
        dateTimeStringFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSz"
        let d = dateTimeStringFormatter.dateFromString(dateTimeString)!
        self.init(timeInterval: 0, sinceDate: d)
    }
    
    func getDateComponents() -> NSDateComponents {
        return NSCalendar.currentCalendar().components([NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day, NSCalendarUnit.Weekday, NSCalendarUnit.Hour, NSCalendarUnit.Minute], fromDate: self)
    }
    
    func isTheSameDayAs(secondDate:NSDate) -> Bool {
        let dateOneComponents:NSDateComponents = self.getDateComponents()
        let dateTwoComponents:NSDateComponents = secondDate.getDateComponents()
        return (dateOneComponents.day == dateTwoComponents.day && dateOneComponents.month == dateTwoComponents.month && dateOneComponents.year == dateTwoComponents.year)
    }
    
    func getDateString() -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.stringFromDate(self)
    }
    
    func getTimeString() -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.stringFromDate(self)
    }
}