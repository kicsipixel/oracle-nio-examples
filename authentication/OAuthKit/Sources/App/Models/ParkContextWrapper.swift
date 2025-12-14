import Hummingbird

struct ParkContextWrapper {
    let title: String
    let parkContext: ParkContext
    let userContext: UserContext?

    init(title: String, parkContext: ParkContext, userContext: UserContext? = nil) {
        self.title = title
        self.parkContext = parkContext
        self.userContext = userContext
    }
}

typealias ParkEditContext = ParkContextWrapper
typealias ParkShowContext = ParkContextWrapper
