//
//  Filter.swift
//  Pods
//
//  Created by admin on 7/27/17.
//
//

import Foundation

open class Filter {
    public let identifier: String
    public let logger: Logger
    public let tagPattern: String?
    
    var logStore: LogStore {
        get {
            return self.logger.logStore()
        }
    }
    
    required public init(logger: Logger, tagPattern: String?) {
        self.identifier = UUID().uuidString
        self.tagPattern = tagPattern
        self.logger = logger
    }
    
    func getLogStore() -> LogStore? {
        return logger.logStore()
    }
    
    open func configure(_ settings: [String: Any]) {
    }
    
    open func logs(withObject object: Any, tag: String, captured: String?) -> [Log] {
        guard let object = object as? Dictionary<String, Any> else {
            return []
        }
        
        return [Log(tag: tag, date: logger.currentDate(), userInfo: object)]
    }
}
