import Foundation

/// Configuration for the Genesis DB client
public struct Config {
    /// The URL of the Genesis DB API
    public let apiURL: String

    /// The version of the API to use
    public let apiVersion: String

    /// Authentication token
    public let authToken: String

    /// Optional timeout for requests (default: 30 seconds)
    public let timeout: TimeInterval

    /// Optional custom User-Agent string
    public let userAgent: String

    public init(
        apiURL: String,
        apiVersion: String,
        authToken: String,
        timeout: TimeInterval = 30.0,
        userAgent: String = "genesisdb-sdk"
    ) {
        self.apiURL = apiURL
        self.apiVersion = apiVersion
        self.authToken = authToken
        self.timeout = timeout
        self.userAgent = userAgent
    }

    /// Create configuration from environment variables
    public static func fromEnvironment() throws -> Config {
        guard let apiURL = ProcessInfo.processInfo.environment["GENESISDB_API_URL"] else {
            throw GenesisDBError.configurationError("GENESISDB_API_URL environment variable is required")
        }

        guard let apiVersion = ProcessInfo.processInfo.environment["GENESISDB_API_VERSION"] else {
            throw GenesisDBError.configurationError("GENESISDB_API_VERSION environment variable is required")
        }

        guard let authToken = ProcessInfo.processInfo.environment["GENESISDB_AUTH_TOKEN"] else {
            throw GenesisDBError.configurationError("GENESISDB_AUTH_TOKEN environment variable is required")
        }

        return Config(
            apiURL: apiURL,
            apiVersion: apiVersion,
            authToken: authToken
        )
    }
}
