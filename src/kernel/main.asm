org 0x7c00     ;load into bootable sector
bits 16     

%define ENDL 0x0D, 0x0A

start:
    jmp main

;
; @author Olhalvo
; prints a string to the screen
; @param ds:si points to string untill null character
;
puts:
    push si
    push ax
    

.loop:
    lodsb
    or al,al
    jz .done

    mov ah, 0x0e
    mov bh, 0x0
    int 0x10
    
    jmp .loop

.done:
    pop ax
    pop si
    ret
        

main:
    
    mov ax, 0
    mov es, ax
    mov ds, ax

    mov ss, ax
    mov sp, 0x7c00

    mov si, msg_hello
    call puts
        
    hlt

.halt:      
    jmp .halt;



msg_hello: db 'Booting CHIos...', ENDL, 0
msg_hlt: db 'Halted', ENDL, 0

times 510-($-$$)db 0;
dw 0AA55h
