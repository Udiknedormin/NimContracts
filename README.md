# Contracts
[![nimble](https://raw.githubusercontent.com/yglukhov/nimble-tag/master/nimble_js.png)](https://github.com/yglukhov/nimble-tag)

This module is used to make contracts – elegant promises that
pieces of code will fulfill certain conditions.

Contracts are essentially value counterparts of type-based concepts,
generic bounds, type attributes (e.x. ``not nil``) etc. While they
work similarly to assertions, as they throw exceptions when broken,
main reasons for using contracts include elegance of code, clarity
of exception messages, intuitive semantics and ease of analysis,
both for human and external tools.

As usage of this module isn't typical and some extra rules are
applied, aside from documentation for each of module's elements
the description of the module as a whole is included.

## Where could I hear about it?
Contracts and static analysis were briefly mentioned in
[June 8th 2020 Nim blog post](https://nim-lang.org/blog/2020/06/08/static-analysis.html)
and
[Nim v1.2.0 changelog](https://nim-lang.org/blog/2020/04/03/version-120-released.html)
(it actually uses similar names, `requires` vs `require`).
[DrNim (by Araq)](https://nim-lang.org/docs/drnim.html)
project uses such concepts too.

## Hello contracts
For most of the features of this module, ``contractual`` macro should
be used. As it generates exception-raising code, some exceptions
should be imported too. For now, importing whole module is advised
(at least until the submodules are introduced).

Example usage (hello world equivalent):
```nim
import contracts
from math import sqrt, floor
    
proc isqrt[T: SomeInteger](x: T): T {.contractual.} =
  require:
    x >= 0
  ensure:
    result * result <= x
    (result+1) * (result+1) > x
  body:
    (T)(x.toBiggestFloat().sqrt().floor().toBiggestInt())


echo isqrt(18)  # prints 4

echo isqrt(-8)  # runtime error:
                #   broke 'x >= 0' promised at FILE.nim(LINE,COLUMN)
                #   [PreConditionError]
```

## Overview
It is advised to use contracts as part of a fine documentation.
Even when disabled by a switch or pragma, they still look good
and describe one's intentions well. Thanks to that, the code is
often much easier to read even without comments. Also,  a reader
experienced in contractual design (and prefferably Nim) can read
them faster than natural language as they are more compact.

Consider finding key's position in a sorted array:

```nim
 contractual:
   var a = 0
   var b = arr.len-1
   while a < b:
     invariant:
       if key in arr: key in arr[a..b]
       abs(a - b) < `abs(a - b)`
     ensure:
       if key in arr: key == arr[a]
     body:
       let mid = (a + b) div 2
       if arr[mid] < key:
         a = mid + 1
       else:
         b = mid
```

The first loop invariant is rather obvious. The other one is also
intuitive if we know this module uses '`' character meaning roundly
"previously" (in last iteration or yield, can also be used in postconditions
to refer to values seen by preconditions). Actually, we could
strengthen our invariants by adding information about how fast
the range shrinks but it's not necessary to prove the algorithm
works (although it is needed to prove how efficient it is).

While contracts can be of great help, they require care, especially
when object-oriented behaviour is expected. For present version,
one has to follow certain rules described in
[Object-Oriented Contracts](#object-oriented-contracts)
section (in the future they will be followed automatically).

## Contractual context
As already mentioned, for most of this module's features to actually
work, the code has to be inside of a ``contractual`` block. For callables,
it can be applied as a pragma.

Syntax:

```nim
 contractual:
   ...

 proc ... {.contractual.} = ...
```

There are several Contractual Contexts (CoCo) inside of ``contractual``
block. They are bound to plain Nim code blocks, so no additional marking
is needed. CoCo include:
- `proc` is ``procedure``, ``converter`` or ``method`` declaration
- `loop` is ``iterator`` declaration or either ``for`` or ``while`` loop
- `type` is ``type`` declaration (to be used in future versions)

It is advised, although not needed, to use ``contractual`` block
for whole modules and any modules that utilize them.


## Context keywords
| Keyword   |  Related to    |    Semantics   |proc|loop|type|
|-----------|:--------------:|:--------------:|:--:|:--:|:---:
| require   |  PreCondition  |   is needed    | yes| yes|  no|
| invariant |    Invariant   | doesn't change |  no| yes| yes|
| ensure    |  PostCondition |   is provided  | yes| yes|  no|
| body      | implementation | how it is done | yes| yes|  no|

Sections should be used in the same order as in the table above.

There is also ``promise`` keyword (related to CustomContract) which
describes any conditions and as the only one doesn't require being
used in ``contractual``. Its usage discouraged if any other CoCo
would do as its less descriptive and have no additional rules to it
but for the assertion.

## Other features
This module also includes a few non-context tools:
- ``ghost`` makes a block of code active only when contracts are turned on
- ``forall`` and ``forsome`` represent quantifiers
- ``assume`` is used for assumptions for human reader and external tools
      (no code generated)
- ``promise`` makes custom contracts

## Documentation
Contracts can be treated as a part of the signature of the routine
or type associated with it. Due to that, this module can generate
additional code block for the entity's documentation so that the code
would blend in with the signature.

Example code:

``` nim
 proc isqrt[T: SomeInteger](x: T): T {.contractual.} =
   ## Integer square root function.
   require:
     x >= 0
   ensure:
     result >= 0
     result * result <= x
     (result+1) * (result+1) > x
   body:
     (T)(x.toBiggestFloat().sqrt().floor().toBiggestInt())
```

Generated docs:

```nim
 proc isqrt[T: SomeInteger](x: T): T
```
> ```nim
>    requires:
>      x >= 0
>    ensures:
>      result >= 0
>      result * result <= x
>      (result+1) * (result+1) > x
> ```
> Integer square root function.

Doc comments can be added anywhere between contractual sections,
they will be treated just like when written in one place.

Contracts docs generation can be disabled using `noContractsDocs`
compilation flag.

## Diagnostics
To diagnose contracts, use `explainContracts` compile flag.
It provides diagnostic informations about contracts, according to its
numerical value:
- 0: None (default) --- doesn't show any diagnostics
- 1: Output (when flag defined but has no value) --- show final code
- 2: Basic --- show both source and final code
- 3: Verbose --- as Basic + show each type
    of contract detected for the entity (directly or indirectly).

## Non-obvious goodies
Nim has an undocumented problem with JS `deepCopy` implementation lacking.
Contracts uses its own implementation of `deepCopy` for JS backend, thus
solving the problem. Thanks to that, "previous values" can be used on JS
backend just like on C or C++ ones.


## Future
### Exception awareness
As for now, contracts cannot refer to exceptions, although it is planned
for future versions to enable such a feature. In core Nim, it is possible
to inform about what types of exceptions can be throw in the callable.
However, there is no possibility to express what conditions should be
met for these exceptions to be thrown. Additionally, it should be possible
to specify what conditions will be true if an exception raises (notice they
are not necessarily the same conditions).

### Object-Oriented Contracts
New context `type` is planned for future versions. With it's introduction
both `proc` and `loop` contexts will be changed to force object-oriented
rules. For now, user should follow them manually.

|     contract   |  containing | inheritance |
|----------------|:-----------:|:-----------:|
| type invariant |    added    |      ?      |
|  pre-condition |    added    | alternative |
| loop invariant |    added    |    added    |
| post-condition |    added    |    added    |



## Comparison to other libraries

### Nim built-in pragmas

Nim itself defines some contract pragmas, including `requires`, `ensures`,
`assume`, `assert`, `invariant`. Note how many of them are very similar to
those used by Contracts. However, these do not generate any runtime checks
and are there only to be inspected by external tools. In comparison,
Contracts actually generates runtime checks with meaningful errors.

If some tooling starts actually using these pragmas, Contracts might get an
option to inject these pragmas too, so that external tooling can use them.

