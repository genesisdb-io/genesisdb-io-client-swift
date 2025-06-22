# Genesis DB Swift SDK

This is the official Swift SDK for Genesis DB. It provides a simple interface to interact with the Genesis DB API using modern Swift concurrency.

## Requirements

* iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+
* Swift 5.9+
* Xcode 15.0+

## Installation

### Swift Package Manager

Add the following dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/genesisdb-io/genesisdb-io-client-swift.git", from: "1.0.0")
]
```

Or add it directly in Xcode:
1. Go to File → Add Package Dependencies
2. Enter the repository URL: `https://github.com/genesisdb-io/genesisdb-io-client-swift.git`
3. Select the version you want to use

## Configuration

The SDK requires the following environment variables to be set:

* `GENESISDB_API_URL`: The URL of the Genesis DB API
* `GENESISDB_API_VERSION`: The version of the API to use
* `GENESISDB_AUTH_TOKEN`: Your authentication token

Alternatively, you can pass these values directly when creating the client:

```swift
import GenesisDB

let config = Config(
    apiURL: "https://your-api-url",
    apiVersion: "v1",
    authToken: "your-auth-token"
)

let client = try GenesisDBClient(config: config)
```

Or create configuration from environment variables:

```swift
let config = try Config.fromEnvironment()
let client = try GenesisDBClient(config: config)
```

## Usage

### Streaming Events

```swift
import GenesisDB

do {
    let events = try await client.streamEvents(subject: "/customer")

    for event in events {
        print("Event Type: \(event.type), Data: \(event.data)")
    }
} catch {
    print("Error streaming events: \(error)")
}
```

### Committing Events

```swift
import GenesisDB

// Example for creating new events
let events = [
    Event(
        source: "io.genesisdb.app",
        subject: "/customer",
        type: "io.genesisdb.app.customer-added",
        data: [
            "firstName": "Bruce",
            "lastName": "Wayne",
            "emailAddress": "bruce.wayne@enterprise.wayne"
        ]
    ),
    Event(
        source: "io.genesisdb.app",
        subject: "/customer",
        type: "io.genesisdb.app.customer-added",
        data: [
            "firstName": "Alfred",
            "lastName": "Pennyworth",
            "emailAddress": "alfred.pennyworth@enterprise.wayne"
        ]
    ),
    Event(
        source: "io.genesisdb.store",
        subject: "/article",
        type: "io.genesisdb.store.article-added",
        data: [
            "name": "Tumbler",
            "color": "black",
            "price": 2990000.00
        ]
    ),
    Event(
        source: "io.genesisdb.app",
        subject: "/customer/fed2902d-0135-460d-8605-263a06308448",
        type: "io.genesisdb.app.customer-personaldata-changed",
        data: [
            "firstName": "Angus",
            "lastName": "MacGyver",
            "emailAddress": "angus.macgyer@phoenix.foundation"
        ]
    )
]

do {
    try await client.commitEvents(events)
    print("Events successfully committed")
} catch {
    print("Error committing events: \(error)")
}
```

### Querying Events

```swift
import GenesisDB

let query = """
FROM e IN events
WHERE e.type == 'io.genesisdb.app.customer-added'
ORDER BY e.time
PROJECT INTO { id: e.id, firstName: e.data.firstName, lastName: e.data.lastName }
"""

do {
    let results = try await client.query(query)

    for result in results {
        print("Result: \(result)")
    }
} catch {
    print("Error executing query: \(error)")
}
```

### Health Checks

```swift
import GenesisDB

// Ping the API
do {
    let response = try await client.ping()
    print("Ping response: \(response)")
} catch {
    print("Error pinging API: \(error)")
}

// Run audit
do {
    let response = try await client.audit()
    print("Audit response: \(response)")
} catch {
    print("Error running audit: \(error)")
}
```

## Event Model

The `Event` struct represents an event in the GenesisDB system:

```swift
public struct Event: Codable {
    public let id: String?                    // Unique identifier
    public let source: String?                // Source of the event
    public let subject: String                // Subject of the event
    public let type: String                   // Type of the event
    public let time: RFC3339Time?             // Timestamp
    public let data: [String: Any]            // Event data
    public let dataContentType: String?       // Content type
    public let specVersion: String?           // Specification version
}
```

## Error Handling

The SDK uses Swift's native error handling with the `GenesisDBError` enum:

```swift
public enum GenesisDBError: LocalizedError {
    case configurationError(String)
    case networkError(Error)
    case apiError(Int, String)
    case jsonError(Error)
    case invalidResponse(String)
    case missingField(String)
    case custom(String)
}
```

All methods can throw errors, so make sure to handle them appropriately using `do-catch` blocks or `try?`/`try!` as needed.

## Async/Await Support

The SDK is built with modern Swift concurrency using `async`/`await`. All network operations are asynchronous and should be called from an async context:

```swift
// In an async function or Task
Task {
    do {
        let events = try await client.streamEvents(subject: "/customer")
        // Handle events
    } catch {
        // Handle error
    }
}
```

## Thread Safety

The `GenesisDBClient` is thread-safe and can be used from multiple threads concurrently. However, individual client instances should not be shared across different threads without proper synchronization.

## License

Copyright © 2025 Genesis DB. All rights reserved.
