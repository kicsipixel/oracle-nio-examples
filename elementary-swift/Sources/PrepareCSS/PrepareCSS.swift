import CSSSetup
import Foundation

@main
struct PrepareCSS {
    static func main() async throws {
      try await CSSSetup.compileCSS(
            input: URL(filePath: "Sources/App/Resources/Styles/app.css"),
            output: URL(filePath: "public/styles/app.css")
        )
    }
}
