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
    #expect(CapsloxPresentation.secureInputDetail(for: status) == "Keyboard input is blocked by Secure Input from Google Chrome.")
    #expect(CapsloxPresentation.secureInputActionTitle(for: status) == "Quit Google Chrome")
}

@Test func secureInputStatusDescribesStalePid() {
    let status = SecureInputStatus(pid: 86543, owner: nil)

    #expect(CapsloxPresentation.secureInputDetail(for: status) == "macOS still reports Secure Input from pid 86543, but that process is no longer running. Log out and back in if CapsMov still cannot receive keys.")
    #expect(CapsloxPresentation.secureInputActionTitle(for: status) == "Refresh")
}
