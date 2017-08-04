import Foundation
import KurioPuree

class TestAppendParamFilter: Filter {    
    override func logs(withObject object: Any, tag: String, captured: String?) -> [Log] {
        guard var userInfo = object as? Dictionary<String, Any>, let ext = captured else {
            return []
        }
        userInfo["ext"] = ext
        
        return [Log(tag: tag, date: self.logger.currentDate(), userInfo: userInfo)]
    }
}
