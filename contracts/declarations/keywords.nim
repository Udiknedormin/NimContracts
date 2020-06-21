
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
  ContractKeywordsNormal =
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

proc docName(k: Keyword): string =
  case k:
    of keyPre:  "Requires"
    of keyPost: "Ensures"
    of keyInv:  "Invariants"
    of keyCust: "Promises"
    of keyImpl: "Body"
    of keyNone: ""

proc fieldName(k: Keyword): string =
  case k:
    of keyPre:  "pre"
    of keyPost: "post"
    of keyInv:  "inv"
    of keyCust: "cust"
    of keyImpl: "impl"
    of keyNone: ""

proc ident(k: Keyword): NimIdent {.compileTime.} =
  !("key_" & k.fieldName)
