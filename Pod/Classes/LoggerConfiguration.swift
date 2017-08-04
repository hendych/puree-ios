//
//  LoggerConfiguration.swift
//  Pods
//
//  Created by admin on 7/27/17.
//
//

//  Converted with Swiftify v1.0.6414 - https://objectivec2swift.com/
import Foundation

open class LoggerConfiguration {
    public var logStore = LogStore.defaultLogStore()
    public var filterSettings = [FilterSetting]()
    public var outputSettings = [OutputSetting]()
    
    public init() { }
    
    public class func defaultConfiguration() -> LoggerConfiguration {
        return LoggerConfiguration()
    }
}
