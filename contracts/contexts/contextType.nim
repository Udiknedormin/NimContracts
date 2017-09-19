
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

## Kind of entity to produce.
type EntityKind = enum
   declaration,  # routine or type declaration
   blocklike,    # block of code
   other         # other code

## Context data for handling.
type Context = ref object
   name:     string
   kind:     EntityKind
   sections: seq[Keyword]
   head:     NimNode  # before the implementation
   tail:     NimNode  # implementation (contains all but header)
   preNode:  NimNode  # pre-conditions
   postNode: NimNode  # post-conditions
   invNode:  NimNode  # invariants
   implNode: NimNode  # implementation (body)


# forward-declaration
proc findContract(thisNode: NimNode): NimNode
  ## Finds any occurences of contracts


proc findSection(stmts: NimNode, keyword: Keyword): NimNode =
   # Finds a requested section in the statement list.
   result = stmts.findChild(it.kind == nnkCall and
                            it[0].kind == nnkIdent and
                            it[0].asKeyword == keyword)
   if result != nil:
      if result.len > 2:  # invalid section (more arguments than just code):
        error(ErrInvalidSection % [result.repr])
      result = result[1]  # unwrap

proc isContractual(stmts: NimNode): bool =
   ## Checks if the entity is contractual,
   ## i.e. it contains a contractual section.
   stmts.findChild(it.kind == nnkCall and
                   it[0].kind == nnkIdent and
                   it[0].isKeyword) != nil

proc checkContractual(ct: Context, stmts: NimNode) =
    ## Checks the context 
    var child: NimNode

    # check if only the right contractual sections are used as children
    child = stmts.findChild(it.kind == nnkCall and
                            it[0].kind != nnkIdent or
                            not it[0].isKeyword)
    if child != nil:
      error(ErrMsgChildNotContractBlock % [ct.name, $child[0]])

    # check if only right contractual keywords are used
    child = stmts.findChild(it[0].asKeyword notin ct.sections)
    if child != nil:
      error(ErrMsgWrongUsage % [ct.name, $child[0]])

    # check if the order of keywords if right
    var idxOfKey    = -2
    var newIdxOfKey = -2
    for child in stmts.children:
       newIdxOfKey = ct.sections.find($child[0])
       if newIdxOfKey <= idxOfKey:
          error(ErrMsgWrongOrder %
            [ct.name, $child[0], ct.sections[idxOfKey]])
       if newIdxOfKey == idxOfKey:
          error(ErrMsgDuplicate %
            [ct.name, ct.sections[idxOfKey]])
       idxOfKey = newIdxOfKey

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
   of nnkMacroDef:
      result = "macro"
   of nnkTypeDef:
      result = "type"
   of nnkWhileStmt:
      result = "while"
   of nnkForStmt:
      result = "for"
   else:
      result = "entity"

proc entityKind(thisNode: NimNode): EntityKind =
   ## Whether the entity is a declaration of routine or type.
   if thisNode.kind in {nnkConverterDef,
                        nnkIteratorDef,
                        nnkMethodDef,
                        nnkProcDef,
                        nnkTemplateDef,
                        nnkMacroDef,
                        nnkTypeDef}:
      EntityKind.declaration
   elif thisNode.kind in {nnkWhileStmt, nnkForStmt}:
      EntityKind.blocklike
   else:
      EntityKind.other
  

proc newContext(code: NimNode, sections: openArray[Keyword]): Context =
   ## Creates a new Context based on its AST and section list.
   let stmts = code.findChild(it.kind == nnkStmtList)
   if not stmts.isContractual:
     return nil
   new(result)
   result.name = getEntityName(code)
   result.kind = code.entityKind
   result.sections = @sections
   checkContractual(result, stmts)
 
   result.head       = newStmtList()
   result.tail       = code
   result.preNode    = stmts.findSection(keyPre)
   result.postNode   = stmts.findSection(keyPost)
   result.invNode    = stmts.findSection(keyInvL)
   result.implNode   = stmts.findSection(keyImpl)

proc handle(ct: Context, handler: proc(ct: Context) {.closure.}): NimNode =
   ghost do:
      if ct.preNode != nil:
         ct.preNode = contractInstance(
           PreConditionError.name.ident, ct.preNode)

      if ct.postNode != nil:
         let preparationNode = getOldValues(
           ct.postNode, newNimNode(nnkLetSection), false)
         let postCondNode = contractInstance(
           PostConditionError.name.ident, ct.postNode)
         ct.postNode = newTree(nnkDefer, postCondNode)
         ct.head.add preparationNode.reduceOldValues

      ct.handler()  # notice invarinat MUST be included in impl!

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
