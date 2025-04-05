import Foundation
import Hummingbird

struct Person {
  let id: UUID?
  let details: Details

  struct Details: Codable {
    let name: Name
    let email: String
    let nationality: String
    let hobbies: [String]
  }
}

extension Person: ResponseCodable {}
