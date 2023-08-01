/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation

typealias CommandList = [String: [String]]

/// Returns the list of allowed commands, or nil if none exist.
func getCommandList() -> CommandList? {
  if let obj = UserDefaults(suiteName: "com.facebook.cpe.Sado")?.object(forKey: "ValidCommands") {
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
