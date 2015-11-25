//
//  VTContainerViewController.m
//  soccer
//
//  Created by 杨逴先 on 15/3/8.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

#import "VTContainerViewController.h"

@interface VTContainerViewController ()

@end

@implementation VTContainerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.viewControllersByIdentifier = [NSMutableDictionary dictionary];
    [self performSegueWithIdentifier:@"basicInfo" sender:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.childViewControllers.count < 1) {
        [self performSegueWithIdentifier:@"basicInfoSegue" sender:self];
    }
    NSLog(@"will appear");
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    self.destinationViewController.view.frame = self.view.bounds;
}

- (void)didReceiveMemoryWarning {
    [[self.viewControllersByIdentifier allKeys] enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        if (![self.destinationIdentifier isEqualToString:key]) {
            [self.viewControllersByIdentifier removeObjectForKey:key];
        }
    }];
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([self.destinationIdentifier isEqual:identifier]) {
        //Dont perform segue, if visible ViewController is already the destination ViewController
        return NO;
    }
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if (![segue isKindOfClass:[VTTabSwitchSegue class]]) {
        [super prepareForSegue:segue sender:sender];
        return;
    }
    self.oldViewController = self.destinationViewController;
    //if view controller isn't already contained in the viewControllers-Dictionary
    if (![self.viewControllersByIdentifier objectForKey:segue.identifier]) {
        [self.viewControllersByIdentifier setObject:segue.destinationViewController forKey:segue.identifier];
    }
    self.destinationIdentifier = segue.identifier;
    self.destinationViewController = [self.viewControllersByIdentifier objectForKey:self.destinationIdentifier];
}

- (void)swapViewController:(int)tabIndex {
    switch (tabIndex) {
        case 1: {
            [self performSegueWithIdentifier:@"basicInfoSegue" sender:self];
            NSLog(@"11");
        }
        break;
        case 2: {
            [self performSegueWithIdentifier:@"statisticsSegue" sender:self];
            NSLog(@"22");
        }
        break;
        case 3: {
            [self performSegueWithIdentifier:@"playerIDSegue" sender:self];
            NSLog(@"33");
        }
        break;
        default:
        break;
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
