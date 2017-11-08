import strutils


const ExplainIndent = 2

type ExplainLevel {.pure.} = enum  ## defines how verbose
                                   ## diagnostic outputs will be
   None    = 0,
   Output  = 1,
   Basic   = 2,
   Verbose = 3

const explainContracts {.strdefine.} = ""

# None by default
# Output if explainContracts is defined but has no value
# value of explainContracts if defined
const explainLevel =
   when defined(explainContracts):
      if explainContracts == "true":
         ExplainLevel.Output
      else:
         (ExplainLevel)explainContracts.parseInt
   else:
      ExplainLevel.None

proc showContractKind(name: string, code: NimNode) =
   if code == nil:
      echo "no $1".format(name).indent(ExplainIndent)
   else:
      echo "$1:".format(name).indent(ExplainIndent),
           code.repr.indent(ExplainIndent*2)
   echo ""

proc explainContractBefore(ct: Context) =
   when explainLevel != ExplainLevel.None:
      echo "contractual $1 \"$2\":".format(ct.typ, ct.name)
   when explainLevel == ExplainLevel.Basic or
        explainLevel == ExplainLevel.Verbose:
      echo "original code:".indent(ExplainIndent)
      echo ct.original.repr.indent(ExplainIndent*2)
   when explainLevel == ExplainLevel.Verbose:
      showContractKind("preconditions",  ct.preNode)
      showContractKind("postconditions", ct.postNode)
      showContractKind("invariants", ct.invNode)

proc explainContractAfter(ct: Context) =
   when explainLevel != ExplainLevel.None:
      echo "final code:".indent(ExplainIndent)
      echo ct.final.repr.indent(ExplainIndent*2)
