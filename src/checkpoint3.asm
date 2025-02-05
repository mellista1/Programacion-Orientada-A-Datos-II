

;########### ESTOS SON LOS OFFSETS Y TAMAÑO DE LOS STRUCTS
; Completar:
NODO_LENGTH	EQU	0x20
LONGITUD_OFFSET	EQU 0x18

PACKED_NODO_LENGTH	EQU	0X15
PACKED_LONGITUD_OFFSET	EQU	0X11 

;########### SECCION DE DATOS
section .data

;########### SECCION DE TEXTO (PROGRAMA)
section .text

;########### LISTA DE FUNCIONES EXPORTADAS
global cantidad_total_de_elementos
global cantidad_total_de_elementos_packed

;########### DEFINICION DE FUNCIONES
;extern uint32_t cantidad_total_de_elementos(lista_t* lista);
;registros: lista[rdi]
cantidad_total_de_elementos:
	push rbp
	mov rbp, rsp
	
	xor rax, rax   ;inicializo rax en 0
	mov rsi, [rdi] ; rsi = nodo* 

	loop:
		cmp rsi, 0 ;vemos si apunta a nullptr
		je fin	   ;termine
		add eax, DWORD[rsi + LONGITUD_OFFSET] ;
		mov rsi, [rsi]
		jmp loop


	fin:
		pop rbp
		ret

;extern uint32_t cantidad_total_de_elementos_packed(packed_lista_t* lista);
;registros: lista[rdi]
cantidad_total_de_elementos_packed:
	push rbp
	mov rbp, rsp
	
	xor rax, rax   ;inicializo rax en 0
	mov rsi, [rdi] ; rsi = nodo* 

	loop2:
		cmp rsi, 0 ;vemos si apunta a nullptr
		je fin2	   ;termine
		add eax, DWORD [rsi + PACKED_LONGITUD_OFFSET] ;
		mov rsi, [rsi]
		jmp loop2


	fin2:
		pop rbp
		ret
	ret

