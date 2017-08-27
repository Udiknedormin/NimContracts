
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
  callableBase ContractKeywordsIter:
    let invariantChild  = Stmts.findChild($it[0] == keyInvL)
    implChild[1] = return2break(implChild[1])
    if invariantChild != nil:
      let preparationNode = getOldValues(
        invariantChild[1], newNimNode(nnkVarSection), true).
        reduceOldValues
      let invariantNode = contractInstance(
        LoopInvariantError.name.ident, invariantChild[1]).
        markBoundageDependent
      Contracts.insert(0, preparationNode)
      implChild[1] = yield2yielded(
        implChild[1],
        invariantNode,
        updateOldValues(preparationNode))
    else:
      implChild[1] = yield2yielded(
        implChild[1],
        newEmptyNode(),
        newEmptyNode())
    newStmts.add(thisNode.yieldedVar)

