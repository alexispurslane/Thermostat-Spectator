//
//  AuthorizeViewController.swift
//  Thermostat Spectator
//
//  Created by Christopher Dumas on 11/1/15.
//  Copyright © 2015 Christopher Dumas. All rights reserved.
//

import UIKit

class AuthorizeViewController: UIViewController {
    @IBOutlet weak var webView: UIWebView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.webView.loadRequest(NSURLRequest(URL: NSURL(string: "https://home.nest.com/login/oauth2?client_id=18d350b8-616e-4112-8920-8d128261bcca&state=STATE")!))
    }
}