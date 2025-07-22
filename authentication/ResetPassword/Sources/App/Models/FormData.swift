import Hummingbird

struct FormData: ResponseCodable {
  let password: String
  let confirmPassword: String
  let tokenValue: String

  enum CodingKeys: String, CodingKey {
    case password, tokenValue
    case confirmPassword = "confirm_password"
  }
}
