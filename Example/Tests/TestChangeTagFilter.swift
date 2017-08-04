import Foundation
import KurioPuree

class TestChangeTagFilter: Filter {
    var tagSuffix: String?

    override func configure(_ settings: [String: Any]) {
        tagSuffix = settings["tagSuffix"] as? String
    }

    override func logs(withObject object: Any, tag: String, captured: String?) -> [Log] {
        guard let userInfo = object as? [String: Any], let suffix = tagSuffix else {
            return []
        }

        let newTag = tag + suffix
        
        return [Log(tag: newTag, date: self.logger.currentDate(), userInfo: userInfo)]
    }
}
