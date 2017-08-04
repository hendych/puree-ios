import Foundation

public class BufferedOutputChunk {
    private(set) public var logs = [Log]()
    var retryCount: Int = 0
    
    init(logs: [Log]) {
        self.logs = logs
    }
}

open class BufferedOutput: Output {
    public static let SettingsLogLimitKey: String = "BufferedOutputLogLimit"
    public static let SettingsFlushIntervalKey: String = "BufferedOutputFlushInterval"
    public static let SettingsMaxRetryCountKey: String = "BufferedOutputMaxRetryCount"
    
    public static let DidStartNotification = NSNotification.Name("BufferedOutputDidStartNotification")
    public static let DidResumeNotification = NSNotification.Name("BufferedOutputDidResumeNotification")
    public static let DidFlushNotification = NSNotification.Name("BufferedOutputDidFlushNotification")
    public static let DidTryWriteChunkNotification = NSNotification.Name("BufferedOutputDidTryWriteChunkNotification")
    public static let DidSuccessWriteChunkNotification = NSNotification.Name("BufferedOutputDidSuccessWriteChunkNotification")
    public static let DidRetryWriteChunkNotification = NSNotification.Name("BufferedOutputDidRetryWriteChunkNotification")
    
    public static let DefaultLogLimit: Int = 5
    public static let DefaultFlushInterval: Int = 10
    public static let DefaultMaxRetryCount: Int = 3
    
    
    private(set) var buffer = [Log]()
    private(set) var logLimit: Int = 0
    private(set) var flushInterval = TimeInterval()
    private(set) var maxRetryCount: Int = 0
    private(set) var recentFlushTime = CFAbsoluteTime()
    private(set) var timer: Timer?
    
    deinit {
        timer?.invalidate()
    }
    
    func setUpTimer() {
        timer?.invalidate()
        timer = Timer(timeInterval: 1.0, target: self, selector: #selector(self.tick), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: RunLoopMode.commonModes)
    }
    
    override open func configure(_ settings: [String: Any]) {
        super.configure(settings)
        var value: Any?
        
        value = settings[BufferedOutput.SettingsLogLimitKey]
        logLimit = value as? Int ?? BufferedOutput.DefaultLogLimit
        
        value = settings[BufferedOutput.SettingsFlushIntervalKey]
        flushInterval = TimeInterval(value as? Int ?? BufferedOutput.DefaultFlushInterval)
        
        value = settings[BufferedOutput.SettingsMaxRetryCountKey]
        maxRetryCount = value as? Int ?? BufferedOutput.DefaultMaxRetryCount
        
        buffer = [Log]()
    }
    
    open override func start() {
        super.start()
        
        buffer.removeAll()
        retrieveLogs({(_ logs: [Log]) -> Void in
            NotificationCenter.default.post(name: BufferedOutput.DidStartNotification, object: self)
            
            if let timer = self.timer, timer.isValid == false {
                return
            }
            
            self.buffer += logs
            self.flush()
        })
        
        setUpTimer()
    }
    
    open override func resume() {
        super.resume()
        
        buffer.removeAll()
        retrieveLogs({(_ logs: [Log]) -> Void in
            NotificationCenter.default.post(name: BufferedOutput.DidResumeNotification, object: self)
            
            if let timer = self.timer, timer.isValid == false {
                return
            }
            
            self.buffer += logs
            self.flush()
        })
        
        setUpTimer()
    }
    
    open override func suspend() {
        timer?.invalidate()
        
        super.suspend()
    }
    
    @objc func tick() {
        if (CFAbsoluteTimeGetCurrent() - recentFlushTime) > flushInterval {
            flush()
        }
    }
    
    func retrieveLogs(_ completion: @escaping LogStoreRetrieveCompletionBlock) {
        buffer.removeAll()
        logStore
        logStore.retrieveLogs(for: self, completion: completion)
    }
    
    override open func emitLog(_ log: Log) {
        buffer.append(log)
        logStore.add(log, for: self, completion: {() -> Void in
            if self.buffer.count >= self.logLimit {
                self.flush()
            }
        })
    }
    
    public func flush() {
        recentFlushTime = CFAbsoluteTimeGetCurrent()
        
        if buffer.count == 0 {
            return
        }
        
        let logCount = min(buffer.count, logLimit) - 1
        
        var flushLogs = [Log]()
        flushLogs.append(contentsOf: buffer[0...logCount])
        buffer.removeSubrange(0...logCount)
        
        let chunk = BufferedOutputChunk(logs: flushLogs)
        self.callWrite(chunk)
        
        NotificationCenter.default.post(name: BufferedOutput.DidFlushNotification, object: self)
    }
    
    func callWrite(_ chunk: BufferedOutputChunk) {
        self.write(chunk) { (success) in
            NotificationCenter.default.post(name: BufferedOutput.DidTryWriteChunkNotification, object: self)
            
            if success {
                logStore.remove(chunk.logs, for: self, completion: nil)
                
                NotificationCenter.default.post(name: BufferedOutput.DidSuccessWriteChunkNotification, object: self)
                
                return
            }
            
            chunk.retryCount += 1
            
            if chunk.retryCount <= self.maxRetryCount {
                let delay = NSDecimalNumber(decimal: 2.0 * pow(2, chunk.retryCount - 1))
                
                DispatchQueue.main.asyncAfter(deadline: .now() + delay.doubleValue, execute: {
                    NotificationCenter.default.post(name: BufferedOutput.DidRetryWriteChunkNotification, object: self)
                    
                    self.callWrite(chunk)
                })
            }
            
        }
    }
    
    open func write(_ chunk: BufferedOutputChunk, completion: (_: Bool) -> Void) {
        completion(true)
    }
}
