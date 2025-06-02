import Foundation
import Hummingbird
import HummingbirdAuth
import HummingbirdBcrypt
import OracleNIO

struct BasicAuthenticator<Context: AuthRequestContext>: AuthenticatorMiddleware where Context.Identity == User {
    let client: OracleClient
    
    func authenticate(request: Request, context: Context) async throws -> User? {
        guard let basic = request.headers.basic else {
            return nil
        }
        
        return try await client.withConnection { conn in
            let stream = try await conn.execute(
        """
        SELECT
          id,
          nickname,
          email,
          password,
          created_at
        FROM
          users
        WHERE email = \(basic.username)
        """
            )
            
            for try await (id, nickname, email, password, created_at) in stream.decode((UUID, String, String, String, Date).self) {
                let user = User(
                    id: id,
                    nickname: nickname,
                    email: email,
                    password: password,
                    createdAt: created_at
                )
                
                // Check if the password is correct
                if Bcrypt.verify(basic.password, hash: user.password) {
                    return user
                }
            }
            return nil
        }
    }
}
