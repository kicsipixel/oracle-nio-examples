import Foundation

/// UUID extension to generate Oracle `SYS_GUID`
extension UUID {
    func generateSysGuid() -> String {
        let uuid = UUID().uuid
        let data = withUnsafeBytes(of: uuid) { Data($0) }
        return data.map { String(format: "%02hhx", $0).uppercased() }.joined()
    }
}
