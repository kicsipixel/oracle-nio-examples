import Foundation
import Hummingbird
import Mustache

struct ErrorMiddleware: RouterMiddleware {
    let mustacheLibrary: MustacheLibrary

    func handle(
        _ request: Request, context: AuthRequestContext, next: (Request, AuthRequestContext) async throws -> Response
    ) async throws -> Response {
        do {
            return try await next(request, context)
        } catch let error as HTTPError {
            // Render a Mustache error page
            let errorContext: [String: Any] = [
                "title": "Error \(error.status.code)",
                "status": error.status.code,
                "message": error.description,
            ]

            if let html = mustacheLibrary.render(errorContext, withTemplate: "error") {
                let buffer = ByteBuffer(string: html)
                return Response(
                    status: error.status,
                    headers: [.contentType: "text/html"],
                    body: .init(byteBuffer: buffer)
                )
            }

            // Fallback plain text
            let buffer = ByteBuffer(string: error.description)
            return Response(
                status: error.status,
                headers: [.contentType: "text/plain"],
                body: .init(byteBuffer: buffer)
            )
        } catch {
            let buffer = ByteBuffer(string: "Unexpected error")
            return Response(
                status: .internalServerError,
                headers: [.contentType: "text/plain"],
                body: .init(byteBuffer: buffer)
            )
        }
    }
}
