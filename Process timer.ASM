.286
code_seg segment
ASSUME CS:code_seg, DS:code_seg,SS:code_seg
org 100h
start:
	jmp init ;переход на интилизацию
	
	
    ;Объявление переменных
	int_2Fh_vector  DD  ? ;для сохранения векторов
	old_09h         DD  ?
	old_1Ch         DD  ?
	
	;для подсчёта времени
	tic dw ? 
	sec dw ?
	
	;для вывода на экран
	run_time_message db 'Have passed  - ' 
	for4 db ?
	for3 db ?
	for2 db ?
	for1 db ?
	runte db ' - seconds since the program was launched!',0Ah,0Dh,'$'
	
; Задаём новый обработчик 9-го прерывания	
new_09h proc far 

	pushf			    ;сохраняем флаги
	push    AX
    in      AL, 60h     ;загружаем сканкод  
	cmp AL, 20 			;сравниваем сканкод со сканкодом нужной клавиши, в нашем случае "t"
	je t_pressed 		;если нажали, то идём дальше
	
	;Если не t или не нажат ALT, то востанавливаем предыдущие значения 9-го прерывания. 
	no_hot:     
    pop     AX                
	popf
    jmp     dword ptr CS:[old_09h]
	
	;Проверяем нажатие ALT
	t_pressed: 
	push ES  
	mov AX, 40h
	mov ES, AX
	mov AL, ES: [17h] 
	pop ES 
	cmp AL, 08h 
	je hotkey ;если нажат, то переходим на основную часть.
	
	jmp no_hot
	
hotkey:

	;Часть отвечающая за основную функцию программы.
	;Готовим программу к резидентной работе и взаимодействию с другими частями. 
    sti                 
    in      AL,61h      
    or      AL,80h      
    out     61h,AL      
    and     AL,7Fh      
    out     61h,AL     
	pusha
	
	;Очищаем поля для вывода
	mov DL, 0
	mov CS:for4, DL  
	mov CS:for3, DL 
	mov CS:for2, DL 
	mov CS:for1, DL 	
	
	mov DX, CS:sec ;преобразовываем секунды в нужную для вывода форму
	
	;Предварительно убираем все значения что больше 1000 (возможно модернизировать программу и на большее время).
	add DX, 10000 
	op10000:
	sub DX, 10000
	cmp DX, 10000
	jge op10000
	
	;Далее алгоритм для каждой части аналогичен и заключается в нахождении остатка от деления на 1000 (100, 10)
	;с параллельным запоминанием целой части, для того чтобы выводить от 0-9.
	add DX, 1000 
	op1000:
	sub DX, 1000
	add CS:for4, 1
	cmp DX, 1000
	jge op1000
	
	sub CS:for4, 1
	
	;Трансформируем в аски код для корректного вывода
	add CS:for4, 30h 
	
	add DX, 100
	op100:
	sub DX, 100
	add CS:for3, 1
	cmp DX, 100
	jge CS:op100
	sub CS:for3, 1
	add CS:for3, 30h 
	
	add DX, 10
	op10:
	sub DX, 10
	add CS:for2, 1
	cmp DX, 10
	jge CS:op10
	sub CS:for2, 1
	add CS:for2, 30h 
	
	mov CS:for1, DL
	add CS:for1, 30h
	
	push DS
	push CS
	
	pop DS
	
	;Организуем вывод нашего времени
	mov AH, 9 
	mov DX, offset run_time_message
	int 21h
	
	pop DS
	popa
	
	;Заканчиваем работу по выводу времени, вызваной нажатием горячей клавиши.
    cli
    mov     AL, 20h    
    out     20h,AL       
    pop     AX
	popf
    iret	
new_09h     endp

; Для подсчёта времени будем использовать обработчик прерывания таймера, который вызывается 18 раз в секунду.

new_1Ch proc 
	push DX
	
	;Проверяем сколько тиков было
	mov DX, CS:tic     
	inc DX
	
	;Если 18 тиков, увеличиваем количесвто секунд, зануляем количесво тиков, если нет продолжаем считать.
	cmp DX, 18
	jl no_sec   
	
	mov DX, CS:sec     
	inc DX
	mov CS:sec, DX
	mov DX, 0
	
	no_sec:
	mov CS:tic, DX
	pop DX
	jmp     dword ptr CS:[old_1Ch] 
	iret
new_1Ch endp


;Задаём обработчик мультиплексного прерывания для нашей программы.

int_2Fh proc far 
    cmp     AH,0C7h         
    jne     Pass_2Fh       
    cmp     AL,00h          
    je      inst    
	cmp     AL,01h          
    je      unins          	
    jmp     short Pass_2Fh  

;Для проверки статуса загрузки	

inst: 
    mov     AL,0FFh         
    iret
	
Pass_2Fh:
    jmp dword PTR CS:[int_2Fh_vector]

;Организация проверки на возможность выгрузки резидентной программы
; Для этого сравниваем наши адреса прерываний с актуальными	

unins:  
    push    BX
    push    CX
    push    DX
    push    ES
	
    mov     CX,CS   
    mov     AX,3509h    
    int     21h 
	
    mov     DX,ES
    cmp     CX,DX
    jne     Not_remove
	
    cmp     BX, offset CS:new_09h 
    jne     Not_remove
	
    mov     AX,352Fh    
    int     21h 
    mov     DX,ES
    cmp     CX,DX
    jne     Not_remove
	
    cmp     BX, offset CS:int_2Fh
    jne     Not_remove
	
	mov     AX,351Ch    
    int     21h 
    mov     DX,ES
    cmp     CX,DX
    jne     Not_remove
	
    cmp     BX, offset CS:new_1Ch
    jne     Not_remove
	
    push    DS
	lds     DX, CS:old_09h  
    mov     AX,2509h       
    int     21h
	
	lds     DX, CS:int_2Fh_vector   
    mov     AX,252Fh
    int     21h
	
	lds     DX, CS:old_1Ch   
    mov     AX,251Ch
    int     21h
	
    pop     DS
    mov     ES,CS:2Ch       
    mov     AH, 49h         
    int     21h
	
    mov     AX, CS
    mov     ES, AX          
    mov     AH, 49h         
    int     21h
	
    mov     AL,0Fh          
    jmp     short pop_ret
	
Not_remove:
    mov     AL,0F0h   
	
pop_ret:
    pop     ES
    pop     DX
    pop     CX
    pop     BX
    iret
int_2Fh endp

;Интилизация нашей программы, её запуск.

init:
	mov SI, 130 ;загружаем ключ
	lodsb
	mov AH, 0
	mov key, AX
	
;Установки	нашей программы, если это необходимо.

install:
	mov AX,0C700h 
	int 2Fh 
	
	cmp AL,0FFh
	je  installed ; Если программа уже установлена, то уходим с установки.
	
	mov AX,352Fh
	int 21h
	
	;Сохраняем старые вектора
	mov word ptr int_2Fh_vector,BX
	mov word ptr int_2Fh_vector+2,ES
	
	;Устанавливаем новые вектора для обновлённых прерываний.
	mov DX,offset int_2Fh
	mov AX,252Fh
	int 21h
	
	mov AX,3509h                                                         
    int 21h
	
    mov word ptr old_09h,BX   
    mov word ptr old_09h+2,ES
	
    mov DX,offset new_09h
    mov AX,2509h                          
    int 21h
	
	mov AX,351Ch                          
    int 21h
	
	mov word ptr old_1Ch,BX   
    mov word ptr old_1Ch+2,ES
	
    mov DX,offset new_1Ch                                              
    mov AX,251Ch                          
    int 21h	
	
	mov DX, offset s_i
	mov AH, 09h
	int 21h
	
	mov DX,offset init           
    int 27h   
	
;Если программа была установлена ранее, то проверяем не был ли передан ключ 'u', если был, то переходим на удаление
;Если нет, то выводим, что программа уже была установлена 	

installed:
	mov DX, 'u';ключ на выгрузку
	cmp key, DX
	jz uninstall
	mov DX, offset a_i
	mov AH, 09h
	int 21h
	int 20h
	
;Организация удаления программы по ключу. 

uninstall:

	;Вызываем мультиплексное прерывание для выгрузки
	mov AX,0C701h  
    int 2Fh             
	
    cmp AL,0F0h
    je  not_sucsess   ;Если не вышло удалить, то сообщаем об этом.
	
    cmp AL,0Fh
    jne not_sucsess
	
	;Если программа удалена из памяти, печатаем и завершаем работу нашей программы.
    mov DX,offset s_u 
    mov AH, 09h
	int 21h
    int 20h

;Распечатка неудачного удаления.
	
not_sucsess:
    mov DX,offset c_u  
    mov AH,09h
	int 21h
    int 20h
	int 20h
	
	;Блок сообщений для резидентной программы.
	
	s_i db 'The program is running and ready to use!',0Dh, 0Ah, 'Press "ALT" + "T" to print out the time!',0Dh, 0Ah, '"L2 u" for uninstall!' ,0Dh, 0Ah, '$'
	a_i db 'The program is already running!',0Dh, 0Ah, '$'
	s_u db 'The program was successfully deleted from memory!',0Dh,0Ah,'$'
	c_u db 'Unable to delete the program from memory!',0Dh,0Ah,'$'
	key dw 0
	
code_seg ends
end start