import Foundation
import KurioPuree

class TestFailureOutput: BufferedOutput {
    var logStorage: TestLogStorage!

    override func configure(_ settings: [String: Any]) {
        super.configure(settings)

        if let logStorage = settings["logStorage"] as? TestLogStorage {
            self.logStorage = logStorage
        }
    }

    override func write(_ chunk: BufferedOutputChunk, completion: (_: Bool) -> Void) {
        self.logStorage.add(log: "error")
        print("\(Date()): error!(retry debug)")
        completion(false)
    }
}
