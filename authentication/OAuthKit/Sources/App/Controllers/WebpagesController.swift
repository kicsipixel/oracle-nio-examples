import Foundation
import Hummingbird
import Mustache
import OracleNIO

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

    let client: OracleClient
    let mustacheLibrary: MustacheLibrary

    func addRoutes(to group: RouterGroup<some RequestContext>) {
        group
            .get("/", use: indexHandler)
    }

    @Sendable
    func indexHandler(request: Request, context: some RequestContext) async throws -> HTML {
        var parks = [ParkContext]()

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

        let ctx = ParkIndexContext(parksContext: parks)

        guard let html = self.mustacheLibrary.render(ctx, withTemplate: "index") else {
            throw HTTPError(.internalServerError, message: "Failed to render template.")
        }

        return HTML(html: html)
    }
}
