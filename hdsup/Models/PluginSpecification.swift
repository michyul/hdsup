//
//  PluginSpecification.swift
//  hdsup
//
//  API Plugin Specification and Schema
//

import Foundation

// MARK: - Plugin API Specification Version 1.0

/// The standard API response format that all plugins must return
struct PluginAPIResponse: Codable {
    /// API version for compatibility checking
    let apiVersion: String
    
    /// Plugin metadata
    let plugin: PluginMetadata
    
    /// The actual data payload
    let data: PluginDataPayload
    
    /// Optional error information
    let error: PluginError?
    
    /// Response timestamp (ISO 8601 format)
    let timestamp: String
}

/// Plugin metadata returned with each response
struct PluginMetadata: Codable {
    /// Unique plugin identifier (reverse domain notation recommended)
    let id: String
    
    /// Human-readable plugin name
    let name: String
    
    /// Plugin version (semantic versioning)
    let version: String
    
    /// Plugin author/organization
    let author: String
    
    /// Plugin description
    let description: String
    
    /// Plugin icon name (SF Symbol or URL)
    let icon: String
    
    /// Categories this plugin belongs to
    let categories: [String]
    
    /// Refresh interval in seconds (recommended update frequency)
    let refreshInterval: Int
    
    /// Optional plugin homepage URL
    let homepage: String?
}

/// The data payload structure
struct PluginDataPayload: Codable {
    /// Primary metric value
    let value: PluginValue
    
    /// Additional metrics (optional)
    let metrics: [String: PluginValue]?
    
    /// Contextual metadata
    let metadata: [String: String]?
    
    /// Data collection timestamp
    let collectedAt: String
    
    /// Data source information
    let source: DataSourceInfo?
}

/// Flexible value type supporting multiple data types
enum PluginValue: Codable {
    case string(String)
    case number(Double)
    case integer(Int)
    case boolean(Bool)
    case array([String])
    
    var stringValue: String {
        switch self {
        case .string(let str): return str
        case .number(let num): return String(format: "%.2f", num)
        case .integer(let int): return "\(int)"
        case .boolean(let bool): return bool ? "true" : "false"
        case .array(let arr): return arr.joined(separator: ", ")
        }
    }
    
    var numericValue: Double? {
        switch self {
        case .number(let num): return num
        case .integer(let int): return Double(int)
        case .string(let str): return Double(str)
        default: return nil
        }
    }
}

/// Information about the data source
struct DataSourceInfo: Codable {
    /// Source name/identifier
    let name: String
    
    /// Source type (api, database, sensor, etc.)
    let type: String
    
    /// Source location/endpoint
    let location: String?
    
    /// Data freshness in seconds
    let freshnessSeconds: Int?
}

/// Error information structure
struct PluginError: Codable {
    /// Error code
    let code: String
    
    /// Human-readable error message
    let message: String
    
    /// Detailed error description
    let details: String?
    
    /// Whether the error is retryable
    let retryable: Bool
}

// MARK: - Plugin Discovery Response

/// Response format for plugin discovery endpoint
struct PluginDiscoveryResponse: Codable {
    /// API version
    let apiVersion: String
    
    /// List of available plugins at this endpoint
    let plugins: [PluginManifest]
}

/// Plugin manifest for discovery
struct PluginManifest: Codable {
    /// Plugin metadata
    let metadata: PluginMetadata
    
    /// Endpoint path for this plugin (relative to base URL)
    let endpoint: String
    
    /// Authentication requirements
    let authentication: AuthenticationRequirement?
    
    /// Rate limiting information
    let rateLimit: RateLimitInfo?
    
    /// Supported query parameters
    let parameters: [PluginParameter]?
    
    /// Example response
    let exampleResponse: String?
}

/// Authentication requirements
struct AuthenticationRequirement: Codable {
    /// Auth type (none, apikey, bearer, oauth2)
    let type: String
    
    /// Where to include the auth (header, query, body)
    let location: String
    
    /// Parameter/header name
    let parameterName: String?
    
    /// OAuth2 configuration (if applicable)
    let oauth2Config: OAuth2Config?
}

/// OAuth2 configuration
struct OAuth2Config: Codable {
    let authorizationURL: String
    let tokenURL: String
    let scopes: [String]
}

/// Rate limiting information
struct RateLimitInfo: Codable {
    /// Max requests per period
    let maxRequests: Int
    
    /// Time period in seconds
    let periodSeconds: Int
    
    /// Current remaining requests (optional)
    let remaining: Int?
}

/// Query parameter definition
struct PluginParameter: Codable {
    /// Parameter name
    let name: String
    
    /// Parameter type
    let type: String
    
    /// Is required?
    let required: Bool
    
    /// Default value
    let defaultValue: String?
    
    /// Parameter description
    let description: String
    
    /// Allowed values (for enums)
    let allowedValues: [String]?
}

// MARK: - Plugin Configuration

/// Local plugin configuration stored in the app
struct PluginConfiguration: Codable, Identifiable {
    let id: UUID
    
    /// Plugin endpoint URL
    let endpoint: String
    
    /// Plugin metadata (cached from discovery)
    let metadata: PluginMetadata
    
    /// Is this plugin enabled?
    var enabled: Bool
    
    /// Custom refresh interval (overrides plugin recommendation)
    var customRefreshInterval: Int?
    
    /// Authentication configuration
    var authConfig: PluginAuthConfig?
    
    /// Custom parameters
    var parameters: [String: String]?
    
    /// Display preferences
    var displayPreferences: DisplayPreferences?
    
    /// Last successful fetch timestamp
    var lastFetchedAt: Date?
    
    /// Last error
    var lastError: String?
}

/// Authentication configuration stored locally
struct PluginAuthConfig: Codable {
    let type: String
    var apiKey: String?
    var bearerToken: String?
    var oauth2Token: OAuth2Token?
}

/// OAuth2 token storage
struct OAuth2Token: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Date?
}

/// Display preferences for plugin data
struct DisplayPreferences: Codable {
    /// Preferred ornament style
    var ornamentStyle: String? // "compact", "detailed", "minimal"
    
    /// Preferred widget size
    var widgetSize: String? // "small", "medium", "large"
    
    /// Custom color theme
    var colorTheme: String?
    
    /// Custom icon override
    var customIcon: String?
    
    /// Show in ornament positions
    var showInTop: Bool?
    var showInBottom: Bool?
    var showInSide: Bool?
}
