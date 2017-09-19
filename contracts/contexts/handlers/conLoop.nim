
#
# Loops
#
proc loopContract(thisNode: NimNode): NimNode =
  warning("Loop contracts are known to be buggy as for now, use with caution.")
  var outContracts: NimNode
  callableBase ContractKeywordsIter:
    outContracts = Contracts.copyNimTree
    Contracts.del(n = Contracts.len)

    let invChild  = Stmts.findChild($it[0] == keyInvL)
    if invChild != nil:
      let preparationNode = getOldValues(
        invChild[1], newNimNode(nnkVarSection), true).
        reduceOldValues
      let invNode = contractInstance(
        LoopInvariantError.name.ident, invChild[1]).
        markBoundageDependent
      outContracts.insert(0, preparationNode)
      implChild[1].add(invNode).add(updateOldValues(preparationNode))

  var outRequire: NimNode
  var outEnsure: NimNode
  if outContracts.len > 0 and outContracts[^1].kind == nnkDefer:
    outRequire = outContracts
    outEnsure = outContracts[^1][0]
    outRequire.del(outRequire.len - 1)
  else:
    outRequire = outContracts[0]
    outEnsure = outContracts
    outEnsure.del(0)
  result = newStmtList(outRequire, result, outEnsure)
