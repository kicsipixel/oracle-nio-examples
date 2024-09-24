import Foundation

// MARK: - Filter
struct Filter: Codable {
    let query: [Query]
}

// MARK: - Query
struct Query: Codable {
    let conditions: [Condition]
    let queryOperator: String
    
    enum CodingKeys: String, CodingKey {
        case conditions
        case queryOperator = "operator"
    }
}

// MARK: - Condition
struct Condition: Codable {
    let field, value: String
}
