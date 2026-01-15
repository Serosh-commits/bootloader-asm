[bits 16]
[org 0x7c00]

start:
    cli
    xor     ax, ax
    mov     ds, ax
    mov     es, ax
    mov     ss, ax
    mov     sp, 0x7c00
    sti

    mov     [boot_drive], dl

    mov     ah, 0x02
    mov     al, 0x04
    mov     ch, 0x00
    mov     dh, 0x00
    mov     cl, 0x02
    mov     bx, 0x8000
    int     0x13
    jc      disk_error

    in      al, 0x92
    or      al, 2
    out     0x92, al

    cli
    lgdt    [gdt_desc]
    mov     eax, cr0
    or      al, 1
    mov     cr0, eax

    jmp     0x08:pm_start

disk_error:
    mov     si, error_msg
    call    print_rm
    hlt
    jmp     $

print_rm:
    lodsb
    or      al, al
    jz      .done
    mov     ah, 0x0e
    mov     bx, 7
    int     0x10
    jmp     print_rm
.done:
    ret

[bits 32]
pm_start:
    mov     ax, 0x10
    mov     ds, ax
    mov     es, ax
    mov     fs, ax
    mov     gs, ax
    mov     ss, ax

    mov     ebp, 0x90000
    mov     esp, ebp

    jmp     0x8000

boot_drive  db 0
error_msg   db "Disk read error!", 0

gdt_null:
    dd 0
    dd 0

gdt_code:
    dw 0xffff
    dw 0
    db 0
    db 10011010b
    db 11001111b
    db 0

gdt_data:
    dw 0xffff
    dw 0
    db 0
    db 10010010b
    db 11001111b
    db 0

gdt_end:

gdt_desc:
    dw gdt_end - gdt_null - 1
    dd gdt_null

times 510-($-$$) db 0
dw 0xaa55
