//
//  LogStore.swift
//  Pods
//
//  Created by admin on 7/27/17.
//
//

//  Converted with Swiftify v1.0.6414 - https://objectivec2swift.com/
import Foundation
import YapDatabase


public typealias LogStoreRetrieveCompletionBlock = (_ logs: [Log]) -> Void

private func LogStoreCollectionNameForPattern(pattern: String) -> String {
    return LogStore.LogDataCollectionNamePrefix + (pattern)
}

private func LogKey(output: Output, log: Log) -> String {
    return NSStringFromClass(type(of: output)) + ("_") + (log.identifier)
}

public class LogStore {
    fileprivate static let LogDatabaseDirectory = "com.cookpad.eeData.default"
    fileprivate static let LogDatabaseFileName = "logs.db"
    fileprivate static let LogDataCollectionNamePrefix = "log_"
    fileprivate static var __databases = [String: YapDatabase]()
    
    var databasePath: URL
    var databaseConnection: YapDatabaseConnection?
    var databaseReadWriteCompletionQueue: DispatchQueue?
    
    public static func defaultLogStore() -> LogStore {
        return LogStore(databasePath: LogStore.defaultDatabasePath())
    }
    
    public init(databasePath: URL) {
        self.databasePath = databasePath
        self.databaseReadWriteCompletionQueue = DispatchQueue(label: "PureeLogStoreReadWriteCompletion")
    }
    
    deinit {
        self.databaseReadWriteCompletionQueue = nil
    }
    
    public func prepare() -> Bool {
        let fileManager = FileManager.default
        let databaseDirectory = databasePath.deletingLastPathComponent().absoluteString
        
        if fileManager.fileExists(atPath: databaseDirectory) == false {
            let error: Error? = nil
            
            try? fileManager.createDirectory(atPath: databaseDirectory, withIntermediateDirectories: true, attributes: nil)
            
            if error != nil {
                return false
            }
        }
        
        var database: YapDatabase? = LogStore.__databases[databasePath.absoluteString]
        
        if database == nil {
            database = YapDatabase(path: databasePath.absoluteString)
            LogStore.__databases[databasePath.absoluteString] = database
        }
        
        if databaseConnection?.database != database {
            databaseConnection = database?.newConnection()
        }
        
        return true
    }
    
    public static func defaultDatabasePath() -> URL {
        let libraryCachePaths = NSSearchPathForDirectoriesInDomains(.cachesDirectory,
                                                                    .userDomainMask,
                                                                    true)
        let libraryCacheDirectoryPath = libraryCachePaths.first! as! String
        let filePath = "\(LogDatabaseDirectory)/\(LogDatabaseFileName)"
        let databasePath = URL(fileURLWithPath: "\(libraryCacheDirectoryPath)/\(filePath)")
        
        return databasePath
    }
    
    public func retrieveLogs(for output: Output, completion: @escaping LogStoreRetrieveCompletionBlock) {
        assert(self.databaseConnection != nil, "Database connection is not available")
        
        var logs: [Log] = [Log]()
        
        databaseConnection?.asyncRead({ (transaction) in
            let keyPrefix = NSStringFromClass(type(of: output)).appending("_")
            
            transaction.enumerateRows(inCollection: LogStoreCollectionNameForPattern(pattern: output.tagPattern),
                                      using: { (key, log, metadata, stop) in
                                        logs.append(log as! Log)
            }, withFilter: { (key) -> Bool in
                return key.hasPrefix(keyPrefix)
            })
            
        }, completionQueue: self.databaseReadWriteCompletionQueue, completionBlock: { 
            completion(logs)
        })
    }
    
    public func add(_ log: Log, for output: Output, completion: (() -> Void)?) {
        assert((databaseConnection != nil), "Database connection is not available")
        add([log], for: output, completion: completion)
    }
    
    public func add(_ logs: [Log], for output: Output, completion: (() -> Void)?) {
        assert((databaseConnection != nil), "Database connection is not available")
        
        databaseConnection?.asyncReadWrite({ (transaction) in
            let collectionName = LogStoreCollectionNameForPattern(pattern: output.tagPattern)
            for log in logs {
                transaction.setObject(log, forKey: LogKey(output: output, log: log), inCollection: collectionName)
            }
        }, completionQueue: self.databaseReadWriteCompletionQueue, completionBlock: completion)
    }
    
    public func remove(_ logs: [Log], for output: Output, completion: (() -> Void)?) {
        assert((databaseConnection != nil), "Database connection is not available")
        
        databaseConnection?.asyncReadWrite({ (transaction) in
            let collectionName = LogStoreCollectionNameForPattern(pattern: output.tagPattern)
            for log in logs {
                transaction.removeObject(forKey: LogKey(output: output, log: log), inCollection: collectionName)
            }
        }, completionQueue: self.databaseReadWriteCompletionQueue, completionBlock: completion)
    }
    
    public func clearAll() {
        assert((databaseConnection != nil), "Database connection is not available")
        
        databaseConnection?.readWrite({ (transaction) in
            transaction.removeAllObjectsInAllCollections()
        })
    }
}


