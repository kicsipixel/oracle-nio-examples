import Hummingbird

struct RequireAuthMiddleware: RouterMiddleware {
    func handle(
        _ request: Request,
        context: AuthRequestContext,
        next: (Request, AuthRequestContext) async throws -> Response
    ) async throws -> Response {

        // If session exists, then continue
        if context.sessions.session != nil {
            return try await next(request, context)
        }

        //  If it is already expired, throws an error
        throw HTTPError(.unauthorized, message: "authentication is required. Please log in.")
    }
}
