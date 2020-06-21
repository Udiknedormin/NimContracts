
#
# Procedures and converters
#

import ../deepCopyPolyfill

proc proceduralContract(thisNode: NimNode): NimNode =
  ## Handles contracts for procedures and converters.
  contextHandle(thisNode, @ContractKeywordsProc) do (it: Context):
    if it.olds != nil:
      if it.olds.kind == nnkVarSection:
        let new_olds = newNimNode(nnkLetSection)
        for i, section in it.olds:
          # `var name: type(impl)` --> `let name = impl`
          let name = section[0]
          let type_src = section[1][1]
          let impl = getAst(systemDeepCopy(type_src))
          let new_section = newIdentDefs(name, newEmptyNode(), impl)
          new_olds.add new_section
        it.olds = new_olds
