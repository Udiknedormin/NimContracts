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


proc infoContractKind(name: string,
                      code: NimNode,
                      alwaysView = true): (string, string, string) =
   ## Stringify a ceratin kind of a contract into a tuple of
   ## kind, code and docs. No extracted documentation!
   if code != nil:
      result[0] = name.indent(ExplainIndent)
      #code.add newCommentStmtNode("sth!")
      #echo code.treeRepr
      if code.last.kind == nnkCommentStmt:
         let comm = code.last
         code.del(code.len-1)
         result[2] = comm.repr.indent(ExplainIndent*2)
      else:
         result[2] = ""
      result[1] = code.repr.indent(ExplainIndent*2)
   elif alwaysView:
      result[0] = "no $1".format(name).indent(ExplainIndent)
      result[1] = ""
      result[2] = ""
   else:
      result = ("","","")

proc strContractsAll(ct: Context, alwaysView = true): string =
   ## Stringify all contracts. No extracted documentation!
   var s = newSeq[(string,string,string)]()
   s.add infoContractKind("preconditions",  ct.preNode,  alwaysView)
   s.add infoContractKind("postconditions", ct.postNode, alwaysView)
   s.add infoContractKind("invariants",     ct.invNode,  alwaysView)
   proc formatCK(it: (string,string,string)): string =
      if it[0] == "":
         ""
      elif it[2] == "":
         "$1:$2".format(it[0], it[1])
      else:
         "$1:$2".format(it[0], it[2])
   s.mapIt(formatCK(it)).join("\n")

proc explainContractBefore(ct: Context) =
   when explainLevel != ExplainLevel.None:
      echo "contractual $1 \"$2\":".format(ct.typ, ct.name)
   when explainLevel == ExplainLevel.Basic or
        explainLevel == ExplainLevel.Verbose:
      echo "original code:".indent(ExplainIndent)
      echo ct.original.repr.indent(ExplainIndent*2)
   when explainLevel == ExplainLevel.Verbose:
      echo ct.strContractsAll()

proc explainContractAfter(ct: Context) =
   when explainLevel != ExplainLevel.None:
      echo "final code:".indent(ExplainIndent)
      echo ct.final.repr.indent(ExplainIndent*2)


proc genDocs(ct: Context, alwaysView = false): string =
   ct.strContractsAll(alwaysView)

proc add2docs(docs: NimNode, new_docs: string) =
   when not defined(noContractsDocs):
      let openCode = ".. code-block:: nim"
      if docs.strVal != "":
         docs.strVal = "$1\n$2\n$3".format(openCode, new_docs, docs.strVal)
      else:
         docs.strVal = "$1\n$2".format(openCode, new_docs)

proc docs2body(tree: NimNode, docs: NimNode) =
   if docs.strVal != "":
      if tree.kind in RoutineNodes:
         tree.body.insert(0, docs)
      else:
         tree.insert(0, docs)
