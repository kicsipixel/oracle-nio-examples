import Hummingbird

struct UserContext: Codable {
    let userId: String
    let email: String
    let givenName: String?

    init(userId: String, email: String, givenName: String? = "My Friend") {
        self.userId = userId
        self.email = email
        self.givenName = givenName
    }
}
