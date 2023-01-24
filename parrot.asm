default rel

global _main

SYS_EXIT  equ 0x2000001
SYS_READ  equ 0x2000003	
SYS_WRITE equ 0x2000004
SYS_OPEN  equ 0x2000005
SYS_CLOSE equ 0x2000006

extern _malloc
	
section .text

_main:
;; open random file
	mov rax, SYS_OPEN
	mov rdi, dev_random ; file name
	mov rsi, 0      ; read mode
	syscall
	mov [random_fd], rax 	; save file descriptor to variable

;; read input
	mov rax, SYS_READ
	mov rdi, 0      ; fd: stdin
	mov rsi, input  ; dest: input
	mov rdx, 140    ; length: 140
	syscall
	
;; iterate the characters of the message
	xor r9, r9 		; init counter
	
write_char:
	mov r8, input   ; start of message
	add r8, r9		; offset by counter

	mov rdi, [r8]   ; load byte to first argument
	push r8         ; save character index
	push r9         ; save counter
	call change_vowel
	pop r9          ; pop counter
	pop r8          ; pop character index
	mov [r8], al    ; update character with result of change_vowel
	
	mov rax, SYS_WRITE
	mov rdi, 1 		; write to stdout
	mov rsi, r8		; write the character index (input + r9)
	mov rdx, 1 		; write 1 byte
	syscall			; perform write operation
	inc r9			; increment counter
 	cmp r9, 140		; check if counter is end of loop
	jne write_char	

;; close file
	mov rax, SYS_CLOSE
	mov rdi, [random_fd]	; load file descriptor of /dev/random into first argument
	syscall	

;; exit
	mov rax, SYS_EXIT	
	mov rdi, 0		; process' exit code
	syscall

change_vowel:
	mov rax, rdi 		; load first argument 
	cmp al, "a"		; compare LS byte from rax
	je is_vowel_lc
	cmp al, "e"
	je is_vowel_lc
	cmp al, "i"
	je is_vowel_lc
	cmp al, "o"
	je is_vowel_lc
	cmp al, "u"
	je is_vowel_lc
	cmp al, "A"
	je is_vowel_uc
	cmp al, "E"
	je is_vowel_uc
	cmp al, "I"
	je is_vowel_uc
	cmp al, "O"
	je is_vowel_uc
	cmp al, "U"
	je is_vowel_uc					
	ret			; not a vowel, al holds return value
is_vowel_lc:
	call random_vowel_lc
	ret
is_vowel_uc:
	call random_vowel_uc
	ret

random_vowel_lc:
	call random_idx
	mov rbx, vowels_lc
	add rbx, rax 		; add random index return value
	movzx rax, byte [rbx] 	; index into the vowels and put the result in rax
	ret

random_vowel_uc:
	call random_idx
	mov rbx, vowels_uc	
	add rbx, rax 		; add random index return value
	movzx rax, byte [rbx] 	; index into the vowels and put the result in rax
	ret
	
random_idx: 			; get a random index 0 - 4
	sub rsp, 1		; reserve a byte on the stack
	mov rax, SYS_READ
	mov rdi, [random_fd]	; file descriptor for /dev/random
	mov rsi, rsp		; read data to the stack
	mov rdx, 1		; read 1 byte
	syscall
	xor rax, rax		; zero rax
	mov al, [rsp]		; get the top byte of the stack
	add rsp, 1		; un-reserve the space
	mov rbx, 5		; set up 5 as the divisor
	div bl			; divide ax (0 + al) by bl. quotient goes to al, remainder goes to ah
	mov al, ah		; move ah to least significant bits
	movzx rax, al		; zero extend to clear out rest of rax
	ret	
	
section .data
dev_random: db "/dev/urandom", 0
random_fd: dq 0
helloworld: db "Hello, world!", 10
.len: equ $ - helloworld
vowels_lc: db "aeiou"
vowels_uc: db "AEIOU"

section .bss
input:	resb 140
