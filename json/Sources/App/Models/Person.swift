import Foundation
import Hummingbird

struct Person: Codable {
    let id: UUID
    let name: Name
    let email: String
    let nationality: String
    let hobbies: [String]
    
    enum CodingKeys: String, CodingKey {
        case id, name, email, hobbies
        case nationality = "nat"
    }
}

extension Person: ResponseCodable { }
