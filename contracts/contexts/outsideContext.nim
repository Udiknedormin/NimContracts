
#
# Context keywords when used outside ``contractual``
#
template require* (conds: untyped) =
  ## Makes a list of preconditions, i.e. conditions
  ## to be fulfilled when entering the entity.
  ##
  ## Every expression represents a single requirement
  ## and should return a value convertible to bool.
  ## Example:
  ##
  ## .. code-block:: nim
  ##  proc peekAll[T](s: seq[seq[T]])
  ##                 {.contractual, inline.} =
  ##    require:
  ##      s.len > 0
  ##      all e in s: e.len > 0
  ##    body:
  ##      for e in s:
  ##        echo s.high
  ##
  ## Requirements are checked in the order of appearance.
  ##
  ## Some control statements can be used, namely
  ## ``if`` and ``when``. Both mean that a contract is valid
  ## only if certain condition (runtime or compile-time
  ## respectively) is fulfilled. ``elif`` and ``else`` branches
  ## are also possible.
  ## Example:
  ##
  ## .. code-block:: nim
  ##  proc vecOp[T](s: seq[T], T => T) {.contractual.} =
  ##    require:
  ##      when T is SomeReal:
  ##        all e in s: not e.isNaN
  ##    ...
  static:
    error(ErrMsgOutsideContractual % $keyPre)

template ensure* (conds: untyped) =
  ## Makes a list of postconditions, i.e. conditions
  ## to be fulfilled when returning from entity.
  ##
  ## Syntax is the same as for ``require`` with one addition:
  ## expression embraced with '`' special character means
  ## "the value of the expression from the time the entity
  ## was entered".
  ## Example:
  ##
  ## .. code-block:: nim
  ##  proc checkedPop[T](s: var seq[T]): T
  ##    {.contractual, inline, noSideEffect.} =
  ##    require:
  ##      s.len > 0
  ##    ensure:
  ##      s.len == `s.len` - 1
  ##      result == `s[s.len - 1]`
  ##      all i in 0 ..< s.len: `s`[i] == s[i]
  ##    body:
  ##      result = s.pop
  ## 
  ## This escaping works for any expression, each one is
  ## evaluated once (which may give unexpected results
  ## for iterators or some other subroutines).
  ##
  ## .. code-block:: nim
  ##  `s[s.len - 1]`
  ##  `s`[`s.len - 1`]
  ##  `s`[s.len - 1]
  ##
  ## The first and second expression return the same (although
  ## the first one binds only one variable).
  ## The last one's return value is the same only if s.len
  ## didn't change.
  static:
    error(ErrMsgOutsideContractual % $keyPost)

template invariant* (conds: untyped) =
  ## Makes a list of loop invariants, i.e. conditions
  ## to be fulfilled after each loop's iteration
  ## or just before iterator's yield.
  ##
  ## Syntax is the same as for ``ensure`` with one modification:
  ## escaped expression means "expression's value from
  ## the previous iteration".
  ## Example:
  ##
  ## .. code-block:: nim
  ##  proc sortedTreeSearch[T](tree: Node[T], key: T): Node[T]
  ##                          {.contractual, noSideEffect.} =
  ##    ensure:
  ##      if key in tree:
  ##        result.data == key
  ##      else:
  ##        result == nil
  ##    body:
  ##      while result != nil and result.data != key:
  ##        invariant:
  ##          if key in tree: key in result
  ##        body:
  ##          if result.data < key:
  ##            result = result.left
  ##          else:
  ##            resutl = result.right
  static:
    error(ErrMsgOutsideContractual % $keyInvL)

template body* (conds: untyped) =
  ## Defines contractual unit's body (implementation).
  ## It stores the code that promises to fulfill contracts
  ## preceding this block. It should be proven that its does,
  ## either through testing or formal proof.
  static:
    error(ErrMsgOutsideContractual % $keyImpl)

template promise* (conds: untyped): untyped =
  ## Makes a list of custom conditions, can be inserted
  ## even outside ``contractual`` block.
  ##
  ## It is highly discouraged to use custom contracts
  ## if any other contract fits for semantic reasons.
  static:
    const inst = instantiationInfo()
    hint(HintMsgCustomContractUsed %
      ["$1($2)" % [$(inst[0]), $(inst[1])]])
  contractInstanceMacro(CustomContractException, conds)

template assume* (conds: untyped): untyped =
  ## Marks assumptions, i.e. conditions which are always
  ## fulfilled but either are either not deductable from
  ## the code or difficult to be deduced. It's also useful
  ## for external proving tools.
  discard

