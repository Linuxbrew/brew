#!/usr/bin/swift

import Foundation

struct swifterr: TextOutputStream {
  public static var stream = swifterr()
  mutating func write(_ string: String) { fputs(string, stderr) }
}

if #available(macOS 10.10, *) {
  if (CommandLine.arguments.count < 4) {
    exit(2)
  }

  let dataLocationUrl: NSURL = NSURL.init(fileURLWithPath: CommandLine.arguments[1])

  var errorBag: NSError?

  let quarantineProperties: [String: Any] = [
    kLSQuarantineAgentNameKey as String: "Homebrew Cask",
    kLSQuarantineTypeKey as String: kLSQuarantineTypeWebDownload,
    kLSQuarantineDataURLKey as String: CommandLine.arguments[2],
    kLSQuarantineOriginURLKey as String: CommandLine.arguments[3]
  ]

  if (dataLocationUrl.checkResourceIsReachableAndReturnError(&errorBag)) {
    do {
      try dataLocationUrl.setResourceValue(
        quarantineProperties as NSDictionary,
        forKey: URLResourceKey.quarantinePropertiesKey
        )
    }
    catch {
      print(error.localizedDescription, to: &swifterr.stream)
      exit(1)
    }
  }
  else {
    print(errorBag!.localizedDescription, to: &swifterr.stream)
    exit(3)
  }

  exit(0)
}
else {
  exit(5)
}
