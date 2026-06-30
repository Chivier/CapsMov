import Foundation

public struct SecureInputOwner: Equatable, Sendable {
    public var pid: Int
    public var name: String
    public var bundleIdentifier: String?

    public init(pid: Int, name: String, bundleIdentifier: String? = nil) {
        self.pid = pid
        self.name = name
        self.bundleIdentifier = bundleIdentifier
    }
}

public struct SecureInputStatus: Equatable, Sendable {
    public var pid: Int
    public var owner: SecureInputOwner?

    public init(pid: Int, owner: SecureInputOwner?) {
        self.pid = pid
        self.owner = owner
    }

    public static func parseIORegistryOutput(_ output: String) -> SecureInputStatus? {
        let marker = "\"kCGSSessionSecureInputPID\"="
        guard let markerRange = output.range(of: marker) else {
            return nil
        }

        let remainder = output[markerRange.upperBound...]
        let digits = remainder.prefix { character in
            character >= "0" && character <= "9"
        }
        guard let pid = Int(digits), pid > 0 else {
            return nil
        }

        return SecureInputStatus(pid: pid, owner: nil)
    }
}
