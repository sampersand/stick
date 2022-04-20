	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 12, 0	sdk_version 12, 0
	.globl	_push                           ; -- Begin function push
	.p2align	2
_push:                                  ; @push
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #16                     ; =16
	.cfi_def_cfa_offset 16
	str	x0, [sp, #8]
	ldr	x8, [sp, #8]
	adrp	x11, _idx@PAGE
	ldr	x9, [x11, _idx@PAGEOFF]
	add	x10, x9, #8                     ; =8
	str	x10, [x11, _idx@PAGEOFF]
	str	x8, [x9]
	add	sp, sp, #16                     ; =16
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_pop                            ; -- Begin function pop
	.p2align	2
_pop:                                   ; @pop
	.cfi_startproc
; %bb.0:
	adrp	x10, _idx@PAGE
	ldr	x8, [x10, _idx@PAGEOFF]
	subs	x9, x8, #8                      ; =8
	str	x9, [x10, _idx@PAGEOFF]
	ldur	x0, [x8, #-8]
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_add                            ; -- Begin function add
	.p2align	2
_add:                                   ; @add
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #32                     ; =32
	stp	x29, x30, [sp, #16]             ; 16-byte Folded Spill
	add	x29, sp, #16                    ; =16
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	bl	_pop
	str	x0, [sp, #8]
	bl	_pop
	ldr	x8, [sp, #8]
	add	x0, x0, x8
	ldp	x29, x30, [sp, #16]             ; 16-byte Folded Reload
	add	sp, sp, #32                     ; =32
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_main                           ; -- Begin function main
	.p2align	2
_main:                                  ; @main
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #32                     ; =32
	stp	x29, x30, [sp, #16]             ; 16-byte Folded Spill
	add	x29, sp, #16                    ; =16
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	mov	x0, #34
	bl	_push
	mov	x0, #45
	bl	_push
	bl	_add
	mov	x8, x0
	adrp	x0, l_.str@PAGE
	add	x0, x0, l_.str@PAGEOFF
	mov	x9, sp
	str	x8, [x9]
	bl	_printf
	mov	w0, #0
	ldp	x29, x30, [sp, #16]             ; 16-byte Folded Reload
	add	sp, sp, #32                     ; =32
	ret
	.cfi_endproc
                                        ; -- End function
	.comm	_globals,800000,3               ; @globals
	.section	__DATA,__data
	.globl	_idx                            ; @idx
	.p2align	3
_idx:
	.quad	_globals

	.section	__TEXT,__cstring,cstring_literals
l_.str:                                 ; @.str
	.asciz	"%lld\n"

.subsections_via_symbols
