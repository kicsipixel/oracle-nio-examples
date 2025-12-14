import Foundation
import Hummingbird
import OAuthKit
import OracleNIO

struct RequireAuthMiddleware: RouterMiddleware {
    let client: OracleClient
    let oauthService: OAuthService

    func handle(
        _ request: Request,
        context: AuthRequestContext,
        next: (Request, AuthRequestContext) async throws -> Response
    ) async throws -> Response {

        // If session exists, then continue
        if context.sessions.session != nil {
            return try await next(request, context)
        }

        // Try UID cookie fallback
        if let userCookie = request.cookies["UserId"] {
            let userId = userCookie.value
            // Look up refresh token in persistent store
            var refreshToken: String? = nil

            try await client.withConnection { conn in
                let stream = try await conn.execute(
                    """
                    SELECT
                      refresh_token
                    FROM
                      tokens
                    WHERE user_id = \(userId)
                    """
                )

                for try await (refresh_token) in stream.decode((String).self) {
                    refreshToken = refresh_token
                }
            }

            guard let refreshToken = refreshToken else {
                throw HTTPError(.internalServerError, message: "Cannot get refresh token.")
            }

            // Use refresh token to get new access token
            let (tokenResponse, _) = try await oauthService.refreshAccessToken(refreshToken: refreshToken)

            // Verify new access token
            let profile = try await oauthService.getUserProfile(accessToken: tokenResponse.accessToken)

            guard let email = profile.email, let userId = profile.sub?.value else {
                throw HTTPError(.internalServerError, message: "Cannot get profile.")
            }

            // Rehydrate session
            let newSession = AuthSession(
                state: UUID().uuidString,
                userId: userId,
                email: email,
                givenName: profile.givenName,
                refreshToken: refreshToken,
            )
            context.sessions.setSession(newSession)

            return try await next(request, context)
        }

        //  If none of the above
        throw HTTPError(.unauthorized, message: "authentication is required. Please log in.")
    }
}
