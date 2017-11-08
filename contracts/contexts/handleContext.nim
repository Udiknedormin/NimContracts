proc handle(ct: Context, handler: proc(ct: Context) {.closure.}): NimNode =
   ghost do:
      ct.explainContractBefore()
      if ct.preNode != nil:
         ct.preNode = contractInstance(
           PreConditionError.name.ident, ct.preNode)

      if ct.postNode != nil:
         let preparationNode = getOldValues(ct.postNode)
         let postCondNode = contractInstance(
           PostConditionError.name.ident, ct.postNode)
         ct.postNode = newTree(nnkDefer, postCondNode)
         ct.head.add preparationNode.reduceOldValues

      ct.handler()  # notice invariant MUST be included in impl!

      result = newStmtList(ct.head)

      if ct.preNode != nil:
         result.add ct.preNode

      if ct.postNode != nil:  # using defer
         result.add ct.postNode

      let stmtsIdx = ct.tail.findChildIdx(it.kind == nnkStmtList)
      ct.tail[stmtsIdx] = findContract(ct.implNode)

      if ct.kind == EntityKind.declaration:
        let tmp = ct.tail[stmtsIdx]
        ct.tail[stmtsIdx] = newStmtList(result, tmp)
        result = ct.tail
      else:
        result.add ct.tail

        if ct.kind == EntityKind.blocklike:
          # for `defer` to work properly:
          result = newBlockStmt(result)

      ct.final = result
      ct.explainContractAfter()

   do:
      let stmtsIdx = ct.tail.findChildIdx(it.kind == nnkStmtList)
      result[stmtsIdx] = findContract(ct.implNode)
    

proc contextHandle(code: NimNode,
                   sections: openArray[Keyword],
                   handler: proc(ct: Context) {.closure.}): NimNode =
   ## Create context and handle it.
   let ct = newContext(code, sections)
   if ct == nil:
      result = code
   else:
      result = ct.handle(handler)
