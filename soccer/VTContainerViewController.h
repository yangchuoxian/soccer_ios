//
//  VTContainerViewController.h
//  soccer
//
//  Created by 杨逴先 on 15/3/8.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VTTabSwitchSegue.h"

@interface VTContainerViewController : UIViewController

@property (weak,nonatomic) UIViewController *destinationViewController;
@property (strong, nonatomic) UIViewController *oldViewController;
@property (nonatomic, strong) NSMutableDictionary *viewControllersByIdentifier;
@property (strong, nonatomic) NSString *destinationIdentifier;
- (void)swapViewController:(int)tabIndex;

@end
