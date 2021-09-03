#
#
#            Nim's Contract Library
#        (c) Copyright 2016 M. Kotwica
#    See the file "LICENSE", included in this
#    distribution, for details about the copyright.
#

# As this module is quite big but semantically divisible,
# it was split into many files.
# In the future, more files may be included.


{.warning[ResultShadowed]:off.}    # due to using findChild template

import macros
import typetraits
import algorithm
import strutils

include contracts / overview
include contracts / declarations
include contracts / features
include contracts / contexts
