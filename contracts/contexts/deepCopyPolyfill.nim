from macros import error


when declared(deepCopy):
  template systemDeepCopy*(y): untyped = system.deepCopy(y)
  template systemDeepCopy*(x, y) = system.deepCopy(x, y)
elif defined(js):
  const deepCopyPolyfill = staticRead("deepCopyPolyfill.js")
  {.emit: deepCopyPolyfill.}

  proc deepCopy[T](x: var T, y: T) {.importc: "__native_deepCopy".}
  proc deepCopy[T](y: T): T {.importc: "__native_deepCopy".}
  
  {.hint: "Target JS lacks deepCopy. Custom implementation used instead.".}

  template systemDeepCopy*(y): untyped = deepCopy(y)
  template systemDeepCopy*(x, y) = deepCopy(x, y)
else:
  {.warning:
    "Target does not support deepCopy. 'Old values' feature cannot be used."
  .}

  template systemDeepCopy*(y): untyped =
    error: "Target does not support deepCopy, but 'old values' used!"
    y
  template systemDeepCopy*(x, y) =
    error: "Target does not support deepCopy, but 'old values' used!"
    x = y
