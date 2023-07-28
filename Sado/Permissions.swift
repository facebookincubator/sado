// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import Foundation

typealias CommandList = [String: [String]]

/// Returns the list of allowed commands, or nil if none exist.
func getCommandList() -> CommandList? {
  if let obj = UserDefaults().object(forKey: "ValidCommands") {
    if let list = obj as? CommandList {
      return list
    }
    // we try to log the object as an NSObject but if we can't we give up
    if let nsObject = obj as? NSObject {
      sadoLogger().error("Unable to cast `\(nsObject, privacy: .public)` to CommandList")
    }
  } else {
    sadoLogger().warning("Unable to find UserDefaults key for `ValidCommands`")
  }
  return nil
}

/// Sets the list of allowed commands.
func setCommandList(_ commandList: CommandList) {
  UserDefaults.standard.set(commandList as NSDictionary, forKey: "ValidCommands")
}

/// Clears the list of allowed commands.
func clearCommandList() {
  UserDefaults.standard.removeObject(forKey: "ValidCommands")
}

/// Returns true if the given command is allowed or if no rules exist
func isValidCommand(_ command: [String]) -> Bool {
  getCommandList()?.values.contains(command) ?? true
}
