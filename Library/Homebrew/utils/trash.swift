#!/usr/bin/swift

import Cocoa

DispatchQueue.main.async {
  let arguments = CommandLine.arguments.dropFirst().filter { !$0.isEmpty }
  let URLs = arguments.map { URL(fileURLWithPath: $0) }

  #if swift(>=4.0)
  let workspace = NSWorkspace.shared
  #else
  let workspace = NSWorkspace.shared()
  #endif

  workspace.recycle(URLs) { (dict, error) in
    dict.forEach {
      #if swift(>=4.0)
      let originalPath = $0.0.path
      let trashPath    = $0.1.path
      #else
      let originalPath = $0.path
      let trashPath    = $1.path
      #endif

      print("moved \(originalPath) to \(trashPath)")
    }

    if error == nil {
      exit(0)
    }

    let trashedURLs = dict.keys
    let untrashedURLs = URLs.filter { !trashedURLs.contains($0) }

    untrashedURLs.forEach {
      fputs("could not move \($0.path) to trash\n", stderr)
    }

    exit(1)
  }
}

RunLoop.main.run()
