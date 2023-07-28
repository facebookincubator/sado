// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import ArgumentParser
import Foundation
import os
import System

// Disable some lint checks that don't apply to a CLI
// @patternlint-disable avoid-print-to-prevent-production-overhead

/// Executes the given command and blocks until exit.
///  - Parameters:
///   - executable: Absolute path of executable.
///   - args: Additional arguments to the executable.
private func executeCommand(executable: String, args: [String]) throws {
  try ([executable] + args).withArrayOfCStrings { argv in
    execv(executable, argv)
    // IF we're here, exec exited. Which means sadness.
    let e = Errno(rawValue: errno)
    sadoLogger().log("execve failed: \(e.description, privacy: .public)")
    throw e
  }
}

var standardError = FileHandle.standardError

private func runDisclaimed(executable: String, args: [String]) throws {
  // Don't put execname back in. Its already in args, and it's easiest
  // to just let it be there already
  try (args).withArrayOfCStrings { argv in
    // set the disclaim flag. Only the posix_spawn API is documented
    // so I have to use that, so also set the exec flag
    var attr = posix_spawnattr_t(nil as OpaquePointer?)
    posix_spawnattr_init(&attr)
    posix_spawnattr_setflags(&attr, Int16(POSIX_SPAWN_SETEXEC))
    let handle = dlopen(nil, RTLD_NOW)
    let setdisclaim = dlsym(handle, "responsibility_spawnattrs_setdisclaim")
    if setdisclaim == nil {
      throw NSError(domain: "Failure finding setdisclaim symbol", code: Int(errno))
    }
    typealias SetDisclaimType = @convention(c) (UnsafeMutablePointer<Optional<posix_spawnattr_t> >, Int32) -> Int32
    let responsibility_spawnattrs_setdisclaim: SetDisclaimType = unsafeBitCast(setdisclaim, to: SetDisclaimType.self)
    var rc = responsibility_spawnattrs_setdisclaim(&attr, 1)
    if rc != 0 {
      throw Errno(rawValue: rc)
    }
    rc = posix_spawn(nil, executable, nil, &attr, argv, environ)
    // IF we're here, "exec" returned. Which means sadness.
    throw Errno(rawValue: rc)
  }
}

@main
struct Sado: ParsableCommand {
  // Adding more flags will complicate the run() function, where disclaim is implemented
  static var configuration = CommandConfiguration(
    abstract: "A signed app wrapper.",
    subcommands: [Run.self, RunByName.self, Disclaim.self, ListCommands.self, AddCommand.self, ClearCommands.self],
    defaultSubcommand: RunByName.self)

  static func claimSelf() throws {
    // We want ourself to be the responsible process. Unfortunately the API to do that isn't
    // known to the internet so I have to, instead, disclaim myself. (run the same process again
    // after disclaiming it.
    guard let exec_path = Bundle.main.executablePath else {
      throw ValidationError("Unable to disclaim unknown process")
    }
    var claimed_args: [String] = CommandLine.arguments
    if let index = claimed_args.firstIndex(of: "--claim") {
      claimed_args.remove(at: index)
    }

    try runDisclaimed(executable: exec_path, args: claimed_args )

    throw ValidationError("Unable to spawn self to claim responsibiliy")
  }

  struct Run: ParsableCommand {
    static var configuration = CommandConfiguration(
      abstract: "Run the given executable under our context.")
    @Flag var claim = false
    @Argument var executable: String
    @Argument(parsing: .unconditionalRemaining)
    var args: [String] = []
    func logArgs() {
      sadoLogger().log("executable: \(executable, privacy: .public), args: \(args, privacy: .public)")
    }

    mutating func run() throws {
      if claim {
        try claimSelf()
      }
      // has to be a different, non-mutating function because of the escaping autoclosure behaviour of `Logger()` string interpolation: https://forums.swift.org/t/new-loggers-string-interpolation-requires-explicit-self/40902
      logArgs()

      // first, perform permissions checking
      let command = [executable] + args
      if !isValidCommand(command) {
        sadoLogger().error("Unable to run `\(command, privacy: .public)")
        print("`\(command) not in a valid command", to: &standardError)
        return
      }
      try executeCommand(executable: executable, args: args)
    }
  }

  struct RunByName: ParsableCommand {
    static var configuration = CommandConfiguration(
      abstract: "Run the executable by its shortname.")
    @Flag var claim = false
    @Argument var name: String

    mutating func run() throws {
      if claim {
        try claimSelf()
      }
      let name = name // `name` does not need to be mutable, necessary for logging
      guard let command = getCommandList()?[name] else {
        sadoLogger().error("Was asked to run the `\(name, privacy: .public)` command but it does not exist")
        print("`\(name)` command does not exist", to: &standardError)
        return
      }
      guard let executable = command.first else {
        sadoLogger().info("Command `\(name, privacy: .public)` was empty")
        print("`\(name)` command is empty", to: &standardError)
        return
      }
      try executeCommand(executable: executable, args: Array(command[1...]))
    }
  }

  struct Disclaim: ParsableCommand {
    static var configuration = CommandConfiguration(
      abstract: "Run the following commands after disclaiming responsibility.")

    @Argument var executable: String
    @Argument(parsing: .unconditionalRemaining)

    var args: [String] = []
    func logArgs() {
      sadoLogger().log("disclaim: \(executable, privacy: .public), args: \(args, privacy: .public)")
    }

    mutating func run() throws {
      // has to be a different, non-mutating function because of the escaping autoclosure behaviour
      // of `Logger()` string interpolation:
      // https://forums.swift.org/t/new-loggers-string-interpolation-requires-explicit-self/40902
      logArgs()

      // do NOT perform permissions checking here. This is not granting anything our privileges,
      // and so we care less. And managing an allow-list would prevent this from being used for
      // testing, which is the purpose.
      try runDisclaimed(executable: executable, args: [ executable ] + args )
    }
  }

  struct ListCommands: ParsableCommand {
    static var configuration = CommandConfiguration(
      abstract: "List all allowed commands to run.")
    mutating func run() throws {
      guard let commandList = getCommandList() else {
        print("No available commands.")
        return
      }
      print("Available commands:")
      for (name, command) in commandList {
        print("\(name): \(command)")
      }
    }
  }

  struct AddCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
      abstract: "Add to the list of commands.")

    @Argument var name: String
    @Argument(parsing: .unconditionalRemaining)
    var command: [String]
    mutating func run() throws {
      var commandList: CommandList = getCommandList() ?? [:]
      commandList[name] = command
      setCommandList(commandList)
    }
  }

  struct ClearCommands: ParsableCommand {
    static var configuration = CommandConfiguration(
      abstract: "Clear the user-managed list of commands")
    mutating func run() throws {
      clearCommandList()
    }
  }
}
