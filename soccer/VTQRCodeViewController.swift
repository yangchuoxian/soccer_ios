//
//  VTQRCodeViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/29.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTQRCodeViewController: UIViewController {

    @IBOutlet weak var imageView_fullQRCode: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // setup full size QR code image
        self.imageView_fullQRCode.image = Toolbox.generateQRCodeWithString(Singleton_CurrentUser.sharedInstance.userId!, scale: 25.0)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "二维码名片")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        if self.imageView_fullQRCode != nil {
            self.imageView_fullQRCode.image = nil
        }
    }
}
