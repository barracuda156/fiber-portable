  .text
  .align 2

  .globl _fiber_asm_switch
_fiber_asm_switch:

  mfcr r5
  stw r5, 0(r3)
  lwz r5, 0(r4)
  mtcr r5

  mflr r0
  stw r0, 8(r3)
  lwz r0, 8(r4)
  mtlr r0

  stw r1, 16(r3)
  lwz r1, 16(r4)

  ; Save and restore GPRs (r13 to r31)
  li r5, 0                     ; Initialize loop counter
Lsave_gprs:
  add r6, r13, r5              ; Calculate r13 + i
  stw r6, 24(r3)               ; Save GPR to 24 + 4 * i (r3)
  lwz r6, 24(r4)               ; Restore GPR from 24 + 4 * i (r4)
  addi r5, r5, 4               ; Increment i by 4 (size of a GPR)
  cmpwi r5, 19 * 4             ; Check if all 19 registers (r13-r31) are processed
  blt Lsave_gprs               ; Loop if more registers remain

  ; Save and restore FPRs (f14 to f31)
  li r6, 0                     ; Initialize loop counter (offset = 0)
Lfprs_loop:
  add r7, r3, r6               ; Effective address: r7 = r3 + current offset
  stfd f14, 0(r7)              ; Save f14 + i at the calculated address
  add r7, r4, r6               ; Effective address: r7 = r4 + current offset
  lfd f14, 0(r7)               ; Restore f14 + i from the calculated address
  addi r6, r6, 8               ; Increment offset by 8 (size of an FPR)
  cmpwi r6, 18 * 8             ; Check if all 18 registers (f14–f31) are processed
  blt Lfprs_loop               ; Loop if more registers remain

  ; 16-byte alignment for vector registers
  addi r3, r3, (18 + 3) * 4 + 15
  rlwinm r3, r3, 0, 0, 27      ; Align r3 to 16 bytes
  addi r4, r4, (18 + 3) * 4 + 15
  rlwinm r4, r4, 0, 0, 27      ; Align r4 to 16 bytes

  ; Save and restore vector registers (v20 to v31)
  stvx v20, 0, r3              ; Save v20
  lvx v20, 0, r4               ; Restore v20

  li r5, 16                    ; Initialize offset for vector registers
  li r6, 21                    ; Start register index (v21 = v20 + 1)
Lsave_vectors:
  add r7, r3, r5               ; Calculate effective address for saving
  stvx v6, 0, r7               ; Save vector register
  add r7, r4, r5               ; Calculate effective address for restoring
  lvx v6, 0, r7                ; Restore vector register
  addi r5, r5, 16              ; Increment offset by 16 (vector register size)
  addi r6, r6, 1               ; Increment register index
  cmpwi r6, 32                 ; Stop when v31 is reached
  blt Lsave_vectors            ; Continue loop if more registers remain

  blr

  .globl _fiber_asm_invoke
_fiber_asm_invoke:

  lwz r3, 0(r1)
  lwz r12, 8(r1)
  mtctr r12
  stwu r1, -48(r1)
  stw r2, 24(r1)
  bctrl
  lwz r2, 24(r1)
  lwz r0, 72(r1)
  mtlr r0
  lwz r3, 64(r1)
  mr r1, r3
  blr

  .globl _fiber_asm_exec_on_stack
_fiber_asm_exec_on_stack:

  mflr r0
  mr r6, r31
  mr r12, r4
  mtctr r4
  mr r31, r1
  stw r0, 16(r1)
  mr r1, r5
  stw r6, -8(r1)
  stwu r1, -48(r1)
  stw r2, 24(r1)
  bctrl
  lwz r2, 24(r1)
  mr r3, r31
  lwz r31, 40(r1)
  mr r1, r3
  lwz r0, 16(r1)
  mtlr r0
  blr
