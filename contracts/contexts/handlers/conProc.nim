
#
# Procedures and converters
#
proc proceduralContract(thisNode: NimNode): NimNode =
  ## Handles contracts for procedures and converters.
  contextHandle(thisNode, @ContractKeywordsProc) do (it: Context):
    discard
