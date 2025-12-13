import Hummingbird

struct ParkIndexContext {
    let title: String?
    let parksContext: [ParkContext]
    
    init(title: String? = "Parks", parksContext: [ParkContext]) {
        self.title = title
        self.parksContext = parksContext
    }
}
