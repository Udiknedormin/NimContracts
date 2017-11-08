# Package

version       = "0.1.0"
author        = "M. Kotwica"
description   = "Design by contract (DbC) library."
license       = "MIT"
skipDirs      = @["tests"]


# Dependencies

requires "nim >= 0.17.2"


# Tests
import ospaths, sequtils

task tests, "run tests":
  --hints: off
  --linedir: on
  --stacktrace: on
  --linetrace: on
  --debuginfo
  --define:explainContracts
  --path: "."
  --run
  var dir_list = @["tests"]
  while dir_list.len != 0:
    let dir = dir_list.pop
    dir_list.add listDirs(dir)
    if splitPath(dir).tail != "nimcache":
      for file in listFiles(dir):
        var (_, _, ext) = splitFile(file)
        if ext == ".nim":
          echo "running ---- " & file
          setCommand "c", file

task test, "run tests":
  setCommand "tests"
