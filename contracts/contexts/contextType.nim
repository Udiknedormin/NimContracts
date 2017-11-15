import tables

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

## Type of entity to produce.
type EntityType {.pure.} = enum
   Converter = "converter",
   Iterator = "iterator",
   Method = "method",
   Procedure = "proc",
   Template = "template",
   Macro = "macro",
   Type = "type",
   While = "while",
   For = "for",
   Other = "entity"

## Kind of entity to produce.
type EntityKind = enum
   declaration,  # routine or type declaration
   blocklike,    # block of code
   other         # other code

## Context data for handling.
type Context = ref object
   name:     string
   typ:      EntityType
   kind:     EntityKind
   secNames: seq[Keyword]
   head:     NimNode  # before the implementation
   tail:     NimNode  # implementation (contains all but header)
   docsNode: NimNode  # docs
   sections: Table[Keyword, NimNode]  # sections
   original: NimNode  # original source
   final:    NimNode  # final code


# forward-declaration
proc findContract(thisNode: NimNode): NimNode
  ## Finds any occurences of contracts


proc findDocs(stmts: NimNode): NimNode =
   ## Finds all doc-comments in the statement list.
   var docs = ""
   for child in stmts.children:
     if child.kind == nnkCommentStmt:
       docs.add child.strVal
       docs.add "\n"
   if docs != "":
     docs.delete(docs.len-1, docs.len-1)  # delete last \n
   result = newCommentStmtNode(docs)

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
    # allow doc comments
    child = stmts.findChild(it.kind != nnkCommentStmt and
                            (it.kind == nnkCall and
                             it[0].kind != nnkIdent or
                             not it[0].isKeyword))
    if child != nil:
      error(ErrMsgChildNotContractBlock.format(ct.typ, child[0]))

    # check if only right contractual keywords are used
    child = stmts.findChild(it.kind != nnkCommentStmt and
                            it[0].asKeyword notin ct.secNames)
    if child != nil:
      error(ErrMsgWrongUsage.format(ct.typ, child[0]))

    # check if the order of keywords if right
    var idxOfKey    = -2
    var newIdxOfKey = -2
    for child in stmts.children:
       if child.kind == nnkCommentStmt:
          continue
       newIdxOfKey = ct.secNames.find($child[0])
       if newIdxOfKey <= idxOfKey:
          error(ErrMsgWrongOrder %
            [$ct.typ, $child[0], ct.secNames[idxOfKey]])
       if newIdxOfKey == idxOfKey:
          error(ErrMsgDuplicate %
            [$ct.typ, ct.secNames[idxOfKey]])
       idxOfKey = newIdxOfKey

proc entityType(thisNode: NimNode): EntityType =
   ## Gets contractual entity's type.
   const mapper = {
      nnkConverterDef: EntityType.Converter,
      nnkIteratorDef:  EntityType.Iterator,
      nnkMethodDef:    EntityType.Method,
      nnkProcDef:      EntityType.Procedure,
      nnkTemplateDef:  EntityType.Template,
      nnkMacroDef:     EntityType.Macro,
      nnkTypeDef:      EntityType.Type,
      nnkWhileStmt:    EntityType.While,
      nnkForStmt:      EntityType.For
   }.toTable

   if mapper.hasKey(thisNode.kind):
      result = mapper[thisNode.kind]
   else:
      result = EntityType.Other

const RoutineTypes = {EntityType.Converter,
                      EntityType.Iterator,
                      EntityType.Method,
                      EntityType.Procedure,
                      EntityType.Template,
                      EntityType.Macro}
const LoopTypes = {EntityType.While, EntityType.For}

proc entityKind(typ: EntityType): EntityKind =
   ## Whether the entity is a declaration of routine or type.
   if typ in RoutineTypes or typ == EntityType.Type:
      EntityKind.declaration
   elif typ in LoopTypes:
      EntityKind.blocklike
   else:
      EntityKind.other
      
proc getEntityName(code: NimNode, typ: EntityType): string =
   ## Gets contractual entity's name.
   if typ in RoutineTypes:
      $code.name
   elif typ == EntityType.Type:
      code[0].repr
   elif typ in LoopTypes:
      $typ
   else:
      "entity"

proc newContext(code: NimNode, sections: openArray[Keyword]): Context =
   ## Creates a new Context based on its AST and section list.
   let stmts = code.findChild(it.kind == nnkStmtList)
   if not stmts.isContractual:
     return nil
   new(result)

   result.typ  = code.entityType
   result.kind = result.typ.entityKind
   result.name = getEntityName(code, result.typ)
   result.secNames = @sections
   checkContractual(result, stmts)
 
   result.head       = newStmtList()
   result.tail       = code
   result.docsNode   = stmts.findDocs()
   result.sections   = initTable[Keyword, NimNode]()
   for key in ContractKeywordsNormal:
      result.sections.add(key, stmts.findSection(key))
   result.original   = code.copyNimTree
   result.final      = nil

iterator sections(ct: Context): (Keyword, NimNode) =
   ## Iterates over all sections from a context, including implementation.
   for key, value in ct.sections:
      yield (key, value)


template sectionProperty(name, key) =
   proc name(ct: Context): NimNode  = ct.sections[key]
   proc `name =`(ct: Context, val: NimNode) =
      ct.sections[key] = val

macro genSectionProperties(): untyped =
   result = newStmtList()
   for key in ContractKeywordsNormal:
      result.add getAst(sectionProperty(!key.fieldName, key.ident))

genSectionProperties()
