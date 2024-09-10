import Foundation
import Hummingbird

struct Park {
    let id: UUID?
    let name: String
    let latitude: Float
    let longitude: Float
}

extension Park: ResponseCodable, Equatable {}
