import Foundation

public enum CapsMovRelease {
  public static let currentVersion = "0.2.0"
  public static let repository = "Chivier/CapsMov"
  public static let releasesURL = URL(string: "https://github.com/Chivier/CapsMov/releases")!
  public static let latestReleaseAPIURL = URL(
    string: "https://api.github.com/repos/Chivier/CapsMov/releases/latest")!
}

public struct CapsMovVersion: Comparable, Equatable, Sendable {
  private let components: [Int]

  public init?(_ value: String) {
    let normalized =
      value
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .trimmingPrefix("v")
      .split(separator: "-", maxSplits: 1)
      .first

    guard let normalized else {
      return nil
    }

    let components = normalized.split(separator: ".").compactMap { Int($0) }
    guard !components.isEmpty,
      components.count == normalized.split(separator: ".").count
    else {
      return nil
    }
    self.components = components
  }

  public static func < (lhs: CapsMovVersion, rhs: CapsMovVersion) -> Bool {
    let count = max(lhs.components.count, rhs.components.count)
    for index in 0..<count {
      let left = index < lhs.components.count ? lhs.components[index] : 0
      let right = index < rhs.components.count ? rhs.components[index] : 0
      if left != right {
        return left < right
      }
    }
    return false
  }

  public static func == (lhs: CapsMovVersion, rhs: CapsMovVersion) -> Bool {
    !(lhs < rhs) && !(rhs < lhs)
  }
}

public struct CapsMovReleaseAsset: Decodable, Equatable, Sendable {
  public let name: String
  public let downloadURL: URL

  enum CodingKeys: String, CodingKey {
    case name
    case downloadURL = "browser_download_url"
  }
}

public struct CapsMovGitHubRelease: Decodable, Equatable, Sendable {
  public let tagName: String
  public let pageURL: URL
  public let assets: [CapsMovReleaseAsset]

  enum CodingKeys: String, CodingKey {
    case tagName = "tag_name"
    case pageURL = "html_url"
    case assets
  }

  public var version: CapsMovVersion? {
    CapsMovVersion(tagName)
  }

  public var displayVersion: String {
    String(tagName.trimmingPrefix("v"))
  }

  public var preferredDownloadURL: URL {
    assets.first { $0.name.lowercased().hasSuffix(".dmg") }?.downloadURL ?? pageURL
  }

  public func isNewer(than currentVersion: String) -> Bool {
    guard let version, let current = CapsMovVersion(currentVersion) else {
      return false
    }
    return version > current
  }
}
