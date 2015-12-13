//
//  soccer-Bridging-Header.h
//  soccer
//
//  Created by 杨逴先 on 15/5/16.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

#ifndef soccer_soccer_Bridging_Header_h
#define soccer_soccer_Bridging_Header_h

#import "DBManager.h"   // lib to handle sql lite3, written by YCX
#import "MBProgressHUD.h"   // lib to show customized alert with image, text and etc
#import "JTCalendar.h"  // lib to show calendar
#import "ActionSheetStringPicker.h"
#import "ActionSheetPicker.h"   // lib to customize action sheet
#import "UIScrollView+UzysAnimatedGifLoadMore.h"    // lib to show activity indicator or any customized user loading image when scrolls to the bottom of a scroll view
#import "JSQMessages.h" // JSQ message controller lib
#import "MGSwipeTableCell.h"
#import "MGSwipeButton.h"   // lib to customize table cell so that table cell shows extra buttons/options on the left or right when swiped
#import <AVFoundation/AVFoundation.h>
#import "Reachability.h"    // lib to check if network is available
#import "BMapKit.h" // baidu map lib
#import "KeychainItemWrapper.h" // lib to store login credentials encrypted in keychain
#import "UMSocial.h"    // you meng social sharing lib
#import "UMSocialWechatHandler.h"   // you meng social sharing lib for wechat
#import "iVersion.h"    // lib to check for app updates programmatically
#import "RESideMenu.h" // lib for content/sidebar menu view controller

// VT-TO-DO 蒲公英内测SDK，在发布正式版本时需要删除
// #import <PgySDK/PgyManager.h>

#endif
