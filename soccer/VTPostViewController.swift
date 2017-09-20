//
//  VTPostViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/9.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTPostViewController: UIViewController, NSURLConnectionDelegate, NSURLConnectionDataDelegate {

    @IBOutlet weak var webview_post: UIWebView!
    
    var HUD: MBProgressHUD?
    var postType: PostType?
    var responseData: NSMutableData? = NSMutableData()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController!.navigationBar.topItem!.title = ""
 
        // http request to get post content from server
        let url = URLGetPostByTitle + self.postType!.rawValue
        let viewTitle = self.postType!.rawValue
        Appearance.customizeNavigationBar(self, title: viewTitle)
        
        let connection = Toolbox.asyncHttpGetFromURL(url, delegate: self)
        if connection == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: nil)
        }
        self.webview_post.scrollView.contentSize = CGSize(width: self.webview_post.frame.size.width, height: self.webview_post.scrollView.contentSize.height)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func connection(_ connection: NSURLConnection, didReceive data: Data) {
        self.responseData?.append(data)
    }
    
    func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        self.HUD?.hide(true)
        self.HUD = nil
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络超时")
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        self.HUD?.hide(true)
        self.HUD = nil
        // show the html string in html form in webview
        let responseStr = NSString(data: self.responseData! as Data, encoding: String.Encoding.utf8.rawValue)
        self.webview_post.loadHTMLString(responseStr! as String, baseURL: nil)
        
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    deinit {
        self.HUD = nil
        self.responseData = nil
    }

}
