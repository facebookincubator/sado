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
import os

extension Bundle {
  /// The localized name of the app bundle.
  var displayName: String? {
    return object(forInfoDictionaryKey: "CFBundleDisplayam") as? String ??
      object(forInfoDictionaryKey: "CFBundleName") as? String
  }
}

extension Array where Element == String {
  public func withArrayOfCStrings<R>(
    _ body: ([UnsafeMutablePointer<CChar>?]) throws -> R
  ) rethrows -> R {
    let cStrings = self.map { strdup($0) }
    defer { cStrings.forEach { free($0) } }
    return try body(cStrings + [nil])
  }
}

// Make it easier to use stderr/stdout for a CLI
extension FileHandle: TextOutputStream {
  public func write(_ string: String) {
    let data = Data(string.utf8)
    self.write(data)
  }
}

/// Returns a logger for the Sado project.
func sadoLogger(category: String = "default") -> Logger {
  return Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.facebook.cpe.Sado", category: category)
}
