import Testing

@testable import CapsloxCore

@Test func secureInputStatusParsesPidFromIORegistryOutput() {
  let output = """
      |   "IOConsoleUsers" = ({"kCGSSessionOnConsoleKey"=Yes,"kCGSSessionSecureInputPID"=86543,"kCGSessionLoginDoneKey"=Yes})
    """

  #expect(SecureInputStatus.parseIORegistryOutput(output)?.pid == 86543)
}

@Test func secureInputStatusIgnoresOutputWithoutSecureInputPid() {
  let output = """
      |   "IOConsoleUsers" = ({"kCGSSessionOnConsoleKey"=Yes,"kCGSessionLoginDoneKey"=Yes})
    """

  #expect(SecureInputStatus.parseIORegistryOutput(output) == nil)
}

@Test func processOutputDrainsLargeStdoutBeforeWaitingForExit() {
  let output = ProcessOutput.run(
    executablePath: "/usr/bin/perl",
    arguments: ["-e", "print \"x\" x 200000"]
  )

  #expect(output?.count == 200000)
}

@Test func secureInputStatusDescribesLiveOwner() {
  let status = SecureInputStatus(
    pid: 86543,
    owner: .init(pid: 86543, name: "Google Chrome", bundleIdentifier: "com.google.Chrome")
  )

  #expect(CapsloxPresentation.secureInputStatusTitle == "Secure Input")
  #expect(CapsloxPresentation.secureInputBlockedValue == "Blocked")
  #expect(
    CapsloxPresentation.secureInputDetail(for: status)
      == "Google Chrome is using macOS Secure Input, so CapsMov can't read keys for now. This is expected while a password field is focused—move focus out of it (or quit Google Chrome) and CapsMov resumes on its own."
  )
  #expect(CapsloxPresentation.secureInputActionTitle(for: status) == "Quit Google Chrome")
}

@Test func secureInputStatusDescribesStalePid() {
  let status = SecureInputStatus(pid: 86543, owner: nil)

  #expect(status.isStaleProcess)
  #expect(
    CapsloxPresentation.secureInputDetail(for: status)
      == "macOS is still blocking keyboard monitoring for pid 86543, even though that process has exited. Reset safely locks your Mac; unlock once and CapsMov will recheck automatically."
  )
  #expect(CapsloxPresentation.secureInputActionTitle(for: status) == "Reset…")
}

@Test func secureInputStatusDescribesUnknownOwnerWithoutCallingItStale() {
  let status = SecureInputStatus(pid: 0, owner: nil)

  #expect(!status.isStaleProcess)
  #expect(
    CapsloxPresentation.secureInputDetail(for: status)
      == "macOS Secure Input is active, but the owning app could not be identified. Move focus out of any password field, then refresh."
  )
  #expect(CapsloxPresentation.secureInputActionTitle(for: status) == "Refresh")
}
