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

    mov     si, boot_msg
    call    print_rm

    mov     cx, 12
dotloop:
    mov     si, dot
    call    print_rm

    mov     dx, 0xffff
delay:
    dec     dx
    jnz     delay
    loop    dotloop

    mov     si, newline
    call    print_rm

    in      al, 0x92
    or      al, 2
    out     0x92, al

    cli
    lgdt    [gdt_desc]
    mov     eax, cr0
    or      al, 1
    mov     cr0, eax

    jmp     0x08:pm_start

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

    mov     edi, 0xb8000
    mov     ax, 0x1f20
    mov     ecx, 80*25
    rep     stosw

    mov     edi, 0xb8000 + (9*160 + 50)
    mov     ah, 0x1e
    mov     esi, title_msg
    call    print_pm

    mov     edi, 0xb8000 + (12*160 + 44)
    mov     ah, 0x1a
    mov     esi, success_msg
    call    print_pm

    mov     eax, 0
    cpuid
    mov     dword [vendor_str], ebx
    mov     dword [vendor_str+4], edx
    mov     dword [vendor_str+8], ecx
    mov     byte [vendor_str+12], 0

    mov     edi, 0xb8000 + (15*160 + 40)
    mov     ah, 0x1f
    mov     esi, cpu_label
    call    print_pm

    mov     edi, 0xb8000 + (15*160 + 70)
    mov     ah, 0x1b
    mov     esi, vendor_str
    call    print_pm

    cli
halt:
    hlt
    jmp     halt

print_pm:
.next:
    lodsb
    or      al, al
    jz      .done
    stosw
    jmp     .next
.done:
    ret

boot_msg     db 13,10,"Booting my custom bootloader...",0
dot          db ".",0
newline      db 13,10,0

title_msg    db "Custom x86 Bootloader",0
success_msg  db "Protected mode active!",0
cpu_label    db "CPU:",0

vendor_str   times 13 db 0

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
