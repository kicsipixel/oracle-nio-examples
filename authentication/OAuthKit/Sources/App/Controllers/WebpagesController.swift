import Hummingbird
import Mustache

struct WebpagesController {
    struct HTML: ResponseGenerator {
        let html: String

        public func response(from request: Request, context: some RequestContext) throws -> Response
        {
            let buffer = ByteBuffer(string: self.html)
            return .init(
                status: .ok, headers: [.contentType: "text/html"], body: .init(byteBuffer: buffer))
        }
    }

    let mustacheLibrary: MustacheLibrary

    func addRoutes(to group: RouterGroup<some RequestContext>) {
        group
            .get("/", use: indexHandler)
    }

    @Sendable
    func indexHandler(request: Request, context: some RequestContext) async throws -> HTML {
        guard let html = self.mustacheLibrary.render((), withTemplate: "index") else {
            throw HTTPError(.internalServerError, message: "Failed to render template.")
        }

        return HTML(html: html)
    }
}
