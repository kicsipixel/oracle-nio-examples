import Foundation
import Hummingbird

struct URLFormRequestDecoder: RequestDecoder {
    let decoder = URLEncodedFormDecoder()

    func decode<T>(_ type: T.Type, from request: Request, context: some RequestContext) async throws -> T where T: Decodable {
        guard let header = request.headers[.contentType] else { throw HTTPError(.badRequest) }
        guard let mediaType = MediaType(from: header) else { throw HTTPError(.badRequest) }
        switch mediaType {
        case .applicationJson:
            return try await JSONDecoder().decode(type, from: request, context: context)
        case .applicationUrlEncoded:
            return try await URLEncodedFormDecoder().decode(type, from: request, context: context)
        default:
            throw HTTPError(.badRequest)
        }
    }
}
