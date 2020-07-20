//
//  ViewController.swift
//  anar
//
//  Created by Kent Bogestam on 2018-12-21.
//  Copyright © 2018 Kent Bogestam. All rights reserved.
//

import UIKit
import WebKit
import CoreLocation

class ViewController: UIViewController, WKUIDelegate {
    var webView: WKWebView!
    let userContentController = WKUserContentController()
    let locationManager = CLLocationManager()
    
    var dataModel = DataModel()
    
    var positionA : CLLocation?
    
    private enum Commands: String {
        case geoAddress
        case responseGeoAddressFromIosNative
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        webView.load(URLRequest(url: Constant.url))
    }
    
    override func loadView() {
        super.loadView()
        
        let config = WKWebViewConfiguration()
        config.userContentController = userContentController
        
        webView = WKWebView(frame: self.view.bounds, configuration: config)
        userContentController.add(self, name: Commands.geoAddress.rawValue)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        view = webView
    }
    
    func sendCurrentLocation(data: DataModel) {
        let dict = data.dictionaryRepresentation
        
        if !data.action.isEmpty {
            let jsonData = try! JSONSerialization.data(withJSONObject: dict, options: [])
            let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)!
            debugPrint(jsonString)
            // Send the location update to the page
            let functionName = "\(Commands.responseGeoAddressFromIosNative.rawValue)(\(jsonString))"
            self.webView.evaluateJavaScript(functionName) { result, error in
                guard error == nil else {
                    debugPrint(error ?? "")
                    return
                }
            }
        }
    }

}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let lastLocation = locations.last!
        
        dataModel.lat = String(lastLocation.coordinate.latitude)
        dataModel.long = String(lastLocation.coordinate.longitude)
        dataModel.locationPermission = "1"
        
        if (positionA == nil) {
            positionA = lastLocation
        }
        
        let distanceInMeters = positionA?.distance(from: lastLocation)
//        debugPrint("distanceInMeters: \(String(describing: distanceInMeters))")
        
        guard let distance = distanceInMeters else {
            return
        }
        
        if distance > 20 {
            debugPrint("exceed 20 meter")
            positionA = lastLocation
            dataModel.action = "getLocation"
            sendCurrentLocation(data: self.dataModel)
        }
        else {
            debugPrint("under 20 meter")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        debugPrint("location manager authorization status changed")
        
        switch status {
            
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            return
        case .denied, .restricted:
            dataModel.locationPermission = "0"
            sendCurrentLocation(data: self.dataModel)
            return
        case .authorizedAlways, .authorizedWhenInUse:
            sendCurrentLocation(data: self.dataModel)
            break
        }
    }
    
    func determineCurrentLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()

        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
    }
    
}

extension ViewController : WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == Commands.geoAddress.rawValue {
            let strMsg = message.body as! String
            dataModel.action = strMsg
            
            let status = CLLocationManager.authorizationStatus()
            
            switch status {
                
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
                return
            case .denied, .restricted:
                dataModel.locationPermission = "0"
                sendCurrentLocation(data: self.dataModel)
                return
            case .authorizedAlways, .authorizedWhenInUse:
                sendCurrentLocation(data: self.dataModel)
                break
            }
            
            locationManager.startUpdatingLocation()
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let otherAction = UIAlertAction(title: "OK", style: .default, handler: {
            action in completionHandler()
        })
        
        alertController.addAction(otherAction)
        present(alertController, animated: true, completion: nil)
    }
}

extension ViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        debugPrint("didStartProvisionalNavigation\(webView.url!)")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        debugPrint("didFinish: \(webView.url!)")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        debugPrint("didFail navigation")
    }
}



