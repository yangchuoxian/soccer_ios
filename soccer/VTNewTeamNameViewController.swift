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
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target:self, action: #selector(VTNewTeamNameViewController.cancelNewTeamCreation))
        
        // Set this in every view controller so that the back button displays back instead of the root view controller name
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.input_teamName.addTarget(self, action: #selector(VTNewTeamNameViewController.validateUserInput), for: .editingChanged)
        
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.input_teamName {
            if self.button_nextStep.isEnabled {
                self.input_teamName.resignFirstResponder()
                self.button_nextStep.sendActions(for: .touchUpInside)
                return true
            }
            return false
        }
        return false
    }
    
    func cancelNewTeamCreation() {
        // close modal view and all its related navigation controller to go back to teams list table view
        self.performSegue(withIdentifier: "cancelNewTeamCreationFromTeamNameViewControllerSegue", sender: self)
 
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.input_teamName.resignFirstResponder()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "newTeamLocationSegue" {
            let destinationViewController = segue.destination as! VTNewTeamLocationTableViewController
            destinationViewController.teamName = self.teamName
        }
    }

    @IBAction func nextStepOfCreatingNewTeam(_ sender: AnyObject) {
        self.teamName = Toolbox.trim(self.input_teamName.text!)
        self.performSegue(withIdentifier: "newTeamLocationSegue", sender: self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    deinit {
        self.teamName = nil
    }
    
}
