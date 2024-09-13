import Foundation
import Hummingbird

struct FormData: Codable {
    let location: String
    let distance: String
    let unit: Unit

    enum Unit: String, Codable {
        case km
        case mile
    }
}
