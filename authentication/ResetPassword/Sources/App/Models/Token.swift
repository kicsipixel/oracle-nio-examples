import Foundation
import Hummingbird

struct Token {
    let id: UUID?
    let tokenValue: String
    let userId: UUID
    let createdAt: Date?
    
    var createdLessThanHalfAnHour: Bool {
    guard let createdAt = createdAt else { return false }
    let now = Date()
    let timezoneOffset =  TimeZone.current.secondsFromGMT()
    let epochDate = now.timeIntervalSince1970
    let timezoneEpochOffset = (epochDate + Double(timezoneOffset))
      
    return timezoneEpochOffset - createdAt.timeIntervalSince1970 < 1800
  }
}

extension Token: ResponseCodable {
    static func generate(for user: User) throws -> Token {
        let random = (1...8).map( {_ in Int.random(in: 0...999)} )
        let tokenString = String(describing: random).toBase64()
        guard let userId = user.id else {
            throw HTTPError(.internalServerError, message: "Something went wrong with associating with the user.")
        }
        return Token(id: nil, tokenValue: tokenString, userId: userId, createdAt: nil)
    }
}
