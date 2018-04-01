//
//  ViewController.swift
//  pCars Dash-socket
//
//  Created by Derouich on 20/09/2015.
//  Copyright © 2015 Derouich. All rights reserved.
//

import UIKit

class ViewController: UIViewController,NSStreamDelegate {
    
    @IBOutlet weak var ip1: UITextField!
    @IBOutlet weak var ip2: UITextField!
    @IBOutlet weak var ip3: UITextField!
    @IBOutlet weak var ip4: UITextField!
    
    var segueShouldOccur:Bool=false
    
    enum   EncryptionError : ErrorType
    {
        case empty
        case short
    }
    
    var inputStream : NSInputStream?
    var outputStream : NSOutputStream?
    var message : NSMutableArray = []
    var timer = NSTimer()
    var stopper=NSTimer()

    var ipString:String=""
    var pressed:Bool=false
    //var openned:Bool=false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
//        if(openned == false){
//            self.initNetworkCommunication(self.ipString)
//            NSLog("joining . . .")
//            scheduledTimerWithTimeInterval()
//        }
        
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "DismissKeyboard")
        view.addGestureRecognizer(tap)
        
    }
    
    func DismissKeyboard(){
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    @IBAction func buttonPressed(sender: AnyObject) {
        
        var ipString=ip1.text! + "."
        ipString += ip2.text! + "."
        ipString+=ip3.text! + "."
        ipString+=ip4.text!
        self.ipString=ipString
        
        NSLog(ipString)
        
        self.initNetworkCommunication(self.ipString)
        NSLog("joining . . .")
        scheduledTimerWithTimeInterval()
    }
    
    func scheduledTimerWithTimeInterval(){
        // Scheduling timer to Call the function **Countdown** with the interval of 1 seconds
        timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("sendingRequest"), userInfo: nil, repeats: true)
        stopper = NSTimer.scheduledTimerWithTimeInterval(4.5, target: self, selector: Selector("stopRequest"), userInfo: nil, repeats: true)
    }
    
    func stopRequest(){
        
        timer.invalidate()
        
        if #available(iOS 8.0, *) {
            let alert = UIAlertController(title: "Connection Problem", message: "Can't connect to the given IP", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            stopper.invalidate()
        } else {
            // Fallback on earlier versions
            NSLog("probleme")
        }
        
        
    }
    
    func initNetworkCommunication(ipString:String) -> Void{

        let host : CFString = NSString(string: ipString)
        let port : UInt32 = UInt32(23614)
        
        var readStream : Unmanaged<CFReadStream>?
        var writeStream : Unmanaged<CFWriteStream>?
        
        CFStreamCreatePairWithSocketToHost(nil,host, port,&readStream,&writeStream )
        
        inputStream = readStream!.takeUnretainedValue()
        outputStream = writeStream!.takeUnretainedValue()
        
        inputStream!.delegate=self
        outputStream!.delegate=self
        
        inputStream!.scheduleInRunLoop(NSRunLoop.currentRunLoop(),forMode : NSDefaultRunLoopMode)
        outputStream!.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        
        
        inputStream!.open()
        outputStream!.open()
        
    }
    
    func sendingRequest ()
    {
        
        NSLog("Sending request from View Controller")
        
        let data: NSData = "json".dataUsingEncoding(NSUTF8StringEncoding)!
        self.outputStream?.write(UnsafePointer<UInt8>(data.bytes), maxLength: data.length)
    }
    
    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent ) {
        switch (eventCode){
        case NSStreamEvent.OpenCompleted:
            NSLog("Stream opened")
            //Socket responding with data
            //Translation to second scene screen
            break
        case NSStreamEvent.HasBytesAvailable:
            NSLog("HasBytesAvailable")
            //Socket responding with data
            //transation to the second screen
            //self.openned=true
            timer.invalidate()
            stopper.invalidate()
            self.segueShouldOccur=true
            let controller = storyboard?.instantiateViewControllerWithIdentifier("SecondViewController") as! SecondViewController
            controller.ipString = self.ipString
            presentViewController(controller, animated: true, completion: nil)
            break
        case NSStreamEvent.ErrorOccurred:
            NSLog("ErrorOccurred")
            self.stopRequest()
            break
        case NSStreamEvent.EndEncountered:
            NSLog("EndEncountered")
            timer.invalidate()
            break
        case NSStreamEvent.HasSpaceAvailable:
            NSLog("HasSpaceAvailable")
            break
        default:
            NSLog("unknown.")
        }
    }
    
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
//        if (segue.identifier == "segueTest") {
//            let svc = segue.destinationViewController as! SecondViewController;
//            
////            svc.inputStream=self.inputStream
////            svc.outputStream=self.outputStream
//            //passing ip adress
//            NSLog(ipString)
//            svc.ipString=self.ipString
//            
//        }
//    }
    
    override func shouldPerformSegueWithIdentifier(identifier: (String!), sender: AnyObject!) -> Bool {
        if identifier == "segueTest" { // you define it in the storyboard (click on the segue, then Attributes' inspector > Identifier
            if !segueShouldOccur {
                print("*** NOPE, segue won't occur")
                return false
            }
            else {
                print("*** YEP, segue will occur")
            }
        }
        // by default, transition
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

