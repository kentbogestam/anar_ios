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

class ViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate, CLLocationManagerDelegate {
    var webView: WKWebView!
    let userContentController = WKUserContentController()
    let locationManager = CLLocationManager()
    var dict = ["lat": "0.00", "long": "0.00", "action": "", "locationPermission" : "1"]
    var positionA : CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = URL(string: "https://anar-dev.dastjar.com")!
        webView.load(URLRequest(url: url))
    }
    
    override func loadView() {
        super.loadView()
        let config = WKWebViewConfiguration()
        config.userContentController = userContentController
        
        webView = WKWebView(frame: self.view.bounds, configuration: config)
        userContentController.add(self, name: "geoAddress")
        webView.navigationDelegate = self
        webView.uiDelegate = self
        view = webView
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        debugPrint("didStartProvisionalNavigation\(webView.url!)")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        debugPrint("didFinish: \(webView.url!)")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        debugPrint("didFail navigation")
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "geoAddress" {
            let strMsg = message.body as! String
            dict["action"] = strMsg
            
            let status = CLLocationManager.authorizationStatus()
            
            switch status {
                
            // 1
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
                return
            // 2
            case .denied, .restricted:
                // let alert = UIAlertController(title: "Location Services disabled", message: "Please enable Location Services in Settings", preferredStyle: .alert)
                // let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                // alert.addAction(okAction)
                // present(alert, animated: true, completion: nil)
                dict["locationPermission"] = "0"
                sendCurrentLocation(dict: self.dict as [NSString : NSString])
                return
            // 3
            case .authorizedAlways, .authorizedWhenInUse:
                sendCurrentLocation(dict: self.dict as [NSString : NSString])
                break
            }

            // 4
            locationManager.delegate = self
            locationManager.startUpdatingLocation()
        }
        // now use the name and token as you see fit!
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let otherAction = UIAlertAction(title: "OK", style: .default, handler: {
            action in completionHandler()
        })
        alertController.addAction(otherAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let lastLocation = locations.last!
        debugPrint("didUpdateLocations")
        dict = [
            "lat": String(lastLocation.coordinate.latitude),
            "long": String(lastLocation.coordinate.longitude),
            "locationPermission" : "1"
        ]
        
        if (positionA == nil) {
            positionA = lastLocation
        }
        
        let distanceInMeters = positionA?.distance(from: lastLocation)
        debugPrint("distanceInMeters: \(String(describing: distanceInMeters))")
        
        guard let distance = distanceInMeters else {
            return
        }
        
        if distance > 20 {
            debugPrint("exceed 20 meter")
            positionA = lastLocation
            dict["action"] = "getLocation"
            sendCurrentLocation(dict: self.dict as [NSString : NSString])
        }
        else {
            debugPrint("under 20 meter")
        }
    }
    
    func sendCurrentLocation(dict: [NSString:NSString]) {
        let jsonData = try! JSONSerialization.data(withJSONObject: dict, options: [])
        let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)!
        print(jsonString)
        // Send the location update to the page
        self.webView.evaluateJavaScript("responseGeoAddressFromIosNative(\(jsonString))") { result, error in
            guard error == nil else {
                debugPrint(error ?? "")
                return
            }
        }
    }

}



