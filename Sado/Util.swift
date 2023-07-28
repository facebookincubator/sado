// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

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
