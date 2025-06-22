import Foundation

/// Errors that can occur when using the GenesisDB SDK
public enum GenesisDBError: LocalizedError {
    /// Configuration error
    case configurationError(String)

    /// Network error
    case networkError(Error)

    /// API error with status code and message
    case apiError(Int, String)

    /// JSON encoding/decoding error
    case jsonError(Error)

    /// Invalid response format
    case invalidResponse(String)

    /// Missing required field
    case missingField(String)

    /// Custom error
    case custom(String)

    public var errorDescription: String? {
        switch self {
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let statusCode, let message):
            return "API error (\(statusCode)): \(message)"
        case .jsonError(let error):
            return "JSON error: \(error.localizedDescription)"
        case .invalidResponse(let message):
            return "Invalid response: \(message)"
        case .missingField(let field):
            return "Missing required field: \(field)"
        case .custom(let message):
            return message
        }
    }
}
