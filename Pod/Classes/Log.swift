//
//  Log.swift
//  Pods
//
//  Created by admin on 7/27/17.
//
//

import Foundation

@objc(PURLogger)
public class Log: NSObject, NSCoding {
    public let identifier: String
    public let tag: String
    public let date: Date
    public let userInfo: Dictionary<String, Any>
    
    public init(tag: String, date: Date, userInfo: Dictionary<String, Any>) {
        self.identifier = UUID().uuidString
        self.tag = tag
        self.date = date
        self.userInfo = userInfo
    }
    
    
    required public init?(coder aDecoder: NSCoder) {
        identifier = aDecoder.decodeObject(forKey: "identifier") as! String
        tag = aDecoder.decodeObject(forKey: "tag") as! String
        date = aDecoder.decodeObject(forKey: "date") as! Date
        userInfo = aDecoder.decodeObject(forKey: "userInfo") as! Dictionary<String, Any>
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(identifier, forKey: "identifier")
        aCoder.encode(tag, forKey: "tag")
        aCoder.encode(date, forKey: "date")
        aCoder.encode(userInfo, forKey: "userInfo")
    }
    
}
