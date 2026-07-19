; ==========================================================
; HOS v2.0 - 64-bit version with GDI Graphics
; Компилятор: MASM64 (ml64.exe)
; ==========================================================

option casemap:none

; ==========================================================
; INCLUDES
; ==========================================================
include \masm64\include\windows.inc
include \masm64\include\kernel32.inc
include \masm64\include\user32.inc
include \masm64\include\gdi32.inc
includelib \masm64\lib\kernel32.lib
includelib \masm64\lib\user32.lib
includelib \masm64\lib\gdi32.lib

; ==========================================================
; DATA SECTION
; ==========================================================
.data
    ; Консоль
    hStdOut   dq 0
    hStdIn    dq 0
    
    ; Окно
    hWnd      dq 0
    hDC       dq 0
    hBitmap   dq 0
    hOldBitmap dq 0
    hMemDC    dq 0
    
    ; Буфер ввода
    cmd_buffer db 30 dup(0)
    cmd_len    dq 0
    
    ; Аргументы команд
    arg1_text db 20 dup(0)
    arg2_text db 20 dup(0)
    arg3_text db 20 dup(0)
    
    ; 64-битные числа
    num1       dq 0
    num2       dq 0
    result     dq 0
    
    ; Для BMP
    bmpFile    db 'image.bmp',0
    bmpHandle  dq 0
    bmpBuffer  db 64000 dup(0)
    bmi        BITMAPINFO <>
    bmih       BITMAPINFOHEADER <>
    
    ; Для файловых операций
    file_handle dq 0
    file_data   db 64000 dup(0)
    file_size   dq 0
    bytes_read  dq 0
    bytes_written dq 0
    
    ; Строки
    msg_welcome db 'HOS v2.0 (64-bit with GDI)',13,10,0
    msg_unknown db 'Unknown command!',13,10,0
    msg_created db ' created!',13,10,0
    msg_reading db ' reading...',13,10,0
    msg_graphics_on db 'Graphics ON!',13,10,0
    msg_bad_arg db 'Bad arg!',13,10,0
    msg_equal db 'EQUAL',13,10,0
    msg_not_equal db 'NOT EQUAL',13,10,0
    msg_imported db ' imported!',13,10,0
    msg_exported db ' exported!',13,10,0
    msg_running db 'Running program: ',0
    msg_test_done db 'Program finished',13,10,0
    msg_test_error db 'File not found!',13,10,0
    msg_error db 'File not found!',13,10,0
    msg_import db 'Importing...',13,10,0
    msg_export db 'Exporting...',13,10,0
    msg_result db ' = result',13,10,0
    msg_div_zero db 'Division by zero!',13,10,0
    msg_file_ok db 'File OK',13,10,0
    msg_file_error db 'File error!',13,10,0
    msg_size db 'Size: ',0
    msg_bytes db ' bytes',13,10,0
    newline db 13,10,0
    grp_str db 'grp',0
    exit_str db 'exit',0
    ext_flg db '.flg',0
    
    ; Класс окна
    wc WNDCLASSEX <>
    className db 'HOSWindow',0
    windowTitle db 'HOS v2.0 - Graphics',0

.code
start proc
    ; Получаем дескрипторы консоли
    invoke GetStdHandle, STD_OUTPUT_HANDLE
    mov hStdOut, rax
    invoke GetStdHandle, STD_INPUT_HANDLE
    mov hStdIn, rax
    
    ; Приветствие
    lea rcx, msg_welcome
    call print_str
    call new_line
    
main_loop:
    call new_line
    invoke WriteConsoleA, hStdOut, '>', 1, NULL, NULL
    invoke WriteConsoleA, hStdOut, ' ', 1, NULL, NULL
    
    ; Читаем команду
    lea rcx, cmd_buffer
    mov rdx, 30
    call read_input
    
    ; Парсим команду
    lea rcx, cmd_buffer
    call parse_command
    
    cmp rax, 1
    jne unknown_cmd
    
    jmp main_loop
start endp

; ==========================================================
; ПАРСИНГ КОМАНД
; ==========================================================
parse_command proc
    lea rdx, cmd_crt_str
    call strcmp
    je cmd_crt_handler
    
    lea rdx, cmd_rdg_str
    call strcmp
    je cmd_rdg_handler
    
    lea rdx, cmd_dsp_str
    call strcmp
    je cmd_dsp_handler
    
    lea rdx, cmd_enb_str
    call strcmp
    je cmd_enb_handler
    
    lea rdx, cmd_mmr_str
    call strcmp
    je cmd_mmr_handler
    
    lea rdx, cmd_cnd_str
    call strcmp
    je cmd_cnd_handler
    
    lea rdx, cmd_import_str
    call strcmp
    je cmd_import_handler
    
    lea rdx, cmd_export_str
    call strcmp
    je cmd_export_handler
    
    lea rdx, cmd_test_str
    call strcmp
    je cmd_test_handler
    
    lea rdx, cmd_add_str
    call strcmp
    je cmd_add_handler
    
    lea rdx, cmd_sub_str
    call strcmp
    je cmd_sub_handler
    
    lea rdx, cmd_mul_str
    call strcmp
    je cmd_mul_handler
    
    lea rdx, cmd_div_str
    call strcmp
    je cmd_div_handler
    
    lea rdx, cmd_exit_str
    call strcmp
    je cmd_exit_handler
    
    mov rax, 0
    ret
parse_command endp

; ==========================================================
; КОМАНДЫ
; ==========================================================

cmd_crt_str db 'crt',0
cmd_crt_handler:
    call read_arg1
    call read_arg2
    lea rcx, arg1_text
    call print_str
    lea rcx, msg_created
    call print_str
    ret

cmd_rdg_str db 'rdg',0
cmd_rdg_handler:
    call read_arg1
    lea rcx, arg1_text
    call print_str
    lea rcx, msg_reading
    call print_str
    ret

cmd_dsp_str db 'dsp',0
cmd_dsp_handler:
    call read_arg1
    lea rcx, arg1_text
    call print_str
    call new_line
    ret

cmd_enb_str db 'enb',0
cmd_enb_handler:
    call read_arg1
    lea rcx, arg1_text
    lea rdx, grp_str
    call strcmp
    je enable_graphics
    lea rcx, msg_bad_arg
    call print_str
    ret

enable_graphics:
    ; Создаём окно с GDI
    call create_window
    lea rcx, msg_graphics_on
    call print_str
    ret

cmd_mmr_str db 'mmr',0
cmd_mmr_handler:
    call read_arg1
    lea rcx, arg1_text
    call show_bmp_in_window
    ret

cmd_cnd_str db 'cnd',0
cmd_cnd_handler:
    call read_arg1
    call read_arg2
    lea rcx, arg1_text
    lea rdx, arg2_text
    call strcmp
    je cnd_equal
    lea rcx, msg_not_equal
    call print_str
    ret

cnd_equal:
    lea rcx, msg_equal
    call print_str
    ret

; ==========================================================
; IMPORT — ЗАГРУЗКА ДАННЫХ ИЗ .FLG ФАЙЛА
; ==========================================================
cmd_import_str db 'import',0
cmd_import_handler:
    lea rcx, msg_import
    call print_str
    call read_arg1
    
    ; Добавляем расширение .flg
    lea rcx, arg1_text
    call add_extension
    
    ; Открываем файл для чтения
    invoke CreateFileA, addr arg1_text, GENERIC_READ, FILE_SHARE_READ, \
           NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    cmp rax, INVALID_HANDLE_VALUE
    je import_error
    mov file_handle, rax
    
    ; Читаем данные
    invoke ReadFile, file_handle, addr file_data, 64000, addr bytes_read, NULL
    cmp rax, 0
    je import_read_error
    
    mov rax, bytes_read
    mov file_size, rax
    
    ; Закрываем файл
    invoke CloseHandle, file_handle
    
    lea rcx, arg1_text
    call print_str
    lea rcx, msg_imported
    call print_str
    
    ; Показываем размер
    call print_file_size
    ret

import_error:
    lea rcx, msg_error
    call print_str
    ret

import_read_error:
    invoke CloseHandle, file_handle
    lea rcx, msg_file_error
    call print_str
    ret

; ==========================================================
; EXPORT — СОХРАНЕНИЕ ДАННЫХ В .FLG ФАЙЛ
; ==========================================================
cmd_export_str db 'export',0
cmd_export_handler:
    lea rcx, msg_export
    call print_str
    call read_arg1
    
    ; Добавляем расширение .flg
    lea rcx, arg1_text
    call add_extension
    
    ; Проверяем, есть ли данные
    cmp file_size, 0
    je export_no_data
    
    ; Создаём файл
    invoke CreateFileA, addr arg1_text, GENERIC_WRITE, 0, \
           NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
    cmp rax, INVALID_HANDLE_VALUE
    je export_error
    mov file_handle, rax
    
    ; Записываем данные
    mov rcx, file_size
    invoke WriteFile, file_handle, addr file_data, rcx, addr bytes_written, NULL
    cmp rax, 0
    je export_write_error
    
    mov rax, bytes_written
    cmp rax, file_size
    jne export_write_error
    
    ; Закрываем файл
    invoke CloseHandle, file_handle
    
    lea rcx, arg1_text
    call print_str
    lea rcx, msg_exported
    call print_str
    
    call print_file_size
    ret

export_no_data:
    lea rcx, msg_file_error
    call print_str
    ret

export_error:
    lea rcx, msg_file_error
    call print_str
    ret

export_write_error:
    invoke CloseHandle, file_handle
    lea rcx, msg_file_error
    call print_str
    ret

; ==========================================================
; ДОБАВЛЕНИЕ РАСШИРЕНИЯ .FLG
; ==========================================================
add_extension proc
    push rsi
    push rdi
    push rax
    
    mov rsi, rcx
    mov rdi, rcx
    
    ; Ищем конец строки
add_ext_loop:
    cmp byte ptr [rdi], 0
    je add_ext_found
    inc rdi
    jmp add_ext_loop
    
add_ext_found:
    ; Проверяем, есть ли уже расширение
    mov rsi, rdi
    dec rsi
    cmp byte ptr [rsi], '.'
    je add_ext_done      ; Если есть точка, не добавляем
    
    ; Добавляем .flg
    mov byte ptr [rdi], '.'
    inc rdi
    mov byte ptr [rdi], 'f'
    inc rdi
    mov byte ptr [rdi], 'l'
    inc rdi
    mov byte ptr [rdi], 'g'
    inc rdi
    mov byte ptr [rdi], 0
    
add_ext_done:
    pop rax
    pop rdi
    pop rsi
    ret
add_extension endp

; ==========================================================
; ВЫВОД РАЗМЕРА ФАЙЛА
; ==========================================================
print_file_size proc
    push rax
    push rbx
    push rcx
    push rdx
    
    lea rcx, msg_file_ok
    call print_str
    
    lea rcx, msg_size
    call print_str
    
    ; Выводим размер
    mov rax, file_size
    lea rcx, arg1_text
    call int64_to_str
    
    lea rcx, arg1_text
    call print_str
    
    lea rcx, msg_bytes
    call print_str
    
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret
print_file_size endp

; ==========================================================
; TEST — ЗАПУСК ПРОГРАММЫ ИЗ ФАЙЛА
; ==========================================================
cmd_test_str db 'test',0
cmd_test_handler:
    call read_arg1
    lea rcx, msg_running
    call print_str
    lea rcx, arg1_text
    call print_str
    call new_line
    
    ; Открываем файл
    invoke CreateFileA, addr arg1_text, GENERIC_READ, FILE_SHARE_READ, \
           NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    cmp rax, INVALID_HANDLE_VALUE
    je test_error
    mov file_handle, rax
    
test_read_loop:
    ; Читаем строку из файла
    invoke ReadFile, file_handle, addr cmd_buffer, 30, addr bytes_read, NULL
    cmp rax, 0
    je test_done
    cmp bytes_read, 0
    je test_done
    
    ; Выполняем команду
    lea rcx, cmd_buffer
    call parse_command
    
    jmp test_read_loop

test_done:
    invoke CloseHandle, file_handle
    lea rcx, msg_test_done
    call print_str
    ret

test_error:
    lea rcx, msg_test_error
    call print_str
    ret

; ==========================================================
; 64-БИТНАЯ АРИФМЕТИКА
; ==========================================================

cmd_add_str db 'add',0
cmd_add_handler:
    call read_arg1
    call read_arg2
    call read_arg3
    
    lea rcx, arg2_text
    call str_to_int64
    mov num1, rax
    
    lea rcx, arg3_text
    call str_to_int64
    mov num2, rax
    
    mov rax, num1
    add rax, num2
    mov result, rax
    
    lea rcx, arg1_text
    mov rax, result
    call int64_to_str
    
    lea rcx, arg1_text
    call print_str
    lea rcx, msg_result
    call print_str
    ret

cmd_sub_str db 'sub',0
cmd_sub_handler:
    call read_arg1
    call read_arg2
    call read_arg3
    
    lea rcx, arg2_text
    call str_to_int64
    mov num1, rax
    
    lea rcx, arg3_text
    call str_to_int64
    mov num2, rax
    
    mov rax, num1
    sub rax, num2
    mov result, rax
    
    lea rcx, arg1_text
    mov rax, result
    call int64_to_str
    
    lea rcx, arg1_text
    call print_str
    lea rcx, msg_result
    call print_str
    ret

cmd_mul_str db 'mul',0
cmd_mul_handler:
    call read_arg1
    call read_arg2
    call read_arg3
    
    lea rcx, arg2_text
    call str_to_int64
    mov num1, rax
    
    lea rcx, arg3_text
    call str_to_int64
    mov num2, rax
    
    mov rax, num1
    mov rbx, num2
    mul rbx
    mov result, rax
    
    lea rcx, arg1_text
    mov rax, result
    call int64_to_str
    
    lea rcx, arg1_text
    call print_str
    lea rcx, msg_result
    call print_str
    ret

cmd_div_str db 'div',0
cmd_div_handler:
    call read_arg1
    call read_arg2
    call read_arg3
    
    lea rcx, arg2_text
    call str_to_int64
    mov num1, rax
    
    lea rcx, arg3_text
    call str_to_int64
    mov num2, rax
    
    cmp num2, 0
    je div_zero
    
    mov rax, num1
    xor rdx, rdx
    mov rbx, num2
    div rbx
    mov result, rax
    
    lea rcx, arg1_text
    mov rax, result
    call int64_to_str
    
    lea rcx, arg1_text
    call print_str
    lea rcx, msg_result
    call print_str
    ret

div_zero:
    lea rcx, msg_div_zero
    call print_str
    ret

; ==========================================================
; ПРЕОБРАЗОВАНИЯ (64-БИТНЫЕ)
; ==========================================================

str_to_int64 proc
    push rbx
    push rsi
    mov rsi, rcx
    xor rax, rax
    mov rbx, 10
str_to_int64_loop:
    movzx rcx, byte ptr [rsi]
    cmp rcx, 0
    je str_to_int64_done
    cmp rcx, 13
    je str_to_int64_done
    cmp rcx, 10
    je str_to_int64_done
    sub rcx, '0'
    cmp rcx, 9
    ja str_to_int64_done
    mul rbx
    add rax, rcx
    inc rsi
    jmp str_to_int64_loop
str_to_int64_done:
    pop rsi
    pop rbx
    ret
str_to_int64 endp

int64_to_str proc
    push rbx
    push rcx
    push rdx
    push rsi
    mov rsi, rcx
    mov rcx, 0
    mov rbx, 10
int64_to_str_loop:
    xor rdx, rdx
    div rbx
    push rdx
    inc rcx
    test rax, rax
    jnz int64_to_str_loop
int64_to_str_store:
    pop rdx
    add dl, '0'
    mov [rsi], dl
    inc rsi
    loop int64_to_str_store
    mov byte ptr [rsi], 0
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret
int64_to_str endp

; ==========================================================
; ГРАФИКА (GDI)
; ==========================================================

create_window proc
    ; Регистрируем класс окна
    mov wc.cbSize, sizeof WNDCLASSEX
    mov wc.style, CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc, rcx
    lea rax, WndProc
    mov wc.lpfnWndProc, rax
    mov wc.cbClsExtra, 0
    mov wc.cbWndExtra, 0
    mov wc.hInstance, NULL
    mov wc.hIcon, NULL
    mov wc.hCursor, NULL
    mov wc.hbrBackground, COLOR_WINDOW+1
    lea rax, className
    mov wc.lpszClassName, rax
    invoke RegisterClassEx, addr wc
    
    ; Создаём окно
    invoke CreateWindowEx, 0, addr className, addr windowTitle, \
           WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, \
           320, 240, NULL, NULL, NULL, NULL
    mov hWnd, rax
    
    ; Показываем окно
    invoke ShowWindow, hWnd, SW_SHOW
    invoke UpdateWindow, hWnd
    
    ret
create_window endp

WndProc proc hWnd:QWORD, msg:QWORD, wParam:QWORD, lParam:QWORD
    cmp msg, WM_DESTROY
    je wm_destroy
    cmp msg, WM_PAINT
    je wm_paint
    invoke DefWindowProc, hWnd, msg, wParam, lParam
    ret
wm_destroy:
    invoke PostQuitMessage, 0
    xor rax, rax
    ret
wm_paint:
    invoke BeginPaint, hWnd, addr ps
    ; Здесь будет отрисовка
    invoke EndPaint, hWnd, addr ps
    xor rax, rax
    ret
WndProc endp

show_bmp_in_window proc
    ; Загружаем BMP файл и показываем в окне
    lea rcx, bmpFile
    invoke LoadImage, NULL, rcx, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE
    mov hBitmap, rax
    
    ; Получаем DC окна
    invoke GetDC, hWnd
    mov hDC, rax
    
    ; Создаём совместимый DC
    invoke CreateCompatibleDC, hDC
    mov hMemDC, rax
    
    ; Выбираем битмап в DC
    invoke SelectObject, hMemDC, hBitmap
    mov hOldBitmap, rax
    
    ; Копируем на экран
    invoke BitBlt, hDC, 0, 0, 320, 240, hMemDC, 0, 0, SRCCOPY
    
    ; Очистка
    invoke SelectObject, hMemDC, hOldBitmap
    invoke DeleteDC, hMemDC
    invoke ReleaseDC, hWnd, hDC
    invoke DeleteObject, hBitmap
    
    ret
show_bmp_in_window endp

; ==========================================================
; ВСПОМОГАТЕЛЬНЫЕ
; ==========================================================

read_arg1 proc
    lea rcx, arg1_text
    mov rdx, 20
    call read_input
    call new_line
    ret
read_arg1 endp

read_arg2 proc
    lea rcx, arg2_text
    mov rdx, 20
    call read_input
    call new_line
    ret
read_arg2 endp

read_arg3 proc
    lea rcx, arg3_text
    mov rdx, 20
    call read_input
    call new_line
    ret
read_arg3 endp

strcmp proc
    push rsi
    push rdi
    mov rsi, rcx
    mov rdi, rdx
strcmp_loop:
    mov al, [rsi]
    mov dl, [rdi]
    cmp al, dl
    jne strcmp_not_equal
    test al, al
    jz strcmp_equal
    inc rsi
    inc rdi
    jmp strcmp_loop
strcmp_equal:
    pop rdi
    pop rsi
    mov rax, 1
    ret
strcmp_not_equal:
    pop rdi
    pop rsi
    mov rax, 0
    ret
strcmp endp

print_str proc
    invoke WriteConsoleA, hStdOut, rcx, lstrlen(rcx), NULL, NULL
    ret
print_str endp

new_line proc
    lea rcx, newline
    call print_str
    ret
new_line endp

read_input proc
    push rbx
    push rdi
    mov rdi, rcx
    mov rbx, rdx
    xor rcx, rcx
read_input_loop:
    invoke ReadConsoleA, hStdIn, rdi, 1, addr rcx, NULL
    cmp rcx, 0
    je read_input_done
    cmp byte ptr [rdi], 13
    je read_input_done
    cmp byte ptr [rdi], 10
    je read_input_done
    inc rdi
    dec rbx
    cmp rbx, 0
    je read_input_done
    jmp read_input_loop
read_input_done:
    mov byte ptr [rdi], 0
    pop rdi
    pop rbx
    ret
read_input endp

; ==========================================================
; ЗАВЕРШЕНИЕ
; ==========================================================
exit:
    invoke ExitProcess, 0

end start