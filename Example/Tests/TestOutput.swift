import Foundation
import KurioPuree

class TestOutput: Output {
    var logStorage: TestLogStorage!

    override func configure(_ settings: [String: Any]) {
        super.configure(settings)

        if let logStorage = settings["logStorage"] as? TestLogStorage {
            self.logStorage = logStorage
        }
    }

    override func emitLog(_ log: Log) {
        let userInfo = log.userInfo as! [String: String]
        let record = userInfo.keys.sorted().map { "\($0):\(log.userInfo[$0]!)" }.joined(separator: ",")
        self.logStorage.add(log: "\(log.tag)|\(record)")
    }
}
