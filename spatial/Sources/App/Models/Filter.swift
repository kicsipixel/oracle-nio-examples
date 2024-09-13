import Foundation
import Hummingbird

struct Filter: Codable {
    let userPosition: Coordinates
    let distance: Float
    let unit: Unit

    struct Coordinates: Codable {
        let latitude: Double
        let longitude: Double
    }

    enum Unit: String, Codable {
        case km
        case mile
    }
}
