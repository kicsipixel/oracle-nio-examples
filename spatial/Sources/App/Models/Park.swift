import Foundation
import Hummingbird

struct Park {
    let id: UUID?
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
}

extension Park: ResponseCodable, Equatable {}
