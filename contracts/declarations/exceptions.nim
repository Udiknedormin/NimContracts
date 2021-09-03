
type
  ContractDefect*       = object of Defect ## \
    ## violation of any contract at runtime
  CustomContractDefect* = object of ContractDefect ## \
    ## violation of a custom contract (promise)
  PreConditionDefect*   = object of ContractDefect ## \
    ## violation of a requirement
  PostConditionDefect*  = object of ContractDefect ## \
    ## violation of an assurance
  LoopInvariantDefect*  = object of ContractDefect ## \
    ## violation of a loop/iterator invariant
