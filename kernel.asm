[bits 32]
[org 0x8000]

entry:
    mov     edi, 0xb8000
    mov     ah, 0x1f
    mov     esi, stage2_msg
    call    print_pm

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
    mov     esi, no_cpuid_msg
    call    print_pm
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
    mov     esi, no_lm_msg
    call    print_pm
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
    add     edi, 0x1000
    mov     dword [edi], 0x4003
    add     edi, 0x1000

    mov     ebx, 0x00000003
    mov     ecx, 512

.set_entry:
    mov     dword [edi], ebx
    add     ebx, 0x1000
    add     edi, 8
    loop    .set_entry
    ret

edit_gdt:
    ret

print_pm:
    pusha
.next:
    lodsb
    or      al, al
    jz      .done
    mov     [edi], al
    mov     [edi+1], ah
    add     edi, 2
    jmp     .next
.done:
    popa
    ret

stage2_msg      db "Second stage loaded. Transitioning to 64-bit...", 0
no_cpuid_msg    db "CPUID not supported!", 0
no_lm_msg       db "Long Mode not supported!", 0

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

    mov     rdi, 0xb8000
    mov     rax, 0x2f532f532f532f53
    mov     rcx, 500
    rep     stosq

    mov     rsi, lm_success
    mov     rdi, 0xb8000 + (12*160 + 40)
    mov     ah, 0x2f
.print:
    lodsb
    or      al, al
    jz      .halt
    mov     [rdi], al
    mov     [rdi+1], ah
    add     rdi, 2
    jmp     .print

.halt:
    hlt
    jmp     .halt

lm_success db "Successfully entered 64-bit Long Mode!", 0
