//
//  NSDateExtension.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/17.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

extension Date {
    /**
     * NSDate customized initializer to intialize NSDate object from string with format "2015-07-17"
     */
    init(dateString: String) {
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = "yyyy-MM-dd"
        let d = dateStringFormatter.date(from: dateString)!
        (self as NSDate).init(timeInterval:0, since: d)
    }
    
    /**
     * NSDate customized initializer to intialize NSDate object from string with format "2015-07-29T03:32:00.000Z"
     */
    init(dateTimeString: String) {
        let dateTimeStringFormatter = DateFormatter()
        dateTimeStringFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSz"
        let d = dateTimeStringFormatter.date(from: dateTimeString)!
        (self as NSDate).init(timeInterval: 0, since: d)
    }
    
    func getDateComponents() -> DateComponents {
        return (Calendar.current as NSCalendar).components([NSCalendar.Unit.year, NSCalendar.Unit.month, NSCalendar.Unit.day, NSCalendar.Unit.weekday, NSCalendar.Unit.hour, NSCalendar.Unit.minute], from: self)
    }
    
    func isTheSameDayAs(_ secondDate:Date) -> Bool {
        let dateOneComponents:DateComponents = self.getDateComponents()
        let dateTwoComponents:DateComponents = secondDate.getDateComponents()
        return (dateOneComponents.day == dateTwoComponents.day && dateOneComponents.month == dateTwoComponents.month && dateOneComponents.year == dateTwoComponents.year)
    }
    
    func getDateString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: self)
    }
    
    func getTimeString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: self)
    }
}
