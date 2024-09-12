import Foundation
import Hummingbird
import Logging
import Mustache
import OracleNIO

struct HTML: ResponseGenerator {
    let html: String
    
    public func response(from request: Request, context: some RequestContext) throws -> Response {
        let buffer = ByteBuffer(string: self.html)
        return .init(status: .ok, headers: [.contentType: "text/html"], body: .init(byteBuffer: buffer))
    }
}

struct WebsitesController {
    
    let mustacheLibrary: MustacheLibrary
    let client: OracleClient
    let logger: Logger
    
    func addRoutes(to router: Router<some RequestContext>) {
        router.get("/", use: self.index)
    }
    
    @Sendable
    func index(request: Request, context: some RequestContext) async throws -> HTML {
        var parks = [ParkContext]()
        try await client.withConnection { conn in
            let rows = try await conn.execute(
                """
                    SELECT
                        p.id,
                        p.name,
                        p.address,
                        p.geometry.SDO_POINT.X AS longitude,
                        p.geometry.SDO_POINT.Y AS latitude
                    FROM
                        spatialparks p
                """)
            
            for try await (id, name, address, latitude, longitude) in rows
                .decode((UUID, String, String, Double, Double).self)
            {
                let park = ParkContext(id: id,
                                name: name,
                                address: address,
                                latitude: latitude,
                                longitude: longitude)
                parks.append(park)
            }
        }
        
//        let parkContext = ParkContext(name: "Letenské sady", latitude: 50.0959721, longitude: 14.4202892)
//        let parkContext2 = ParkContext(name: "Žernosecká - Čumpelíkova", latitude: 50.132259369, longitude: 14.46098423)
        
        let context = IndexContext(park: parks)
        guard let html = self.mustacheLibrary.render(context, withTemplate: "index") else {
            throw HTTPError(.internalServerError, message: "Failed to render template.")
        }
        return HTML(html: html)
    }
}

struct IndexContext {
    let park: [ParkContext]
}

struct ParkContext {
    let id: UUID?
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
}
