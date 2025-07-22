import Hummingbird

struct ForgotPassword {
  let email: String
}

extension ForgotPassword: ResponseCodable {}
