    ; ----------------------------------------------------------------------------------------
    ; Writes "Hello, World" to the console using only system calls. Runs on 64-bit Linux only.
    ; To assemble and run:
    ;
    ;     nasm -felf64 hello.asm && ld hello.o && ./a.out
    ; ----------------------------------------------------------------------------------------
    global  _start
    %define WIDTH 80
    %define HEIGHT 25 
    %define PADDLE_X  10  
    %define PADDLE_LEN  10 
    %define BALL_X 1  
    %define BALL_Y 1  
    %define BALL_CHAR 0x11
    %define LCHAR 'a'
    %define RCHAR 'd'

    extern system
    extern getchar
    extern fcntl
    extern usleep

    global main
    section .data    
        message:    db      " ",0      ; note the newline at the end
        newline: db 0xd,0xa,0
        noecho: db "stty raw -echo isig",0
        
        purple:db   0x1b,"[1;45m",0
        green:db   0x1b,"[1;42m",0
        white:db   0x1b,"[1;47m",0
        clear_screen: db 0x1b,"[2J",0
        color_done:   db   0x1b,"[0;0m",0
        hide_cursor: db   0x1b,"[?25l",0
        cursor_home: db 0x1b,"[H",0
        ball_char: db "@",0 
        screen:
            %rep 25 
            dq 0,0,0,0,0,0,0,0,0,0
            %endrep 

        paddle_x:
            dq PADDLE_X

        paddle_len:
            dq PADDLE_LEN
               
        ball_y:
            dq BALL_Y
        ball_x:
            dq BALL_X

        buffer:
            dq 0

    section .text
    setup_terminal:
        mov rdi,noecho
        call system

        ; setup stdin as non block
        ;   fcntl(0, F_SETFL, fcntl(0, F_GETFL) | O_NONBLOCK);
        mov rsi, 0x3
        mov rdi, 0
        mov  rax,0
        call fcntl
        or ah, 0x8
        mov rdx,rax
        mov  rsi,0x4
        mov  rdi,0
        mov  rax,0
        call fcntl
        ret

    main:
        call setup_terminal


        mov rax,screen+79
        mov BYTE [rax],1

        ;hide_cursor
        mov rax,hide_cursor
        call print_func
        
        main_loop:
        mov rax,screen
        call zero_screen_array
        mov rax,screen+79
        mov BYTE [rax],1



    ;    inc BYTE [ball_x]
        mov rax, cursor_home
        call print_func
         mov rax,clear_screen
;        call print_func

        call do_paddle
        call do_ball
        mov rax,screen
        call draw_screen  
        
        call handle_input
        mov rdi, 0x1000
        call usleep
        jmp main_loop
    
    zero_screen_array:
        xor rdi,rdi
        xor rdx,rdx
        start_zero_loop:
        mov QWORD [rax+rdi],0
        add rdi,8
        add rdx,1
        cmp rdx,250
        jl start_zero_loop
        zero_loop_done:
        ret
    do_paddle:
            push r11
            push rdi
            xor r11,r11
            xor rdi,rdi 
            mov  r11,[paddle_x]
            add r11,screen+1920; last row
            start_paddle_loop:
            mov BYTE [r11+rdi],2
            inc rdi
            cmp rdi, [paddle_len]
            jl start_paddle_loop
            pop rdi
            pop r11
            ret


    do_ball:
            push r11
            push rdi
            xor r11,r11
            xor rdi,rdi
            imul r11,[ball_y],WIDTH
            add r11,[ball_x],
            add r11,screen
            mov BYTE [r11],BALL_CHAR
            pop rdi
            pop r11
            ret


    draw_screen:
        xor rdi,rdi ;
        push rdx
        push r11
        push r10
        push rdi
        mov rdx,rax
        len_loop:
            xor r10, r10 ;j
            inner_len_loop:
            ;calculate current offset
            imul r11,rdi,WIDTH
            add r11,r10      
            cmp BYTE [rdx+r11],1
            je draw_green
            cmp BYTE [rdx+r11],2
            je draw_purple
            cmp BYTE [rdx+r11],3
            je draw_white
            cmp BYTE [rdx+r11],0 
            je done_draw
            cmp BYTE [rdx+r11],BALL_CHAR 
            je draw_ball
            

            jmp $
            
            draw_ball:
                mov rax,ball_char
                call print_func
                jmp skip_color

            draw_white:

                mov rax,white
                call print_func
            
                jmp done_draw
            draw_purple:

                mov rax,purple
                call print_func
            
                jmp done_draw
            
            draw_green:
                mov rax,green
                call print_func

                jmp done_draw
                
            done_draw:
                mov rax,message
                call print_func
                mov rax,color_done
                call print_func

            skip_color:
            inc r10
     
            cmp r10,WIDTH
            jl inner_len_loop
            ;;; inner loop done
            mov rax,newline
            call print_func
            inc rdi
            cmp rdi,HEIGHT
            jl len_loop
       pop rdi
       pop r10
       pop r11
       pop rdx
       ret 

        
        
    handle_input:
        call getchar 
        cmp rax,LCHAR
        je h_go_left
        cmp rax,RCHAR
        je h_go_right
        jmp h_ignore

        h_go_left:
        ;check to make sure we are within bounds
        mov rax,[paddle_x]
        cmp rax,0
        je h_ignore
    
        dec BYTE [paddle_x]
        jmp h_ignore 
        h_go_right:
        mov rax,[paddle_x]
        add rax,PADDLE_LEN
        cmp rax,WIDTH 
        je h_ignore
        inc BYTE [paddle_x]
    

        h_ignore:
        ret

exit_func:
    ; exit(0)
    mov     eax, 60                 ; system call 60 is exit
    xor     rdi, rdi                ; exit code 0
    syscall                         ; invoke operating system to exit

print_func:
    push rdi
    push rdx
    xor rdx,rdx
    mov rsi,rax
start_loop: ;calculate strlen to pass into write()
    mov cl, [rax]
    cmp cl,0
    jz call_sys
    inc rax
    inc rdx
    jmp start_loop
call_sys:
    mov rax,1 
    mov rdi,1
    syscall 
    pop rdx
    pop rdi
    ret
   
  
   
   
    
    

