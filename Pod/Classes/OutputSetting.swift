//
//  OutputSetting.swift
//  Pods
//
//  Created by admin on 7/27/17.
//
//

import Foundation

public class OutputSetting {
    private(set) var outputClass: Output.Type
    private(set) var tagPattern: String
    private(set) var settings: [String: Any]?
    
    convenience init(output outputClass: Output.Type, tagPattern: String) {
        self.init(output: outputClass, tagPattern: tagPattern, settings: nil)
    }
    
    public init(output outputClass: Output.Type, tagPattern: String, settings: [String: Any]?) {
        self.outputClass = outputClass
        self.tagPattern = tagPattern
        self.settings = settings
    }
}
