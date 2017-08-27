#
# Declarative programming
#

template getForLoopElems(code: untyped): untyped =
  ## Get ``for`` statement's container and element
  var
    first  {.inject.}: NimNode
    second {.inject.}: NimNode
  if what.kind == nnkInfix:
    first = what[1]
    second = what[2]
  else:
    first = what[0][2]
    second = what[0][1]

macro some* (what, cond: untyped): untyped =
  ## For-like existential quantifier.
  ## It works similar to ``any`` from
  ## `sequtils <http://nim-lang.org/docs/sequtils.html>`_
  ## module but is more generic.
  getForLoopElems(what)
  let decl = newVarStmt(ident"flag", newLit(false))
  let forStmt = newNimNode(nnkForStmt).
    add(first).
    add(second).
    add(quote do:
      if `cond`:
        flag = true
        break
    )
  result = newBlockStmt(newEmptyNode(),
    newStmtList(decl, forStmt, ident"flag"))

macro each* (what, cond: untyped): untyped =
  ## For-like universal quantifier.
  ## It works similar to ``all`` from
  ## `sequtils <http://nim-lang.org/docs/sequtils.html>`_
  ## module but is more generic.
  getForLoopElems(what)
  let decl = newVarStmt(ident"flag", newLit(true))
  let forStmt = newNimNode(nnkForStmt).
    add(first).
    add(second).
    add(quote do:
      if not `cond`:
        flag = false
        break
    )
  result = newBlockStmt(newEmptyNode(),
    newStmtList(decl, forStmt, ident"flag"))

