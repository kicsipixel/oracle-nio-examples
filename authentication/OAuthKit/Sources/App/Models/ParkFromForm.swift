import Hummingbird

struct ParkFromForm {
    let name: String
    let latitude: Double
    let longitude: Double
}

extension ParkFromForm: ResponseCodable {}
