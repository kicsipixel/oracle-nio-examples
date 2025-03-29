import Foundation
import Hummingbird

struct Park {
  let id: UUID?
  let coordinates: Coordinates
  let details: Details

  struct Coordinates: Codable {
    let latitude: Float
    let longitude: Float
  }

  struct Details: Codable {
    let name: String
  }
}

extension Park: ResponseCodable {}
