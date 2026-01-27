import Elementary

struct Footer: HTML {
  var body: some HTML {
    footer(.class("px-4 py-4 text-center text-gray-600")) {
      p { "🌳 2026 - Parks of Prague" }
    }
  }
}
