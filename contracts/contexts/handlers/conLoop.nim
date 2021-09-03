
#
# Loops
#
proc loopContract(this: NimNode): NimNode =
   contextHandle(this, @ContractKeywordsIter) do (it: Context):
      if it.inv != nil:
         let boundedFlag = boundedFlagDecl()
         let oldValuesDecl = getOldValues(it.inv).reduceOldValues
         it.inv = contractInstance(
           ident(LoopInvariantDefect.name), it.inv).
           markBoundageDependent(boundedFlag.getFlagSym)
         it.impl.add it.inv
         if oldValuesDecl != nil:
            if it.pre == nil:
               it.pre = newStmtList()
            it.pre.add oldValuesDecl
            it.pre.add boundedFlag
            it.impl.add updateOldValues(oldValuesDecl)
            it.impl.add updateFlag(boundedFlag.getFlagSym)
