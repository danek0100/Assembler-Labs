code_seg segment
        ASSUME  CS:CODE_SEG,DS:code_seg,ES:code_seg
	org 100h  
Begin:      

CR		EQU		13
LF		EQU		10
Space	EQU		20h
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print_letter	macro	letter
	push	AX
	push	DX
	mov	DL, letter
	mov	AH,	02
	int	21h
	pop	DX
	pop	AX
	endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
print_mes	macro	message
	local	msg, nxt
	push	AX
	push	DX
	mov	DX, offset msg
	mov	AH,	09h
	int	21h
	pop	DX
	pop	AX
	jmp nxt
	msg	DB message,'$'
	nxt:
endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Seed 	dw ?                   ;macros generachii random chisla
;
rnd1 macro
	push dx 
	mov ax,Seed 
	add ax,7 
	mov dx,13 
	mul dx 
	mov Seed,ax  
	pop dx  
endm 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;code
print_mes 'Start mixing:'

mov ah, 1   ;poluchaem simvol
int 21h 

   
xor ah, ah 
mov cx, ax 
xor ax, ax 
push cx    ;     preobrasyem simvol v startovoe smeshenie generachii


mov CX, 30                   ;clear window
Clear_window: 
print_letter CR
print_letter LF
loop clear_window
 
                    
pop cx 
                                   ;generiryem col-vo priymoygolnikov
kol:
push cx  

kolv:         ;smeshayen i generiryem 
rnd1	 
loop kolv 

pop cx
dec cx  
                 ;oranichivayem kol-vo
xor ah,ah                                   
cmp AL, 0
je kol   
cmp AL, 8
jae kol

mov cx,ax              ;peredaym col-vo 
xor ax,ax
xor bx,bx
   
mov ax,0B800h                      ;zahodi, v bufer
mov es,ax  
mov di,2                             ;startovoe smeshenie
  
kolvo:    ;sozdaym priymoygolniki
push cx                    ;schytchik
add di, 494                 ;izmeneniy sheshenya
push di  
 
rnd1                           ;generator cveta
mov al,0DBh	                    ;maket pramoygolnika
rol ah, 1
     
push ax
xor bx, bx
rowandcol:                      
mov cx,1
rnd1	 
loop rowandcol 
cmp bx, 0
jne columss
xor ah,ah   
cmp AL, 0
je rowandcol 
cmp AL, 8
jae rowandcol 
mov bx, ax
push bx  
jmp rowandcol
columss: 
xor ah,ah   
cmp AL, 0
je rowandcol
cmp AL, 10
jae rowandcol            ;generiryem shiriny
mov bx, ax              ;sohranyem polychennyu shiriny
pop cx  
pop ax

New_line:                      ;pechat visotii
push CX 
mov cx, bx 

Next_blok:                      ;pechat shiriny 
mov es:[di],ax                   ;pechat odnogo bloka
add di,2
loop Next_blok 
               
add di,160
  
push ax
push bx

mov ax, bx
mov bx, 2
mul bx   
sub di, ax

pop bx
pop ax                 ;polychenie smesheniy dly sled stroki

pop cx
    
loop New_line                   ; perehod na novyy stroky
  
pop di 
pop cx
      
loop kolvo                      ;end cycle



mov ah,10h
int 16h
int 20h
code_seg ends
     end Begin