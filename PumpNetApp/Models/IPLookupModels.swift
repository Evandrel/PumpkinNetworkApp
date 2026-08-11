import Foundation

enum IPLookupKind: Equatable {
    case addressOnly
    case details
}

struct IPAddressResponse: Decodable {
    let ip: String
}

struct IPInfoResponse: Decodable {
    let ip: String
    let city: String?
    let region: String?
    let country: String?
    let loc: String?
    let org: String?
    let postal: String?
    let timezone: String?
}

enum IPLookupError: LocalizedError {
    case invalidResponse
    var errorDescription: String? { "The IP lookup provider returned an invalid response." }
}
