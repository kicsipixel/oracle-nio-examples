import Foundation
import Hummingbird

struct ParkContext {
    let id: UUID
    let name: String
    let latitude: Double
    let longitude: Double

    init(id: UUID, name: String, latitude: Double, longitude: Double) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }
}
