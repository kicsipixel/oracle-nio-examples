import Foundation
import OracleNIO

struct Details: Codable {
  let name: String
  let address: Address
  let email: [String]
  let phone: [String]
  let web: [String]
  let openingHours: [OpeningHour]
}

struct Address: Codable {
  let city: String
  let street: String
  let zip: String
}

struct OpeningHour: Codable {
  let dayOfWeek: String
  let opens: String
  let closes: String

  enum CodingKeys: String, CodingKey {
    case dayOfWeek = "day_of_week"
    case opens, closes
  }
}
