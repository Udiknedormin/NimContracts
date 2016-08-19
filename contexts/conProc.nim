
#
# Procedures and converters
#
proc proceduralContract(thisNode: NimNode): NimNode =
  ## Handles contracts for procedures and converters.
  callableBase ContractKeywordsProc:
    discard
