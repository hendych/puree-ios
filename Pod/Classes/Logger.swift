//
//  Logger.swift
//  Pods
//
//  Created by admin on 7/27/17.
//
//

import Foundation

public class Logger {
    
    let configuration: LoggerConfiguration
    private var _defaultFilter: Filter!
    var defaultFilter: Filter {
        return _defaultFilter
    }
    var filters = [String: Filter]()
    var filterReactionTagPatterns = [String: String]()
    var outputs = [String: Output]()
    var outputReactionTagPatterns = [String: String]()
    
    public class func matchesTag(_ tag: String, pattern: String) -> TagCheckingResult {
        if tag == pattern {
            return TagCheckingResult.success()
        }
        
        let elementsSeparator: String = "."
        let wildcard: String = "*"
        let allWildcard: String = "**"
        let patternElements = pattern.components(separatedBy: elementsSeparator)
        let tagElements = tag.components(separatedBy: elementsSeparator)
        let lastPatternElement = patternElements.last
        
        if lastPatternElement == allWildcard {
            var matched = true
            
            for (idx, val) in patternElements.enumerated() {
                if idx == patternElements.count - 1 {
                    break
                }
                
                
                let tagElement = tagElements[idx]
                if tagElement != val {
                    matched = false
                    break
                }
            }
            
            if matched {
                let location = patternElements.count - 1
                let capturedLength = tagElements.count - location
                var capturedString = ""
                
                if capturedLength > 0 {
                    capturedString = tagElements[location...location+capturedLength-1]
                        .joined(separator: elementsSeparator)
                }
                
                return TagCheckingResult.successResult(withCapturedString: capturedString)
            }
            
        } else if (lastPatternElement == wildcard) {
            if tagElements.count == patternElements.count {
                var matched = true
                
                for (idx, val) in patternElements.enumerated() {
                    if idx == patternElements.count - 1 {
                        break
                    }
                    
                    let tagElement: String = tagElements[idx]
                    if tagElement != val {
                        matched = false
                        break
                    }
                }
                
                if matched {
                    return TagCheckingResult.successResult(withCapturedString: tagElements.last)
                }
            }
        }
        
        return TagCheckingResult.failure()
    }
    
    public init(configuration: LoggerConfiguration) {
        self.configuration = configuration
        configure()
        startPlugins()
    }
    
    deinit {
        shutdown()
    }
    
    public func logStore() -> LogStore {
        return configuration.logStore
    }
    
    public func currentDate() -> Date {
        return Date()
    }
    
    public func configure() {
        let _ = configuration.logStore.prepare()
        
        configureFilterPlugins()
        configureOutputPlugins()
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(self.applicationDidEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        notificationCenter.addObserver(self, selector: #selector(self.applicationWillEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    func configureFilterPlugins() {
        _defaultFilter = Filter(logger: self, tagPattern: nil)
        
        var filters = [String: Filter]()
        var filterReactionTagPatterns = [String: String]()
        
        for setting in configuration.filterSettings {
            let filter = setting.filterClass.init(logger: self, tagPattern: setting.tagPattern)
            if filter is Filter == false {
                continue
            }
            
            if let pluginSettings = setting.settings {
                filter.configure(pluginSettings)
            }
            
            filters[filter.identifier] = filter
            filterReactionTagPatterns[filter.identifier] = setting.tagPattern
        }
        
        self.filters = filters
        self.filterReactionTagPatterns = filterReactionTagPatterns
    }
    
    func configureOutputPlugins() {
        var outputs = [String: Output]()
        var outputReactionTagPatterns = [String: String]()
        
        for setting in configuration.outputSettings {
            let output = setting.outputClass.init(logger: self, tagPattern: setting.tagPattern)
            if output is Output == false {
                continue
            }
            
            if let pluginSettings = setting.settings {
                output.configure(pluginSettings)
            }
            
            outputs[output.identifier] = output
            outputReactionTagPatterns[output.identifier] = setting.tagPattern
        }
        
        self.outputs = outputs
        self.outputReactionTagPatterns = outputReactionTagPatterns
    }
    
    func startPlugins() {
        for (_, output) in outputs.enumerated() {
            output.value.start()
        }
    }
    
    @objc func applicationDidEnterBackground(_ notification: Notification) {
        for (_, output) in outputs.enumerated() {
            output.value.suspend()
        }
    }
    
    @objc func applicationWillEnterForeground(_ notification: Notification) {
        for (_, output) in outputs.enumerated() {
            output.value.resume()
        }
    }
    
    func filteredLogs(withObject object: Any, tag: String) -> [Log] {
        var logs = [Log]()
        
        for (key, _) in filterReactionTagPatterns {
            
            let pattern = filterReactionTagPatterns[key]
            let result = Logger.matchesTag(tag, pattern: pattern!)
            
            if result.isMatched == false {
                continue
            }
            
            let filter = filters[key]
            if let filteredLogs = filter?.logs(withObject: object,
                                               tag: tag,
                                               captured: result.capturedString) {
                logs.append(contentsOf: filteredLogs)
            }
        }
        
        if logs.count == 0 {
            return defaultFilter.logs(withObject: object, tag: tag, captured: nil)
        }
        
        return logs
    }
    
    public func post(_ object: Any, tag sourceTag: String) {
        for log in filteredLogs(withObject: object, tag: sourceTag) {
            for (_, value) in outputReactionTagPatterns.enumerated() {
                if Logger.matchesTag(log.tag, pattern: value.value).isMatched {
                    let output = self.outputs[value.key]
                    output?.emitLog(log)
                }
            }
            
        }
    }
    
    public func shutdown() {
        
        filters.removeAll()
        filterReactionTagPatterns.removeAll()
        
        for output in outputs {
            output.value.suspend()
        }
        
        outputs.removeAll()
        outputReactionTagPatterns.removeAll()
        
        NotificationCenter.default.removeObserver(self)
    }
}
