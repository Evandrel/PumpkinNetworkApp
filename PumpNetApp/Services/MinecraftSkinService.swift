import Foundation

actor MinecraftSkinService {
    enum ServiceError: LocalizedError, Equatable {
        case invalidUsername
        case playerNotFound
        case missingSkin
        case invalidResponse
        case serverError

        var errorDescription: String? {
            switch self {
            case .invalidUsername:
                "Enter a valid Minecraft Java username."
            case .playerNotFound:
                "That Minecraft player could not be found."
            case .missingSkin:
                "This player does not have an available skin."
            case .invalidResponse:
                "Minecraft returned an unexpected response."
            case .serverError:
                "Minecraft's services are unavailable right now."
            }
        }
    }

    private struct Profile: Decodable {
        let id: String
        let name: String
    }

    private struct SessionProfile: Decodable {
        struct Property: Decodable {
            let name: String
            let value: String
        }

        let properties: [Property]
    }

    private struct TexturesPayload: Decodable {
        struct Textures: Decodable {
            struct Skin: Decodable {
                struct Metadata: Decodable {
                    let model: String?
                }

                let url: URL
                let metadata: Metadata?
            }

            let skin: Skin

            enum CodingKeys: String, CodingKey {
                case skin = "SKIN"
            }
        }

        let textures: Textures
    }

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchSkin(for rawUsername: String) async throws -> MinecraftSkin {
        let username = rawUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        guard username.range(of: #"^[A-Za-z0-9_]{1,16}$"#, options: .regularExpression) != nil else {
            throw ServiceError.invalidUsername
        }

        let profileURL = URL(string: "https://api.mojang.com/users/profiles/minecraft/\(username)")!
        let (profileData, profileResponse) = try await session.data(from: profileURL)
        guard let profileHTTPResponse = profileResponse as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }
        guard profileHTTPResponse.statusCode != 204 && profileHTTPResponse.statusCode != 404 else {
            throw ServiceError.playerNotFound
        }
        guard (200...299).contains(profileHTTPResponse.statusCode) else {
            throw ServiceError.serverError
        }

        let profile: Profile
        do {
            profile = try JSONDecoder().decode(Profile.self, from: profileData)
        } catch {
            throw ServiceError.invalidResponse
        }

        let sessionURL = URL(string: "https://sessionserver.mojang.com/session/minecraft/profile/\(profile.id)")!
        let (sessionData, sessionResponse) = try await session.data(from: sessionURL)
        try validate(sessionResponse)

        let sessionProfile: SessionProfile
        do {
            sessionProfile = try JSONDecoder().decode(SessionProfile.self, from: sessionData)
        } catch {
            throw ServiceError.invalidResponse
        }

        guard
            let textureValue = sessionProfile.properties.first(where: { $0.name == "textures" })?.value,
            let decodedTextureData = Data(base64Encoded: textureValue),
            let payload = try? JSONDecoder().decode(TexturesPayload.self, from: decodedTextureData)
        else {
            throw ServiceError.missingSkin
        }

        var skinURL = payload.textures.skin.url
        if skinURL.scheme == "http",
           var components = URLComponents(url: skinURL, resolvingAgainstBaseURL: false) {
            components.scheme = "https"
            if let secureURL = components.url {
                skinURL = secureURL
            }
        }

        let (imageData, imageResponse) = try await session.data(from: skinURL)
        try validate(imageResponse)
        guard !imageData.isEmpty else {
            throw ServiceError.missingSkin
        }

        let model: MinecraftSkin.Model = payload.textures.skin.metadata?.model == "slim" ? .slim : .classic
        return MinecraftSkin(
            username: profile.name,
            profileID: profile.id,
            model: model,
            imageData: imageData
        )
    }

    private func validate(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw ServiceError.serverError
        }
    }
}
