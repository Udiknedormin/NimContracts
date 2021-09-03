
#
# Iterators
#
proc return2breakHelper(code: NimNode): NimNode =
  result = code
  if result.kind == nnkReturnStmt:
    if result[0].kind == nnkEmpty:
      result = newNimNode(nnkBreakStmt).add(ident(keyImpl))
    else:
      result = newStmtList(
        newAssignment(ident"result", result[0][1]),
        newNimNode(nnkBreakStmt).add(ident(keyImpl))
      )
  else:
    for i in 0 ..< result.len:
      result[i] = return2breakHelper(result[i])

proc return2break(code: NimNode): NimNode =
  ## Wrap into 'block body' and adapt 'return' statements.
  result = newNimNode(nnkBlockStmt).
    add(ident(keyImpl)).
    add(return2breakHelper(code))

proc yieldedVar(code: NimNode): NimNode =
  ## Add 'yielded' variable declaration to iterator.
  result = newNimNode(nnkVarSection).
    add(newNimNode(nnkIdentDefs).
      add(ident"yielded").
      add(code.findChild(it.kind == nnkFormalParams)[0]).
      add(newEmptyNode())
    )

proc yield2yielded(code, conds, binds: NimNode): NimNode =
  ## Add 'yielded' variable to the iterator's 'body',
  ## it works similar to 'result' in procs: contains the yielded value.
  result = code

  if result.kind == nnkYieldStmt:
    result = newStmtList(
      newAssignment(ident"yielded", result[0]),
      conds,  # invariant conditions
      binds,  # binds variables for the next iteration
      result)
  else:
    for i in 0 ..< result.len:
      result[i] = yield2yielded(result[i], conds, binds)

proc iteratorContract(this: NimNode): NimNode =
  ## Handles contracts for iterators.
  warning("Loop contracts are known to be buggy as for now, use with caution.")
  contextHandle(this, @ContractKeywordsIter) do (it: Context):
    it.impl = return2break(it.impl)
    if it.inv != nil:
      let oldValuesDecl = getOldValues(it.inv).reduceOldValues
      let boundedFlag = if oldValuesDecl == nil: nil
                        else: boundedFlagDecl()
      let invariant = contractInstance(
        LoopInvariantError.name.ident, it.inv).
        markBoundageDependent
      it.pre.add oldValuesDecl
      it.impl = yield2yielded(
        it.impl,
        invariant,
        updateOldValues(oldValuesDecl))
      if boundedFlag != nil:
         it.impl.add updateFlag(boundedFlag)
    else:
      it.impl = yield2yielded(
        it.impl,
        newEmptyNode(),
        newEmptyNode())
    it.impl.add this.yieldedVar

