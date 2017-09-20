//
//  VTUserActivitiesForDateTableViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/21.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


class VTUserActivitiesForDateTableViewController: UITableViewController, VTUserCalendarViewDelegate {
    
    var activitiesOfThisDay = [Activity]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // Display a message and an image when the table is empty
        let emptyTableBackgroundView:UIView = UIView(frame: CGRect(x: 0, y: self.tableView.frame.origin.y, width: self.tableView.frame.size.width, height: self.tableView.frame.size.height))
        emptyTableBackgroundView.tag = TagValue.emptyTableBackgroundView.rawValue
        
        let imageView_noActivityIcon:UIImageView = UIImageView(image: UIImage(named:"tv"))
        imageView_noActivityIcon.frame = CGRect(x: ScreenSize.width / 2 - 55, y: 50, width: 110, height: 110)
        imageView_noActivityIcon.tag = 1
        
        let label_noActivityHint:UILabel = UILabel(frame: CGRect(x: ScreenSize.width / 2 - 55, y: 160, width: self.tableView.frame.size.width, height: 50))
        label_noActivityHint.tag = 2
        label_noActivityHint.text = "今日没有活动"
        label_noActivityHint.textColor = EmptyImageColor
        label_noActivityHint.numberOfLines = 0
        label_noActivityHint.textAlignment = .center
        label_noActivityHint.sizeToFit()
        
        emptyTableBackgroundView.addSubview(imageView_noActivityIcon)
        emptyTableBackgroundView.addSubview(label_noActivityHint)
        
        if self.activitiesOfThisDay.count > 0 {
            self.tableView.backgroundView = nil
            
            // remove all subviews in tableView
            for subView in self.tableView.subviews {
                if subView.tag == TagValue.emptyTableBackgroundView.rawValue {
                    subView.removeFromSuperview()
                }
            }
        } else {
            self.tableView.addSubview(emptyTableBackgroundView)
            self.tableView.sendSubview(toBack: emptyTableBackgroundView)
        }
        
        // return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.activitiesOfThisDay.count
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if self.activitiesOfThisDay.count > 0 {
            return TableSectionHeaderHeight
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if self.activitiesOfThisDay.count > 0 {
            let headerView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: TableSectionHeaderHeight))
            headerView.addSubview(Appearance.setupTableSectionHeaderTitle("当日活动"))
            
            return headerView
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell? = self.tableView.dequeueReusableCell(withIdentifier: "activityRecordCell") as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "activityRecordCell")
        }
        let activity = self.activitiesOfThisDay[(indexPath as NSIndexPath).row]
        let imageView_activityTypeIcon = cell?.contentView.viewWithTag(1) as! UIImageView
        if activity.type == ActivityType.exercise.rawValue {
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
        
        if (indexPath as NSIndexPath).row == 0 { // if the cell is the first row of the section, add a separatorLine
            let separatorLineView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: 1))
            separatorLineView.backgroundColor = ColorBackgroundGray
            cell!.contentView.addSubview(separatorLineView)
        }
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedActivity = self.activitiesOfThisDay[(indexPath as NSIndexPath).row]
        // post notification to let VTUserCalendarViewController know that an activity record is selected, should go to activity detail view controller to show the activity details
        NotificationCenter.default.post(name: Notification.Name(rawValue: "userActivitySelected"), object: selectedActivity)
    }
    
    // delegate method to update activities data for this date
    func getActivitiesForThisDate(_ activities: [Activity]) {
        // sort the activities so that activities on this day would show up in a time ascending order
        self.activitiesOfThisDay = activities
        self.activitiesOfThisDay.sort{
            $0.0.time < $0.1.time
        }
        self.tableView.reloadData()
    }

    deinit {
        self.activitiesOfThisDay.removeAll(keepingCapacity: false)
    }
    
}
