import Hummingbird

struct CreateParkForm {
  let name: String
  let latitude: Float
  let longitude: Float
}

extension CreateParkForm: ResponseCodable {}
