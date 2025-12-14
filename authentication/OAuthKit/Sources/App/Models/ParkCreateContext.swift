import Hummingbird

struct ParkCreateContext {
    let title: String
    let userContext: UserContext?
    
    init(title: String, userContext: UserContext? = nil) {
        self.title = title
        self.userContext = userContext
    }
}

extension ParkCreateContext: ResponseCodable {}
