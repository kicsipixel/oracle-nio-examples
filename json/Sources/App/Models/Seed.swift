import Foundation
import Hummingbird

struct Seed: Codable, Sequence {
    let results: [Result]

    func makeIterator() -> IndexingIterator<[Result]> {
        results.makeIterator()
    }
}

struct Result: Codable {
    let name: Name
    let email: String
    let nationality: String
    let hobbies: [String]
    
    enum CodingKeys: String, CodingKey {
        case name, email, hobbies
        case nationality = "nat"
    }
}

struct Name: Codable {
    let title: String
    let firstName: String
    let lastName: String

    enum CodingKeys: String, CodingKey {
        case title
        case firstName = "first"
        case lastName = "last"
    }
}
