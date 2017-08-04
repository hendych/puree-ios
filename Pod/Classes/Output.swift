//
//  Output.swift
//  Pods
//
//  Created by admin on 7/27/17.
//
//

import Foundation

open class Output {
    public let identifier: String
    public let tagPattern: String
    public let logger: Logger
    
    var logStore: LogStore {
        get {
            return self.logger.logStore()
        }
    }
    
    required public init(logger: Logger, tagPattern: String) {
        self.identifier = UUID().uuidString
        self.tagPattern = tagPattern
        self.logger = logger
    }
    
    open func configure(_ settings: [String: Any]) {
    }
    
    open func start() {
    }
    
    open func resume() {
    }
    
    open func suspend() {
    }
    
    open func emitLog(_ log: Log) {
    }
}
