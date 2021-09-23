//
//  ViewController.swift
//  CombineLocationManager
//
//  Created by Palash Das on 20/09/21.
//

import UIKit
import Combine
import CoreLocation

class ViewController: UIViewController {
    
    var authChangeSubscriber: AnyCancellable?
    var locatorSubscriber: AnyCancellable?
    
    //var subscriptions: Set<AnyCancellable> = []

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Recieve `CLAutorizationStatus`
        authChangeSubscriber = LocationPublisher.default.authStatusSubject.sink(receiveCompletion: { [unowned self] completion in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                self.showAlertWith(message: error.localizedDescription)
            }
        }, receiveValue: { [unowned self] status in
            switch status {
            case .notDetermined:
                LocationPublisher.default.requestWhenInUseAccess()
                break
            case .denied, .restricted:
                let settingsAction = UIAlertAction.init(title: "SETTINGS", style: .default, handler: { (_) in
                    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                        return
                    }
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                            print("Settings opened: \(success)")
                        })
                    }
                })
                let okAction = UIAlertAction.init(title: "OK", style: .default, handler: nil)
                self.showAlertWith(message: LocationError.locationService.localizedDescription, actions: [okAction,settingsAction])
            default:
                //LocationPublisher.default.start()
                break
            }
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        LocationPublisher.default.stop()
        authChangeSubscriber?.cancel()
    }

    @IBAction func startStopLocation(_ sender: UIButton) {
        if sender.isSelected {
            sender.isSelected = false
            sender.setTitle("Start", for: .normal)
            LocationPublisher.default.stop()
            locatorSubscriber?.cancel()
        }
        else {
            sender.isSelected = true
            sender.setTitle("Stop", for: .normal)
            
            // Recieve location updates or error if failed
            locatorSubscriber = LocationPublisher.default.locationSubject.sink(receiveCompletion: {completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    NSLog(error.localizedDescription)
                }
            }, receiveValue: { locations in
                if let location = locations.last {
                    print(location)
                }
            })
            LocationPublisher.default.start()
        }
    }
    
    func showAlertWith(title:String = "WARNING!", message:String, actions:[UIAlertAction] = [UIAlertAction(title:"OK",style:.default, handler: nil)]) {
        
        if let visibleVC = self.navigationController?.visibleViewController, visibleVC.isKind(of: UIAlertController.self) {
            return
        }

        let alert = UIAlertController(title:title,message:message,preferredStyle: .alert)
        
        let titleFont = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18)]
        let messageFont = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)]
        
        let titleAttrString = NSAttributedString(string: title, attributes: titleFont)
        let messageAttrString = NSAttributedString(string: message, attributes: messageFont)
        
        alert.setValue(titleAttrString, forKey: "attributedTitle")
        alert.setValue(messageAttrString, forKey: "attributedMessage")
        
        actions.forEach { action in
            alert.addAction(action)
        }
        
        alert.view.backgroundColor = UIColor(red: 241/255, green: 242/255, blue: 242/255, alpha: 1)
        alert.view.layer.cornerRadius = 0
        
        present(alert,animated: true)
    }
    
    deinit {
        //subscriptions.forEach { $0.cancel()}
    }
}

