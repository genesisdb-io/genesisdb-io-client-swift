import Foundation
import GenesisDB

// MARK: - Basic Usage Example

@main
struct BasicUsageExample {
    static func main() async {
        print("Genesis DB Swift SDK - Basic Usage Example")
        print("==========================================")

        // Create configuration
        let config = Config(
            apiURL: "http://localhost:8080",
            apiVersion: "v1",
            authToken: "your-auth-token"
        )

        // Initialize client
        guard let client = try? GenesisDBClient(config: config) else {
            print("Failed to create client")
            return
        }

        print("Client created successfully")

        // Test connectivity
        await testConnectivity(client)

        // Test event operations
        await testEventOperations(client)

        // Test querying
        await testQuerying(client)
    }

    // MARK: - Connectivity Tests

    static func testConnectivity(_ client: GenesisDBClient) async {
        print("\nTesting connectivity...")

        // Ping test
        do {
            let pingResponse = try await client.ping()
            print("Ping successful: \(pingResponse)")
        } catch {
            print("Ping failed: \(error)")
        }

        // Audit test
        do {
            let auditResponse = try await client.audit()
            print("Audit successful: \(auditResponse)")
        } catch {
            print("Audit failed: \(error)")
        }
    }

    // MARK: - Event Operations

    static func testEventOperations(_ client: GenesisDBClient) async {
        print("\nTesting event operations...")

        // Create test events
        let events = [
            Event(
                source: "io.genesisdb.example",
                subject: "/example/customer",
                type: "io.genesisdb.example.customer-added",
                data: [
                    "firstName": "John",
                    "lastName": "Doe",
                    "email": "john.doe@example.com",
                    "timestamp": Int(Date().timeIntervalSince1970)
                ]
            ),
            Event(
                source: "io.genesisdb.example",
                subject: "/example/product",
                type: "io.genesisdb.example.product-added",
                data: [
                    "name": "Example Product",
                    "price": 99.99,
                    "category": "electronics",
                    "timestamp": Int(Date().timeIntervalSince1970)
                ]
            )
        ]

        // Commit events
        do {
            try await client.commitEvents(events)
            print("Events committed successfully")
        } catch {
            print("Failed to commit events: \(error)")
            return
        }

        // Stream customer events
        do {
            let customerEvents = try await client.streamEvents(subject: "/example/customer")
            print("Retrieved \(customerEvents.count) customer events")

            for event in customerEvents {
                print("  - Event ID: \(event.id ?? "N/A")")
                print("  - Type: \(event.type)")
                print("  - Data: \(event.data)")
            }
        } catch {
            print("Failed to stream customer events: \(error)")
        }

        // Stream product events
        do {
            let productEvents = try await client.streamEvents(subject: "/example/product")
            print("Retrieved \(productEvents.count) product events")

            for event in productEvents {
                print("  - Event ID: \(event.id ?? "N/A")")
                print("  - Type: \(event.type)")
                print("  - Data: \(event.data)")
            }
        } catch {
            print("Failed to stream product events: \(error)")
        }
    }

    // MARK: - Querying

    static func testQuerying(_ client: GenesisDBClient) async {
        print("\nTesting querying...")

        let query = """
        FROM e IN events
        WHERE e.type == 'io.genesisdb.example.customer-added'
        ORDER BY e.time
        PROJECT INTO {
            id: e.id,
            firstName: e.data.firstName,
            lastName: e.data.lastName,
            email: e.data.email
        }
        """

        do {
            let results = try await client.query(query)
            print("Query executed successfully")
            print("Retrieved \(results.count) results:")

            for (index, result) in results.enumerated() {
                print("  Result \(index + 1):")
                for (key, value) in result {
                    print("    \(key): \(value)")
                }
            }
        } catch {
            print("Query failed: \(error)")
        }
    }
}

// MARK: - Advanced Usage Example

struct AdvancedUsageExample {
    static func demonstrateAdvancedFeatures() async {
        print("\nAdvanced Usage Example")
        print("=========================")

        // Create configuration with custom settings
        let config = Config(
            apiURL: "http://localhost:8080",
            apiVersion: "v1",
            authToken: "your-auth-token",
            timeout: 60.0,  // 60 second timeout
            userAgent: "MyApp/1.0 Genesis-DB-Swift-SDK"
        )

        guard let client = try? GenesisDBClient(config: config) else {
            print("Failed to create client")
            return
        }

        // Demonstrate batch event processing
        await demonstrateBatchProcessing(client)

        // Demonstrate error handling
        await demonstrateErrorHandling(client)
    }

    static func demonstrateBatchProcessing(_ client: GenesisDBClient) async {
        print("\n📦 Batch Event Processing")

        // Create a large batch of events
        var batchEvents: [Event] = []

        for i in 1...10 {
            let event = Event(
                source: "io.genesisdb.batch",
                subject: "/batch/test",
                type: "io.genesisdb.batch.item-created",
                data: [
                    "itemId": "item-\(i)",
                    "value": Double(i) * 10.0,
                    "timestamp": Int(Date().timeIntervalSince1970),
                    "batchNumber": i
                ]
            )
            batchEvents.append(event)
        }

        do {
            try await client.commitEvents(batchEvents)
            print("Batch of \(batchEvents.count) events committed")

            // Stream all batch events
            let streamedEvents = try await client.streamEvents(subject: "/batch/test")
            print("Retrieved \(streamedEvents.count) batch events")

        } catch {
            print("Batch processing failed: \(error)")
        }
    }

    static func demonstrateErrorHandling(_ client: GenesisDBClient) async {
        print("\nError Handling Demonstration")

        // Test with invalid subject
        do {
            let events = try await client.streamEvents(subject: "/invalid/subject")
            print("Unexpected success with invalid subject")
        } catch GenesisDBError.apiError(let statusCode, let message) {
            print("Caught API error: \(statusCode) - \(message)")
        } catch {
            print("Caught other error: \(error)")
        }

        // Test with invalid query
        do {
            let results = try await client.query("INVALID QUERY SYNTAX")
            print("Unexpected success with invalid query")
        } catch GenesisDBError.apiError(let statusCode, let message) {
            print("Caught API error: \(statusCode) - \(message)")
        } catch {
            print("Caught other error: \(error)")
        }
    }
}
