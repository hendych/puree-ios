import XCTest
import KurioPuree

class LoggerStandardPluginTest: XCTestCase {
    class TestLoggerConfiguration: LoggerConfiguration {
        let logStorage = TestLogStorage()
        let logStoreOperationDispatchQueue = DispatchQueue(label: "Puree logger test")
    }

    var loggerConfiguration: TestLoggerConfiguration!
    var logger: Logger!

    var testLogStorage: TestLogStorage {
        return loggerConfiguration.logStorage
    }

    override func setUp() {
        let configuration = TestLoggerConfiguration()
        let logStoreDBPath = NSTemporaryDirectory() + "/PureeLoggerTest-\(UUID().uuidString).db"
        let logStore = LogStore(databasePath: URL(fileURLWithPath: logStoreDBPath))
        let logStorage = configuration.logStorage

        configuration.logStore = logStore
        configuration.filterSettings = [
            FilterSetting(filter: TestChangeTagFilter.self, tagPattern: "filter.test", settings: ["tagSuffix": "XXX"]),
            FilterSetting(filter: TestAppendParamFilter.self, tagPattern: "filter.append.**"),
        ]
        configuration.outputSettings = [
            OutputSetting(output: TestOutput.self, tagPattern: "filter.testXXX", settings: ["logStorage": logStorage]),
            OutputSetting(output: TestOutput.self, tagPattern: "filter.append.**", settings: ["logStorage": logStorage]),
            OutputSetting(output: TestOutput.self, tagPattern: "test.*", settings: ["logStorage": logStorage]),
            OutputSetting(output: TestOutput.self, tagPattern: "unbuffered", settings: ["logStorage": logStorage]),
            OutputSetting(output: TestBufferedOutput.self, tagPattern: "buffered.*", settings: ["logStorage": logStorage, BufferedOutput.SettingsFlushIntervalKey: 2]),
            OutputSetting(output: TestFailureOutput.self, tagPattern: "failure", settings: ["logStorage": logStorage]),
        ]

        loggerConfiguration = configuration
        logger = Logger(configuration: configuration)
    }

    override func tearDown() {
        logger.logStore().clearAll()
        logger.shutdown()
    }

    func testChangeTagFilterPlugin() {
        XCTAssertEqual(String(describing: testLogStorage), "")

        logger.post(["aaa": "123"], tag: "filter.test")
        logger.post(["bbb": "456", "ccc": "789"], tag: "filter.test")
        logger.post(["ddd": "12345"], tag: "debug")
        logger.post(["eee": "not filtered"], tag: "filter.testXXX")

        XCTAssertEqual(String(describing: testLogStorage), "[filter.testXXX|aaa:123][filter.testXXX|bbb:456,ccc:789][filter.testXXX|eee:not filtered]")
    }

    func testAppendParamFilterPlugin() {
        XCTAssertEqual(String(describing: testLogStorage), "")

        logger.post(["aaa": "123"], tag: "filter.append")
        logger.post(["bbb": "456"], tag: "filter.append.xxx")
        logger.post(["ddd": "12345"], tag: "debug")
        logger.post(["ccc": "789"], tag: "filter.append.yyy")

        XCTAssertEqual(String(describing: testLogStorage), "[filter.append|aaa:123,ext:][filter.append.xxx|bbb:456,ext:xxx][filter.append.yyy|ccc:789,ext:yyy]")
    }

    func testUnbufferedOutputPlugin() {
        XCTAssertEqual(String(describing: testLogStorage), "")

        logger.post(["aaa": "123"], tag: "test.hoge")
        logger.post(["bbb": "456", "ccc": "789"], tag: "test.fuga")
        logger.post(["ddd": "12345"], tag: "debug")

        XCTAssertEqual(String(describing: testLogStorage), "[test.hoge|aaa:123][test.fuga|bbb:456,ccc:789]")
    }

    func testBufferedOutputPlugin_writeLog() {
        expectation(forNotification: NSNotification.Name(rawValue: BufferedOutput.DidStartNotification.rawValue), object: nil, handler: nil)
        waitForExpectations(timeout: 1.0, handler: nil)

        XCTAssertEqual(String(describing: testLogStorage), "")

        expectation(forNotification: NSNotification.Name(rawValue: BufferedOutput.DidSuccessWriteChunkNotification.rawValue), object: nil, handler: nil)

        logger.post(["aaa": "1"], tag: "buffered.a")
        logger.post(["aaa": "2"], tag: "buffered.a")
        logger.post(["aaa": "3"], tag: "buffered.b")

        XCTAssertEqual(String(describing: testLogStorage), "")

        logger.post(["aaa": "4"], tag: "buffered.b")
        logger.post(["zzz": "###"], tag: "unbuffered")
        logger.post(["aaa": "5"], tag: "buffered.a") // <- flush!

        // stay in buffer
        logger.post(["aaa": "6"], tag: "buffered.a")

        waitForExpectations(timeout: 1.0, handler: nil)

        let logStorageContent = String(describing: testLogStorage)
        XCTAssertTrue(logStorageContent.contains("[unbuffered|zzz:###]"))
        XCTAssertTrue(logStorageContent.contains("{buffered.a|aaa:1}"))
        XCTAssertTrue(logStorageContent.contains("{buffered.a|aaa:2}"))
        XCTAssertTrue(logStorageContent.contains("{buffered.b|aaa:3}"))
        XCTAssertTrue(logStorageContent.contains("{buffered.b|aaa:4}"))
        XCTAssertTrue(logStorageContent.contains("{buffered.a|aaa:5}"))
        XCTAssertFalse(logStorageContent.contains("{buffered.a|aaa:6}"))
    }

    func testBufferedOutputPlugin_resumeStoredLogs() {
        expectation(forNotification: NSNotification.Name(rawValue: BufferedOutput.DidStartNotification.rawValue), object: nil, handler: nil)
        waitForExpectations(timeout: 1.0, handler: nil)

        XCTAssertEqual(String(describing: testLogStorage), "")

        expectation(forNotification: NSNotification.Name(rawValue: BufferedOutput.DidSuccessWriteChunkNotification.rawValue), object: nil, handler: nil)

        logger.post(["aaa": "1"], tag: "buffered.c")
        logger.post(["aaa": "2"], tag: "buffered.c")
        logger.post(["aaa": "3"], tag: "buffered.d")

        XCTAssertEqual(String(describing: testLogStorage), "")

        logger.shutdown()
        expectation(forNotification: NSNotification.Name(rawValue: BufferedOutput.DidStartNotification.rawValue), object: nil, handler: nil)

        // renewal logger!
        logger = Logger(configuration: loggerConfiguration) // <- flush!

        waitForExpectations(timeout: 1.0, handler: nil)

        logger.post(["aaa": "4"], tag: "buffered.d") // stay in buffer
        logger.post(["zzz": "###"], tag: "unbuffered")
        logger.post(["aaa": "5"], tag: "buffered.c") // stay in buffer
        logger.post(["aaa": "6"], tag: "buffered.c") // stay in buffer

        let logStorageContent = String(describing: testLogStorage)
        XCTAssertTrue(logStorageContent.contains("[unbuffered|zzz:###]"))
        XCTAssertTrue(logStorageContent.contains("{buffered.c|aaa:1}"))
        XCTAssertTrue(logStorageContent.contains("{buffered.c|aaa:2}"))
        XCTAssertTrue(logStorageContent.contains("{buffered.d|aaa:3}"))

        XCTAssertFalse(logStorageContent.contains("{buffered.d|aaa:4}"))
        XCTAssertFalse(logStorageContent.contains("{buffered.c|aaa:5}"))
        XCTAssertFalse(logStorageContent.contains("{buffered.c|aaa:6}"))
    }

    func testBufferedOutputPlugin_periodicalFlushing() {
        expectation(forNotification: NSNotification.Name(rawValue: BufferedOutput.DidStartNotification.rawValue), object: nil, handler: nil)
        waitForExpectations(timeout: 1.0, handler: nil)

        XCTAssertEqual(String(describing: testLogStorage), "")

        expectation(forNotification: NSNotification.Name(rawValue: BufferedOutput.DidSuccessWriteChunkNotification.rawValue), object: nil, handler: nil)

        logger.post(["aaa": "1"], tag: "buffered.e")
        logger.post(["aaa": "2"], tag: "buffered.e")
        logger.post(["aaa": "3"], tag: "buffered.f")

        XCTAssertEqual(String(describing: testLogStorage), "")

        // wait flush interval(2sec) ...
        waitForExpectations(timeout: 3.0, handler: nil)

        let logStorageContent = String(describing: testLogStorage)
        XCTAssertTrue(logStorageContent.contains("{buffered.e|aaa:1}"))
        XCTAssertTrue(logStorageContent.contains("{buffered.e|aaa:2}"))
        XCTAssertTrue(logStorageContent.contains("{buffered.f|aaa:3}"))
    }

    func testBufferedOutputPlugin_retry() {
        expectation(forNotification: NSNotification.Name(rawValue: BufferedOutput.DidStartNotification.rawValue), object: nil, handler: nil)
        waitForExpectations(timeout: 1.0, handler: nil)

        XCTAssertEqual(String(describing: testLogStorage), "")

        expectation(forNotification: NSNotification.Name(rawValue: BufferedOutput.DidTryWriteChunkNotification.rawValue), object: nil, handler: nil)

        logger.post(["aaa": "1"], tag: "failure")
        logger.post(["aaa": "2"], tag: "failure")
        logger.post(["aaa": "3"], tag: "failure")
        logger.post(["aaa": "4"], tag: "failure")
        logger.post(["aaa": "5"], tag: "failure")

        waitForExpectations(timeout: 1.0, handler: nil)
        XCTAssertEqual(String(describing: testLogStorage), "[error]")

        expectation(forNotification: NSNotification.Name(rawValue: BufferedOutput.DidTryWriteChunkNotification.rawValue), object: nil, handler: nil)
        // scheduled after 2sec
        waitForExpectations(timeout: 3.0, handler: nil)
        XCTAssertEqual(String(describing: testLogStorage), "[error][error]")

        expectation(forNotification: NSNotification.Name(rawValue: BufferedOutput.DidTryWriteChunkNotification.rawValue), object: nil, handler: nil)
        // scheduled after 4sec
        waitForExpectations(timeout: 5.0, handler: nil)
        XCTAssertEqual(String(describing: testLogStorage), "[error][error][error]")

        expectation(forNotification: NSNotification.Name(rawValue: BufferedOutput.DidTryWriteChunkNotification.rawValue), object: nil, handler: nil)
        // scheduled after 8sec
        waitForExpectations(timeout: 9.0, handler: nil)
        XCTAssertEqual(String(describing: testLogStorage), "[error][error][error][error]")
    }
}
