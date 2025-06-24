import Foundation
import Hummingbird

extension ParksController {
  func fileName(for request: Request) throws -> String {
    guard let fileName = request.headers[.fileName] else {
        throw HTTPError(.badRequest, message: "The filename is missing from the Header.")
    }
    return fileName
  }
}
