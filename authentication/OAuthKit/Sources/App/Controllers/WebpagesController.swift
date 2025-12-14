import Foundation
import Hummingbird
import Logging
import Mustache
import OracleNIO

struct HTML: ResponseGenerator {
    let html: String

    public func response(from request: Request, context: some RequestContext) throws -> Response {
        let buffer = ByteBuffer(string: self.html)
        return .init(
            status: .ok, headers: [.contentType: "text/html"], body: .init(byteBuffer: buffer))
    }
}

struct WebpagesController {
    let client: OracleClient
    let mustacheLibrary: MustacheLibrary
    let oauthService: OAuthService
    let logger: Logger

    func addRoutes(to group: RouterGroup<AuthRequestContext>) {
        group
            .get("/", use: indexHandler)
            .get("/parks/:id", use: showHandler)
            .get("/login", use: loginPageHandler)
            .get("oauth/google", use: loginHandler)
            .get("oauth/google/callback", use: callbackHandler)
            .get("/logout", use: logoutHandler)
            .add(middleware: RequireAuthMiddleware(client: client, oauthService: oauthService))
            .get("/parks/create", use: createHandler)
            .post("/parks/create", use: createPostHandler)
            .get("/parks/:id/edit", use: editHandler)
            .post("/parks/:id/edit", use: editPostHandler)
            .get("/parks/:id/delete", use: deleteHandler)
    }

    // MARK: - index
    /// Gets all parks from database
    @Sendable
    func indexHandler(request: Request, context: AuthRequestContext) async throws -> HTML {
        var parks = [ParkContext]()
        var ctx: ParkIndexContext

        try await client.withConnection { conn in
            let stream = try await conn.execute(
                """
                SELECT
                   p.id,
                   p.coordinates.SDO_POINT.X AS latitude,
                   p.coordinates.SDO_POINT.Y AS longitude,
                   p.details
                FROM
                  parks p
                """
            )

            for try await (id, latitude, longitude, details) in stream.decode(
                (UUID, Double, Double, OracleJSON<Park.Details>).self)
            {
                parks.append(
                    ParkContext(
                        id: id, name: details.value.name, latitude: latitude, longitude: longitude))
            }
        }

        if let email = context.sessions.session?.email, let userId = context.sessions.session?.userId {
            ctx = ParkIndexContext(parksContext: parks, userContext: UserContext(userId: userId, email: email, givenName: context.sessions.session?.givenName))
        } else {
            ctx = ParkIndexContext(parksContext: parks)
        }

        guard let html = self.mustacheLibrary.render(ctx, withTemplate: "index") else {
            throw HTTPError(.internalServerError, message: "Failed to render template.")
        }

        return HTML(html: html)
    }

    // MARK: - show
    /// Shows a park with specified `id`
    @Sendable
    func showHandler(request: Request, context: AuthRequestContext) async throws -> HTML {
        let id = try context.parameters.require("id", as: String.self)
        let guid = id.replacingOccurrences(of: "-", with: "")
        var park: ParkContext? = nil
        var ctx: ParkShowContext

        try await client.withConnection { conn in
            let stream = try await conn.execute(
                """
                SELECT
                  id,
                   p.coordinates.SDO_POINT.X AS latitude,
                   p.coordinates.SDO_POINT.Y AS longitude,
                   p.details
                FROM
                  parks p
                WHERE id = HEXTORAW(\(guid))
                """
            )

            for try await (id, latitude, longitude, details) in stream.decode(
                (UUID, Double, Double, OracleJSON<Park.Details>).self)
            {
                park = ParkContext(
                    id: id, name: details.value.name, latitude: latitude, longitude: longitude)
            }
        }

        guard let park = park else {
            throw HTTPError(.notFound, message: "Park not found.")
        }

        if let email = context.sessions.session?.email, let userId = context.sessions.session?.userId {
            ctx = ParkShowContext(
                title: "\(park.name)", parkContext: park, userContext: UserContext(userId: userId, email: email, givenName: context.sessions.session?.givenName)
            )
        } else {
            ctx = ParkShowContext(title: "\(park.name)", parkContext: park)
        }

        guard let html = self.mustacheLibrary.render(ctx, withTemplate: "show") else {
            throw HTTPError(.internalServerError, message: "Failed to render template.")
        }

        return HTML(html: html)
    }

    // MARK: - create
    @Sendable
    func createHandler(
        request: Request,
        context: AuthRequestContext
    ) async throws -> HTML {
        var ctx: ParkCreateContext

        if let email = context.sessions.session?.email, let userId = context.sessions.session?.userId {
            ctx = ParkCreateContext(
                title: "New park", userContext: UserContext(userId: userId, email: email, givenName: context.sessions.session?.givenName)
            )
        } else {
            ctx = ParkCreateContext(title: "New park")
        }

        guard let html = self.mustacheLibrary.render(ctx, withTemplate: "create") else {
            throw HTTPError(.internalServerError, message: "Failed to render template.")
        }
        return HTML(html: html)
    }

    @Sendable
    func createPostHandler(request: Request, context: AuthRequestContext) async throws -> Response {
        let data = try await request.decode(as: ParkFromForm.self, context: context)

        guard let userId = context.sessions.session?.userId else {
            throw HTTPError(.unauthorized, message: "You must be logged in to create a park.")
        }

        let detailsJSON = OracleJSON(Park.Details(name: data.name))

        let query: OracleStatement = try
            "INSERT INTO parks (coordinates, details, user_id) VALUES (SDO_GEOMETRY(\(data.latitude), \(data.longitude)), \(detailsJSON), \(userId))"

        _ = try await client.withConnection { conn in
            try await conn.execute(query)
        }

        return Response(
            status: .seeOther,
            headers: [.location: "/"]
        )
    }

    // MARK: - edit
    @Sendable
    func editHandler(request: Request, context: AuthRequestContext) async throws -> HTML {
        let id = try context.parameters.require("id", as: String.self)
        let guid = id.replacingOccurrences(of: "-", with: "")
        var originalPark: Park? = nil
        var ctx: ParkEditContext

        // Find original park
        _ = try await client.withConnection { conn in
            let stream = try await conn.execute(
                """
                SELECT
                  id,
                   p.coordinates.SDO_POINT.X AS latitude,
                   p.coordinates.SDO_POINT.Y AS longitude,
                   p.details,
                   p.user_id
                FROM
                  parks p
                WHERE id = HEXTORAW(\(guid))
                """
            )

            for try await (id, latitude, longitude, details, user_id) in stream.decode(
                (UUID, Double, Double, OracleJSON<Park.Details>, String).self)
            {
                originalPark = Park(
                    id: id, coordinates: Park.Coordinates(latitude: latitude, longitude: longitude),
                    details: Park.Details(name: details.value.name), userId: user_id)
            }
        }

        guard let originalPark = originalPark else {
            throw HTTPError(.notFound, message: "Park not found.")
        }

        guard let originalParkId = originalPark.id else {
            throw HTTPError(.internalServerError, message: "Original park ID is missing.")
        }

        // Check if the stored entry has the same `user_id` as the the `userId` in the current session
        if originalPark.userId != context.sessions.session?.userId {
            throw HTTPError(.forbidden, message: "You are not allowed to edit this park.")
        }

        let park = ParkContext(
            id: originalParkId,
            name: originalPark.details.name,
            latitude: originalPark.coordinates.latitude,
            longitude: originalPark.coordinates.longitude
        )

        if let email = context.sessions.session?.email, let userId = context.sessions.session?.userId {
            ctx = ParkEditContext(
                title: "\(park.name)", parkContext: park, userContext: UserContext(userId: userId, email: email, givenName: context.sessions.session?.givenName)
            )
        } else {
            ctx = ParkEditContext(title: "\(park.name)", parkContext: park)
        }

        guard let html = self.mustacheLibrary.render(ctx, withTemplate: "edit", reload: true) else {
            throw HTTPError(.internalServerError, message: "Failed to render template.")
        }
        return HTML(html: html)
    }

    @Sendable
    func editPostHandler(request: Request, context: AuthRequestContext) async throws -> Response {
        let id = try context.parameters.require("id", as: String.self)
        let guid = id.replacingOccurrences(of: "-", with: "")
        let data = try await request.decode(as: ParkFromForm.self, context: context)

        let detailsJSON = OracleJSON(Park.Details(name: data.name))

        let query: OracleStatement = try """
        UPDATE parks
        SET coordinates = SDO_GEOMETRY(\(data.latitude), \(data.longitude)),
        details     = \(detailsJSON)
        WHERE id = HEXTORAW(\(guid))
        """

        _ = try await client.withConnection { conn in
            try await conn.execute(query)
        }

        return Response(
            status: .seeOther,
            headers: [.location: "/"]
        )
    }

    // MARK: - delete
    @Sendable func deleteHandler(request: Request, context: AuthRequestContext) async throws -> Response {
        let id = try context.parameters.require("id", as: String.self)
        let guid = id.replacingOccurrences(of: "-", with: "")
        var toBeDeletedParkUserId = ""

        // Find park to be requested to delete
        _ = try await client.withConnection { conn in
            let stream = try await conn.execute(
                """
                SELECT
                   p.user_id
                FROM
                  parks p
                WHERE id = HEXTORAW(\(guid))
                """
            )

            for try await (user_id) in stream.decode((String).self) {
                toBeDeletedParkUserId = user_id
            }
        }

        // Check if the owner wants to delete it
        if toBeDeletedParkUserId != context.sessions.session?.userId {
            throw HTTPError(.forbidden, message: "You are not allowed to delete this park.")
        }

        _ = try await client.withConnection { conn in
            let stream = try await conn.execute(
                """
                DELETE FROM parks
                WHERE id = HEXTORAW(\(guid))
                """
            )

            let deletedRows = try await stream.affectedRows
            if deletedRows == 0 {
                throw HTTPError(.notFound, message: "Park not found.")
            }
        }

        return Response(
            status: .seeOther,
            headers: [.location: "/"]
        )
    }

    // MARK: - Login
    @Sendable
    func loginPageHandler(request: Request, context: AuthRequestContext) async throws -> HTML {
        guard let html = self.mustacheLibrary.render((), withTemplate: "login") else {
            throw HTTPError(.internalServerError, message: "Failed to render template.")
        }

        return HTML(html: html)
    }

    @Sendable
    func loginHandler(_: Request, context: AuthRequestContext) async throws -> Response {
        let state = UUID().uuidString
        let (url, verifier) = try oauthService.generateGoogleAuthURL(state: state)

        if let verifier = verifier {
            let sessionData = AuthSession(state: state, verifier: verifier)
            context.sessions.setSession(sessionData)
        }

        return Response(
            status: .seeOther,
            headers: [.location: url.absoluteString]
        )
    }

    // MARK: - Callback
    @Sendable
    func callbackHandler(request: Request, context: AuthRequestContext) async throws -> Response {
        guard let state = request.uri.queryParameters["state"] else {
            throw HTTPError(.badRequest, message: "Missing state")
        }

        guard let code = request.uri.queryParameters["code"] else {
            throw HTTPError(.badRequest, message: "Missing code")
        }

        guard let verifier = context.sessions.session?.verifier else {
            throw HTTPError(.badRequest, message: "Missing verifier")
        }

        if let savedState = context.sessions.session?.state, savedState != state {
            throw HTTPError(.badRequest, message: "State does not match.")
        }

        let (tokenResponse, _) = try await oauthService.exchangeCode(
            code: String(code),
            codeVerifier: verifier
        )

        let profile = try await oauthService.getUserProfile(
            accessToken: tokenResponse.accessToken
        )

        guard let email = profile.email, let userId = profile.sub?.value else {
            throw HTTPError(.internalServerError, message: "Cannot get profile details.")
        }

        // Save token to DB
        // Before save if the user already exists, update the refresh token
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

            let queryRows = try await stream.affectedRows

            if queryRows > 0 {
                let updateQuery: OracleStatement = """
                    UPDATE tokens
                    SET refresh_token = \(tokenResponse.refreshToken), 
                        modified_at = CURRENT_TIMESTAMP
                    WHERE user_id = \(userId)
                    """
                try await conn.execute(updateQuery)
            } else {
                let query: OracleStatement =
                    "INSERT INTO tokens (user_id, email, refresh_token) VALUES (\(userId), \(email), \(tokenResponse.refreshToken))"
                try await conn.execute(query)
            }
        }

        // Create new session
        let sessionData = AuthSession(
            state: String(state), verifier: verifier, userId: userId, email: email, givenName: profile.givenName,
            refreshToken: tokenResponse.refreshToken)
        context.sessions.setSession(sessionData)

        // Issue identity cookie
        let identityCookie = Cookie(
            name: "UserId",
            value: userId,
            path: "/",
            secure: true,
            httpOnly: true,
            sameSite: .lax
        )

        var headers: HTTPFields = [.location: "/"]
        headers[.setCookie] = identityCookie.description

        return Response(
            status: .seeOther,
            headers: headers
        )
    }

    // MARK: - logout
    @Sendable
    func logoutHandler(_: Request, context: AuthRequestContext) async throws -> Response {
        context.sessions.clearSession()

        let expiredUserIdCookie = Cookie(
            name: "UserId",
            value: "",
            maxAge: 0,
            path: "/",
            secure: true,
            httpOnly: true,
            sameSite: .lax,
        )

        var headers: HTTPFields = [.location: "/"]
        headers[.setCookie] = expiredUserIdCookie.description

        return Response(
            status: .seeOther,
            headers: headers
        )
    }
}
