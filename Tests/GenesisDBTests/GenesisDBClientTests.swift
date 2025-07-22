import XCTest
@testable import GenesisDB

final class GenesisDBClientTests: XCTestCase {

    var testConfig: Config!
    var client: GenesisDBClient!

    override func setUpWithError() throws {
        testConfig = Config(
            apiURL: "http://localhost:8080",
            apiVersion: "v1",
            authToken: "secret"
        )

        client = try GenesisDBClient(config: testConfig)
    }

    override func tearDownWithError() throws {
        client = nil
        testConfig = nil
    }

    // MARK: - Configuration Tests

    func testValidConfiguration() throws {
        let config = Config(
            apiURL: "http://localhost:8080",
            apiVersion: "v1",
            authToken: "secret"
        )

        let client = try GenesisDBClient(config: config)
        XCTAssertNotNil(client)
    }

    func testMissingAPIURL() {
        let config = Config(
            apiURL: "",
            apiVersion: "v1",
            authToken: "secret"
        )

        XCTAssertThrowsError(try GenesisDBClient(config: config)) { error in
            XCTAssertTrue(error is GenesisDBError)
            if case .configurationError(let message) = error as? GenesisDBError {
                XCTAssertTrue(message.contains("API URL is required"))
            } else {
                XCTFail("Expected configuration error")
            }
        }
    }

    func testMissingAPIVersion() {
        let config = Config(
            apiURL: "http://localhost:8080",
            apiVersion: "",
            authToken: "secret"
        )

        XCTAssertThrowsError(try GenesisDBClient(config: config)) { error in
            XCTAssertTrue(error is GenesisDBError)
            if case .configurationError(let message) = error as? GenesisDBError {
                XCTAssertTrue(message.contains("API version is required"))
            } else {
                XCTFail("Expected configuration error")
            }
        }
    }

    func testMissingAuthToken() {
        let config = Config(
            apiURL: "http://localhost:8080",
            apiVersion: "v1",
            authToken: ""
        )

        XCTAssertThrowsError(try GenesisDBClient(config: config)) { error in
            XCTAssertTrue(error is GenesisDBError)
            if case .configurationError(let message) = error as? GenesisDBError {
                XCTAssertTrue(message.contains("Auth token is required"))
            } else {
                XCTFail("Expected configuration error")
            }
        }
    }

    // MARK: - Event Model Tests

    func testEventInitialization() {
        let event = Event(
            id: "test-id",
            source: "test-source",
            subject: "/test/subject",
            type: "test.type",
            time: RFC3339Time(Date()),
            data: ["key": "value"],
            dataContentType: "application/json",
            specVersion: "1.0"
        )

        XCTAssertEqual(event.id, "test-id")
        XCTAssertEqual(event.source, "test-source")
        XCTAssertEqual(event.subject, "/test/subject")
        XCTAssertEqual(event.type, "test.type")
        XCTAssertNotNil(event.time)
        XCTAssertEqual(event.data["key"] as? String, "value")
        XCTAssertEqual(event.dataContentType, "application/json")
        XCTAssertEqual(event.specVersion, "1.0")
    }

    func testEventWithMinimalData() {
        let event = Event(
            subject: "/test/subject",
            type: "test.type",
            data: [:]
        )

        XCTAssertNil(event.id)
        XCTAssertNil(event.source)
        XCTAssertEqual(event.subject, "/test/subject")
        XCTAssertEqual(event.type, "test.type")
        XCTAssertNil(event.time)
        XCTAssertTrue(event.data.isEmpty)
        XCTAssertNil(event.dataContentType)
        XCTAssertNil(event.specVersion)
    }

    // MARK: - RFC3339Time Tests

    func testRFC3339TimeInitialization() {
        let date = Date()
        let rfcTime = RFC3339Time(date)

        XCTAssertEqual(rfcTime.date, date)
    }

    func testRFC3339TimeEncoding() throws {
        let date = Date()
        let rfcTime = RFC3339Time(date)

        let encoder = JSONEncoder()
        let data = try encoder.encode(rfcTime)
        let string = String(data: data, encoding: .utf8)

        XCTAssertNotNil(string)
        XCTAssertTrue(string!.contains("\""))
    }

    func testRFC3339TimeDecoding() throws {
        let dateString = "\"2024-01-01T12:00:00Z\""
        let data = dateString.data(using: .utf8)!

        let decoder = JSONDecoder()
        let rfcTime = try decoder.decode(RFC3339Time.self, from: data)

        XCTAssertNotNil(rfcTime.date)
    }

    // MARK: - Integration Tests (These would require a running server)

    func testPingIntegration() async throws {
        // This test requires a running GenesisDB server
        // Uncomment and configure when testing against a real server

        /*
        do {
            let response = try await client.ping()
            XCTAssertFalse(response.isEmpty)
            print("Ping response: \(response)")
        } catch {
            // This is expected if no server is running
            print("Ping test skipped - no server running: \(error)")
        }
        */
    }

    func testAuditIntegration() async throws {
        // This test requires a running GenesisDB server
        // Uncomment and configure when testing against a real server

        /*
        do {
            let response = try await client.audit()
            XCTAssertFalse(response.isEmpty)
            print("Audit response: \(response)")
        } catch {
            // This is expected if no server is running
            print("Audit test skipped - no server running: \(error)")
        }
        */
    }

    func testCommitAndStreamEventsIntegration() async throws {
        // This test requires a running GenesisDB server
        // Uncomment and configure when testing against a real server

        /*
        let events = [
            Event(
                source: "io.genesisdb.test",
                subject: "/test/customer",
                type: "io.genesisdb.test.customer-added",
                data: [
                    "firstName": "Max",
                    "lastName": "Mustermann",
                    "email": "max.mustermann@test.de",
                    "timestamp": Int(Date().timeIntervalSince1970)
                ]
            ),
            Event(
                source: "io.genesisdb.test",
                subject: "/test/article",
                type: "io.genesisdb.test.article-added",
                data: [
                    "name": "Test Article",
                    "price": 99.99,
                    "timestamp": Int(Date().timeIntervalSince1970)
                ]
            )
        ]

        do {
            // Commit events
            try await client.commitEvents(events)
            print("Events successfully committed")

            // Stream customer events
            let customerEvents = try await client.streamEvents(subject: "/test/customer")
            XCTAssertFalse(customerEvents.isEmpty)

            let foundCustomer = customerEvents.contains { event in
                event.type == "io.genesisdb.test.customer-added" &&
                event.data["firstName"] as? String == "Max"
            }
            XCTAssertTrue(foundCustomer, "Customer event not found in database")

            // Stream article events
            let articleEvents = try await client.streamEvents(subject: "/test/article")
            XCTAssertFalse(articleEvents.isEmpty)

            let foundArticle = articleEvents.contains { event in
                event.type == "io.genesisdb.test.article-added" &&
                event.data["name"] as? String == "Test Article"
            }
            XCTAssertTrue(foundArticle, "Article event not found in database")

        } catch {
            // This is expected if no server is running
            print("Integration test skipped - no server running: \(error)")
        }
        */
    }

    func testStreamEventsWithLatestByEventType() async throws {
        // This test requires a running GenesisDB server
        // Uncomment and configure when testing against a real server

        /*
        let events = [
            Event(
                source: "io.genesisdb.test",
                subject: "/test/latest",
                type: "io.genesisdb.test.latest-test",
                data: [
                    "message": "Test for Latest By Event Type",
                    "timestamp": Int(Date().timeIntervalSince1970)
                ]
            )
        ]

        do {
            // Commit events
            try await client.commitEvents(events)
            print("Events successfully committed")

            // Stream events with latest by event type
            let latestEvents = try await client.streamEvents(
                subject: "/test/latest",
                latestByEventType: "io.genesisdb.test.latest-test"
            )

            XCTAssertFalse(latestEvents.isEmpty, "Should find events with latestByEventType")

            let foundLatest = latestEvents.contains { event in
                event.type == "io.genesisdb.test.latest-test" &&
                event.data["message"] as? String == "Test for Latest By Event Type"
            }
            XCTAssertTrue(foundLatest, "Latest event not found in database")

        } catch {
            // This is expected if no server is running
            print("Latest by event type test skipped - no server running: \(error)")
        }
        */
    }

    func testQueryIntegration() async throws {
        // This test requires a running GenesisDB server
        // Uncomment and configure when testing against a real server

        /*
        let query = """
        FROM e IN events
        WHERE e.type == 'io.genesisdb.test.customer-added'
        ORDER BY e.time
        PROJECT INTO { id: e.id, firstName: e.data.firstName, lastName: e.data.lastName }
        """

        do {
            let results = try await client.query(query)
            XCTAssertFalse(results.isEmpty)

            for result in results {
                print("Query result: \(result)")
            }
        } catch {
            // This is expected if no server is running
            print("Query test skipped - no server running: \(error)")
        }
        */
    }

    // MARK: - Performance Tests

    func testEventCreationPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = Event(
                    subject: "/test/subject",
                    type: "test.type",
                    data: ["key": "value"]
                )
            }
        }
    }

    func testEventEncodingPerformance() throws {
        let event = Event(
            subject: "/test/subject",
            type: "test.type",
            data: ["key": "value"]
        )

        let encoder = JSONEncoder()

        measure {
            for _ in 0..<1000 {
                _ = try! encoder.encode(event)
            }
        }
    }
}
