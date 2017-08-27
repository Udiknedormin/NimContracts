
#
# finding contracts
#
proc findContract(thisNode: NimNode): NimNode = 
  ## Finds contractual entities inside 'contractual' block.
  result = thisNode
  case result.kind:
  of nnkProcDef, nnkConverterDef, nnkMethodDef:
    result = proceduralContract(result)
  of nnkIteratorDef:
    result = iteratorContract(result)
  of nnkWhileStmt, nnkForStmt:
    result = loopContract(result)
  of nnkCall:
    if result[0].kind in {nnkIdent, nnkSym} and $result[0] == keyCust:
      hint(HintMsgCustomContractUsed % [result.lineinfo])
      result = contractInstance(
        CustomContractError.getType, result[1])
  else:
    for i in 0 .. thisNode.len - 1:
      result[i] = findContract(result[i])


macro contractual*(code: untyped): untyped = 
  ## Creates a block with contractual syntax enabled.
  ## Example:
  ##
  ## .. code-block:: nim
  ##  proc checkedWrite(s: Stream; x: string)
  ##                   {.contractual, inline.} =
  ##    require:
  ##      not s.closed
  ##    body:
  ##      write(s, x)
  ##
  ## While many contractual features could be possible
  ## without an outside 'contractual' block, it is needed
  ## to check syntax (as one of the main reasons for using
  ## contracts is for clarity).
  ##
  ## If future versions of Nim language will enable custom
  ## multi-block macros (similar to if-else), this macro will stop
  ## affecting compilation process and therefore get deprecated.
  findContract(code)
