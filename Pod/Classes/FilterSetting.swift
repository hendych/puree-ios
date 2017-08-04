//
//  FilterSetting.swift
//  Pods
//
//  Created by admin on 7/27/17.
//
//

import Foundation

public class FilterSetting {
    private(set) var filterClass: Filter.Type
    private(set) var tagPattern: String = ""
    private(set) var settings: [String: Any]?
    
    public convenience init(filter filterClass: Filter.Type, tagPattern: String) {
        self.init(filter: filterClass, tagPattern: tagPattern, settings: nil)
    }
    
    public init(filter filterClass: Filter.Type, tagPattern: String, settings: [String: Any]?) {
        self.filterClass = filterClass
        self.tagPattern = tagPattern
        self.settings = settings
    }
}
