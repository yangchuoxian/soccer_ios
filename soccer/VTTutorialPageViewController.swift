//
//  VTTutorialPageViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/27.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTTutorialPageViewController: UIPageViewController, UIPageViewControllerDataSource {

    var pageImageNames: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.pageImageNames = ["tutorial_1", "tutorial_2", "tutorial_3"]
        self.dataSource = self
        
        // set up the first tutorial page content view controller
        let startingViewController = self.viewControllerAtIndex(0)
        let viewControllers = [startingViewController]
        self.setViewControllers(viewControllers, direction: .forward, animated: false, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        var index = (viewController as! VTTutorialPageContentViewController).pageIndex
        if index == NSNotFound || index == 0 {
            return nil
        }
        
        index = index - 1
        return self.viewControllerAtIndex(index)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        var index = (viewController as! VTTutorialPageContentViewController).pageIndex
        if index == NSNotFound {
            return nil
        }
        
        index = index + 1
        if index == self.pageImageNames.count {
            return nil
        }
        return self.viewControllerAtIndex(index)
    }
    
    func viewControllerAtIndex(_ index: Int) -> VTTutorialPageContentViewController {
        // Create a new tutorial page content view controller
        let tutorialContentViewController = self.storyboard?.instantiateViewController(withIdentifier: "tutorialPageContentViewController") as! VTTutorialPageContentViewController
        tutorialContentViewController.imageName = self.pageImageNames[index]
        tutorialContentViewController.pageIndex = index
        
        return tutorialContentViewController
    }
    
}
