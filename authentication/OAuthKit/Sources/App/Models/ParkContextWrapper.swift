import Hummingbird

struct ParkContextWrapper {
    let title: String
    let parkContext: ParkContext
}

typealias ParkEditContext = ParkContextWrapper
typealias ParkShowContext = ParkContextWrapper
