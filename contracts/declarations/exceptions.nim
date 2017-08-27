
type
  ContractError*       = object of Exception ## \
    ## violation of any contract at runtime
  CustomContractError* = object of ContractError ## \
    ## violation of a custom contract (promise)
  PreConditionError*   = object of ContractError ## \
    ## violation of a requirement
  PostConditionError*  = object of ContractError ## \
    ## violation of an assurance
  LoopInvariantError*  = object of ContractError ## \
    ## violation of a loop/iterator invariant
