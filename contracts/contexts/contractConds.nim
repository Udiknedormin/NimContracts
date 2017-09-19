#
# Contract assert-like checks making
#
proc contractInstance(exceptionName, code: NimNode): NimNode =
   ## Makes a list of simple assert-like contracts.
   if (code.len == 0):
      result = nil
   else:
      result = newNimNode(nnkIfStmt)

      for cond in code:
         let newCond = cond.oldValToIdent
         let StrRepr = ContractViolatedStr %
            [($cond.toStrLit).unindent(60).replace("\n", " "),
            cond.lineinfo]

         # default 'true' in if-s and when-s
         if (cond.kind == nnkIfStmt or
             cond.kind == nnkWhenStmt) and
             cond[^1].kind != nnkElse:
            cond.add(
               newNimNode(nnkElse).
                  add(newLit(true)))

         let sig = quote do:
            raise newException(`exceptionName`, `StrRepr`)

         result.
            add(newNimNode(nnkElifBranch).
               add(newCond.prefix("not")).
               add(sig))

macro contractInstanceMacro(exceptionName, code: untyped): untyped =
   ghost:
      result = contractInstance(exceptionName, code)

