
#
# Procedures and converters
#

proc proceduralContract(thisNode: NimNode): NimNode =
  ## Handles contracts for procedures and converters.
  contextHandle(thisNode, @ContractKeywordsProc) do (it: Context):
    if it.olds != nil:
      let li = newStmtList()
      li.add it.olds
      li.add updateOldValues(it.olds)
      it.olds = li
