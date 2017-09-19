
#
# Loops
#
proc loopContract(thisNode: NimNode): NimNode =
   warning("Loop contracts are known to be buggy as for now, use with caution.")
   result = contextHandle(thisNode, @ContractKeywordsIter) do (it: Context):
     if it.invNode != nil:
       let preparationNode = getOldValues(
         it.invNode, newNimNode(nnkVarSection), true).
         reduceOldValues
       it.invNode = contractInstance(
         LoopInvariantError.name.ident, it.invNode).
         markBoundageDependent
       it.implNode.insert(0, preparationNode)
       it.implNode.
         add(it.invNode).
         add(updateOldValues(preparationNode))
