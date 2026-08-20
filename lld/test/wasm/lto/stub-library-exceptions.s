# RUN: split-file %s %t
# RUN: llvm-as %t/main.ll -o %t/main.o
# RUN: llvm-as %t/catch.ll -o %t/catch.o
# RUN: rm -f %t/libcatch.a
# RUN: llvm-ar rcs %t/libcatch.a %t/catch.o
# RUN: wasm-ld -mllvm -enable-emscripten-cxx-exceptions --allow-undefined %t/main.o %t/libcatch.a %t/stub.so -o %t.wasm
# RUN: obj2yaml %t.wasm | FileCheck %s

## Test that stub library symbols with the `__cxa_find_matching_catch_` prefix
## (generated during LTO by WebAssemblyLowerEmscriptenEHSjLj) extract their
## bitcode dependencies from archives before LTO.

# RUN: not wasm-ld -mllvm -enable-emscripten-cxx-exceptions --allow-undefined %t/main.o %t/stub.so -o %t.wasm 2>&1 | FileCheck --check-prefix=MISSING %s
# MISSING: stub.so: undefined symbol: can_catch. Required by __cxa_find_matching_catch_2

# CHECK:         Imports:
# CHECK-NEXT:      - Module:          env
# CHECK-NEXT:        Field:           foo
# CHECK-NEXT:        Kind:            FUNCTION
# CHECK-NEXT:        SigIndex:        0
# CHECK-NEXT:      - Module:          env
# CHECK-NEXT:        Field:           invoke_v
# CHECK-NEXT:        Kind:            FUNCTION
# CHECK-NEXT:        SigIndex:        1
# CHECK-NEXT:      - Module:          env
# CHECK-NEXT:        Field:           __cxa_find_matching_catch_2
# CHECK-NEXT:        Kind:            FUNCTION
# CHECK-NEXT:        SigIndex:        2
# CHECK-NEXT:      - Module:          env
# CHECK-NEXT:        Field:           getTempRet0
# CHECK-NEXT:        Kind:            FUNCTION
# CHECK-NEXT:        SigIndex:        2

# CHECK:         Exports:
# CHECK-NEXT:       - Name:            memory
# CHECK-NEXT:         Kind:            MEMORY
# CHECK-NEXT:         Index:           0
# CHECK-NEXT:       - Name:            _start
# CHECK-NEXT:         Kind:            FUNCTION
# CHECK-NEXT:         Index:           4
# CHECK-NEXT:       - Name:            can_catch
# CHECK-NEXT:         Kind:            FUNCTION
# CHECK-NEXT:         Index:           5

#--- main.ll
target datalayout = "e-m:e-p:32:32-p10:8:8-p20:8:8-i64:64-n32:64-S128-ni:1:10:20"
target triple = "wasm32-unknown-unknown"

declare void @foo()
declare i32 @__gxx_personality_v0(...)

define void @_start() personality ptr @__gxx_personality_v0 {
entry:
  invoke void @foo()
          to label %try.cont unwind label %lpad

lpad:
  %0 = landingpad { ptr, i32 }
          cleanup
  ret void

try.cont:
  ret void
}

#--- catch.ll
target datalayout = "e-m:e-p:32:32-p10:8:8-p20:8:8-i64:64-n32:64-S128-ni:1:10:20"
target triple = "wasm32-unknown-unknown"

define void @can_catch() {
entry:
  ret void
}

#--- stub.so
#STUB
__cxa_find_matching_catch_2: can_catch
