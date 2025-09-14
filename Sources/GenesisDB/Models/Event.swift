import Foundation

/// Represents an event in the Genesis DB system
public struct Event: Codable {
    /// Unique identifier for the event
    public let id: String?

    /// Source of the event
    public let source: String?

    /// Subject of the event
    public let subject: String

    /// Type of the event
    public let type: String

    /// Timestamp of the event
    public let time: RFC3339Time?

    /// Event data
    public let data: [String: Any]

    /// Content type of the data
    public let dataContentType: String?

    /// Specification version
    public let specVersion: String?

    public let options: [String: Any]?

    public init(
        id: String? = nil,
        source: String? = nil,
        subject: String,
        type: String,
        time: RFC3339Time? = nil,
        data: [String: Any],
        dataContentType: String? = nil,
        specVersion: String? = nil,
        options: [String: Any]? = nil
    ) {
        self.id = id
        self.source = source
        self.subject = subject
        self.type = type
        self.time = time
        self.data = data
        self.dataContentType = dataContentType
        self.specVersion = specVersion
        self.options = options
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case id
        case source
        case subject
        case type
        case time
        case data
        case dataContentType = "datacontenttype"
        case specVersion = "specversion"
        case options
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(String.self, forKey: .id)
        source = try container.decodeIfPresent(String.self, forKey: .source)
        subject = try container.decode(String.self, forKey: .subject)
        type = try container.decode(String.self, forKey: .type)
        time = try container.decodeIfPresent(RFC3339Time.self, forKey: .time)
        dataContentType = try container.decodeIfPresent(String.self, forKey: .dataContentType)
        specVersion = try container.decodeIfPresent(String.self, forKey: .specVersion)

        // Handle data as Any
        let dataValue = try container.decode(AnyCodable.self, forKey: .data)
        if let dict = dataValue.value as? [String: Any] {
            data = dict
        } else {
            data = [:]
        }

        // Handle options
        options = try container.decodeIfPresent([String: AnyCodable].self, forKey: .options)?.mapValues { $0.value }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(source, forKey: .source)
        try container.encode(subject, forKey: .subject)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(time, forKey: .time)
        try container.encode(AnyCodable(data), forKey: .data)
        try container.encodeIfPresent(dataContentType, forKey: .dataContentType)
        try container.encodeIfPresent(specVersion, forKey: .specVersion)
        if let options = options {
            try container.encode(options.mapValues { AnyCodable($0) }, forKey: .options)
        }
    }
}

/// RFC3339 formatted time
public struct RFC3339Time: Codable {
    public let date: Date

    public init(_ date: Date) {
        self.date = date
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: stringValue) {
            self.date = date
        } else {
            // Fallback to standard ISO8601 format
            let standardFormatter = ISO8601DateFormatter()
            if let date = standardFormatter.date(from: stringValue) {
                self.date = date
            } else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Invalid RFC3339 date format: \(stringValue)"
                )
            }
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let stringValue = formatter.string(from: date)
        try container.encode(stringValue)
    }
}

/// Helper struct to encode/decode Any values
private struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "AnyCodable cannot decode value"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            let context = EncodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "AnyCodable cannot encode value of type \(type(of: value))"
            )
            throw EncodingError.invalidValue(value, context)
        }
    }
}
