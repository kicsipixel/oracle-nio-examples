import Elementary

extension MainLayout: Sendable where Body: Sendable {}
struct MainLayout<Body: HTML>: HTMLDocument {
  var title: String
  @HTMLBuilder var pageContent: Body

  var head: some HTML {
    meta(.charset(.utf8))
    meta(.name(.viewport), .content("width=device-width, initial-scale=1.0"))
    link(.rel(.stylesheet), .href("/styles/app.css"))
  }

  var body: some HTML {
    div(.class("min-h-screen flex flex-col")) {
      Navbar()
      main(.class("flex-1 mx-auto w-full px-32 py-6")) {
        pageContent
      }
      Footer()
    }
  }
}
