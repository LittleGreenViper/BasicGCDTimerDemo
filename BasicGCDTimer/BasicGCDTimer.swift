import Foundation

/* ################################################################## */
/**
 This is the basic callback protocol for the general-purpose GCD timer class. It has one simple required method.
 */
public protocol BasicGCDTimerDelegate: class {
    /* ############################################################## */
    /**
     Called periodically, as the GCDTimer repeats (or fires once).
     
     - parameter inTimer: The BasicGCDTimer instance that is invoking the callback.
     */
    func timerCallback(_ inTimer: BasicGCDTimer)
}

/* ################################################################## */
/**
 This is a general-purpose GCD timer class.
 
 It requires that an owning instance register a delegate to receive callbacks.
 */
public class BasicGCDTimer {
    /* ############################################################## */
    // MARK: - Private Enums
    /* ############################################################## */
    /// This is used to hold state flags for internal use.
    private enum _State {
        /// The timer is currently invalid.
        case _invalid
        /// The timer is currently paused.
        case _suspended
        /// The timer is firing.
        case _running
    }
    
    /* ############################################################## */
    // MARK: - Private Instance Properties
    /* ############################################################## */
    /// This holds our current run state.
    private var _state: _State = ._invalid
    /// This holds a Boolean that is true, if we are to only fire once (default is false, which means we repeat).
    private var _onlyFireOnce: Bool = false
    /// This contains the actual dispatch timer object instance.
    private var _timerVar: DispatchSourceTimer!
    /// This is the contained delegate instance
    private weak var _delegate: BasicGCDTimerDelegate?
    
    /* ############################################################## */
    /**
     This dynamically initialized calculated property will return (or create and return) a basic GCD timer that (probably) repeats.
     
     It uses the current queue.
     */
    private var _timer: DispatchSourceTimer! {
        if nil == _timerVar {   // If we don't already have a timer, we create one. Otherwise, we simply return the already-instantiated object.
            print("timer create GCD object")
            _timerVar = DispatchSource.makeTimerSource()                                    // We make a generic, default timer source. No frou-frou.
            let leeway = DispatchTimeInterval.milliseconds(leewayInMilliseconds)            // If they have provided a leeway, we apply it here. We assume milliseconds.
            _timerVar.setEventHandler(handler: _eventHandler)                               // We reference our own internal event handler.
            _timerVar.schedule(deadline: .now() + timeIntervalInSeconds,                    // The number of seconds each iteration of the timer will take.
                repeating: (_onlyFireOnce ? 0 : timeIntervalInSeconds),      // If we are repeating (default), we add our duration as the repeating time. Otherwise (only fire once), we set 0.
                leeway: leeway)                                              // Add any leeway we specified.
        }
        
        return _timerVar
    }
    
    /* ############################################################## */
    // MARK: - Private Instance Methods
    /* ############################################################## */
    /**
     This is our internal event handler that is called directly from the timer.
     */
    private func _eventHandler() {
        delegate?.timerCallback(self)   // Assuming that we have a delegate, we call its handler method.
        
        if _onlyFireOnce {  // If we are set to only fire once, we nuke from orbit.
            invalidate()
        }
    }
    
    /* ############################################################## */
    // MARK: - Public Instance Properties
    /* ############################################################## */
    /// This is the time between fires, in seconds.
    public var timeIntervalInSeconds: TimeInterval = 0
    /// This is how much "leeway" we give the timer, in milliseconds.
    public var leewayInMilliseconds: Int = 0
    
    /* ############################################################## */
    // MARK: - Public Calculated Properties
    /* ############################################################## */
    /**
     - returns: true, if the timer is invalid. READ ONLY
     */
    public var isInvalid: Bool {
        return ._invalid == _state
    }
    
    /* ############################################################## */
    /**
     - returns: true, if the timer is currently running. READ ONLY
     */
    public var isRunning: Bool {
        return ._running == _state
    }
    
    /* ############################################################## */
    /**
     - returns: true, if the timer will only fire one time (will return false after that one fire). READ ONLY
     */
    public var isOnlyFiringOnce: Bool {
        return _onlyFireOnce
    }
    
    /* ############################################################## */
    /**
     - returns: the delegate object. READ/WRITE
     */
    public var delegate: BasicGCDTimerDelegate? {
        get {
            return _delegate
        }
        
        set {
            if _delegate !== newValue {
                print("timer changing the delegate from \(String(describing: delegate)) to \(String(describing: newValue))")
                _delegate = newValue
            }
        }
    }
    
    /* ############################################################## */
    // MARK: - Deinitializer
    /* ############################################################## */
    /**
     We have to carefully dismantle this, as we can end up with crashes if we don't clean up properly.
     */
    deinit {
        print("timer deinit")
        self.invalidate()
    }
    
    /* ############################################################## */
    // MARK: - Public Methods
    /* ############################################################## */
    /**
     Default constructor
     
     - parameter timeIntervalInSeconds: The time (in seconds) between fires.
     - parameter leewayInMilliseconds: Any leeway. This is optional, and default is zero (0).
     - parameter delegate: Our delegate, for callbacks. Optional. Default is nil.
     - parameter onlyFireOnce: If true, then this will only fire one time, as opposed to repeat. Optional. Default is false.
     */
    public init(timeIntervalInSeconds inTimeIntervalInSeconds: TimeInterval,
                leewayInMilliseconds inLeewayInMilliseconds: Int = 0,
                delegate inDelegate: BasicGCDTimerDelegate? = nil,
                onlyFireOnce inOnlyFireOnce: Bool = false) {
        print("timer init")
        self.timeIntervalInSeconds = inTimeIntervalInSeconds
        self.leewayInMilliseconds = inLeewayInMilliseconds
        self.delegate = inDelegate
        self._onlyFireOnce = inOnlyFireOnce
    }
    
    /* ############################################################## */
    /**
     If the timer is not currently running, we resume. If running, nothing happens.
     */
    public func resume() {
        if ._running != self._state {
            print("timer resume")
            self._state = ._running
            self._timer.resume()    // Remember that this could create a timer on the spot.
        }
    }
    
    /* ############################################################## */
    /**
     If the timer is currently running, we suspend. If not running, nothing happens.
     */
    public func pause() {
        if ._running == self._state {
            print("timer suspend")
            self._state = ._suspended
            self._timer.suspend()
        }
    }
    
    /* ############################################################## */
    /**
     This completely nukes the timer. It resets the entire object to default.
     */
    public func invalidate() {
        if ._invalid != _state, nil != _timerVar {
            print("timer invalidate")
            delegate = nil
            _timerVar.setEventHandler(handler: nil)
            
            _timerVar.cancel()
            if ._suspended == _state {  // If we were suspended, then we need to call resume one more time.
                print("timer one for the road")
                _timerVar.resume()
            }
            
            _onlyFireOnce = false
            timeIntervalInSeconds = 0
            leewayInMilliseconds = 0
            _state = ._invalid
            _timerVar = nil
        }
    }
}
