import Hummingbird

struct ParkIndexContext {
    let title: String?
    let parksContext: [ParkContext]
    let userContext: UserContext?
    
    init(title: String? = "Parks", parksContext: [ParkContext], userContext: UserContext? = nil) {
        self.title = title
        self.parksContext = parksContext
        self.userContext = userContext
    }
}
