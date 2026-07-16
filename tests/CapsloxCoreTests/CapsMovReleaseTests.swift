import Foundation
import Testing

@testable import CapsloxCore

@Test func versionsCompareNumerically() {
  #expect(CapsMovVersion("v0.2.0")! > CapsMovVersion("0.1.9")!)
  #expect(CapsMovVersion("1.0")! == CapsMovVersion("1.0.0")!)
  #expect(CapsMovVersion("v1.10.0")! > CapsMovVersion("1.9.0")!)
}

@Test func releaseDecodesGitHubPayloadAndPrefersDMG() throws {
  let payload = #"""
    {
      "tag_name": "v0.2.0",
      "html_url": "https://github.com/Chivier/CapsMov/releases/tag/v0.2.0",
      "assets": [
        {
          "name": "CapsMov-0.2.0-macOS.dmg",
          "browser_download_url": "https://example.com/CapsMov-0.2.0-macOS.dmg"
        }
      ]
    }
    """#

  let release = try JSONDecoder().decode(CapsMovGitHubRelease.self, from: Data(payload.utf8))

  #expect(release.displayVersion == "0.2.0")
  #expect(release.isNewer(than: "0.1.0"))
  #expect(!release.isNewer(than: "0.2.0"))
  #expect(
    release.preferredDownloadURL.absoluteString == "https://example.com/CapsMov-0.2.0-macOS.dmg")
}
