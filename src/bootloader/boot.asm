org 0x7c00     ;load into bootable sector
bits 16     

%define ENDL 0x0D, 0x0A

jmp short start
nop

bdb_oem:                   db 'MSWIN4.1'
bdb_bytes_per_sector:      dw 512
bdb_sectors_per_cluster:   db 1
bdb_reserved_sectors:      dw 1
bdb_fat_cout:              db 2
bdb_dir_entries_count:     dw 0e0h
bdb_total_sectors:         dw 2880
bdb_media_descriptor_type: db 0f0h
bdb_sectors_per_fat:       dw 9
bdb_sectors_per_track:     dw 18
bdb_heads:                 dw 2
bdb_hidden_sectors:        dw 0
                           dw 0 
bdb_large_sector_count:    dw 0
                           dw 0

ebr_drive_number:          db 0
                           db 0
ebr_signature:             db 29h
ebr_volume_id:             db 42h, 06h, 97h, 27h
ebr_volume_label:          db 'I LUV CHIOS'
ebr_system_id:             db 'FAT12   '




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

    mov [ebr_drive_number], dl
    
    mov ax, 1
    mov cl, 1 
    mov bx, 0x7E00
    call disk_read

    mov si, msg_hello
    call puts
    cli
    hlt

floppy_error:
    mov si, msg_read_failed
    call puts
    jmp wait_key_and_reboot
    
wait_key_and_reboot:
    mov ah, 0
    int 16h
    jmp 0FFFFh:0

.halt:
    cli      
    jmp .halt;

;
; @author Olhalvo
; Converts an LBA address to a CHS address
; @param ax - LBA address
; @returns cx[0..5]  - sector
; @returns cx[6..15] - cylinder
; @returns dh        - head
;
lba_to_csh:

    push ax
    push dx     
    
    xor dx, dx
    div word [bdb_sectors_per_track]

    inc dx
    mov cx, dx

    xor dx, dx
    div word [bdb_heads]

    mov dh, dl
    mov ch, al
    mov ah, 6
    or cl, ah

    pop ax
    mov dl, al
    pop ax
    ret

;
; @author Olhalvo
; read disk sector
; @param ax    - LBA address
; @param cl    - Number of sectors to read
; @param dl    - Drive number 
; @param es:bx - Memory address where to store data
;
disk_read:
    push ax
    push bx
    push cx
    push dx
    push di
         
    push cx
    call lba_to_csh
    pop ax

    mov ah, 02h
    mov di, 3

    .retry:
        pusha
        stc
        int 13h
        jnc .done


        popa   
        call disk_reset

        dec di
        test di, di
        jnz .retry

    
    .fail:
         jmp floppy_error

    .done:
        popa
        pop di
        pop dx
        pop cx
        pop bx
        pop ax
        ret

;
; @author Olhalvo
; Resets disk controller
; @param dl - drive number
;
disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc floppy_error
    popa
    ret



msg_hello: db 'Booting CHIos...', ENDL, 0
msg_hlt: db 'Halted', ENDL, 0
msg_read_failed: db 'Read from disk failed!', ENDL, 0

times 510-($-$$)db 0;
dw 0AA55h
