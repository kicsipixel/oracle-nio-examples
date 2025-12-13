import Hummingbird

struct AuthSession {
    let state: String
    let verifier: String?
    let userId: String?
    let email: String?
    let refreshToken: String?

    init(state: String, verifier: String? = nil, userId: String? = nil, email: String? = nil, refreshToken: String? = nil) {
        self.state = state
        self.verifier = verifier
        self.userId = userId
        self.email = email
        self.refreshToken = refreshToken
    }
}

extension AuthSession: ResponseCodable {}
