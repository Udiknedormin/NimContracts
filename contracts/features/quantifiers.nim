#
# Declarative programming
#

proc getForLoopElems(code: NimNode): (NimNode, NimNode) =
  ## Get ``for`` statement's container and element
  if code.kind != nnkInfix or code[0] != ident("in") or code.len != 3:
    error("`X in Y` notation expected, found: $1".format(code.repr))
  result = (code[1], code[2])

macro forsome* (what, cond: untyped): untyped =
  ## For-like existential quantifier with natural syntax.
  ## It works similar to
  ## `sequtils.any <http://nim-lang.org/docs/sequtils.html#any>`_
  ## but is more generic.
  ##
  ## .. code-block:: nim
  ##  require:
  ##    forsome x in arr: x == key
  let (first, second) = getForLoopElems(what)
  template forImpl(fi, sec, cond) =
    block:
      var flag = false
      for fi in sec:
        if cond:
          flag = true
          break
      flag
  result = getAst(forImpl(first, second, cond))

macro forall* (what, cond: untyped): untyped =
  ## For-like universal quantifier with natural syntax.
  ## It works similar to
  ## `sequtils.all <http://nim-lang.org/docs/sequtils.html#all>`_
  ## but is more generic.
  ##
  ## .. code-block:: nim
  ##  require:
  ##    forall x in arr: x > 0
  let (first, second) = getForLoopElems(what)
  template forImpl(fi, sec, cond) =
    block:
      var flag = true
      for fi in sec:
        if not cond:
          flag = false
          break
      flag
  result = getAst(forImpl(first, second, cond))
