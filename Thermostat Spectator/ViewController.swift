//
//  ViewController.swift
//  Thermostat Spectator
//
//  Created by Christopher Dumas on 11/1/15.
//  Copyright © 2015 Christopher Dumas. All rights reserved.
//

import Firebase
import UIKit
import Foundation

extension UIColor {
    convenience init(hexString: String) {
        let hexString:NSString = hexString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        let scanner            = NSScanner(string: hexString as String)
        
        if (hexString.hasPrefix("#")) {
            scanner.scanLocation = 1
        }
        
        var color:UInt32 = 0
        scanner.scanHexInt(&color)
        
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        
        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0
        
        self.init(red:red, green:green, blue:blue, alpha:1)
    }
    
    func toHexString() -> String {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        
        return NSString(format:"#%06x", rgb) as String
    }
}

class ViewController: UIViewController {
    
    
    @IBOutlet weak var goal: UILabel!
    @IBOutlet weak var current: UILabel!
    @IBOutlet weak var progress: UIProgressView!
    
    @IBOutlet weak var downB: UIButton!
    @IBOutlet weak var upB: UIButton!
    var goalTemp: Float = 76
    var currentTemp: Float = 76
    var canCool = true
    var canHeat = true
    var measurement = "F"
    var accessToken: String? = ""
    
    @IBAction func up(sender: AnyObject) {
        
    }
    
    @IBAction func down(sender: AnyObject) {
        
    }
    
    var textField: UITextField?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        performSegueWithIdentifier("authorize", sender: self)
        
        let alert = UIAlertController(title: "Authorization Pin Number", message: "Enter the pin number that you got on the previous page.", preferredStyle:
            UIAlertControllerStyle.Alert)
        
        alert.addTextFieldWithConfigurationHandler({ (textField) in
            textField.placeholder = "Pin"
            self.textField = textField
        })
        
        var pin = ""
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) in
            print("Cancel")
        }))
            
        alert.addAction(UIAlertAction(title: "Authorize", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) in
            pin = self.textField!.text!
            
            let request = NSMutableURLRequest(URL: NSURL(string: "https://api.home.nest.com/oauth2/access_token")!)
            request.HTTPMethod = "POST"
            let postString = "code=\(pin)&client_id=5ed3998f-34ec-40d2-83c1-057284ecc948&client_secret=CqUsOU73GJzTyxkQF03ZEElIE&grant_type=authorization_code"
            request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding)
            let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
                data, response, error in
                
                if error != nil {
                    print("\(error)")
                    return
                }
                
                self.accessToken = NSString(data: data!, encoding: NSUTF8StringEncoding) as? String
            }
            task.resume()
            
            self.updateInformation()
        }))
        presentViewController(alert, animated: true, completion: nil)
        
        // Do any additional setup after loading the view, typically from a nib.
        navigationController?.navigationBar.barTintColor = UIColor(hexString: "#00afd8")
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
    }
    
    func updateInformation() {
        if let accessT = self.accessToken {
            let ref = Firebase(url: "wss://developer-api.nest.com")
            ref.authWithCustomToken(accessT, withCompletionBlock: { (e, r) in
                if (e != nil) {
                    print(e.localizedDescription)
                }
                ref.observeEventType(.Value, withBlock: { (snapshot) in
                    let data = snapshot.value
                    let thermostat = data.objectForKey("devices")?.objectForKey("thermostats")?.objectForKey("Zi1KulbnMhFvKSt4_HuEsWEnAvGOm31c")!
                    self.canCool = Bool(thermostat!.objectForKey("can_cool") as! Int)
                    self.canHeat = Bool(thermostat!.objectForKey("can_heat") as! Int)
                    
                    if (!self.canCool) {
                        self.downB.enabled = false
                    }
                    if (!self.canHeat) {
                        self.upB.enabled = false
                    }
                    
                    let postfix = "_\(self.measurement.lowercaseString)"
                    self.goalTemp = (thermostat!.objectForKey("target_temperature" + postfix) as! Float)
                    self.currentTemp = (thermostat!.objectForKey("ambient_temperature" + postfix) as! Float)
                    self.navigationController?.navigationBar.topItem?.title = (thermostat!.objectForKey("name") as! String)
                    
                    let state = thermostat!.objectForKey("hvac_state") as! String
                    if state == "cooling" {
                        self.progress.progressTintColor = UIColor(hexString: "#00afd8")
                    } else if state == "heating" {
                        self.progress.progressTintColor = UIColor.redColor()
                    }
                    
                    self.updateInterface()
                }, withCancelBlock: { (e) in
                    print(e.localizedDescription)
                })
            })
        }
    }
    
    func updateInterface() {
        goal.text = "\(Int(goalTemp))°\(self.measurement)"
        current.text = "Current: \(Int(currentTemp))°\(self.measurement)"
        if currentTemp <= goalTemp {
            progress.progress = currentTemp / goalTemp
        } else if currentTemp >= goalTemp {
            progress.progress = goalTemp / currentTemp
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

