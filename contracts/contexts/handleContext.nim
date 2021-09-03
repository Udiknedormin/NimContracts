proc handle(ct: Context, handler: proc(ct: Context) {.closure.}): NimNode =
   ghost do:
      let docs = ct.genDocs()
      ct.explainContractBefore()

      if ct.pre != nil:
         ct.pre = contractInstance(
           ident(PreConditionDefect.name), ct.pre)

      if ct.post != nil:
         let preparationNode = getOldValues(ct.post).reduceOldValues
         let postCondNode = contractInstance(
           ident(PostConditionDefect.name), ct.post)
         ct.post = newTree(nnkDefer, postCondNode)
         ct.olds = preparationNode

      ct.handler()  # notice invariant MUST be included in impl!

      result = newStmtList(ct.head)

      if ct.olds != nil:
         result.add ct.olds

      if ct.pre != nil:
         result.add ct.pre

      if ct.post != nil:  # using defer
         result.add ct.post

      let stmtsIdx = ct.tail.findChildIdx(it.kind == nnkStmtList)
      ct.tail[stmtsIdx] = findContract(ct.impl)

      if ct.kind == EntityKind.declaration:
        let tmp = ct.tail[stmtsIdx]
        ct.tail[stmtsIdx] = newStmtList(result, tmp)
        result = ct.tail
      else:
        result.add ct.tail

        if ct.kind == EntityKind.blocklike:
          # for `defer` to work properly:
          result = newBlockStmt(result)

      # add generated docs and generate it in the code
      if ct.kind != EntityKind.blocklike:
        ct.docsNode.add2docs(docs)
        result.docs2body(ct.docsNode)

      ct.final = result
      ct.explainContractAfter()

   do:
      let stmtsIdx = ct.tail.findChildIdx(it.kind == nnkStmtList)
      result[stmtsIdx] = findContract(ct.impl)


proc contextHandle(code: NimNode,
                   sections: openArray[Keyword],
                   handler: proc(ct: Context) {.closure.}): NimNode =
   ## Create context and handle it.
   let ct = newContext(code, sections)
   if ct == nil:
      result = code
   else:
      result = ct.handle(handler)
