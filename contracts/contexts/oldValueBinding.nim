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
    result = newIdentNode(!thisNode.oldValIdentToStr)
  else:
    for idx in 0 ..< thisNode.len:
      thisNode[idx] = oldValToIdent(thisNode[idx])
    result = thisNode

proc getOldValuesHelper(thisNode, getter: NimNode): NimNode =
  ## Recursive helper for getOldValues.
  result = getter
  if thisNode.kind == nnkAccQuoted:
    let left = thisNode.oldValIdentToStr.ident
    var rightStr = ""
    for child in thisNode.children:
      rightStr.add($child)
    let right = parseExpr(rightStr)

    result.
      add(newNimNode(nnkIdentDefs).
        add(left).
        add(newEmptyNode()).
        add(right))
  else:
    for child in thisNode.children:
      result = getOldValuesHelper(child, result)

proc getOldValues(thisNode, getter: NimNode,
                  boundageFlag: bool): NimNode =
  ## Prepares entity's old values for 'ensure'
  ## If a special value boundedYet is needed,
  ## boudageFlag should be set to true.
  result = thisNode
  result = getOldValuesHelper(result, getter)
  if boundageFlag:
    result.insert(0, newNimNode(nnkIdentDefs).
      add(ident"boundedYet").
      add(newEmptyNode()).
      add(newLit(false)))

proc updateOldValues(thisNode: NimNode): NimNode =
  ## Updates old values for iterator or loop.
  if thisNode.len > 0 and thisNode[0].kind != nnkEmpty:
    result = newStmtList()
    for child in thisNode.children:
       result.add(newAssignment(child[0], child[2]))
    # 'boundedYet' should be 'true' instead of 'false'
    result[0][1] = newLit(true)
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

proc markBoundageDependent(thisNode: NimNode): NimNode =
  ## Marks all boundage depended conditions.
  result = thisNode
  for idx in 0 ..< result.len:
    if result[idx][0].isBoundageDependent:
      result[idx][0] = infix(ident"boundedYet", "and", result[idx][0])
