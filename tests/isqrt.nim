import math
import macros
import unittest
import contracts


template testInt(T: typed, code: untyped): untyped =
  const MAX_VAL = (T)(sqrt(high(T).toBiggestFloat)-2)
  for i {.inject.} in 1.T .. MAX_VAL:
    code

macro testInts(types: typed, code: untyped): untyped =
  result = newStmtList()
  for typ in types:
    result.add getAst(testInt(typ, code))

template testAllInts(code: untyped): untyped =
  testInts([int8,int16,int32,int64], code)


suite "isqrt with floor":
  proc isqrt[T: SomeInteger](x: T): T {.contractual.} =
    require:
      x >= 0
    ensure:
      result * result <= x
      (result+1) * (result+1) > x
    body:
      (T)(x.toBiggestFloat().sqrt().floor().toBiggestInt())

  test "exact squares":
    testAllInts:
      check isqrt(i*i) == i

  test "between squares":
    testInts([int8, int16]) do:
      for j in i^2+1 .. (i+1)^2-1:
         check isqrt(j) == i

suite "isqrt with round":
  proc isqrt[T: SomeInteger](x: T): T {.contractual.} =
    require:
      x >= 0
    ensure:
      result * result <= x
      (result+1) * (result+1) > x
    body:
      (T)(x.toBiggestFloat().sqrt().round().toBiggestInt())

  test "exact squares":
    testAllInts:
      check isqrt(i*i) == i

  test "between squares (postcondition broken)":
    testInts([int8, int16]) do:
      for j in i^2+1 .. (i+1)^2-1:
        expect PostConditionError:
          if isqrt(j) == i:  # either it throws or the result is ok
            raise newException(PostConditionError, "")

suite "isqrt with cast":
  proc isqrt[T: SomeInteger](x: T): T {.contractual.} =
    require:
      x >= 0
    ensure:
      result * result <= x
      (result+1) * (result+1) > x
    body:
      (T)(x.toBiggestFloat().sqrt().toBiggestInt())

  test "exact squares":
    testAllInts:
      check isqrt(i*i) == i

  test "between squares":
    testInts([int8, int16]) do:
      for j in i^2+1 .. (i+1)^2-1:
         check isqrt(j) == i
