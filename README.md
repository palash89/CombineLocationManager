# CombineLocationManager
A simple implementation of CLLocationManager using Combine publisher & subscriber.


## Installation
Drag the `LocationPublisher.swift` file into your project.


## Usage


Delcare two `Subscriber` variables in your viewcontroller like this:

```
var authChangeSubscriber: AnyCancellable?
var locatorSubscriber: AnyCancellable?
```
The first subscriber variable will recieve `CLAuthorizationStatus` from the publisher defined in 
`LocationPublisher`  class and the second one will recieve `CLLocation` updates.

Delcare the following code in your `ViewDidAppear`:

```
// Recieve `CLAutorizationStatus`
authChangeSubscriber = LocationPublisher.default.authStatusSubject.sink(receiveCompletion: { [unowned self] completion in
    switch completion {
    case .finished:
        break
    case .failure(let error):
        print(error.localizedDescription)
    }
}, receiveValue: { [unowned self] status in
    switch status {
    case .notDetermined:
        LocationPublisher.default.requestWhenInUseAccess()
        break
    case .denied, .restricted:
        print("Location services is disabled. Please trun on from settings.")
    default:
        break
    }
})
```
Now the following code can be used anywhere according to where you want to recieve location updates. In the sample code it was used inside a `UIButton` action. 

```
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
```

This code is self explanetary. The subscriber recieves location updates in `recieveValue` section. Now if we want to stop location updates then we need call `stop` method. Also make sure to call as `cancel` method to stop execution of the `Subscriber` as well.

Finally `cancel` authorization status subscriber in `ViewDidDisappear`.

```
authChangeSubscriber?.cancel()
```
