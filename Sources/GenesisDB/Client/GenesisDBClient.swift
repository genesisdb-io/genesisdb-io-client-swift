import Foundation
import Crypto

/// Main client for interacting with GenesisDB
public class GenesisDBClient {
    private let config: Config
    private let session: URLSession
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder

    public init(config: Config) throws {
        // Validate configuration
        guard !config.apiURL.isEmpty else {
            throw GenesisDBError.configurationError("API URL is required")
        }
        guard !config.apiVersion.isEmpty else {
            throw GenesisDBError.configurationError("API version is required")
        }
        guard !config.authToken.isEmpty else {
            throw GenesisDBError.configurationError("Auth token is required")
        }

        self.config = config

        // Configure URL session
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = config.timeout
        sessionConfig.timeoutIntervalForResource = config.timeout
        self.session = URLSession(configuration: sessionConfig)

        // Configure JSON encoder/decoder
        self.jsonEncoder = JSONEncoder()
        self.jsonDecoder = JSONDecoder()

        // Configure date formatting
        jsonEncoder.dateEncodingStrategy = .iso8601
        jsonDecoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Public Methods

    /// Stream events for a given subject
    /// - Parameter subject: The subject to stream events for
    /// - Returns: Array of events
    public func streamEvents(subject: String) async throws -> [Event] {
        let url = buildURL(path: "stream")
        let body = ["subject": subject]

        let request = try buildRequest(
            url: url,
            method: "POST",
            body: body,
            acceptHeader: "application/x-ndjson"
        )

        let (data, response) = try await session.data(for: request)

        try validateResponse(response)

        return try parseNDJSON(data: data)
    }

    /// Commit events to the database
    /// - Parameter events: Array of events to commit
    public func commitEvents(_ events: [Event]) async throws {
        let url = buildURL(path: "commit")

        // Prepare events with default values
        var preparedEvents = events
        for i in 0..<preparedEvents.count {
            if preparedEvents[i].id == nil {
                preparedEvents[i] = Event(
                    id: UUID().uuidString,
                    source: preparedEvents[i].source ?? config.apiURL,
                    subject: preparedEvents[i].subject,
                    type: preparedEvents[i].type,
                    time: preparedEvents[i].time ?? RFC3339Time(Date()),
                    data: preparedEvents[i].data,
                    dataContentType: preparedEvents[i].dataContentType ?? "application/json",
                    specVersion: preparedEvents[i].specVersion ?? "1.0"
                )
            }
        }

        let body = ["events": preparedEvents]
        let request = try buildRequest(url: url, method: "POST", body: body)

        let (_, response) = try await session.data(for: request)

        try validateResponse(response)
    }

    /// Execute a query
    /// - Parameter query: The query string to execute
    /// - Returns: Array of query results
    public func query(_ query: String) async throws -> [[String: Any]] {
        let url = buildURL(path: "q")
        let body = ["query": query]

        let request = try buildRequest(
            url: url,
            method: "POST",
            body: body,
            acceptHeader: "application/x-ndjson"
        )

        let (data, response) = try await session.data(for: request)

        try validateResponse(response)

        return try parseNDJSONResults(data: data)
    }

    /// Ping the API to check connectivity
    /// - Returns: Ping response string
    public func ping() async throws -> String {
        let url = buildURL(path: "status/ping")
        let request = try buildRequest(url: url, method: "GET")

        let (data, response) = try await session.data(for: request)

        try validateResponse(response)

        guard let responseString = String(data: data, encoding: .utf8) else {
            throw GenesisDBError.invalidResponse("Could not decode response as string")
        }

        return responseString
    }

    /// Get audit information
    /// - Returns: Audit response string
    public func audit() async throws -> String {
        let url = buildURL(path: "status/audit")
        let request = try buildRequest(url: url, method: "GET")

        let (data, response) = try await session.data(for: request)

        try validateResponse(response)

        guard let responseString = String(data: data, encoding: .utf8) else {
            throw GenesisDBError.invalidResponse("Could not decode response as string")
        }

        return responseString
    }

    // MARK: - Private Methods

    private func buildURL(path: String) -> URL {
        let baseURL = config.apiURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let urlString = "\(baseURL)/api/\(config.apiVersion)/\(path)"
        return URL(string: urlString)!
    }

    private func buildRequest(
        url: URL,
        method: String,
        body: [String: Any]? = nil,
        acceptHeader: String? = nil
    ) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(config.authToken)", forHTTPHeaderField: "Authorization")
        request.setValue(config.userAgent, forHTTPHeaderField: "User-Agent")
        
        if let acceptHeader = acceptHeader {
            request.setValue(acceptHeader, forHTTPHeaderField: "Accept")
        }
        
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Check if body contains events array
            if let events = body["events"] as? [Event] {
                // Use JSONEncoder for Event arrays
                let eventsBody = ["events": events]
                request.httpBody = try jsonEncoder.encode(eventsBody)
            } else {
                // Use JSONSerialization for simple dictionaries
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
            }
        }
        
        return request
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GenesisDBError.invalidResponse("Response is not an HTTP response")
        }

        guard httpResponse.statusCode == 200 else {
            throw GenesisDBError.apiError(httpResponse.statusCode, "HTTP \(httpResponse.statusCode)")
        }
    }

    private func parseNDJSON(data: Data) throws -> [Event] {
        guard let string = String(data: data, encoding: .utf8) else {
            throw GenesisDBError.invalidResponse("Could not decode response as string")
        }

        let lines = string.components(separatedBy: .newlines)
        var events: [Event] = []

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedLine.isEmpty else { continue }

            do {
                let eventData = trimmedLine.data(using: .utf8)!
                let event = try jsonDecoder.decode(Event.self, from: eventData)

                // Set default values if not provided
                var finalEvent = event
                if finalEvent.id == nil {
                    finalEvent = Event(
                        id: UUID().uuidString,
                        source: finalEvent.source ?? config.apiURL,
                        subject: finalEvent.subject,
                        type: finalEvent.type,
                        time: finalEvent.time ?? RFC3339Time(Date()),
                        data: finalEvent.data,
                        dataContentType: finalEvent.dataContentType ?? "application/json",
                        specVersion: finalEvent.specVersion ?? "1.0"
                    )
                }

                events.append(finalEvent)
            } catch {
                throw GenesisDBError.jsonError(error)
            }
        }

        return events
    }

    private func parseNDJSONResults(data: Data) throws -> [[String: Any]] {
        guard let string = String(data: data, encoding: .utf8) else {
            throw GenesisDBError.invalidResponse("Could not decode response as string")
        }

        let lines = string.components(separatedBy: .newlines)
        var results: [[String: Any]] = []

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedLine.isEmpty else { continue }

            do {
                let resultData = trimmedLine.data(using: .utf8)!
                let result = try JSONSerialization.jsonObject(with: resultData)

                if let dict = result as? [String: Any] {
                    results.append(dict)
                } else {
                    results.append(["result": result])
                }
            } catch {
                throw GenesisDBError.jsonError(error)
            }
        }

        return results
    }
}
