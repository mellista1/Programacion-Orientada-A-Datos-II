extern malloc
extern free
extern fprintf

section .data

section .text

global strCmp
global strClone
global strDelete
global strPrint
global strLen

; ** String **

; int32_t strCmp(char* a, char* b) a [rdi], b [rsi]
strCmp:
	push rbp
	mov rbp, rsp

loop:
	mov dl, BYTE [rdi] ; a
	mov cl, BYTE [rsi] ; b

	cmp dl, cl
	je equal
	jg greater
	jl lower

greater: ;(A > B)
	mov rax,-1
	jmp end


lower: ;(A < B)
	mov rax,1
	jmp end
	
equal: ;(A == B)
	cmp dl,0 ;Me fijo si dl es el final del string, recordar que dl=cl debido al jump
	je equalStrings
	inc rdi
	inc rsi
	jmp loop

equalStrings: ;(A[] == B[])
	mov rax,0
	jmp end

end:
	pop rbp
	ret


; char* strClone(char* a) a[rdi]
strClone: 
	push rbp 
	mov rbp, rsp ;Alineado a 16

	push rdi ;Desalineado en 8
	sub rsp,0x08 ;Alineado en 16

	call strLen 
				

	mov rdi, rax
	inc rdi

	call malloc ;en rax tenemos puntero a la memoria desalojada

	add rsp,0x08
	pop rdi
	;desde aca tenemos en rax la direccion de memoria
	;y en rdi tenemos el puntero al string  original

	xor rsi, rsi ; indice = 0
loop3:
	mov cl, byte [rdi + rsi]
	mov [rax + rsi], cl

	inc rsi

	cmp cl, 0
	jne loop3

	
	
fin3:
	pop rbp
	ret

; void strDelete(char* a)
strDelete:
	push rbp
	mov rbp, rsp

	call free

	pop rbp
	ret

; void strPrint(char* a, FILE* pFile) ; a : rdi , pfile :rsi
strPrint:
	push rbp
	mov rbp, rsp

	mov rcx, rdi
	mov rdx, rsi

	mov rdi, rcx
	mov rsi, rdx
	
	call fprintf

	pop rbp
	ret
	

; uint32_t strLen(char* a)
strLen:
	push rbp
	mov rbp, rsp
	xor rax,rax
loop2:
	mov dl, BYTE [rdi] ; a
	cmp dl,0
	je fin
	inc rax
	inc rdi
	jmp loop2

fin:
	pop rbp
	ret




