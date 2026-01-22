
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

    mov     si, boot_msg
    call    print_rm

    mov     si, load_msg
    call    print_rm

    mov     ah, 0x41
    mov     bx, 0x55aa
    int     0x13
    jc      use_chs
    cmp     bx, 0xaa55
    jne     use_chs
    test    cx, 1
    jz      use_chs

    mov     word [dap_blocks], 8
    mov     word [dap_off], 0x8000
    mov     word [dap_seg], 0
    mov     dword [dap_lba], 1
    mov     dword [dap_lba+4], 0
    mov     si, dap
    mov     ah, 0x42
    int     0x13
    jc      disk_error
    jmp     after_read

use_chs:
    mov     ah, 0x02
    mov     al, 8
    mov     ch, 0x00
    mov     dh, 0x00
    mov     cl, 0x02
    mov     bx, 0x8000
    int     0x13
    jc      disk_error

after_read:
    mov     si, loaded_msg
    call    print_rm

    xor     ax, ax
    mov     es, ax
    mov     di, 0x500
    mov     ax, 0x4f00
    mov     dword [di], 'VBE2'
    int     0x10
    cmp     ax, 0x004f
    jne     disk_error

    mov     cx, 0x118
    mov     di, 0x700
    mov     ax, 0x4f01
    int     0x10
    cmp     ax, 0x004f
    jne     disk_error

    mov     ax, [di]
    test    ax, 0x80
    jz      disk_error

    mov     bx, 0x4118
    mov     ax, 0x4f02
    int     0x10
    cmp     ax, 0x004f
    jne     disk_error

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
boot_msg    db "Booting OS...", 13, 10, 0
load_msg    db "Loading kernel...", 13, 10, 0
loaded_msg  db "Kernel loaded.", 13, 10, 0

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

dap:
    db 0x10
    db 0
dap_blocks: dw 0
dap_off:    dw 0
dap_seg:    dw 0
dap_lba:    dq 0

times 510-($-$$) db 0
dw 0xaa55

kernel.asm
[bits 32]
[org 0x8000]

entry:
    mov     eax, 0
    cpuid
    mov     [vendor], ebx
    mov     [vendor+4], edx
    mov     [vendor+8], ecx
    mov     byte [vendor+12], 0

    call    check_cpuid
    call    check_long_mode

    call    setup_paging
    call    edit_gdt

    mov     eax, cr4
    or      eax, 1 << 5
    mov     cr4, eax

    mov     edx, 0x1000
    mov     cr3, edx

    mov     ecx, 0xc0000080
    rdmsr
    or      eax, 1 << 8
    wrmsr

    mov     eax, cr0
    or      eax, 1 << 31
    mov     cr0, eax

    lgdt    [gdt_64_desc]
    jmp     0x08:long_mode_start

check_cpuid:
    pushfd
    pop     eax
    mov     ecx, eax
    xor     eax, 1 << 21
    push    eax
    popfd
    pushfd
    pop     eax
    push    ecx
    popfd
    xor     eax, ecx
    jz      .no_cpuid
    ret
.no_cpuid:
    hlt

check_long_mode:
    mov     eax, 0x80000000
    cpuid
    cmp     eax, 0x80000001
    jb      .no_long_mode
    mov     eax, 0x80000001
    cpuid
    test    edx, 1 << 29
    jz      .no_long_mode
    ret
.no_long_mode:
    hlt

setup_paging:
    mov     edi, 0x1000
    mov     cr3, edi
    xor     eax, eax
    mov     ecx, 4096
    rep     stosd
    mov     edi, cr3

    mov     dword [edi], 0x2003
    add     edi, 0x1000
    mov     dword [edi], 0x3003
    mov     dword [edi+8], 0x4003
    mov     dword [edi+16], 0x5003
    mov     dword [edi+24], 0x6003

    mov     edi, 0x3000
    mov     ebx, 0x00000083
    call    set_pd
    add     edi, 0x1000
    mov     ebx, 0x40000083
    call    set_pd
    add     edi, 0x1000
    mov     ebx, 0x80000083
    call    set_pd
    add     edi, 0x1000
    mov     ebx, 0xc0000083
    call    set_pd
    ret

set_pd:
    mov     ecx, 512
.set:
    mov     dword [edi], ebx
    mov     dword [edi+4], 0
    add     edi, 8
    add     ebx, 0x200000
    loop    .set
    ret

edit_gdt:
    ret

no_cpuid_msg    db "CPUID not supported!", 0
no_lm_msg       db "Long Mode not supported!", 0
vendor_label    db "CPU Vendor: ", 0
vendor          times 13 db 0

gdt_64:
    dq 0
    dq 0x00af9a000000ffff
    dq 0x00cf92000000ffff
gdt_64_end:

gdt_64_desc:
    dw gdt_64_end - gdt_64 - 1
    dq gdt_64

[bits 64]
long_mode_start:
    mov     ax, 0x10
    mov     ds, ax
    mov     es, ax
    mov     fs, ax
    mov     gs, ax
    mov     ss, ax

    mov     rdi, 0
    mov     edi, [0x700 + 0x28]
    movzx   rbx, word [0x700 + 0x10]
    movzx   rbp, word [0x700 + 0x12]
    movzx   r12, word [0x700 + 0x14]
    mov     al, [0x700 + 0x19]
    cmp     al, 32
    jne     .halt

    mov     r13, rbp
    shl     r13, 2

    mov     rcx, r12
.outer_clear:
    push    rcx
    mov     rcx, rbp
    xor     eax, eax
    rep     stosd
    pop     rcx
    add     rdi, rbx
    sub     rdi, r13
    loop    .outer_clear

    mov     rax, r12
    shr     rax, 1
    sub     rax, 50
    mov     r14, rax
    mov     rax, rbp
    shr     rax, 1
    sub     rax, 50
    mov     r15, rax

    mov     rcx, 100
.outer_square:
    push    rcx
    mov     rdi, 0
    mov     edi, [0x700 + 0x28]
    mov     rax, r14
    mul     rbx
    mov     rdx, r15
    shl     rdx, 2
    add     rax, rdx
    add     rdi, rax
    mov     rcx, 100
    mov     eax, 0x00ffffff
    rep     stosd
    inc     r14
    pop     rcx
    loop    .outer_square

.halt:
    hlt
    jmp     .halt