//
//  ViewController.swift
//  DragTimer
//
//  Created by Philipp Matthes on 07.08.17.
//  Copyright © 2017 Philipp Matthes. All rights reserved.
//

import UIKit
import Charts
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate, ChartViewDelegate {
    
    let gradientLayer = CAGradientLayer()
    
    @IBOutlet weak var speedReplacementLabel: UILabel!
    @IBOutlet var background: UIView!
    @IBOutlet weak var maxSpeedLabel: UILabel!
    @IBOutlet weak var avgSpeedLabel: UILabel!
    @IBOutlet weak var accuracyLabel: UILabel!
    @IBOutlet weak var accuracyBackground: UIView!
    @IBOutlet weak var avgSpeedBackground: UIView!
    @IBOutlet weak var speedTypeButton: UIButton!
    
    @IBOutlet weak var speedTypeBackground: UIView!
    @IBOutlet weak var maxSpeedBackground: UIView!
    @IBOutlet weak var currentSpeedBackground: UIView!
    @IBOutlet weak var currentSpeedStackView: UIStackView!
    
    @IBOutlet weak var accelerationLabel: UILabel!
    @IBOutlet weak var accelerationBackground: UIView!
    @IBOutlet weak var speedLogChart: LineChartView!
    @IBOutlet weak var speedLogChartBackground: UIView!
    @IBOutlet weak var heightLogChart: LineChartView!
    @IBOutlet weak var heightLogChartBackground: UIView!
    
    let manager = CLLocationManager()
    var speedLog = [Double]()
    var heightLog = [Double]()
    var locations = [CLLocation]()
    
    var currentLocation = CLLocation()
    var currentSpeed = 0.0
    var currentHeight = 0.0
    var convertedCurrentSpeed = 0.0
    var maxSpeed = 0.0
    var convertedMaxSpeed = 0.0
    var avgSpeed = 0.0
    var convertedAvgSpeed = 0.0
    var currentHorizontalAccuracy = 5.0
    var currentAcceleration = 0.0
    
    let drawRange = 60
    
    var speedType = "km/h"
    var speedTypeCoefficient = 3.6
    
    weak var timer: Timer?
    var startTime: Double = 0
    var time: Double = 0
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        self.locations = locations
        self.currentLocation = self.locations[0]
        
        if self.speedLog.count > 1 {
            let exactAcceleration = (self.speedLog[0] - self.speedLog[1]) / 9.809
            self.currentAcceleration = Double(round(100 * exactAcceleration)/100)
        }
        
        // Update current speed
        let speed = self.currentLocation.speed
        if speed >= 0.0 {
            self.currentSpeed = speed
        }
        
        // Update current height
        let height = self.currentLocation.altitude
        if height >= 0.0 {
            self.currentHeight = height
        }
        
        // Update height log
        self.heightLog.insert(self.currentHeight, at: 0)
        if self.heightLog.count > self.drawRange {
            self.heightLog.remove(at: self.drawRange)
        }
        
        // Update speed log
        self.speedLog.insert(self.currentSpeed, at: 0)
        if self.speedLog.count > self.drawRange {
            self.speedLog.remove(at: self.drawRange)
        }
        
        // Convert current speed and save
        self.convertedCurrentSpeed = Double(round(100 * self.currentSpeed * self.speedTypeCoefficient)/100)
        
        
        if self.speedLog.max()! > self.maxSpeed {
            self.maxSpeed = self.speedLog.max()!
        }
        self.convertedMaxSpeed = Double(round(100 * self.maxSpeed * self.speedTypeCoefficient)/100)
        
        self.avgSpeed = self.speedLog.reduce(0, +) / Double(self.speedLog.count)
        self.convertedAvgSpeed = Double(round(100 * self.avgSpeed * self.speedTypeCoefficient)/100)
        
        self.currentHorizontalAccuracy = Double(round(100 * self.currentLocation.horizontalAccuracy)/100)
        
        self.refreshAllLabels()
        self.saveVariables()
        self.updateSpeedGraph()
        self.updateHeightGraph()
        
        
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let test = ("Test1","Test2")
        print(test.0)
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        
        self.setUpInterfaceDesign()
        
        self.speedLogChart.delegate = self
        self.heightLogChart.delegate = self
        
        let touchRecognizerSpeedLog = UITapGestureRecognizer(target: self, action:  #selector (self.speedLogPressed (_:)))
        let touchRecognizerHeightLog = UITapGestureRecognizer(target: self, action:  #selector (self.heightLogPressed (_:)))
        
        speedLogChart.addGestureRecognizer(touchRecognizerSpeedLog)
        heightLogChart.addGestureRecognizer(touchRecognizerHeightLog)
        
        
    }
    
    func startTimerAndUpdateLabel() {
        startTime = Date().timeIntervalSinceReferenceDate
        timer = Timer.scheduledTimer(timeInterval: 0.05,
                                     target: self,
                                     selector: #selector(advanceTimer(timer:)),
                                     userInfo: nil,
                                     repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        timer?.invalidate()
    }
    
    func advanceTimer(timer: Timer) {
        
        //Total time since timer started, in seconds
        time = Date().timeIntervalSinceReferenceDate - startTime
        
        //Convert the time to a string with 2 decimal places
        let timeString = String(format: "%.2f", time)
        
        //Display the time string to a label in our view controller
        print(timeString)
    }
    
    func setUpInterfaceDesign() {
        self.currentSpeedBackground.layer.cornerRadius = 10.0
        self.maxSpeedBackground.layer.cornerRadius = 10.0
        self.avgSpeedBackground.layer.cornerRadius = 10.0
        self.speedTypeBackground.layer.cornerRadius = 10.0
        self.accuracyBackground.layer.cornerRadius = 10.0
        self.speedLogChartBackground.layer.cornerRadius = 10.0
        self.heightLogChartBackground.layer.cornerRadius = 10.0
        self.accelerationBackground.layer.cornerRadius = 10.0
        
        setUpBackground(frame: self.view.bounds)
    }
    
    func setUpBackground(frame: CGRect) {
        gradientLayer.frame = frame
        let color1 = UIColor(red: 1.0, green: 0.666, blue: 0, alpha: 1.0).cgColor as CGColor
        let color2 = UIColor(red: 0.83, green: 0.10, blue: 0.10, alpha: 1.0).cgColor as CGColor
        gradientLayer.colors = [color1, color2]
        gradientLayer.locations = [0.0, 1.0]
        self.view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let screenSize = CGSize(width: size.width * 1.5, height: size.height * 1.5)
        let screenOrigin = CGPoint(x: 0, y: 0)
        let screenFrame = CGRect(origin: screenOrigin, size: screenSize)
        if UIDevice.current.orientation.isLandscape {
            self.setUpBackground(frame: screenFrame)
        } else if UIDevice.current.orientation.isPortrait {
            self.setUpBackground(frame: screenFrame)
        }
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func speedTypeButtonPressed(_ sender: UIButton){
        let alertController = UIAlertController(
            title: "Units selection",
            message: nil,
            preferredStyle: UIAlertControllerStyle.actionSheet
        )
        
        let speedTypeKphAction = UIAlertAction (
            title: "Metric (km/h)",
            style: UIAlertActionStyle.default
        ) {
            (action) -> Void in
            self.speedType = "km/h"
            self.speedTypeCoefficient = 3.6
            self.refreshAllLabels()
        }
        
        let speedTypeMphAction = UIAlertAction (
            title: "Imperialistic (mph)",
            style: UIAlertActionStyle.default
        ) {
            (action) -> Void in
            self.speedType = "mph"
            self.speedTypeCoefficient = 2.23694
            self.refreshAllLabels()
        }
        
        let speedTypeMpsAction = UIAlertAction (
            title: "Native (m/s)",
            style: UIAlertActionStyle.default
        ) {
            (action) -> Void in
            self.speedType = "m/s"
            self.speedTypeCoefficient = 1.0
            self.refreshAllLabels()
        }
        
        let speedTypeKnotsAction = UIAlertAction (
            title: "Aeronautical (kn)",
            style: UIAlertActionStyle.default
        ) {
            (action) -> Void in
            self.speedType = "kn"
            self.speedTypeCoefficient = 1.94384
            self.refreshAllLabels()
        }
        
        let cancelButtonAction = UIAlertAction (
            title: "Cancel",
            style: UIAlertActionStyle.cancel
        ) {
            (action) -> Void in
            print("User cancelled action.")
        }
        
        alertController.addAction(speedTypeKphAction)
        alertController.addAction(speedTypeMphAction)
        alertController.addAction(speedTypeMpsAction)
        alertController.addAction(speedTypeKnotsAction)
        alertController.addAction(cancelButtonAction)
        
        let popOver = alertController.popoverPresentationController
        popOver?.sourceView = sender as UIView
        popOver?.sourceRect = (sender as UIView).bounds
        popOver?.permittedArrowDirections = UIPopoverArrowDirection.any
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    func refreshAllLabels() {
        DispatchQueue.main.async(execute:  {
            self.speedReplacementLabel.text = "\(self.convertedCurrentSpeed) "+self.speedType
            self.speedTypeButton.setTitle(self.speedType, for: .normal)
            self.maxSpeedLabel.text = "\(self.convertedMaxSpeed) "+self.speedType
            self.avgSpeedLabel.text = "\(self.convertedAvgSpeed) "+self.speedType
            self.accuracyLabel.text = "\(self.currentHorizontalAccuracy) m"
            self.accelerationLabel.text = "\(self.currentAcceleration) g"
        })
    }
    
    func updateSpeedGraph() {
        
        var lineChartEntriesSpeed = [ChartDataEntry]()
        
        for i in 0..<self.speedLog.count {
            let value = ChartDataEntry(x: Double(self.speedLog.count - i), y: self.speedLog[i]*self.speedTypeCoefficient)
            lineChartEntriesSpeed.insert(value, at: 0)
        }


        let speedLine = LineChartDataSet(values: lineChartEntriesSpeed, label: "Speed (in "+self.speedType+")")
        speedLine.drawCirclesEnabled = false
        speedLine.drawCubicEnabled = true
        speedLine.lineWidth = 2.0
        speedLine.drawFilledEnabled = true
        speedLine.colors = [NSUIColor.black]

        let data = LineChartData()
        
        data.addDataSet(speedLine)
        
        data.setDrawValues(false)

        self.speedLogChart.data = data
        self.speedLogChart.chartDescription?.text = nil
        self.speedLogChart.notifyDataSetChanged()
        
        self.speedLogChart.setVisibleXRange(minXRange: 0, maxXRange: Double(self.drawRange))
        self.speedLogChart.leftAxis.axisMinimum = 0
        self.speedLogChart.rightAxis.enabled = false
    }
    
    func updateHeightGraph() {
        
        var lineChartEntriesHeight = [ChartDataEntry]()
        
        for i in 0..<self.heightLog.count {
            let value = ChartDataEntry(x: Double(self.heightLog.count - i), y: self.heightLog[i])
            lineChartEntriesHeight.insert(value, at: 0)
        }
        
        let heightLine = LineChartDataSet(values: lineChartEntriesHeight, label: "Height in m")
        heightLine.drawCirclesEnabled = false
        heightLine.drawCubicEnabled = true
        heightLine.lineWidth = 2.0
        heightLine.drawFilledEnabled = true
        heightLine.colors = [NSUIColor.orange]
        
        let data = LineChartData()
        
        data.addDataSet(heightLine)
        
        data.setDrawValues(false)
        
        self.heightLogChart.data = data
        self.heightLogChart.chartDescription?.text = nil
        self.heightLogChart.notifyDataSetChanged()
        
        self.heightLogChart.setVisibleXRange(minXRange: 0, maxXRange: Double(self.drawRange))
        self.heightLogChart.leftAxis.axisMinimum = 0
        self.heightLogChart.rightAxis.enabled = false
        
    }
    
    func saveVariables() {
        UserDefaults.standard.set(self.speedLog, forKey: "speedLog")
        UserDefaults.standard.set(self.speedTypeCoefficient, forKey: "speedTypeCoefficient")
        UserDefaults.standard.set(self.speedType, forKey: "speedType")
        UserDefaults.standard.set(self.drawRange, forKey: "drawRange")
        UserDefaults.standard.set(self.heightLog, forKey: "heightLog")
    }
    
    func speedLogPressed(_ sender:UITapGestureRecognizer) {
        saveVariables()
        performSegue(withIdentifier: "showSpeedLogDetail", sender: self)
    }
    
    func heightLogPressed(_ sender:UITapGestureRecognizer) {
        saveVariables()
        performSegue(withIdentifier: "showHeightLogDetail", sender: self)
    }

}

