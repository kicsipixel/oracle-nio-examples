import Foundation
import Hummingbird

struct URLFormRequestDecoder: RequestDecoder {
  func decode<T: Decodable>(_ type: T.Type, from request: Request, context: some RequestContext) async throws -> T {
    guard let header = request.headers[.contentType],
      let mediaType = MediaType(from: header)
    else {
      throw HTTPError(.badRequest)
    }

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
