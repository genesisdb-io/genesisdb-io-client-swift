import Foundation
import GenesisDB

// MARK: - Precondition Usage Example

struct PreconditionExample {
    static func demonstratePreconditions() async {
        print("GenesisDB Swift SDK - Precondition Example")
        print("==========================================")

        let config = Config(
            apiURL: "http://localhost:8080",
            apiVersion: "v1",
            authToken: "your-auth-token"
        )

        guard let client = try? GenesisDBClient(config: config) else {
            print("❌ Failed to create client")
            return
        }

        // Example 1: Commit events with isSubjectNew precondition
        await commitWithSubjectNewPrecondition(client)

        // Example 2: Commit events with multiple preconditions
        await commitWithMultiplePreconditions(client)

        // Example 3: Commit events without preconditions (existing behavior)
        await commitWithoutPreconditions(client)
    }

    static func commitWithSubjectNewPrecondition(_ client: GenesisDBClient) async {
        print("\n🔒 Example 1: Commit with isSubjectNew precondition")

        let events = [
            Event(
                source: "io.genesisdb.app",
                subject: "/foo/21",
                type: "io.genesisdb.app.foo-added",
                data: [
                    "value": "Foo"
                ]
            )
        ]

        let preconditions = [
            Precondition(
                type: "isSubjectNew",
                payload: [
                    "subject": "/foo/21"
                ]
            )
        ]

        do {
            try await client.commitEvents(events, preconditions: preconditions)
            print("✅ Events committed successfully with isSubjectNew precondition")
        } catch {
            print("❌ Failed to commit events: \(error)")
        }
    }

    static func commitWithMultiplePreconditions(_ client: GenesisDBClient) async {
        print("\n🔒 Example 2: Commit with multiple preconditions")

        let events = [
            Event(
                source: "io.genesisdb.app",
                subject: "/foo/21",
                type: "io.genesisdb.app.foo-added",
                data: [
                    "value": "Foo"
                ]
            )
        ]

        let preconditions = [
            Precondition(
                type: "isSubjectNew",
                payload: [
                    "subject": "/foo/21"
                ]
            ),
            Precondition(
                type: "isSubjectNew",
                payload: [
                    "subject": "/foo/21"
                ]
            )
        ]

        do {
            try await client.commitEvents(events, preconditions: preconditions)
            print("✅ Events committed successfully with multiple preconditions")
        } catch {
            print("❌ Failed to commit events: \(error)")
        }
    }

    static func commitWithoutPreconditions(_ client: GenesisDBClient) async {
        print("\n🔒 Example 3: Commit without preconditions (existing behavior)")

        let events = [
            Event(
                source: "io.genesisdb.app",
                subject: "/foo/21",
                type: "io.genesisdb.app.foo-added",
                data: [
                    "value": "Foo"
                ]
            )
        ]

        do {
            // This uses the default parameter (preconditions: nil)
            try await client.commitEvents(events)
            print("✅ Events committed successfully without preconditions")
        } catch {
            print("❌ Failed to commit events: \(error)")
        }
    }
}

// MARK: - Convenience Extensions

extension Precondition {
    /// Convenience initializer for isSubjectNew precondition
    public static func isSubjectNew(subject: String) -> Precondition {
        return Precondition(
            type: "isSubjectNew",
            payload: ["subject": subject]
        )
    }

    /// Convenience initializer for custom precondition
    public static func custom(type: String, payload: [String: Any]) -> Precondition {
        return Precondition(type: type, payload: payload)
    }
}

// MARK: - Usage with Convenience Methods

struct ConvenientPreconditionExample {
    static func demonstrateConvenienceMethods() async {
        print("\n🚀 Convenience Methods Example")

        let config = Config(
            apiURL: "http://localhost:8080",
            apiVersion: "v1",
            authToken: "your-auth-token"
        )

        guard let client = try? GenesisDBClient(config: config) else {
            print("❌ Failed to create client")
            return
        }

        let events = [
            Event(
                source: "io.genesisdb.app",
                subject: "/foo/21",
                type: "io.genesisdb.app.foo-added",
                data: ["value": "Foo"]
            )
        ]

        // Using convenience methods
        let preconditions = [
            Precondition.isSubjectNew(subject: "/foo/21"),
            Precondition.custom(type: "userExists", payload: ["userId": "456"])
        ]

        do {
            try await client.commitEvents(events, preconditions: preconditions)
            print("✅ Events committed using convenience methods")
        } catch {
            print("❌ Failed to commit events: \(error)")
        }
    }
}
