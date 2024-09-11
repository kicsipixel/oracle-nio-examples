import Foundation
import Hummingbird

struct Seed: Codable, Sequence {
    let features: [Feature]

    struct Feature: Codable {
        let geometry: Geometry
        let properties: Properties
    }

    func makeIterator() -> IndexingIterator<[Feature]> {
        features.makeIterator()
    }
}

struct Geometry: Codable {
    let coordinates: [Double]
}

struct Properties: Codable {
    let address: Address
    let name: String
}

struct Address: Codable {
    let addressFormatted: String

    enum CodingKeys: String, CodingKey {
        case addressFormatted = "address_formatted"
    }
}
