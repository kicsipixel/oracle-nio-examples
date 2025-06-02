import Hummingbird
import HummingbirdAuth

struct ParksAuthRequestContext: AuthRequestContext, RequestContext {
  var coreContext: CoreRequestContextStorage
  var identity: User?

  init(source: Source) {
    self.coreContext = .init(source: source)
    self.identity = nil
  }
}
