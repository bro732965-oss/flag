# flag
![Table in PWR](ca104887_a946_4308_b35b_d2a5631e7dea.jpg) 
Две версии простой операционной системы-эмулятора для обучения низкоуровневому программированию и работе с ассемблером.

## 📁 Структура проекта

- **f.asm** - 16-битная версия для DOS (MASM/TASM)
- **f1.asm** - 64-битная версия для Windows с GDI (MASM64)
- **image.bmp** - тестовое изображение для графических команд

## 🖥️ Версии

### f.asm (16-bit DOS)
- Компилятор: MASM/TASM
- Графика: VGA 13h (320x200, 256 цветов)
- Вывод через BIOS/DOS

### f1.asm (64-bit Windows)
- Компилятор: MASM64 (ml64.exe)
- Графика: GDI
- Использует WinAPI

## 🚀 Команды

| Команда | Аргументы | Описание |
|---------|-----------|----------|
| `crt` | `имя, тип` | Создать объект |
| `rdg` | `имя` | Чтение объекта |
| `dsp` | `текст` | Вывести текст |
| `enb` | `grp` | Включить графику |
| `mmr` | `файл.bmp` | Показать BMP |
| `cnd` | `a, b` | Сравнить строки |
| `add` | `рез, a, b` | Сложение |
| `sub` | `рез, a, b` | Вычитание |
| `mul` | `рез, a, b` | Умножение |
| `div` | `рез, a, b` | Деление |
| `import` | `имя` | Загрузить .flg |
| `export` | `имя` | Сохранить .flg |
| `test` | `файл` | Запустить скрипт |
| `exit` | - | Выход |

## 📝 Примеры

```bash
> dsp Hello World
>test
Hello World

> add result 10 20
>test
30 = result

> enb grp
>test
Graphics ON!

> mmr image.bmp
>test
# Показывает изображение

> import data
>test
Importing...
data.flg imported!
File OK Size: 1234 bytes

> export data
>test
Exporting...
data.flg exported!
File OK Size: 1234 bytes

> test script.txt
>test
Running program: script.txt
Program finished