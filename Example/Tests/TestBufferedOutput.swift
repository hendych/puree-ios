import Foundation
import KurioPuree

class TestBufferedOutput: BufferedOutput {
    var logStorage: TestLogStorage!

    override func configure(_ settings: [String: Any]) {
        super.configure(settings)

        if let logStorage = settings["logStorage"] as? TestLogStorage {
            self.logStorage = logStorage
        }
    }
    

    override func write(_ chunk: BufferedOutputChunk, completion: @escaping (_: Bool) -> Void) {
        let logString = chunk.logs.map { log in
            let userInfo = log.userInfo as! [String: String]
            let record = userInfo.keys.sorted().map { "\($0):\(log.userInfo[$0]!)" }.joined(separator: ",")

            return "{\(log.tag)|\(record)}"
        }.joined()
        self.logStorage.add(log: logString)
        completion(true)
    }
}
