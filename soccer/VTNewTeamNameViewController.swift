//
//  VTNewTeamNameViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/3.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTNewTeamNameViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var input_teamName: UITextField!
    @IBOutlet weak var button_nextStep: UIButton!
    
    var teamName: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        Appearance.customizeNavigationBar(self, title: "球队名称")
        Appearance.customizeTextField(self.input_teamName, iconName: "tshirt")
        
        // add right button in navigation bar programmatically
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Stop, target:self, action: "cancelNewTeamCreation")
        
        // Set this in every view controller so that the back button displays back instead of the root view controller name
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        self.input_teamName.addTarget(self, action: "validateUserInput", forControlEvents: .EditingChanged)
        
        self.input_teamName.delegate = self
    }
    
    func validateUserInput() {
        let enteredTeamNameLength = Toolbox.trim(self.input_teamName.text!).characters.count
        if enteredTeamNameLength > 0 && enteredTeamNameLength < 100 {
            Toolbox.toggleButton(self.button_nextStep, enabled: true)
        } else {
            Toolbox.toggleButton(self.button_nextStep, enabled: false)
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == self.input_teamName {
            if self.button_nextStep.enabled {
                self.input_teamName.resignFirstResponder()
                self.button_nextStep.sendActionsForControlEvents(.TouchUpInside)
                return true
            }
            return false
        }
        return false
    }
    
    func cancelNewTeamCreation() {
        // close modal view and all its related navigation controller to go back to teams list table view
        self.performSegueWithIdentifier("cancelNewTeamCreationFromTeamNameViewControllerSegue", sender: self)
 
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.input_teamName.resignFirstResponder()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "newTeamLocationSegue" {
            let destinationViewController = segue.destinationViewController as! VTNewTeamLocationTableViewController
            destinationViewController.teamName = self.teamName
        }
    }

    @IBAction func nextStepOfCreatingNewTeam(sender: AnyObject) {
        self.teamName = Toolbox.trim(self.input_teamName.text!)
        self.performSegueWithIdentifier("newTeamLocationSegue", sender: self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    deinit {
        self.teamName = nil
    }
    
}
