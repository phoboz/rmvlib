; The Removers'Library 
; Copyright (C) 2006-2008 Seb/The Removers
; http://removers.atari.org/
	
; This library is free software; you can redistribute it and/or 
; modify it under the terms of the GNU Lesser General Public 
; License as published by the Free Software Foundation; either 
; version 2.1 of the License, or (at your option) any later version. 

; This library is distributed in the hope that it will be useful, 
; but WITHOUT ANY WARRANTY; without even the implied warranty of 
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU 
; Lesser General Public License for more details. 

; You should have received a copy of the GNU Lesser General Public 
; License along with this library; if not, write to the Free Software 
; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA 

	include	"../jaguar.inc"
	include	"../screen/screen_def.s"

NB_PARAMS	equ	3
	
	.include	"../routine.s"

	.include	"render_def.s"
	
	.text

	.phrase
renderer:
	.gpu
	.org	0
.renderer_begin:
.render_polygon:
	move	PC,r0		; to relocate
	movei	#.renderer_params+4-.render_polygon,r1
	add	r0,r1		; relocate
	load	(r1),r14	; polygon list (not null)
	subq	#4,r1
	load	(r1),r15	; target screen
	movei	#A2_BASE,r1
	load	(r15+(SCREEN_DATA/4)),r2 ; screen address
	load	(r15+(SCREEN_FLAGS/4)),r3 ; flags
	store	r2,(r1)			  ; A2_BASE
	addq	#A2_FLAGS-A2_BASE,r1
	store	r3,(r1)
.render_one_polygon:
	load	(r14+(POLY_FLAGS/4)),r2		; load flags and size
	moveq	#VERTEX_SIZEOF,r3
	addq	#POLY_VERTICES,r14
	mult	r2,r3		; size of vertices in bytes
	shrq	#16,r2		; flags
	;; next polygon
	subq	#POLY_VERTICES,r14
	movei	#.render_one_polygon-.render_polygon,r1
	load	(r14),r14
	add	r0,r1
	cmpq	#0,r14
	jump	ne,(r1)
	nop
	;; done
	;; return from sub routine and clear mutex
	movei	#.renderer_params+8-.renderer_begin,r1	
	moveq	#0,r2
	add	r0,r1
	load	(r31),r0	; return address
	addq	#4,r31		; restore stack
	jump	(r0)		; return
	store	r2,(r1)		; clear mutex
	.long
.renderer_params:
	.rept	NB_PARAMS
	dc.l	0
	.endr
	.long
.renderer_end:	

RENDERER_SIZE	equ	.renderer_end-.renderer_begin
RENDERER_RENDER	equ	.render_polygon-.renderer_begin	
RENDERER_PARAMS equ	.renderer_params-.renderer_begin
	
	.print	"Renderer routine size: ", RENDERER_SIZE
	.print	"Render: ",RENDERER_RENDER

	.68000
	.text
	
	.extern _bcopy
	.globl  _init_renderer

;;; void *init_renderer(void *gpu_addr);
_init_renderer:
	pea	RENDERER_SIZE
	move.l	4+4(sp),-(sp)
	pea	renderer
	jsr	_bcopy
	lea	12(sp),sp
	move.l	4(sp),d0
	move.l	d0,renderer_gpu_address
	add.l	#RENDERER_SIZE,d0
	rts

	.globl	_render_polygon
;;; void render_polygon(screen *target, polygon *p)
_render_polygon:
	move.l	renderer_gpu_address,a0
	lea	RENDERER_PARAMS(a0),a1
	move.l	4(sp),(a1)+
	move.l	8(sp),(a1)+
	move.l	#$80000000,(a1)
	lea	RENDERER_RENDER(a0),a1
	jsr_gpu	a1
	lea	RENDERER_PARAMS+8(a0),a0
.wait:
	tst.l	(a0)
	bmi.s	.wait
	rts
	
	.data
	.phrase
	dc.b	'Software Renderer by Seb/The Removers'
	.phrase

	.bss
	.long
renderer_gpu_address:
	ds.l	1