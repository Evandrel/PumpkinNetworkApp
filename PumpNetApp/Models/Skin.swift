import Foundation

struct MinecraftSkin: Sendable {
    enum Model: String, Sendable {
        case classic = "Classic"
        case slim = "Slim"
    }

    let username: String
    let profileID: String
    let model: Model
    let imageData: Data

    var filename: String {
        let safeName = username.replacingOccurrences(
            of: "[^A-Za-z0-9_-]",
            with: "_",
            options: .regularExpression
        )
        return "\(safeName)-skin.png"
    }
}
