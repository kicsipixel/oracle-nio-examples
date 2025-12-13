import Foundation
import Hummingbird
import OAuthKit

final class OAuthService: Sendable {
    private let oauthClient: OAuthClientFactory
    private let googleProvider: GoogleOAuthProvider

    init() async throws {
        self.oauthClient = OAuthClientFactory()
        let env = try await Environment.dotEnv()
        self.googleProvider = try await oauthClient.googleProvider(
            clientID: env.get("GOOGLE_CLIENT_ID") ?? "N/A",
            clientSecret: env.get("GOOGLE_CLIENT_SECRET") ?? "N/A",
            redirectURI: "http://localhost:8080/oauth/google/callback"
        )
    }

    // Generate a Google Sign-In URL with recommended parameters
    func generateGoogleAuthURL(state: String, loginHint: String? = nil) throws -> (URL, String?) {
        try googleProvider.generateAuthURL(
            state: state,
            prompt: .consent,
            loginHint: "test@test.com",
            scopes: ["profile", "email", "openid"],
        )
    }

    // In your callback handler, after receiving the code from Google:
    func exchangeCode(code: String, codeVerifier: String) async throws -> (
        TokenResponse, IDTokenClaims
    ) {
        // First exchange the code for tokens
        let (token, claims) = try await googleProvider.exchangeCode(
            code: code,
            codeVerifier: codeVerifier
        )

        return (token, claims)
    }

    // Get the user's Google profile info
    func getUserProfile(accessToken: String) async throws -> IDTokenClaims {
        try await googleProvider.getUserProfile(
            accessToken: accessToken
        )
    }

    // Refresh the access token using the refresh token
    func refreshAccessToken(refreshToken: String) async throws -> (TokenResponse, IDTokenClaims?) {
        let (token, claims) = try await googleProvider.refreshAccessToken(
            refreshToken: refreshToken
        )
        return (token, claims)
    }
}
