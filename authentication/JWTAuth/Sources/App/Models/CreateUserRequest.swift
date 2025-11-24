import Hummingbird

struct CreateUserRequest: Decodable {
  let name: String
  let email: String
  let password: String?

  init(name: String, email: String, password: String?) {
    self.name = name
    self.email = email
    self.password = password
  }
}
