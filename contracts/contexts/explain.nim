import strutils
import sequtils


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


## Contract section docs information.
type ContractSectionInfo = object
   key:     Keyword
   code:    NimNode
   comment: NimNode

proc `$`(csi: ContractSectionInfo, alwaysView = true): string =
  if csi.code == nil:
     if alwaysView:
        "no $1".format(csi.key.docName)
     else:
        ""
  elif csi.comment == nil:
     "$1:$2".format(csi.key.docName,
                    csi.code.repr)
  else:
     var comm = csi.comment.repr
     if comm[2] == ' ':
        comm.delete(0, 2)
     else:
        comm.delete(0, 1)
     "$1:\n$2".format(csi.key.docName,
                      comm.indent(ExplainIndent))

proc strContractsAll(ct: Context, alwaysView = false): string =
   ## Stringify all contracts. No extracted documentation!
   var s = newSeq[ContractSectionInfo]()
   for key in ContractKeywordsNormal:
      if key != keyImpl:
         # Due to a bug in Nim's AST system, comments are not present
         # in AST for `EXPR  ## COMM`.
         s.add ContractSectionInfo(key:     key,
                                   code:    ct.sections[key],
                                   comment: nil)
   s.mapIt(`$`(it, alwaysView))
    .filterIt(it != "")
    .join("\n")

proc explainContractBefore(ct: Context) =
   when explainLevel != ExplainLevel.None:
      echo "contractual $1 \"$2\":".format(ct.typ, ct.name)
   when explainLevel == ExplainLevel.Basic or
        explainLevel == ExplainLevel.Verbose:
      echo "original code:".indent(ExplainIndent)
      echo ct.original.repr.indent(ExplainIndent*2)
   when explainLevel == ExplainLevel.Verbose:
      echo ct.strContractsAll(alwaysView = true).indent(ExplainIndent)

proc explainContractAfter(ct: Context) =
   when explainLevel != ExplainLevel.None:
      echo "final code:".indent(ExplainIndent)
      echo ct.final.repr.indent(ExplainIndent*2)


proc genDocs(ct: Context, alwaysView = false): string =
   ct.strContractsAll(alwaysView)

proc add2docs(docs: NimNode, new_docs: string) =
   when not defined(noContractsDocs):
      let openCode = ".. code-block:: nim"
      let oldDocs = docs.strVal
      docs.strVal = "$1\n$2".format(openCode, new_docs)
                            .indent(ExplainIndent)
      if oldDocs != "":
         docs.strVal = "$1\n$2".format(docs.strVal, oldDocs)

proc docs2body(tree: NimNode, docs: NimNode) =
   if docs.strVal != "":
      if tree.kind in RoutineNodes:
         tree.body.insert(0, docs)
      else:
         tree.insert(0, docs)
