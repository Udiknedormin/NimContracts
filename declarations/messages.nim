
let
  ContractViolatedStr {.compileTime.} =
    "broke '$1' promised at $2" ## \
    ## string to show when a contract is violated
  ErrMsgOutsideContractual {.compileTime.} =
    "keyword '$1' used outside 'contractual' block" ## \
    ## string to show when contractual keyword is present
    ## outside ``contractual`` block
  ErrMsgBodyNotFound {.compileTime.} =
    "no '$1' part present for contractual $$1" % $keyImpl ## \
    ## string to show when ``body`` part is not present
    ## for a contractual entity
  ErrMsgChildNotContractBlock {.compileTime.} =
    "contractual $1 contains child '$2' which is not contract block" ## \
    ## string to show when contractual callable has
    ## a child which is not contract block
  ErrMsgWrongUsage {.compileTime.} =
    "'$2' used wrongly in contractual $1" ## \
    ## string to show when contractual keyword used was valid
    ## but the context was wrong
  ErrMsgWrongOrder {.compileTime.} =
    "'$2' should be used before '$3' in contractual $1" ## \
    ## string to show when contractual entity has
    ## a wrong order child which is not contract block
  ErrMsgDuplicate {.compileTime.} =
    "'$2' contractual block duplicated in contractual $1" ## \
    ## string to show when contractual entity has
    ## reused the same contractual block
  ErrMsgContractualAfterNon {.compileTime.} =
    "'$2' used after non-contractual statement in contractual $1" ## \
    ## string to show when contractual entity has
    ## reused the same contractual block
  HintMsgCustomContractUsed {.compileTime.} =
    "consider using standard contracts instead of '$1' at $$1" % $keyCust ## \
    ## string to show when ``promise`` block is encountered

