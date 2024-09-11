import Foundation
import Hummingbird

/// This allow you to refer to `Resources` and `Public` dirrectory as `app.resourcesDirectory` and `app.publicDirectory`
/// respectively
extension ApplicationProtocol {
    var directory: DefineWorkingDirectory {
        DefineWorkingDirectory.detect()
    }
}

struct DefineWorkingDirectory {
    var workingDirectory: String
    var resourcesDirectory: String
    var publicDirectory: String

    init(workingDirectory: String) {
        self.workingDirectory = workingDirectory + "/"
        self.resourcesDirectory = self.workingDirectory + "Resources/"
        self.publicDirectory = self.workingDirectory + "Public/"
    }

    static func detect() -> DefineWorkingDirectory {
        if let cwd = getcwd(nil, Int(PATH_MAX)) {
            defer { free(cwd) }
            return DefineWorkingDirectory(workingDirectory: String(cString: cwd))
        }
        return DefineWorkingDirectory(workingDirectory: "./")
    }
}
