//
//  SecondViewController.swift
//  pCars Dash-socket
//
//  Created by Derouich on 20/09/2015.
//  Copyright © 2015 Derouich. All rights reserved.
//

import UIKit

class SecondViewController: UIViewController,NSStreamDelegate {

    @IBOutlet weak var gearLabel: UILabel!
    @IBOutlet weak var lapTimeLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var positionLabel: UILabel!
    @IBOutlet weak var nbOppon: UILabel!
    @IBOutlet weak var rpmLabel: UILabel!
    @IBOutlet weak var kersProgress: UIProgressView!
    @IBOutlet weak var fuelLevelProgress: UIProgressView!
    @IBOutlet weak var bestLapTimeData: UILabel!
    @IBOutlet weak var lastLapTimeData: UILabel!
    
    @IBOutlet weak var suspWarning: UIImageView!
    @IBOutlet weak var engineWarning: UIImageView!
    @IBOutlet weak var brakeWarnin: UIImageView!
        
    struct Telemetry {
        var OilTempCelsius : Float32 = 0
        var OilPressureKPa : Float32 = 0
        var WaterTempCelsius :Float32 = 0
        var WaterPressureKPa : Float32 = 0
        var FuelPressureKPa : Float32 = 0
        var FuelLevel : Float32 = 0
        var FuelCapacity : Float32 = 0
        var Speed : Float32 = 0
        var Rpm : Float32 = 0
        var MaxRPM : Float32 = 0
        var Gear : Int = 0
        var NumGears : Int = 0
        var CurrentLapTimer : Float64 = 0
        var ActiveBoost : Int = 0
        var BoostAmount : Float32 = 0
        var NumberPart : Int=0
        var bestLap : Float64=0
        var lastLap : Float64=0
        var LastTime : Float64=0
        var susWarn : Float32=0
        var engWarn : Float32=0
        var brakWarn : Float32=0
        init() {
        }
    }
    
    @IBOutlet weak var rpmView: UIImageView!
    
    var dataTelemetry = Telemetry()
    
    
    var inputStream : NSInputStream?
    var outputStream : NSOutputStream?
    var timer = NSTimer()
    var onEstPasse:Bool=false
    
    public var ipString:String!
    var outputCut:String = ""
    
    @IBAction func buttonQuit(sender: AnyObject) {
        self.timer.invalidate()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.sharedApplication().idleTimerDisabled = true
        
        //App running second scene for loading data
        initNetworkCommunication(self.ipString)
        self.scheduledTimerWithTimeInterval()
        
        kersProgress.transform = CGAffineTransformScale(kersProgress.transform,1,2)
        fuelLevelProgress.transform = CGAffineTransformScale(fuelLevelProgress.transform,1,2)
        
    }
    
    func initNetworkCommunication(ipString:String) -> Void{
        NSLog("initialisation from second view")
        let host : CFString = NSString(string: self.ipString)
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
    
    
    func scheduledTimerWithTimeInterval(){
        // Scheduling timer to Call the function **Countdown** with the interval of 1 seconds
        timer = NSTimer.scheduledTimerWithTimeInterval(0.0155, target: self, selector: Selector("sendingRequest"), userInfo: nil, repeats: true)
        //0.0155
    }
    
    func sendingRequest ()
    {
        let data: NSData = "json".dataUsingEncoding(NSUTF8StringEncoding)!
        self.outputStream?.write(UnsafePointer<UInt8>(data.bytes), maxLength: data.length)
    }
    
    
    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent ) {
        switch (eventCode){
        case NSStreamEvent.OpenCompleted:
            NSLog("Stream opened")
            break
        case NSStreamEvent.HasBytesAvailable:
            NSLog("HasBytesAvailable")
            var buffer = [UInt8](count:2000, repeatedValue: 0)
            if ( aStream == inputStream){
                while (inputStream!.hasBytesAvailable){
                    let len = inputStream!.read(&buffer, maxLength: buffer.count)
                    if(len > 0){
                        let output = NSString(bytes: &buffer, length: buffer.count, encoding: NSUTF8StringEncoding)
                        //self.intSub = self.extractDataFromBuffer((output as? String)!)
                        if (output != ""){
                            if(self.onEstPasse){
                                outputCut = (output?.substringToIndex(len))!
                                //var str="[{\"pCARS\":{\"State\":\"0\"}}]"
                                let data : NSData=(outputCut.dataUsingEncoding(NSUTF8StringEncoding))!
                                // var errorParse : NSError?
                                
                                //convert NSData to anyObj
                                var anyObj:AnyObject? = []
                                do{
                                    //NSJSONReadingOptions.AllowFragments
                                    anyObj = try NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions())
                                    // Parsing json Data to arrayar
                                    self.parseJson(anyObj!)
                                    //Rafraiching screen app
                                    dispatch_async(dispatch_get_main_queue(), {
 
                                        if(self.dataTelemetry.Gear == -1 ){
                                                self.gearLabel.text=String("R")
                                        }
                                        else if (self.dataTelemetry.Gear==0){
                                            self.gearLabel.text="N"
                                        }
                                        else{
                                            self.gearLabel.text=String(self.dataTelemetry.Gear)
                                        }
                                        if(self.dataTelemetry.CurrentLapTimer>0){
                                            self.lapTimeLabel.text = self.secondsToHoursMinutesSeconds(self.dataTelemetry.CurrentLapTimer)
                                        }
                                        else
                                        {
                                            self.lapTimeLabel.text="00:00:00"
                                        }
                                        if(self.dataTelemetry.bestLap>0)
                                        {
                                            self.bestLapTimeData.text=self.secondsToHoursMinutesSeconds(self.dataTelemetry.bestLap)
                                        }
                                        else{
                                            self.bestLapTimeData.text="00:00:00"
                                        }

                                        if(self.dataTelemetry.lastLap>0)
                                        {
                                            self.bestLapTimeData.text=self.secondsToHoursMinutesSeconds(self.dataTelemetry.lastLap)
                                        }
                                        else{
                                            self.lastLapTimeData.text="00:00:00"
                                        }
                                        
                                        self.speedLabel.text=String(self.dataTelemetry.Speed)

                                        self.rpmLabel.text=String(self.dataTelemetry.Rpm)
                                        
                                        if(self.dataTelemetry.Rpm >= self.dataTelemetry.MaxRPM){
                                                self.gearLabel.backgroundColor=UIColor.redColor()
                                            }
                                        else
                                        {
                                            self.gearLabel.backgroundColor=UIColor.whiteColor()
                                        }

                                        if(self.dataTelemetry.BoostAmount != 0)
                                        {
                                            self.kersProgress.setProgress(self.dataTelemetry.BoostAmount/100, animated: true)
                                        }
                                        
//                                        if(self.dataTelemetry.susWarn != 0 )
//                                        {
//                                            self.suspWarning.hidden=false
//                                        }
//                                        else{
//                                            self.suspWarning.hidden = true
//                                        }
                                        
                                        if(self.dataTelemetry.engWarn != 0)
                                        {
                                            self.engineWarning.hidden = false
                                        }
                                        else{
                                            self.engineWarning.hidden = true
                                        }
                                        
                                        if(self.dataTelemetry.brakWarn != 0)
                                        {
                                            self.brakeWarnin.hidden = false
                                        }
                                        else{
                                            self.brakeWarnin.hidden = true
                                        }
                                        
                                        self.fuelLevelProgress.setProgress(self.dataTelemetry.FuelLevel, animated: true)
                                    })
                                    
                                    
                                }
                                catch let error as NSError{
                                    print(error)
                                }
                            }
                            else
                            {
                                self.onEstPasse=true
                            }
                        }
                    }
                }
            }
            
            break
        case NSStreamEvent.ErrorOccurred:
            NSLog("ErrorOccurred")
            self.timer.invalidate()
            let controller = storyboard?.instantiateViewControllerWithIdentifier("ViewController") as! ViewController
            presentViewController(controller, animated: true, completion: nil)
            //Back to First screen
            break
        case NSStreamEvent.EndEncountered:
            NSLog("EndEncountered")
            self.timer.invalidate()
            let controller = storyboard?.instantiateViewControllerWithIdentifier("ViewController") as! ViewController
            presentViewController(controller, animated: true, completion: nil)
            //Back to First screen
            break
        case NSStreamEvent.HasSpaceAvailable:
            NSLog("HasSpaceAvailable")
            break
        default:
            NSLog("unknown.")
        }
    }
    
    func parseJson(anyObj:AnyObject)
    {
        if (anyObj is Array<AnyObject>){
            if let item = anyObj[0] as AnyObject? {
                if let gameStat = item["pCARS"] as AnyObject?{
                    
                    if let statu = gameStat["State"] as AnyObject?{
                        
                        if (statu.integerValue > 0){
                            print("Game is RUNNING, Gathering telemetry data")
                            
                            if let json = gameStat["Me"] as AnyObject? {
                                
                                self.dataTelemetry.FuelCapacity = (json["FuelCapacity"] as? Float32 )!
                                self.dataTelemetry.FuelLevel = (json["FuelLevel"] as? Float32  )!
                                self.dataTelemetry.FuelPressureKPa = (json["FuelPressureKPa"] as? Float32 )!
                                self.dataTelemetry.Gear = (json["Gear"] as? Int  )!
                                self.dataTelemetry.MaxRPM = (json["MaxRPM"] as? Float32 )!
                                self.dataTelemetry.NumGears = (json["NumGears"] as? Int )!
                                self.dataTelemetry.OilPressureKPa = (json["OilPressureKPa"] as? Float32 )!
                                self.dataTelemetry.OilTempCelsius = (json["OilTempCelsius"] as? Float32 )!
                                self.dataTelemetry.Rpm = (json["Rpm"] as? Float32 )!
                                self.dataTelemetry.Speed = (json["Speed"] as? Float32 )!
                                self.dataTelemetry.WaterPressureKPa = (json["WaterPressureKPa"] as? Float32 )!
                                self.dataTelemetry.WaterTempCelsius = (json["WaterTempCelsius"] as? Float32 )!
                                self.dataTelemetry.NumberPart = (json["NumberParticipant"] as? Int )!
                                self.dataTelemetry.CurrentLapTimer=(json["CurrentLapTime"] as? Float64)!
                                
                                self.dataTelemetry.bestLap = (json["BestLapTime"] as? Float64 )!
                                self.dataTelemetry.lastLap = (json["LastLapTime"] as? Float64 )!
                                
                                self.dataTelemetry.brakWarn = (json["BrakeDamage"] as? Float32 )!
                                self.dataTelemetry.engWarn = (json["EngineDamage"] as? Float32 )!
                                //self.dataTelemetry.susWarn = (json["SuspensionDamage"] as? Float32 )!
                                
                                self.dataTelemetry.BoostAmount=(json["BoostAmount"] as? Float32)!
                            }
                        }
                        else{
                        print("Game not RUNNING")
                        print(statu)
                        }
                    }
                }
            }
        }
    }
    // passing data
    
    


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        self.timer.invalidate()
    }
    
    func secondsToHoursMinutesSeconds (seconds : Double) -> (String) {
        let (hr,  minf) = modf (seconds / 3600)
        let (min, secf) = modf (60 * minf)
        var retour:String//=String(hr) + ":"
        retour = String(min) + ":"
        retour += String.localizedStringWithFormat("%.3f",60 * secf)
        return String(retour)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    

}
