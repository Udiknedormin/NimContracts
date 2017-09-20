
#
# Loops
#
proc loopContract(thisNode: NimNode): NimNode =
   contextHandle(thisNode, @ContractKeywordsIter) do (it: Context):
      if it.invNode != nil:
         let boundedFlag = boundedFlagDecl()
         let oldValuesDecl = getOldValues(it.invNode).reduceOldValues
         it.invNode = contractInstance(
           LoopInvariantError.name.ident, it.invNode).
           markBoundageDependent(boundedFlag.getFlagSym)
         it.implNode.add it.invNode
         if oldValuesDecl != nil:
            if it.preNode == nil:
               it.preNode = newStmtList()
            it.preNode.add oldValuesDecl
            it.preNode.add boundedFlag
            it.implNode.add updateOldValues(oldValuesDecl)
            it.implNode.add updateFlag(boundedFlag.getFlagSym)
