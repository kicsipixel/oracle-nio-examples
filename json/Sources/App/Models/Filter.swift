import Foundation

struct Filter: Codable {
  let query: [Query]
}

struct Query: Codable {
  let conditions: [Condition]
  let queryOperator: String

  enum CodingKeys: String, CodingKey {
    case conditions
    case queryOperator = "operator"
  }
}

struct Condition: Codable {
  let key: String
  let value: String
}
