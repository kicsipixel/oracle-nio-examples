import Hummingbird
import Mustache

struct HTML: ResponseGenerator {
    let html: String
    
    public func response(from request: Request, context: some RequestContext) throws -> Response {
        let buffer = ByteBuffer(string: self.html)
        return .init(status: .ok, headers: [.contentType: "text/html"], body: .init(byteBuffer: buffer))
    }
}

struct WebsitesController {
    
    let mustacheLibrary: MustacheLibrary
    
    func addRoutes(to router: Router<some RequestContext>) {
        router.get("/", use: self.index)
    }
    
    @Sendable
    func index(request: Request, context: some RequestContext) async throws -> HTML {
        let parkContext = ParkContext(name: "Letenské sady", latitude: 50.0959721, longitude: 14.4202892)
        let parkContext2 = ParkContext(name: "Žernosecká - Čumpelíkova", latitude: 50.132259369, longitude: 14.46098423)
        
        let context = IndexContext(park: [parkContext, parkContext2])
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
    let name: String
    let latitude: Double
    let longitude: Double
}
