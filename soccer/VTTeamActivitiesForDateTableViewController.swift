//
//  VTTeamActivitiesForDateTableViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/21.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTTeamActivitiesForDateTableViewController: UITableViewController, VTTeamCalendarViewDelegate {
    
    var activitiesOfThisDay: [Activity] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // remove separators of cells for static table view
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        
        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Display a message and an image when the table is empty
        let emptyTableBackgroundView:UIView = UIView(frame: CGRect(x: 0, y: self.tableView.frame.origin.y, width: self.tableView.frame.size.width, height: self.tableView.frame.size.height))
        emptyTableBackgroundView.tag = TagValue.EmptyTableBackgroundView.rawValue
        
        let imageView_noActivityIcon:UIImageView = UIImageView(image: UIImage(named: "tv"))
        imageView_noActivityIcon.frame = CGRectMake(ScreenSize.width / 2 - 55, 50, 110, 110)
        imageView_noActivityIcon.tag = 1
        
        let label_noActivityHint:UILabel = UILabel(frame: CGRectMake(ScreenSize.width / 2 - 55, 160, self.tableView.frame.size.width, 50))
        label_noActivityHint.tag = 2
        label_noActivityHint.text = "今日没有活动"
        label_noActivityHint.textColor = EmptyImageColor
        label_noActivityHint.numberOfLines = 0
        label_noActivityHint.textAlignment = NSTextAlignment.Center
        label_noActivityHint.sizeToFit()
        
        emptyTableBackgroundView.addSubview(imageView_noActivityIcon)
        emptyTableBackgroundView.addSubview(label_noActivityHint)
        
        if self.activitiesOfThisDay.count > 0 {
            self.tableView.backgroundView = nil
            
            // remove all subviews in tableView
            for subView in self.tableView.subviews {
                if subView.tag == TagValue.EmptyTableBackgroundView.rawValue {
                    subView.removeFromSuperview()
                }
            }
        } else {
            self.tableView.addSubview(emptyTableBackgroundView)
            self.tableView.sendSubviewToBack(emptyTableBackgroundView)
        }
        
        // return the number of sections
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.activitiesOfThisDay.count
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if self.activitiesOfThisDay.count > 0 {
            return TableSectionHeaderHeight
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if self.activitiesOfThisDay.count > 0 {
            let view_header = UIView(frame: CGRect(x: 0, y: 0, width: Int(ScreenSize.width), height: Int(TableSectionHeaderHeight)))
            view_header.addSubview(Appearance.setupTableSectionHeaderTitle("当日活动"))
            
            return view_header
        }
        return nil
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:UITableViewCell? = self.tableView.dequeueReusableCellWithIdentifier("activityRecordCell") as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: "activityRecordCell")
        }
        let activity = self.activitiesOfThisDay[indexPath.row]
        
        let imageView_activityTypeIcon = cell?.contentView.viewWithTag(1) as! UIImageView
        if activity.type == ActivityType.Exercise.rawValue {
            imageView_activityTypeIcon.image = UIImage(named: "exercise")
        } else {
            imageView_activityTypeIcon.image = UIImage(named: "match")
        }
        
        // set up activity time
        let label_activityTime = cell?.contentView.viewWithTag(2) as! UILabel
        label_activityTime.text = activity.time
        // set up activity address
        let label_activityAddress = cell?.contentView.viewWithTag(3) as! UILabel
        label_activityAddress.text = activity.place
        label_activityAddress.sizeToFit()
        
        if indexPath.row == 0 {   // if the cell is the first row of the section, add a separatorLine
            let separatorLineView:UIView = UIView(frame: CGRectMake(0, 0, ScreenSize.width, 1))
            separatorLineView.backgroundColor = ColorBackgroundGray
            cell!.contentView.addSubview(separatorLineView)
        }
        
        return cell!
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let selectedActivity = self.activitiesOfThisDay[indexPath.row]
        // post notification to let VTTeamCalendarViewController know that an activity record is selected, should go to activity detail view controller to show the activity details
        NSNotificationCenter.defaultCenter().postNotificationName("activitySelected", object: selectedActivity)
    }
    
    // delegate method to update activities data for this date
    func getActivitiesForThisDate(activities: [Activity]) {
        // sort the activities so that activities on this day would show up in a time ascending order
        self.activitiesOfThisDay = activities
        self.activitiesOfThisDay.sortInPlace{
            return $0.0.time < $0.1.time
        }
        self.tableView.reloadData()
    }
    
    deinit {
        self.activitiesOfThisDay.removeAll(keepCapacity: false)
    }
}
