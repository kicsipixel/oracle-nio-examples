import Hummingbird
import HummingbirdAuth

/// `SessionContext` type, which holds the session data for the current request
struct AuthRequestContext: SessionRequestContext {
    init(source: Hummingbird.ApplicationRequestContextSource) {
        self.coreContext = CoreRequestContextStorage(source: source)
        self.sessions = SessionContext<AuthSession>()
    }

    /// core context
    public var coreContext: CoreRequestContextStorage

    /// session context with String as the session object
    public var sessions: SessionContext<AuthSession>

    /// Request decoder that can decode URL-encoded forms
    var requestDecoder: URLFormRequestDecoder { .init() }
}
