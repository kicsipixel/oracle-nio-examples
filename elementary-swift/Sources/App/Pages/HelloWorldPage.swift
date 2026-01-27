import Elementary

struct HelloWorldPage: HTMLDocument {
  var title = "Hello"

  var head: some HTML {
    meta(.name(.description), .content("Typesafe HTML in modern Swift"))
    meta(.charset(.utf8))
    meta(.name(.viewport), .content("width=device-width, initial-scale=1.0"))
    link(.rel(.stylesheet), .href("/styles/app.css"))
  }

  var body: some HTML {
    main {
      div(.class("min-h-screen flex items-center justify-center")) {
        h1(.class("text-2xl  text-green-900 font-bold")) { "Hello, World! 🌍" }
      }
    }
  }
}
