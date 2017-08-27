
#
# General helpers
#
template findChildIdx(n, cond): int =
  ## Like ``findChild`` but returns an index (-1 if not found).
  block:
    var idx: int = -1
    var it {.inject.}: NimNode
    for i in 0 .. (n.len - 1):
      it = n[i]
      if cond:
        idx = i
        break
    idx

#
# Contractual block-related
#
proc findContract(thisNode: NimNode): NimNode
  ## Finds any occurences of contracts

proc getEntityName(thisNode: NimNode): string =
  ## Gets contractual entity's name.
  case thisNode.kind:
  of nnkConverterDef:
    result = "converter"
  of nnkIteratorDef:
    result = "iterator"
  of nnkMethodDef:
    result = "method"
  of nnkProcDef:
    result = "procedure"
  of nnkTemplateDef:
    result = "template"
  of nnkTypeDef:
    result = "type"
  else:
    result = "entity"

template isContractual(Stmts: untyped): untyped =
  ## Checks if the entity is contractual.
  Stmts.findChild(it.kind == nnkCall and
                  it[0].kind == nnkIdent and
                  it[0].isKeyword) != nil

template checkSyntax(stmtsChild, implChild, name, SyntaxWords,
                     onlyContractual: untyped): untyped =
  ## Check contractual entity's syntax
  block checkSyntax:
    # check if 'body' part is present
    # if not, raise compile error
    if implChild == nil and onlyContractual:
      error(ErrMsgBodyNotFound % [name])

    var child: NimNode
    if onlyContractual:
      # check if only contractual keywords are used as children
      child = stmtsChild.findChild(it.kind == nnkCall and
                                   it[0].kind != nnkIdent or
                                   not it[0].isKeyword)
      if child != nil:
        error(ErrMsgChildNotContractBlock % [name, $child[0]])

    # check if only right contractual keywords are used
    child = stmtsChild.findChild(it[0].asKeyword notin SyntaxWords)
    if child != nil:
      error(ErrMsgWrongUsage % [name, $child[0]])

    # check if the order of keywords if right
    var idxOfKey    = -2
    var newIdxOfKey = -2
    for child in stmtsChild.children:
      newIdxOfKey = SyntaxWords.find($child[0])
      if newIdxOfKey <= idxOfKey:
        if idxOfKey == -1:
          error(ErrMsgContractualAfterNon %
            [name, SyntaxWords[idxOfKey]])
        else:
          error(ErrMsgWrongOrder %
            [name, $child[0], SyntaxWords[idxOfKey]])
      if newIdxOfKey == idxOfKey and not idxOfKey == int.high:
        error(ErrMsgDuplicate %
          [name, SyntaxWords[idxOfKey]])
      idxOfKey = newIdxOfKey

template prepareContractuals(thisNode, onlyContractual, keywords: untyped) =
  ## Binds variables for statements and body children,
  ## checks the syntax and gets entity's name.
  let StmtsIdx {.inject.}  = thisNode.findChildIdx(it.kind == nnkStmtList)
  let Stmts {.inject.}     = thisNode[`Stmts Idx`]
  let implChild {.inject.} = Stmts.findChild(it.kind == nnkCall and
                                             it[0].kind == nnkIdent and
                                             it[0].asKeyword == keyImpl)
  if not Stmts.isContractual:
    return thisNode
  else:
    let name = getEntityName(thisNode)
    checkSyntax(Stmts, implChild, name, keywords, onlyContractual)

template callableBase(SyntaxWords, code: untyped,
                      onlyContractual: bool = true): untyped =
  ## Callable contractual entities' base.
  result = thisNode
  prepareContractuals(result, onlyContractual, SyntaxWords)

  ghost do:
    let newStmts {.inject.} = newStmtList()
    let Contracts {.inject.} = newStmtList()

    let preCondChild {.inject.} = Stmts.
      findChild(it[0].asKeyword == keyPre)
    let postCondChild  {.inject.} = Stmts.
      findChild(it[0].asKeyword == keyPost)

    if preCondChild != nil:
      Contracts.add(contractInstance(
        PreConditionError.name.ident, preCondChild[1]))

    if postCondChild != nil:
      let preparationNode = getOldValues(
        postCondChild[1], newNimNode(nnkLetSection), false)
      let postCondNode = contractInstance(
        PostConditionError.name.ident, postCondChild[1])
      Contracts.
        add(newNimNode(nnkDefer).
          add(postCondNode))
      Contracts.insert(0, preparationNode.reduceOldValues)

    code
    newStmts.add(Contracts).add(findContract(implChild[1]))
    result[StmtsIdx] = newStmts
  do:
    result[StmtsIdx] = findContract(implChild[1]) 

