import UIKit
import BasicGCDTimer

// Testing class.
class EventClass: BasicGCDTimerDelegate {
    var instanceCount: Int = 0  // How many times we've been called.
    var timer: BasicGCDTimer?   // Our timer object.
    let iAmADelegate: Bool
    let nameTag: String
    
    // Just prints the count.
    func timerCallback(_ inTimer: BasicGCDTimer) {
        print("main (\(nameTag)) callback count: \(instanceCount)")
        instanceCount += 1
    }
    
    // Set the parameter to false to remove the delegate registration.
    init(name inName: String, registerAsADelegate inRegisterAsADelegate: Bool = true) {
        print("main (HI MY NAME IS \(inName)) init")
        nameTag = "HI MY NAME IS " + inName
        iAmADelegate = inRegisterAsADelegate
        isRunning = true
    }
    
    // This won't get called if we register as a delegate.
    deinit {
        print("main (\(nameTag)) deinit")
        timer = nil
        isRunning = false
    }
    
    // This will create and initialize a new timer, if we don't have one. If we turn it off, it will destroy the timer.
    var isRunning: Bool {
        get {
            return nil != timer
        }
        
        set {
            if !isRunning && newValue {
                print("main (\(nameTag)) creating a new timer")
                timer = BasicGCDTimer(timeIntervalInSeconds: 1.0, leewayInMilliseconds: 200, delegate: iAmADelegate ? self : nil)
                timer?.resume()
            } else if isRunning && !newValue {
                print("main (\(nameTag)) deleting the timer")
                
                // MARK: - MYSTERY SPOT
                timer?.invalidate()  // If you comment out this line, the timer will keep firing, even though we dereference it.
                // MARK: -
                
                timer = nil
            }
        }
    }
}

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        testBasicGCDTimerWithDelegate()
        testBasicGCDTimerWithoutDelegate()
    }
    
    func testBasicGCDTimerWithDelegate() {
        // We instantiate an instance of the test, register it as a delegate, then wait six seconds. We will see updates.
        print("** Test With Delegate")   // We will not get a deinit after this one.
        let iAmADelegate: EventClass = EventClass(name: "Delegate")
        
        // We create a timer, then wait six seconds. After that, we stop/delete the timer, and create a new one, without a delegate.
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            iAmADelegate.isRunning = false
            print("** Done")   // We will not get a deinit after this one.
        }
    }
    
    func testBasicGCDTimerWithoutDelegate() {
        print("\n** Test Without Delegate")   // We will not get a deinit after this one.
        
        // Do it again, but this time, don't register as a delegate (it will be quiet).
        let iAmNotADelegate: EventClass = EventClass(name: "No Delegate", registerAsADelegate: false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            iAmNotADelegate.isRunning = false
            print("** Done")   // We will get a deinit after this one.
        }
    }
}

