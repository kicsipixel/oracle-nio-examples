import Foundation
import SwiftKaze

public enum CSSSetup {
    public static func compileCSS(
        input: URL,
        output: URL,
        skipIfNotWritable: Bool = false
    ) async throws {
        let outputDir = output.deletingLastPathComponent()

        if skipIfNotWritable {
            let dirExists = FileManager.default.fileExists(atPath: outputDir.path)
            let isWritable = FileManager.default.isWritableFile(atPath: outputDir.path)
            if dirExists && !isWritable {
                return
            }
        }

        try FileManager.default.createDirectory(
            at: outputDir,
            withIntermediateDirectories: true
        )

        let kaze = SwiftKaze()
        try await kaze.run(input: input, output: output, in: URL(filePath: "."))
    }
}
