bits 64
default rel

section .data

    delta dd 0.0
    speed dd 400.0
    playerOnePos dd 0.0, 200.0
    playerTwoPos dd 1550.0, 200.0
    rectSize dd 50.0, 250.0
    ballSize dd 20.0, 20.0
    velocityOne dd 0.0, 0.0
    velocityTwo dd 0.0, 0.0
    ballVelocity dd 100.0, 100.0
    ballCurrentVelocity dd 1.0, 1.0
    successMsg db "Exited with no errors!", 10, 0
    windowTitle db "SFML in Assembly!", 0
    windowCenter dd 790.0, 440.0 ; offset by ballsize/2 because i dont want to set origin
    fmt db "%f", 10


section .bss
    clock resb 8
    playerOne resb 16
    playerTwo resb 16
    ball resb 16

section .text
global main
extern exit
extern printf
extern sfRenderWindow_isOpen ;window
extern sfRenderWindow_pollEvent ;window, event
extern sfRenderWindow_create ;mode, title, style, settings
extern sfRenderWindow_clear ;window, clearcolor
extern sfRenderWindow_display ;window
extern sfRenderWindow_destroy ;window
extern sfRenderWindow_close ; window
extern sfRenderWindow_drawRectangleShape ; window, rectangle, null
extern sfRectangleShape_destroy ; rectangle
extern sfRectangleShape_create ; void
extern sfRectangleShape_setSize ; rectangle, sfVector2f
extern sfRectangleShape_setFillColor ; rectangle, sfColor
extern sfRectangleShape_setPosition ; rectangle, sfVector2f
extern sfRectangleShape_move
extern sfClock_create
extern sfClock_restart
extern sfTime_asSeconds
extern sfKeyboard_isKeyPressed



%macro PRINT 1
    push rcx
    sub rsp, 8
    mov rcx, %1
    call printf
    add rsp, 8
    pop rcx
%endmacro

moveBall:
    sub rsp, 8
    movss xmm0, [ballVelocity]
    mulss xmm0, [delta]
    movss [ballCurrentVelocity], xmm0
    movss xmm0, [ballVelocity + 4]
    mulss xmm0, [delta]

    movss [ballCurrentVelocity + 4], xmm0



    mov rcx, [ball]
    mov rdx, [ballCurrentVelocity]
    call sfRectangleShape_move
    add rsp, 8
    ret


movePaddles:
    sub rsp, 8 ; align stack
    ;calculate velocity
    mov rcx, 17 ; sfKeyR
    call sfKeyboard_isKeyPressed
    mov r14, rax

    mov rcx, 22 ; sfKeyW
    call sfKeyboard_isKeyPressed
    sub r14, rax

    cvtsi2ss xmm0, r14 ; convert to float

    mulss xmm0, [delta]
    mulss xmm0, [speed]
    movss [velocityOne + 4], xmm0

    mov rcx, 74 ; sfKeyDown
    call sfKeyboard_isKeyPressed
    mov r14, rax

    mov rcx, 73 ; sfKeyUp
    call sfKeyboard_isKeyPressed
    sub r14, rax

    cvtsi2ss xmm0, r14 ; convert to float

    mulss xmm0, [delta]
    mulss xmm0, [speed]
    movss [velocityTwo + 4], xmm0

    checkPlayerOne:
    movss xmm0, dword [playerOnePos + 4]
    movss xmm1, dword [velocityOne + 4]
    addss xmm0, xmm1
    cvtss2si rax, xmm0
    cmp rax, 0
    jl checkPlayerTwo

    movss xmm0, dword [playerOnePos + 4]
    movss xmm1, dword [velocityOne + 4]
    addss xmm0, xmm1
    cvtss2si rax, xmm0
    cmp rax, 650
    jg checkPlayerTwo
    call movePlayerOne

    checkPlayerTwo:
    movss xmm0, dword [playerTwoPos + 4]
    movss xmm1, dword [velocityTwo + 4]
    addss xmm0, xmm1
    cvtss2si rax, xmm0
    cmp rax, 0
    jl endMove

    movss xmm0, dword [playerTwoPos + 4]
    movss xmm1, dword [velocityTwo + 4]
    addss xmm0, xmm1
    cvtss2si rax, xmm0
    cmp rax, 650
    jg endMove
    call movePlayerTwo
    jmp endMove

    movePlayerOne:
    ; move rectangle
    mov rcx, [playerOne]
    mov rdx, [velocityOne]
    call sfRectangleShape_move

    movss xmm0, [velocityOne + 4]
    movss xmm1, [playerOnePos + 4]
    addss xmm1, xmm0
    movss [playerOnePos + 4], xmm1
    ret

    movePlayerTwo:
    mov rcx, [playerTwo]
    mov rdx, [velocityTwo]
    call sfRectangleShape_move

    movss xmm0, [velocityTwo + 4]
    movss xmm1, [playerTwoPos + 4]
    addss xmm1, xmm0
    movss [playerTwoPos + 4], xmm1
    ret


    endMove:
    add rsp, 8 ; restore stack position
    ret


render:
    sub rsp, 8 ; align the stack
    ; Clear the window
    lea rcx, [rbx]
    mov rdx, 0x4B9CD300
    call sfRenderWindow_clear

    ; Draw the rectangle
    lea rcx, [rbx]
    mov rdx, [playerOne]
    mov r8, 0
    call sfRenderWindow_drawRectangleShape

    lea rcx, [rbx]
    mov rdx, [playerTwo]
    mov r8, 0
    call sfRenderWindow_drawRectangleShape

    lea rcx, [rbx]
    mov rdx, [ball]
    mov r8, 0
    call sfRenderWindow_drawRectangleShape

    ; Display the window
    lea rcx, [rbx]
    call sfRenderWindow_display
    add rsp, 8 ; restore stack position
    ret

main:
    ; For future reference: C functions are called by passing the arguments
    ; into registers. The order of registers to parameters goes as follows:
    ; rcx, rdx, r8, r9, stack pushes in reverse order
    ; Function calls clear registers for some reason so be aware of that and set registers for each function call
    ; Useful sizes to know: Videomode struct is 12 bytes, sfVector2f is 8 bytes, sfEvent is a maximum 28 bytes (union)
    ; To create a Vector2f struct allocate the values in the data section and modify as needed, then pass directly to register
    ; Don't try to use floating point registers to create a sfVector2f on the fly it won't work
    ; Note that sometimes the implementation of the external functions can unintentionally modify registers. If the
    ; Implementation seems right but its just not working, try a different register.

    ; Initialize stack frame
    push rbp
    mov rbp, rsp

    sub rsp, 16; allocate 16 bytes on the stack for videomode

    mov dword [rsp], 1600 ; width
    mov dword [rsp + 4],900 ; height
    mov dword [rsp + 8], 32 ; bits per pixel

    ; Registers for sfRenderWindow_create call
    lea rcx, [rsp]
    mov rdx, windowTitle
    mov r8, 7 ; sfDefaultStyle
    mov r9, 0 ; NULL
    call sfRenderWindow_create
    add rsp, 16 ; Free create memory and stack alignment
    ; sfRenderWindow pointer now lies in rax

    mov rbx, rax ; rbx is in charge of storing the window.

    ; Create playerOne and playerTwo
    call sfRectangleShape_create
    mov [playerOne], rax
    call sfRectangleShape_create
    mov [playerTwo], rax
    call sfRectangleShape_create
    mov [ball], rax


    ; set size to (200, 200)
    mov rcx, [playerOne]
    mov rdx, [rectSize]
    call sfRectangleShape_setSize

    mov rcx, [playerTwo]
    mov rdx, [rectSize]
    call sfRectangleShape_setSize

    mov rcx, [ball]
    mov rdx, [ballSize]
    call sfRectangleShape_setSize

    ; set position to (200, 200)
    mov rcx, [playerOne]
    mov rdx, [playerOnePos]
    call sfRectangleShape_setPosition

    mov rcx, [playerTwo]
    mov rdx, [playerTwoPos]
    call sfRectangleShape_setPosition

    mov rcx, [ball]
    mov rdx, [windowCenter]
    call sfRectangleShape_setPosition

    call sfClock_create
    mov [clock], rax


    loop:

        eventLoop:

            sub rsp, 32 ; Allocate stack for sfEvent struct
            lea rcx, [rbx] ; window pointer
            lea rdx, [rsp] ; buffer for sfEvent
            call sfRenderWindow_pollEvent
            mov r8, rax ; holds whether the event queue has another member

            cmp rax, 0
            je controlLogic ; If we dont have another event to process to the rest of the loop

            cmp dword [rdx], 0 ; rdx contains the sfEvent union. It has a maximum of 28 bytes so we need to ony take 4 of those for comparison
            jne notClosed ; skip closing the window if the event is not sfClose (0)

            closed:
                lea rcx, [rbx] ; window pointer
                call sfRenderWindow_close

            notClosed:
                cmp r8, 1 ; if we have another event to process go back
                je eventLoop

        controlLogic:
            ; Free stack allocation from event loop
            add rsp, 32

            ;calculate deltatime
            lea rcx, [clock]
            call sfClock_restart
            mov rcx, rax
            call sfTime_asSeconds
            movss [delta], xmm0

            call movePaddles
            call moveBall
            call render

            ; Check if the window is open and redo the loop if it is
            lea rcx, [rbx]
            call sfRenderWindow_isOpen
            cmp rax, 1
            je loop

    end:
        ; Clean up memory
        lea rcx, [r15]
        call sfRectangleShape_destroy

        lea rcx, [rbx]
        call sfRenderWindow_destroy

        PRINT successMsg

        ; exit program with code 0
        mov rcx, 0
        call exit
