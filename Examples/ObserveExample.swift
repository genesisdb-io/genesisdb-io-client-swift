import Foundation
import GenesisDB

// MARK: - Observe Events Example

struct ObserveExample {
    static func demonstrateObserveEvents() async {
        print("Genesis DB Swift SDK - Observe Events Example")
        print("=============================================")

        let config = Config(
            apiURL: "http://localhost:8080",
            apiVersion: "v1",
            authToken: "your-auth-token"
        )

        guard let client = try? GenesisDBClient(config: config) else {
            print("Failed to create client")
            return
        }

        // Example 1: Basic observe events
        await basicObserveExample(client)

        // Example 2: Observe with error handling
        await observeWithErrorHandling(client)

        // Example 3: Observe with timeout
        await observeWithTimeout(client)
    }

    static func basicObserveExample(_ client: GenesisDBClient) async {
        print("\nExample 1: Basic observe events")

        do {
            let eventStream = client.observeEvents(subject: "/foo/21")

            for try await event in eventStream {
                print("Received event:")
                print("  ID: \(event.id ?? "N/A")")
                print("  Type: \(event.type)")
                print("  Subject: \(event.subject)")
                print("  Data: \(event.data)")
                print("  Time: \(event.time?.date ?? Date())")
                print("---")
            }
        } catch {
            print("Error observing events: \(error)")
        }
    }

    static func observeWithErrorHandling(_ client: GenesisDBClient) async {
        print("\nExample 2: Observe with error handling")

        do {
            let eventStream = client.observeEvents(subject: "/foo/21")

            for try await event in eventStream {
                // Process each event
                await processEvent(event)
            }
        } catch GenesisDBError.apiError(let statusCode, let message) {
            print("API Error (\(statusCode)): \(message)")
        } catch GenesisDBError.networkError(let error) {
            print("Network Error: \(error)")
        } catch {
            print("Unexpected error: \(error)")
        }
    }

    static func observeWithTimeout(_ client: GenesisDBClient) async {
        print("\nExample 3: Observe with timeout")

        do {
            let eventStream = client.observeEvents(subject: "/foo/21")

            // Set a timeout for the observation
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
                throw GenesisDBError.custom("Observation timeout")
            }

            // Observe events with timeout
            async let observationTask = observeEventsWithTimeout(eventStream)

            do {
                try await observationTask
            } catch {
                if error.localizedDescription.contains("timeout") {
                    print("Observation completed due to timeout")
                } else {
                    throw error
                }
            }

            timeoutTask.cancel()
        } catch {
            print("Error in timeout example: \(error)")
        }
    }

    // MARK: - Helper Methods

    private static func processEvent(_ event: Event) async {
        // Simulate some processing time
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        print("Processing event: \(event.type)")

        // Example: Different handling based on event type
        switch event.type {
        case "io.genesisdb.app.foo-added":
            print("  Handling foo-added event")
            if let value = event.data["value"] as? String {
                print("  Value: \(value)")
            }
        case "io.genesisdb.app.foo-updated":
            print("  Handling foo-updated event")
        case "io.genesisdb.app.foo-deleted":
            print("  Handling foo-deleted event")
        default:
            print("  Handling unknown event type")
        }
    }

    private static func observeEventsWithTimeout(_ eventStream: AsyncThrowingStream<Event, Error>) async throws {
        var eventCount = 0
        let maxEvents = 10 // Limit to 10 events for this example

        for try await event in eventStream {
            print("Received event \(eventCount + 1): \(event.type)")
            eventCount += 1

            if eventCount >= maxEvents {
                print("Reached maximum event count, stopping observation")
                break
            }
        }
    }
}

// MARK: - Advanced Observe Example

struct AdvancedObserveExample {
    static func demonstrateAdvancedFeatures() async {
        print("\nAdvanced Observe Features")
        print("=========================")

        let config = Config(
            apiURL: "http://localhost:8080",
            apiVersion: "v1",
            authToken: "your-auth-token"
        )

        guard let client = try? GenesisDBClient(config: config) else {
            print("Failed to create client")
            return
        }

        // Example: Multiple concurrent observations
        await observeMultipleSubjects(client)

        // Example: Observe with filtering
        await observeWithFiltering(client)
    }

    static func observeMultipleSubjects(_ client: GenesisDBClient) async {
        print("\nObserving multiple subjects concurrently")

        let subjects = ["/foo/21", "/foo/22", "/foo/23"]

        await withTaskGroup(of: Void.self) { group in
            for subject in subjects {
                group.addTask {
                    do {
                        let eventStream = client.observeEvents(subject: subject)
                        var eventCount = 0

                        for try await event in eventStream {
                            print("[\(subject)] Event \(eventCount + 1): \(event.type)")
                            eventCount += 1

                            if eventCount >= 5 {
                                break // Limit events per subject
                            }
                        }
                    } catch {
                        print("[\(subject)] Error: \(error)")
                    }
                }
            }
        }
    }

    static func observeWithFiltering(_ client: GenesisDBClient) async {
        print("\nObserving with client-side filtering")

        do {
            let eventStream = client.observeEvents(subject: "/foo/21")

            for try await event in eventStream {
                // Filter events based on type
                guard event.type.contains("foo") else { continue }

                // Filter events based on data
                if let value = event.data["value"] as? String, value == "Foo" {
                    print("Filtered event: \(event.type) with value '\(value)'")
                }
            }
        } catch {
            print("Error in filtering example: \(error)")
        }
    }
}
