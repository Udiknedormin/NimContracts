
type
  Keyword = enum
    keyPre   = "require",
    keyPost  = "ensure",
    keyInv   = "invariant",
    keyCust  = "promise",
    keyImpl  = "body",
    keyNone

const
  keyInvL = keyInv
#  keyInvT = keyInv

  ContractKeywordsProc =
    [keyPre, keyPost, keyImpl]
  ContractKeywordsIter =
    [keyPre, keyInvL, keyPost, keyImpl]

proc asKeyword(node: NimNode): Keyword =
  case $node:
  of $keyPre:
    result = keyPre
  of $keyPost:
    result = keyPost
  of $keyInv:
    result = keyInv
  of $keyCust:
    result = keyCust
  of $keyImpl:
    result = keyImpl
  else:
    result = keyNone

proc isKeyword(node: NimNode): bool =
  node.asKeyword != keyNone

converter toString(k: Keyword): string = $k
