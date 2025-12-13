import Foundation
import Hummingbird

struct Park {
    let id: UUID?
    let coordinates: Coordinates
    let details: Details
    let userId: String

    struct Coordinates: Codable {
        let latitude: Double
        let longitude: Double

        init(latitude: Double, longitude: Double) {
            self.latitude = latitude
            self.longitude = longitude
        }
    }

    struct Details: Codable {
        let name: String

        init(name: String) {
            self.name = name
        }
    }

    init(id: UUID?, coordinates: Coordinates, details: Details, userId: String) {
        self.id = id
        self.coordinates = coordinates
        self.details = details
        self.userId = userId
    }
}

extension Park: ResponseCodable {}
