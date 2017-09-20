#
# Bind old values with escaping
#

proc oldValIdentToStr(thisNode: NimNode): string =
  ## Changes old value's identifier to string
  result = "`"
  for child in thisNode.children:
    result.add($child)
  result.add("`")

proc oldValToIdent(thisNode: NimNode): NimNode =
  ## Changes AccQuoted structure for old value
  ## into an identifier
  if thisNode.kind == nnkAccQuoted:
    result = thisNode.oldValIdentToStr.ident
  else:
    for idx in 0 ..< thisNode.len:
      thisNode[idx] = thisNode[idx].oldValToIdent
    result = thisNode

proc getOldValuesHelper(thisNode, getter: NimNode): NimNode =
  ## Recursive helper for getOldValues.
  result = getter
  if thisNode.kind == nnkAccQuoted:
    let name = thisNode.oldValIdentToStr.ident
    var tyStr = ""
    for child in thisNode.children:
      tyStr.add($child)
    let ty = newCall(bindSym"type", parseExpr(tyStr))

    result.
      add(newNimNode(nnkIdentDefs).
        add(name).
        add(ty).
        add(newEmptyNode()))
  else:
    for child in thisNode.children:
      result = getOldValuesHelper(child, result)

proc getOldValues(thisNode: NimNode): NimNode =
  ## Prepares entity's old values for 'ensure'
  ## If a special value boundedYet is needed,
  ## boudageFlag should be set to true.
  result = getOldValuesHelper(thisNode, newNimNode(nnkVarSection))
  if result.len == 0:  # no variables, empty section => remove it entirely
    result = nil

proc boundedFlagDecl(): NimNode {.compileTime.} =
  ## Generates boundedYet flag.
  let sym = genSym(nskVar, "boundedYet")
  template decl(sym) =
    var sym = false
  result = getAst(decl(sym))[0]

proc getFlagSym(flag: NimNode): NimNode =
  ## Gets flag symbol given its declaration.
  flag.expectKind(nnkVarSection)
  flag[0][0].expectKind({nnkIdent, nnkSym})
  result = flag[0][0]

proc updateFlag(flag: NimNode, value = newLit(true)): NimNode =
  ## Updates flag given by its symbol to a certain value
  ## (true literal by default).
  result = newAssignment(flag, value)

proc updateOldValues(thisNode: NimNode): NimNode =
  ## Updates old values for iterator or loop.
  if thisNode.len > 0 and thisNode[0].kind != nnkEmpty:
    result = newStmtList()
    for child in thisNode.children:
      result.add(newAssignment(child[0], child[1][1]))
  else:
    result = newEmptyNode()

proc reduceOldValues(thisNode: NimNode): NimNode =
  ## Reduces repetitions in old values,
  ## either 'let' or 'var'.
  result = thisNode
  var olds: seq[string] = @[]
  var toDelete: seq[int] = @[]
  for idx in 0 ..< result.len:
    let name = $result[idx][0]
    if name in olds:
      toDelete.add(idx)
    else:
      olds.add(name)
  for idx in reversed(toDelete):
    result.del(idx)
  # empty 'var' or 'let' is not ok
  if result.len == 0:
    result = newEmptyNode()

import future
proc isBoundageDependent(thisNode: NimNode): bool =
  ## Makes an expression only checked if variable
  ## boundage already happened
  if thisNode.kind == nnkIdent and ($thisNode)[0] == '`':
    result = true
  else:
    if thisNode.len == 0:
      result = false
    else:
      result = forsome child in thisNode.children:
        child.isBoundageDependent

proc markBoundageDependent(thisNode: NimNode,
                           flag: NimNode = ident"boundedYet"): NimNode =
  ## Marks all boundage depended conditions, use given flag.
  result = thisNode
  for idx in 0 ..< result.len:
    if result[idx][0].isBoundageDependent:
      result[idx][0] = infix(flag, "and", result[idx][0])
