# GenesisDB Swift SDK

This is the official Swift SDK for GenesisDB, an awesome and production ready event store database system for building event-driven apps.

## GenesisDB Advantages

* Incredibly fast when reading, fast when writing 🚀
* Easy backup creation and recovery
* [CloudEvents](https://cloudevents.io/) compatible
* GDPR-ready
* Easily accessible via the HTTP interface
* Auditable. Guarantee database consistency
* Logging and metrics for Prometheus
* SQL like query language called GenesisDB Query Language (GDBQL)
* ...

This SDK provides a simple interface to interact with the GenesisDB API using modern Swift concurrency.

## Requirements

* iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+
* Swift 5.9+
* Xcode 15.0+

## Installation

### Swift Package Manager

Add the following dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/genesisdb-io/genesisdb-io-client-swift.git", from: "latest")
]
```

Or add it directly in Xcode:
1. Go to File → Add Package Dependencies
2. Enter the repository URL: `https://github.com/genesisdb-io/genesisdb-io-client-swift.git`
3. Select the version you want to use

## Configuration

The SDK requires the following environment variables to be set:

* `GENESISDB_API_URL`: The URL of the GenesisDB API
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

### Stream Events from lower bound

```swift
import GenesisDB

do {
    let events = try await client.streamEvents(
        subject: "/",
        lowerBound: "2d6d4141-6107-4fb2-905f-445730f4f2a9",
        includeLowerBoundEvent: true
    )

    for event in events {
        print("Event Type: \(event.type), Data: \(event.data)")
    }
} catch {
    print("Error streaming events: \(error)")
}
```


### Stream Events with latest by event type

```swift
import GenesisDB

do {
    let events = try await client.streamEvents(
        subject: "/",
        latestByEventType: "io.genesisdb.app.customer-updated"
    )

    for event in events {
        print("Event Type: \(event.type), Data: \(event.data)")
    }
} catch {
    print("Error streaming events: \(error)")
}
```

This feature allows you to stream only the latest event of a specific type for each subject. Useful for getting the current state of entities.

### Observing Events in Real-Time

```swift
import GenesisDB

do {
    let eventStream = client.observeEvents(subject: "/user/456")

    for try await event in eventStream {
        print("Received event: \(event.type)")
        print("Data: \(event.data)")
    }
} catch {
    print("Error observing events: \(error)")
}
```

### Observe Events from lower bound (Message queue)

```swift
import GenesisDB

do {
    let eventStream = client.observeEvents(
        subject: "/customer",
        lowerBound: "2d6d4141-6107-4fb2-905f-445730f4f2a9",
        includeLowerBoundEvent: true
    )

    for try await event in eventStream {
        print("Received event: \(event.type)")
        print("Data: \(event.data)")
    }
} catch {
    print("Error observing events: \(error)")
}
```


### Observe Latest Events by Event Type (Message queue)

```swift
import GenesisDB

do {
    let eventStream = client.observeEvents(
        subject: "/customer",
        latestByEventType: "io.genesisdb.app.customer-updated"
    )

    for try await event in eventStream {
        print("Latest event: \(event.type)")
        print("Data: \(event.data)")
    }
} catch {
    print("Error observing events: \(error)")
}
```

You can also observe events with error handling and filtering:

```swift
import GenesisDB

do {
    let eventStream = client.observeEvents(subject: "/user/456")

    for try await event in eventStream {
        // Filter events based on type
        guard event.type.contains("foo") else { continue }

        // Process the event
        await processEvent(event)
    }
} catch GenesisDBError.apiError(let statusCode, let message) {
    print("API Error (\(statusCode)): \(message)")
} catch {
    print("Error: \(error)")
}
```

### Committing Events

```swift
import GenesisDB

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
    try await client.commitEvents(events)
    print("Events successfully committed")
} catch {
    print("Error committing events: \(error)")
}
```

### Usage of referenced data (GDPR)

```swift
import GenesisDB

let events = [
    Event(
        source: "io.genesisdb.app",
        subject: "/user/456",
        type: "io.genesisdb.app.user-created",
        data: [
            "firstName": "John",
            "lastName": "Doe",
            "email": "john.doe@example.com"
        ],
        options: [
            "storeDataAsReference": true
        ]
    )
]

do {
    try await client.commitEvents(events)
    print("Events committed with data stored as reference")
} catch {
    print("Error committing events: \(error)")
}
```

### Deleting referenced data (GDPR)

```swift
import GenesisDB

do {
    try await client.eraseData(subject: "/user/456")
    print("Data successfully erased")
} catch {
    print("Error erasing data: \(error)")
}
```

#### Committing Events with Preconditions

You can optionally provide preconditions to the `commitEvents` method. Preconditions allow you to enforce certain checks on the server before committing events. For example, you can require that a subject is new:

```swift
import GenesisDB

let events = [
    Event(
        source: "io.genesisdb.app",
        subject: "/user/456",
        type: "io.genesisdb.app.user-created",
        data: [
            "firstName": "John",
            "lastName": "Doe",
            "email": "john.doe@example.com"
        ]
    )
]

let preconditions = [
    Precondition(
        type: "isSubjectNew",
        payload: [
            "subject": "/user/456"
        ]
    )
]

do {
    try await client.commitEvents(events, preconditions: preconditions)
    print("Events committed successfully with preconditions")
} catch {
    print("Error committing events: \(error)")
}
```


## Preconditions

Preconditions allow you to enforce certain checks on the server before committing events. GenesisDB supports multiple precondition types:

### isSubjectNew
Ensures that a subject is new (has no existing events):

```swift
let events = [
    Event(
        source: "io.genesisdb.app",
        subject: "/user/456",
        type: "io.genesisdb.app.user-created",
        data: [
            "firstName": "John",
            "lastName": "Doe",
            "email": "john.doe@example.com"
        ]
    )
]

let preconditions = [
    Precondition(
        type: "isSubjectNew",
        payload: [
            "subject": "/user/456"
        ]
    )
]

do {
    try await client.commitEvents(events, preconditions: preconditions)
    print("Events committed successfully with preconditions")
} catch {
    print("Error committing events: \(error)")
}
```

### isSubjectExisting
Ensures that events exist for the specified subject:

```swift
let events = [
    Event(
        source: "io.genesisdb.app",
        subject: "/user/456",
        type: "io.genesisdb.app.user-created",
        data: [
            "firstName": "John",
            "lastName": "Doe",
            "email": "john.doe@example.com"
        ]
    )
]

let preconditions = [
    Precondition(
        type: "isSubjectExisting",
        payload: [
            "subject": "/user/456"
        ]
    )
]

do {
    try await client.commitEvents(events, preconditions: preconditions)
    print("Events committed successfully with preconditions")
} catch {
    print("Error committing events: \(error)")
}
```

### isQueryResultTrue
Evaluates a query and ensures the result is truthy. Supports the full GDBQL feature set including complex WHERE clauses, aggregations, and calculated fields.

**Basic uniqueness check:**
```swift
let events = [
    Event(
        source: "io.genesisdb.app",
        subject: "/user/456",
        type: "io.genesisdb.app.user-created",
        data: [
            "firstName": "John",
            "lastName": "Doe",
            "email": "john.doe@example.com"
        ]
    )
]

let preconditions = [
    Precondition(
        type: "isQueryResultTrue",
        payload: [
            "query": "STREAM e FROM events WHERE e.data.email == 'john.doe@example.com' MAP COUNT() == 0"
        ]
    )
]

do {
    try await client.commitEvents(events, preconditions: preconditions)
    print("User created with uniqueness check")
} catch {
    print("Error committing events: \(error)")
}
```

**Business rule enforcement (transaction limits):**
```swift
let events = [
    Event(
        source: "io.genesisdb.banking",
        subject: "/user/123/transactions",
        type: "io.genesisdb.banking.transaction-processed",
        data: [
            "amount": 500.00,
            "currency": "EUR"
        ]
    )
]

let preconditions = [
    Precondition(
        type: "isQueryResultTrue",
        payload: [
            "query": "STREAM e FROM events WHERE e.subject UNDER '/user/123' AND e.type == 'transaction-processed' AND e.time >= '2024-01-01T00:00:00Z' MAP SUM(e.data.amount) + 500 <= 10000"
        ]
    )
]

do {
    try await client.commitEvents(events, preconditions: preconditions)
    print("Transaction processed with limit check")
} catch {
    print("Error committing events: \(error)")
}
```

**Complex validation with aggregations:**
```swift
let events = [
    Event(
        source: "io.genesisdb.events",
        subject: "/conference/2024/registrations",
        type: "io.genesisdb.events.registration-created",
        data: [
            "attendeeId": "att-789",
            "ticketType": "premium"
        ]
    )
]

let preconditions = [
    Precondition(
        type: "isQueryResultTrue",
        payload: [
            "query": "STREAM e FROM events WHERE e.subject UNDER '/conference/2024/registrations' AND e.type == 'registration-created' GROUP BY e.data.ticketType HAVING e.data.ticketType == 'premium' MAP COUNT() < 50"
        ]
    )
]

do {
    try await client.commitEvents(events, preconditions: preconditions)
    print("Registration created with capacity check")
} catch {
    print("Error committing events: \(error)")
}
```

**Supported GDBQL Features in Preconditions:**
- WHERE conditions with AND/OR/IN/BETWEEN operators
- Hierarchical subject queries (UNDER, DESCENDANTS)
- Aggregation functions (COUNT, SUM, AVG, MIN, MAX)
- GROUP BY with HAVING clauses
- ORDER BY and LIMIT clauses
- Calculated fields and expressions
- Nested field access (e.data.address.city)
- String concatenation and arithmetic operations

If a precondition fails, the commit returns HTTP 412 (Precondition Failed) with details about which condition failed.


### Querying Events

```swift
import GenesisDB

let query = """
STREAM e FROM events
WHERE e.type == 'io.genesisdb.app.customer-added'
ORDER BY e.time
MAP { id: e.id, firstName: e.data.firstName, lastName: e.data.lastName }
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

### Querying Events (Alternative Method)

```swift
import GenesisDB

let query = "STREAM e FROM events WHERE e.type == \"io.genesisdb.app.customer-added\" ORDER BY e.time DESC LIMIT 20 MAP { subject: e.subject, firstName: e.data.firstName }"

do {
    let results = try await client.queryEvents(query)

    for result in results {
        print("Result: \(result)")
    }
} catch {
    print("Error executing query: \(error)")
}
```


## Health Checks

```swift
import GenesisDB

// Ping the API
do {
    let response = try await client.ping()
    print("Ping response: \(response)")
} catch {
    print("Error pinging API: \(error)")
}

// Run audit to check event consistency
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

## Precondition Model

The `Precondition` struct allows you to specify checks that must pass before events are committed:

```swift
public struct Precondition: Codable {
    public let type: String
    public let payload: [String: Any]
}
```

You can create preconditions using the standard initializer:

```swift
let precondition = Precondition(
    type: "isSubjectNew",
    payload: ["subject": "/some/subject"]
)
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

MIT

## Author

* E-Mail: mail@genesisdb.io
* URL: https://www.genesisdb.io
* Docs: https://docs.genesisdb.io
