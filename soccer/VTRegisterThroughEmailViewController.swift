//
//  VTRegisterThroughEmailViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/28.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTRegisterThroughEmailViewController: UIViewController, UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate, NSURLConnectionDataDelegate, NSURLConnectionDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var input_username: UITextField!
    @IBOutlet weak var input_password: UITextField!
    @IBOutlet weak var input_email: UITextField!
    @IBOutlet weak var button_register: UIButton!
    @IBOutlet weak var image_avatar: UIImageView!
    
    enum httpRequest {
        case uploadAvatar
        case submitNewUser
    }
    
    var picker: UIImagePickerController?
    var HUD: MBProgressHUD?
    var userId: String?
    var currentActiveTextFieldIndex: Int?
    var indexOfCurrentHttpRequest: httpRequest?
    var responseData: NSMutableData? = NSMutableData()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Appearance.customizeAvatarImage(self.image_avatar)
        Appearance.customizeTextField(self.input_username, iconName: "person")
        Appearance.customizeTextField(self.input_password, iconName: "locked")
        Appearance.customizeTextField(self.input_email, iconName: "at")
        
        self.button_register.layer.cornerRadius = 2.0
        // add tap gesture event to image_avatar, when image_avatar is tapped, user will be provided with options to whether select image or shoot a photo as avatar to upload
        let singleTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(VTRegisterThroughEmailViewController.avatarImageTapped))
        singleTap.numberOfTapsRequired = 1
        
        self.image_avatar.isUserInteractionEnabled = true
        self.image_avatar.addGestureRecognizer(singleTap)
        // assign tag value for different textField so that the system knows which textField is active/being edited
        self.input_username.tag = TagValue.textFieldUsername.rawValue
        self.input_password.tag = TagValue.textFieldPassword.rawValue
        self.input_email.tag = TagValue.textFieldEmail.rawValue
        
        self.input_username.delegate = self
        self.input_password.delegate = self
        self.input_email.delegate = self
        
        // add tap gesture for scrollView to hide keyboard
        let gestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(VTRegisterThroughEmailViewController.hideKeyboard(_:)))
        self.scrollView.addGestureRecognizer(gestureRecognizer)
        self.input_username.addTarget(self, action: #selector(VTRegisterThroughEmailViewController.validateUserInput), for: .editingChanged)
        self.input_password.addTarget(self, action: #selector(VTRegisterThroughEmailViewController.validateUserInput), for: .editingChanged)
        self.input_email.addTarget(self, action: #selector(VTRegisterThroughEmailViewController.validateUserInput), for: .editingChanged)
    }
    
    func validateUserInput() {
        let enteredUsernameLength = Toolbox.trim(self.input_username.text!).characters.count
        let enteredPasswordLength = Toolbox.trim(self.input_password.text!).characters.count
        let enteredEmail = Toolbox.trim(self.input_email.text!)
        let enteredEmailLength = Toolbox.trim(enteredEmail).characters.count
        
        if enteredUsernameLength > 0 && enteredUsernameLength <= 80 &&
            enteredPasswordLength >= 6 && enteredPasswordLength <= 20 &&
            enteredEmailLength > 0 && enteredEmailLength < 100 &&
            Toolbox.isValidEmail(enteredEmail) {
            Toolbox.toggleButton(self.button_register, enabled: true)
        } else {
            Toolbox.toggleButton(self.button_register, enabled: false)
        }
    }
    
    func hideKeyboard(_ sender: AnyObject) {
        // hide keyboard
        self.input_username.resignFirstResponder()
        self.input_password.resignFirstResponder()
        self.input_email.resignFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func actionSheet(_ actionSheet: UIActionSheet, clickedButtonAt buttonIndex: Int) {
        if buttonIndex == 1 {   // choose image from gallery
            // release self.picker memory first
            if self.picker != nil {
                self.picker?.delegate = nil
            }
            self.picker = nil
            
            self.picker = UIImagePickerController()
            self.picker?.delegate = self
            self.picker?.allowsEditing = true
            self.picker?.sourceType = .photoLibrary
            
            self.present(self.picker!, animated: true, completion: nil)
        } else if buttonIndex == 2 {    // take a photo
            if self.picker != nil {
                self.picker?.delegate = nil
            }
            self.picker = nil
            
            self.picker = UIImagePickerController()
            self.picker?.delegate = self
            self.picker?.allowsEditing = true
            self.picker?.sourceType = .camera
            
            self.present(self.picker!, animated: true, completion: nil)
        }
    }
    
    func avatarImageTapped() {
        let selectPhoto: String = "选择照片"
        let takePhoto: String = "拍照"
        let cancelTitle: String = "取消"
        let actionSheet: UIActionSheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: cancelTitle, destructiveButtonTitle: nil, otherButtonTitles: selectPhoto, takePhoto)
        actionSheet.show(in: self.view)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.currentActiveTextFieldIndex = textField.tag
    }
    
    // called when the UIKeyboardDidShowNotification is sent
    func keyboardWasShown(_ notification: Notification) {
        let info: NSDictionary = (notification as NSNotification).userInfo! as NSDictionary
        let keyboardSize: CGSize = (info.object(forKey: UIKeyboardFrameBeginUserInfoKey)! as AnyObject).cgRectValue.size
        let contentInsets: UIEdgeInsets = UIEdgeInsetsMake(0, 0, keyboardSize.height, 0)
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
        
        // if active text field is hidden by keyboard, scroll it so it's visible
        let tempRect: CGRect = CGRect(x: self.view.frame.origin.x, y: self.view.frame.origin.y + (ToolbarHeight + NavigationbarHeight), width: self.view.frame.size.width, height: self.view.frame.size.height - keyboardSize.height - (ToolbarHeight + NavigationbarHeight))
        var activeField: UITextField?
        switch self.currentActiveTextFieldIndex! {
        case TagValue.textFieldUsername.rawValue:
            activeField = self.input_username
            break
        case TagValue.textFieldPassword.rawValue:
            activeField = self.input_password
            break
        case TagValue.textFieldEmail.rawValue:
            activeField = self.input_email
            break
        default:
            activeField = nil
            break
        }
        if !tempRect.contains(activeField!.frame.origin) {
            self.scrollView.scrollRectToVisible(activeField!.frame, animated: true)
        }
    }
    
    // called when the UIKeyboardWillHideNotification is sent
    func keyboardWillBeHidden(_ notification: Notification) {
        let contentInsets: UIEdgeInsets = UIEdgeInsets(top: ToolbarHeight + NavigationbarHeight, left: 0, bottom: 0, right: 0)
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.input_username {
            self.input_username.resignFirstResponder()
            self.input_password.becomeFirstResponder()
            return true
        } else if textField == self.input_password {
            self.input_password.resignFirstResponder()
            self.input_email.becomeFirstResponder()
            return true
        } else if textField == self.input_email {
            if self.button_register.isEnabled {
                self.input_email.resignFirstResponder()
                self.button_register.sendActions(for: .touchUpInside)
                return true
            }
            return false
        }
        return false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        Appearance.customizeNavigationBar(self, title: "用户注册")
        // register for keyboard notifications
        NotificationCenter.default.addObserver(self, selector: #selector(VTRegisterThroughEmailViewController.keyboardWasShown(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(VTRegisterThroughEmailViewController.keyboardWillBeHidden(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        
        if self.picker != nil {
            self.picker?.delegate = nil
        }
        self.picker = nil
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [AnyHashable: Any]!) {
        self.image_avatar.image = image
        self.uploadAvatar(image)
        picker.dismiss(animated: true, completion: nil)
        
        if self.picker != nil {
            self.picker?.delegate = nil
        }
        self.picker = nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "serviceAgreementSegue" {
            let destinationViewController = segue.destination as! VTPostViewController
            destinationViewController.postType = .ServiceAgreement
        }
    }
    
    func uploadAvatar(_ image: UIImage) {
        var connection: NSURLConnection?
        if Toolbox.isStringValueValid(self.userId) {    // self.userId defined, meaning user avatar is already uploaded, temporary user already generated in server database
            let postParamsDictionary = ["modelId": self.userId!]
            connection = Toolbox.uploadImageToURL(URLUploadUserAvatar, image: image, parameters: postParamsDictionary, delegate: self)
        } else {
            connection = Toolbox.uploadImageToURL(URLUploadUserAvatar, image: image, parameters: nil, delegate: self)
        }
        if connection == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            self.indexOfCurrentHttpRequest = .uploadAvatar
            self.HUD = MBProgressHUD(view: self.navigationController?.view)
            self.navigationController?.view.addSubview(self.HUD!)
            self.HUD?.show(true)
        }
        connection = nil
    }

    func connection(_ connection: NSURLConnection, didReceive data: Data) {
        self.responseData?.append(data)
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        self.HUD!.hide(true)
        self.HUD = nil
        
        let responseStr = NSString(data: self.responseData! as Data, encoding: String.Encoding.utf8.rawValue)
        if self.indexOfCurrentHttpRequest == .uploadAvatar {
            // response for user avatar upload
            // retrieve user id from json data
            let jsonArray = (try? JSONSerialization.jsonObject(with: self.responseData! as Data, options: .mutableLeaves)) as? NSDictionary
            self.userId = jsonArray!.object(forKey: "modelId") as? String
            // save successfully uploaded user avatar to local app directory
            Toolbox.saveAvatarImageLocally(self.image_avatar.image!, modelId: self.userId!)
        } else {    // response for new user registration
            // if registration succeeded, response from server should be user info JSON data, so retrieve username from this JSON data to see if registration is successful
            let userJSON = (try? JSONSerialization.jsonObject(with: self.responseData! as Data, options: .mutableLeaves)) as? [AnyHashable: Any]
            
            let respondedUsername = userJSON?["username"] as? String
            if respondedUsername != nil {   // submit new user succeeded
                Singleton_CurrentUser.sharedInstance.processUserLogin(userJSON!)
            } else {    // submit new user failed with error message
                Toolbox.showCustomAlertViewWithImage("unhappy", title: responseStr as! String)
            }
        }
        
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        self.HUD!.hide(true)
        self.HUD = nil
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "加载失败")
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    @IBAction func submitNewUser(_ sender: AnyObject) {
        let username = Toolbox.trim(self.input_username.text!)
        let password = Toolbox.trim(self.input_password.text!)
        let email = Toolbox.trim(self.input_email.text!)

        var postParamsString: String
        if Toolbox.isStringValueValid(self.userId) {
            postParamsString = Toolbox.addDeviceIDAndDeviceTypeToHttpRequestParameters("username=\(username)&password=\(password)&email=\(email)&id=\(self.userId!)")
        } else {    // self.userId not defined, meaning user avatar is NOT uploaded
            postParamsString = Toolbox.addDeviceIDAndDeviceTypeToHttpRequestParameters("username=\(username)&password=\(password)&email=\(email)")
        }
        let connection = Toolbox.asyncHttpPostToURL(URLSubmitNewUser, parameters: postParamsString, delegate: self)
        if connection == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            self.indexOfCurrentHttpRequest = .submitNewUser
            self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: nil)
        }
    }
    
    deinit {
        self.image_avatar.image = nil
        if self.picker != nil {
            self.picker?.delegate = nil
            self.picker = nil
        }
        self.HUD = nil
        self.userId = nil
        self.currentActiveTextFieldIndex = nil
        self.indexOfCurrentHttpRequest = nil
        self.responseData = nil
    }
}
