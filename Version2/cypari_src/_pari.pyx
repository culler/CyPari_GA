# Use sys.getdefaultencoding() to convert Unicode strings to <char*>
#
# cython: c_string_encoding=default
"""
Sage class for PARI's GEN type

See the ``Pari`` class for documentation and examples.

AUTHORS:

- William Stein (2006-03-01): updated to work with PARI 2.2.12-beta

- William Stein (2006-03-06): added newtonpoly

- Justin Walker: contributed some of the function definitions

- Gonzalo Tornaria: improvements to conversions; much better error
  handling.

- Robert Bradshaw, Jeroen Demeyer, William Stein (2010-08-15):
  Upgrade to PARI 2.4.3 (:trac:`9343`)

- Jeroen Demeyer (2011-11-12): rewrite various conversion routines
  (:trac:`11611`, :trac:`11854`, :trac:`11952`)

- Peter Bruin (2013-11-17): move Pari to a separate file
  (:trac:`15185`)

- Jeroen Demeyer (2014-02-09): upgrade to PARI 2.7 (:trac:`15767`)

- Martin von Gagern (2014-12-17): Added some Galois functions (:trac:`17519`)

- Jeroen Demeyer (2015-01-12): upgrade to PARI 2.8 (:trac:`16997`)

- Jeroen Demeyer (2015-03-17): automatically generate methods from
  ``pari.desc`` (:trac:`17631` and :trac:`17860`)

- Kiran Kedlaya (2016-03-23): implement infinity type

- Luca De Feo (2016-09-06): Separate Sage-specific components from
  generic C-interface in ``Pari`` (:trac:`20241`)

- Marc Culler and Nathan Dunfield (2016): adaptation for the standalone
  CyPari module.

"""

#*****************************************************************************
#       Copyright (C) 2006,2010 William Stein <wstein@gmail.com>
#       Copyright (C) ???? Justin Walker
#       Copyright (C) ???? Gonzalo Tornaria
#       Copyright (C) 2010 Robert Bradshaw <robertwb@math.washington.edu>
#       Copyright (C) 2010-2016 Jeroen Demeyer <jdemeyer@cage.ugent.be>
#       Copyright (C) 2016 Luca De Feo <luca.defeo@polytechnique.edu>
#       Copyright (C) 2016 Marc Culler and Nathan Dunfield
#
#  Distributed under the terms of the GNU General Public License (GPL)
#  as published by the Free Software Foundation; either version 2 of
#  the License, or (at your option) any later version.
#                  http://www.gnu.org/licenses/
#*****************************************************************************
from __future__ import print_function

# Define the conditional compilation variable SAGE
include "sage.pxi"

import sys, types
if sys.version_info.major > 2:
    iterable_types = (list, tuple, types.GeneratorType)
else:
    iterable_types = (list, tuple, types.XRangeType, types.GeneratorType)
from builtins import range

cimport cython

from cpython.int cimport PyInt_Check
from cpython.long cimport PyLong_Check
from cpython.bytes cimport PyBytes_Check
from cpython.unicode cimport PyUnicode_Check
from cpython.float cimport PyFloat_AS_DOUBLE
from cpython.complex cimport PyComplex_RealAsDouble, PyComplex_ImagAsDouble
from cpython.object cimport Py_EQ, Py_NE, Py_LE, Py_GE, Py_LT, Py_GT

from .paridecl cimport *
from .paripriv cimport *
cimport libc.stdlib
from libc.stdio cimport *

include "cypari_src/ct_constants.pxi"
# 64 bit Windows is the only system we support where a Pari longword
# is not a long.
IF WIN64:
    ctypedef long long pari_longword
    ctypedef unsigned long long pari_ulongword
ELSE:
    ctypedef long pari_longword
    ctypedef unsigned long pari_ulongword

cdef String(x):
    """
    Return a string from either a string or bytes object, using ascii.
    """
    if isinstance(x, str):
        return x
    elif isinstance(x, bytes):
        return x.decode('ascii')
    else:
        raise ValueError('Neither a str nor a bytes object.')

IF SAGE:
    pass
    # Commented these out to deal with Cython-0.25 bug
#    include "cysignals/memory.pxi"
#    include "cysignals/signals.pxi"
#    from sage.misc.randstate cimport randstate, current_randstate
#    from sage.structure.sage_object cimport rich_to_bool
#    from sage.misc.superseded import deprecation, deprecated_function_alias
#    from sage.libs.pari.closure cimport objtoclosure
#    from sage.rings.integer cimport Integer
#    from sage.rings.rational cimport Rational
#    from sage.rings.infinity import Infinity
#    from pari_instance cimport (Pari, pari_instance, prec_bits_to_words,
#                                prec_words_to_bits, default_bitprec)
#    cdef Pari P = pari_instance
ELSE:
    include "memory.pxi"
    include "signals.pyx"
    init_cysignals()
    include "stack.pyx"
    include "pari_instance.pyx"
    include "convert.pyx"
    include "handle_error.pyx"
    include "closure.pyx"
    include "gen.pyx"
