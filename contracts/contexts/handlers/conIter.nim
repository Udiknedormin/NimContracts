
#
# Iterators
#
proc return2breakHelper(code: NimNode): NimNode =
  result = code
  if result.kind == nnkReturnStmt:
    if result[0].kind == nnkEmpty:
      result = newNimNode(nnkBreakStmt).add(keyImpl.ident)
    else:
      result = newStmtList(
        newAssignment(ident"result", result[0][1]),
        newNimNode(nnkBreakStmt).add(keyImpl.ident)
      )
  else:
    for i in 0 ..< result.len:
      result[i] = return2breakHelper(result[i])

proc return2break(code: NimNode): NimNode =
  ## Wrap into 'block body' and adapt 'return' statements.
  result = newNimNode(nnkBlockStmt).
    add(keyImpl.ident).
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

proc iteratorContract(thisNode: NimNode): NimNode =
  ## Handles contracts for iterators.
  warning("Loop contracts are known to be buggy as for now, use with caution.")
  contextHandle(thisNode, @ContractKeywordsIter) do (it: Context):
    it.implNode = return2break(it.implNode)
    if it.invNode != nil:
      let preparationNode = getOldValues(
        it.invNode, newNimNode(nnkVarSection), true).
        reduceOldValues
      let invariantNode = contractInstance(
        LoopInvariantError.name.ident, it.invNode).
        markBoundageDependent
      it.preNode.add preparationNode
      it.implNode = yield2yielded(
        it.implNode,
        invariantNode,
        updateOldValues(preparationNode))
    else:
      it.implNode = yield2yielded(
        it.implNode,
        newEmptyNode(),
        newEmptyNode())
    it.implNode.add thisNode.yieldedVar

