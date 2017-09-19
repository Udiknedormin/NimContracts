#
# Ghost code-related
#

template ghostly(): untyped =
  ## The conditions which should be fulfilled for ghost code
  ## to be turned on.
  compileOption("assertions")

template ghost*(code: untyped): untyped =
  ## Marks `ghost code`, only used for tests and static analysis.
  ## It can be turned on or off by ``assertions`` compiler flag.
  ## Example:
  ##
  ## .. code-block:: nim
  ##  ghost:
  ##    var Gflag: bool = true
  ##
  ##  contractual:
  ##    proc safeOpen() =
  ##      require:   Gflag
  ##      ensure:  not Gflag
  ##      body:       ...
  ##
  ##    proc safeClose() =
  ##      require: not Gflag
  ##      ensure:    Gflag
  ##      body:       ...
  ##
  ##  safeOpen()   # valid if contracts fulfilled
  ##  # another safeOpen() would be invalid
  ##  safeClose()  # valid, ready for another safeOpen()
  ##
  ## As both ghost code and contracts are assertion-lived,
  ## release code will be equivalent to:
  ##
  ## .. code-block:: nim
  ##  proc safeOpen()  = ...
  ##  proc safeClose() = ...
  ##
  ##  safeOpen()
  ##  safeClose()
  ##
  ## Ghost code should only be used in other ghost code,
  ## contracts or any other assertion-lived code.
  when ghostly:
    code

template ghost*(code1, code2: untyped): untyped =
  ## Same as ghost but handles non-ghost context too.
  ## Usage discouraged.
  when ghostly:
    code1
  else:
    code2
