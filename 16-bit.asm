.model small 
.stack 100h

.data
    ; Буфер ввода
    cmd_buffer label byte
    cmd_max_len db 30
    cmd_act_len db ?
    cmd_text db 30 dup('$')
    
    ; Аргументы команд
    arg1_buffer label byte
    arg1_max db 20
    arg1_act db ?
    arg1_text db 20 dup('$')
    
    arg2_buffer label byte
    arg2_max db 20
    arg2_act db ?
    arg2_text db 20 dup('$')
    
    arg3_buffer label byte
    arg3_max db 20
    arg3_act db ?
    arg3_text db 20 dup('$')
    
    ; Для графики
    handle dw ?
    header db 54 dup (?)
    palette db 1024 dup (?)
    img_buffer db 64000 dup (?)
    
    ; Для файловых операций
    file_handle dw ?
    filename_buffer db 30 dup(0)
    file_data db 64000 dup(0)    ; Буфер для данных
    file_size dw 0
    
    ; Для чисел
    num1 dw 0
    num2 dw 0
    result dw 0
    temp_str db 10 dup('$')
    
    ; Строки
    msg_welcome db 'HOS v1.0$'
    msg_unknown db 'Unknown command!$'
    msg_created db ' created!$'
    msg_reading db ' reading...$'
    msg_graphics_on db 'Graphics ON!$'
    msg_bad_arg db 'Bad arg!$'
    msg_equal db 'EQUAL$'
    msg_not_equal db 'NOT EQUAL$'
    msg_imported db ' imported!$'
    msg_exported db ' exported!$'
    msg_running db 'Running program: $'
    msg_test_done db 'Program finished$'
    msg_test_error db 'File not found!$'
    msg_error db 'File not found!$'
    msg_import db 'Importing...$'
    msg_export db 'Exporting...$'
    msg_result db ' = result$'
    msg_div_zero db 'Division by zero!$'
    msg_file_ok db 'File OK$'
    msg_file_error db 'File error!$'
    newline db 13,10,'$'
    grp_str db 'grp',0
    ext_flg db '.flg',0

.code
start:
    mov ax, @data
    mov ds, ax
    
    lea dx, msg_welcome
    call print_str
    call new_line

; ======================================================
; ГЛАВНЫЙ ЦИКЛ
; ======================================================
main_loop:
    call new_line
    mov ah, 02h
    mov dl, '>'
    int 21h
    mov dl, ' '
    int 21h
    
    lea dx, cmd_buffer
    mov ah, 0Ah
    int 21h
    call new_line
    
    lea si, cmd_text
    call parse_command
    
    cmp al, 1
    jne unknown_cmd
    
    jmp main_loop

; ======================================================
; ПАРСИНГ КОМАНД
; ======================================================
parse_command proc
    lea di, cmd_text
    
    lea si, cmd_crt_str
    call strcmp
    je cmd_crt_handler
    
    lea si, cmd_rdg_str
    call strcmp
    je cmd_rdg_handler
    
    lea si, cmd_dsp_str
    call strcmp
    je cmd_dsp_handler
    
    lea si, cmd_enb_str
    call strcmp
    je cmd_enb_handler
    
    lea si, cmd_mmr_str
    call strcmp
    je cmd_mmr_handler
    
    lea si, cmd_cnd_str
    call strcmp
    je cmd_cnd_handler
    
    lea si, cmd_import_str
    call strcmp
    je cmd_import_handler
    
    lea si, cmd_export_str
    call strcmp
    je cmd_export_handler
    
    lea si, cmd_test_str
    call strcmp
    je cmd_test_handler
    
    lea si, cmd_add_str
    call strcmp
    je cmd_add_handler
    
    lea si, cmd_sub_str
    call strcmp
    je cmd_sub_handler
    
    lea si, cmd_mul_str
    call strcmp
    je cmd_mul_handler
    
    lea si, cmd_div_str
    call strcmp
    je cmd_div_handler
    
    mov al, 0
    ret
parse_command endp

; ======================================================
; КОМАНДЫ
; ======================================================

cmd_crt_str db 'crt',0
cmd_crt_handler:
    call read_arg1
    call read_arg2
    lea dx, arg1_text
    call print_str
    lea dx, msg_created
    call print_str
    ret

cmd_rdg_str db 'rdg',0
cmd_rdg_handler:
    call read_arg1
    lea dx, arg1_text
    call print_str
    lea dx, msg_reading
    call print_str
    ret

cmd_dsp_str db 'dsp',0
cmd_dsp_handler:
    call read_arg1
    lea dx, arg1_text
    call print_str
    call new_line
    ret

cmd_enb_str db 'enb',0
cmd_enb_handler:
    call read_arg1
    lea si, arg1_text
    lea di, grp_str
    call strcmp
    je enable_graphics
    lea dx, msg_bad_arg
    call print_str
    ret

enable_graphics:
    mov ax, 0013h
    int 10h
    lea dx, msg_graphics_on
    call print_str
    ret

cmd_mmr_str db 'mmr',0
cmd_mmr_handler:
    call read_arg1
    lea dx, arg1_text
    call show_picture
    ret

cmd_cnd_str db 'cnd',0
cmd_cnd_handler:
    call read_arg1
    call read_arg2
    lea si, arg1_text
    lea di, arg2_text
    call strcmp
    je cnd_equal
    lea dx, msg_not_equal
    call print_str
    ret

cnd_equal:
    lea dx, msg_equal
    call print_str
    ret

; ======================================================
; IMPORT — ЗАГРУЗКА ДАННЫХ ИЗ .FLG ФАЙЛА
; ======================================================
cmd_import_str db 'import',0
cmd_import_handler:
    lea dx, msg_import
    call print_str
    call read_arg1
    
    ; Добавляем расширение .flg
    lea si, arg1_text
    call add_extension
    
    ; Открываем файл
    mov ah, 3Dh
    mov al, 0                ; Режим чтения
    lea dx, arg1_text
    int 21h
    jc import_error
    
    mov [file_handle], ax
    
    ; Читаем данные из файла
    mov ah, 3Fh
    mov bx, [file_handle]
    mov cx, 64000            ; Максимальный размер
    lea dx, file_data
    int 21h
    
    mov [file_size], ax      ; Сохраняем реальный размер
    
    ; Закрываем файл
    mov ah, 3Eh
    mov bx, [file_handle]
    int 21h
    
    lea dx, arg1_text
    call print_str
    lea dx, msg_imported
    call print_str
    
    ; Показываем размер
    mov ax, [file_size]
    call print_size
    ret

import_error:
    lea dx, msg_error
    call print_str
    ret

; ======================================================
; EXPORT — СОХРАНЕНИЕ ДАННЫХ В .FLG ФАЙЛ
; ======================================================
cmd_export_str db 'export',0
cmd_export_handler:
    lea dx, msg_export
    call print_str
    call read_arg1
    
    ; Добавляем расширение .flg
    lea si, arg1_text
    call add_extension
    
    ; Проверяем, есть ли данные для экспорта
    cmp word ptr [file_size], 0
    je export_no_data
    
    ; Создаём файл
    mov ah, 3Ch
    xor cx, cx               ; Обычный атрибут
    lea dx, arg1_text
    int 21h
    jc export_error
    
    mov [file_handle], ax
    
    ; Записываем данные
    mov ah, 40h
    mov bx, [file_handle]
    mov cx, [file_size]
    lea dx, file_data
    int 21h
    
    cmp ax, [file_size]
    jne export_write_error
    
    ; Закрываем файл
    mov ah, 3Eh
    mov bx, [file_handle]
    int 21h
    
    lea dx, arg1_text
    call print_str
    lea dx, msg_exported
    call print_str
    
    mov ax, [file_size]
    call print_size
    ret

export_no_data:
    lea dx, msg_file_error
    call print_str
    lea dx, newline
    call print_str
    lea dx, msg_file_error
    call print_str
    lea dx, newline
    call print_str
    ret

export_error:
    lea dx, msg_file_error
    call print_str
    ret

export_write_error:
    lea dx, msg_file_error
    call print_str
    ret

; ======================================================
; ДОБАВЛЕНИЕ РАСШИРЕНИЯ .FLG
; ======================================================
add_extension proc
    push si
    push di
    push ax
    
    ; Ищем конец строки
    mov di, si
    xor ax, ax
add_ext_loop:
    cmp byte ptr [di], 0
    je add_ext_found
    cmp byte ptr [di], '$'
    je add_ext_found
    inc di
    jmp add_ext_loop
    
add_ext_found:
    ; Проверяем, есть ли уже расширение
    mov si, di
    dec si
    cmp byte ptr [si], '.'
    je add_ext_done      ; Если есть точка, не добавляем
    
    ; Добавляем .flg
    mov byte ptr [di], '.'
    inc di
    mov byte ptr [di], 'f'
    inc di
    mov byte ptr [di], 'l'
    inc di
    mov byte ptr [di], 'g'
    inc di
    mov byte ptr [di], 0
    
add_ext_done:
    pop ax
    pop di
    pop si
    ret
add_extension endp

; ======================================================
; ВЫВОД РАЗМЕРА ФАЙЛА
; ======================================================
print_size proc
    push ax
    push bx
    push cx
    push dx
    
    lea dx, newline
    call print_str
    lea dx, msg_file_ok
    call print_str
    
    mov ax, [file_size]
    call int_to_str_temp
    
    lea dx, temp_str
    call print_str
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_size endp

int_to_str_temp proc
    push ax
    push bx
    push cx
    push dx
    push si
    
    lea si, temp_str
    mov cx, 0
    mov bx, 10
    
int_to_str_temp_loop:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz int_to_str_temp_loop
    
int_to_str_temp_store:
    pop dx
    add dl, '0'
    mov [si], dl
    inc si
    loop int_to_str_temp_store
    
    mov byte ptr [si], 0
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
int_to_str_temp endp

; ======================================================
; TEST — ЗАПУСК ПРОГРАММЫ ИЗ ФАЙЛА
; ======================================================
cmd_test_str db 'test',0
cmd_test_handler:
    call read_arg1          ; Имя файла
    
    lea dx, msg_running
    call print_str
    lea dx, arg1_text
    call print_str
    call new_line
    
    ; Открываем файл
    mov ah, 3Dh
    mov al, 0
    lea dx, arg1_text
    int 21h
    jc test_error
    
    mov [handle], ax
    
test_read_loop:
    ; Читаем строку из файла
    mov ah, 3Fh
    mov bx, [handle]
    mov cx, 30
    lea dx, cmd_text
    int 21h
    
    cmp ax, 0               ; Конец файла?
    je test_done
    
    ; Выполняем команду
    lea si, cmd_text
    call parse_command
    
    jmp test_read_loop

test_done:
    mov ah, 3Eh
    mov bx, [handle]
    int 21h
    
    lea dx, msg_test_done
    call print_str
    ret

test_error:
    lea dx, msg_test_error
    call print_str
    ret

; ======================================================
; АРИФМЕТИКА
; ======================================================

cmd_add_str db 'add',0
cmd_add_handler:
    call read_arg1
    call read_arg2
    call read_arg3
    
    lea si, arg2_text
    call str_to_int
    mov [num1], ax
    
    lea si, arg3_text
    call str_to_int
    mov [num2], ax
    
    mov ax, [num1]
    add ax, [num2]
    mov [result], ax
    
    lea si, arg1_text
    mov ax, [result]
    call int_to_str
    
    lea dx, arg1_text
    call print_str
    lea dx, msg_result
    call print_str
    ret

cmd_sub_str db 'sub',0
cmd_sub_handler:
    call read_arg1
    call read_arg2
    call read_arg3
    
    lea si, arg2_text
    call str_to_int
    mov [num1], ax
    
    lea si, arg3_text
    call str_to_int
    mov [num2], ax
    
    mov ax, [num1]
    sub ax, [num2]
    mov [result], ax
    
    lea si, arg1_text
    mov ax, [result]
    call int_to_str
    
    lea dx, arg1_text
    call print_str
    lea dx, msg_result
    call print_str
    ret

cmd_mul_str db 'mul',0
cmd_mul_handler:
    call read_arg1
    call read_arg2
    call read_arg3
    
    lea si, arg2_text
    call str_to_int
    mov [num1], ax
    
    lea si, arg3_text
    call str_to_int
    mov [num2], ax
    
    mov ax, [num1]
    mov bx, [num2]
    mul bx
    mov [result], ax
    
    lea si, arg1_text
    mov ax, [result]
    call int_to_str
    
    lea dx, arg1_text
    call print_str
    lea dx, msg_result
    call print_str
    ret

cmd_div_str db 'div',0
cmd_div_handler:
    call read_arg1
    call read_arg2
    call read_arg3
    
    lea si, arg2_text
    call str_to_int
    mov [num1], ax
    
    lea si, arg3_text
    call str_to_int
    mov [num2], ax
    
    cmp word ptr [num2], 0
    je div_zero
    
    mov ax, [num1]
    xor dx, dx
    mov bx, [num2]
    div bx
    mov [result], ax
    
    lea si, arg1_text
    mov ax, [result]
    call int_to_str
    
    lea dx, arg1_text
    call print_str
    lea dx, msg_result
    call print_str
    ret

div_zero:
    lea dx, msg_div_zero
    call print_str
    ret

; ======================================================
; ПРЕОБРАЗОВАНИЯ
; ======================================================

str_to_int proc
    push bx
    push cx
    push dx
    push si
    
    xor ax, ax
    mov bx, 10
    xor cx, cx
    
str_to_int_loop:
    lodsb
    cmp al, 0
    je str_to_int_done
    cmp al, '$'
    je str_to_int_done
    cmp al, 13
    je str_to_int_done
    cmp al, 10
    je str_to_int_done
    
    sub al, '0'
    cmp al, 9
    ja str_to_int_done
    
    push ax
    mov ax, cx
    mul bx
    mov cx, ax
    pop ax
    
    add cx, ax
    jmp str_to_int_loop
    
str_to_int_done:
    mov ax, cx
    
    pop si
    pop dx
    pop cx
    pop bx
    ret
str_to_int endp

int_to_str proc
    push ax
    push bx
    push cx
    push dx
    push si
    
    mov cx, 0
    mov bx, 10
    
int_to_str_loop:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz int_to_str_loop
    
int_to_str_store:
    pop dx
    add dl, '0'
    mov [si], dl
    inc si
    loop int_to_str_store
    
    mov byte ptr [si], 0
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
int_to_str endp

; ======================================================
; ВСПОМОГАТЕЛЬНЫЕ
; ======================================================

read_arg1 proc
    lea dx, arg1_buffer
    mov ah, 0Ah
    int 21h
    call new_line
    ret
read_arg1 endp

read_arg2 proc
    lea dx, arg2_buffer
    mov ah, 0Ah
    int 21h
    call new_line
    ret
read_arg2 endp

read_arg3 proc
    lea dx, arg3_buffer
    mov ah, 0Ah
    int 21h
    call new_line
    ret
read_arg3 endp

strcmp proc
    push si
    push di
    push bx
strcmp_loop:
    lodsb
    mov bl, [di]
    cmp al, bl
    jne strcmp_not_equal
    test al, al
    jz strcmp_equal
    inc di
    jmp strcmp_loop
strcmp_equal:
    pop bx
    pop di
    pop si
    mov ax, 1
    ret
strcmp_not_equal:
    pop bx
    pop di
    pop si
    mov ax, 0
    ret
strcmp endp

print_str proc
    mov ah, 09h
    int 21h
    ret
print_str endp

new_line proc
    lea dx, newline
    call print_str
    ret
new_line endp

show_picture proc
    pusha
    
    mov ah, 3Dh
    mov al, 0
    int 21h
    jc error_pic
    mov [handle], ax
    
    mov ah, 3Fh
    mov bx, [handle]
    mov cx, 54
    lea dx, header
    int 21h
    
    mov ah, 3Fh
    mov bx, [handle]
    mov cx, 1024
    lea dx, palette
    int 21h
    
    mov ah, 3Fh
    mov bx, [handle]
    mov cx, 64000
    lea dx, img_buffer
    int 21h
    
    mov ah, 3Eh
    mov bx, [handle]
    int 21h
    
    mov ax, 0013h
    int 10h
    
    lea si, palette
    mov dx, 3C8h
    mov al, 0
    out dx, al
    inc dx
    
    mov cx, 256
load_pal:
    lodsb
    shr al, 2
    out dx, al
    lodsb
    shr al, 2
    out dx, al
    lodsb
    shr al, 2
    out dx, al
    add si, 1
    loop load_pal
    
    mov ax, 0A000h
    mov es, ax
    lea si, img_buffer
    mov di, 0
    mov cx, 64000
    rep movsb
    
    popa
    ret
    
error_pic:
    lea dx, msg_error
    call print_str
    ret
show_picture endp

end start