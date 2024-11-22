bits 64
default rel

section .data

    delta dq 0.0
    speed dd 400.0
    ballAcceleration dd 20.0
    playerOnePos dd 0.0, 340.0
    playerTwoPos dd 1550.0, 340.0
    rectSize dd 50.0, 250.0
    ballSize dd 20.0, 20.0
    velocityOne dd 0.0, 0.0
    velocityTwo dd 0.0, 0.0
    baseBallVelocity dd 400.0, 400.0
    ballVelocity dd 400.0, 400.0
    ballCurrentVelocity dd 0.0, 0.0
    ballPos dd 790.0, 440.0




    successMsg db "Exited with no errors!", 10, 0
    videoMode dd 1600, 900, 32
    windowTitle db "SFML in Assembly!", 0
    windowCenter dd 790.0, 440.0 ; offset by ballsize/2 because i dont want to set origin
    fmt db "%d", 10, 0


section .bss
    clock resb 8
    playerOne resb 8
    playerTwo resb 8
    ball resb 8
    pOneBounds resb 16
    pTwoBounds resb 16
    ballBounds resb 16


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
extern sfRectangleShape_getGlobalBounds
extern sfRectangleShape_getLocalBounds
extern sfRectangleShape_getSize
extern sfRectangleShape_getFillColor
extern sfRectangleShape_getTexture


extern sfRectangleShape_getPosition
extern sfFloatRect_intersects
extern sfClock_create
extern sfClock_restart
extern sfTime_asSeconds
extern sfKeyboard_isKeyPressed
extern sfFloatRect
extern sfVector2f



%macro PRINT 1
    mov rcx, %1
    call printf
%endmacro

moveBall:
    push rbp
    mov rbp, rsp
    movss xmm0, [ballVelocity]
    mulss xmm0, [delta]
    movss [ballCurrentVelocity], xmm0
    movss xmm1, [ballPos]
    addss xmm1, xmm0
    movss [ballPos], xmm1

    movss xmm0, [ballVelocity + 4]
    mulss xmm0, [delta]
    movss [ballCurrentVelocity + 4], xmm0
    movss xmm1, [ballPos+4]
    addss xmm1, xmm0
    movss [ballPos+4], xmm1

    mov rcx, [ball]
    mov rdx, [ballCurrentVelocity]
    call sfRectangleShape_move

    call checkBall
    leave
    ret

checkBall:
    push rbp
    mov rbp, rsp
    cvtss2si rax, [ballPos + 4]
    cmp rax, 0
    jl reverseY
    cmp rax, 880
    jg reverseY

    paddleCheck:
    ; Get bounds of rectangles
    mov rcx, ballBounds
    mov rdx, [ball]
    call sfRectangleShape_getGlobalBounds
    mov rcx, pOneBounds
    mov rdx, [playerOne]
    call sfRectangleShape_getGlobalBounds
    mov rcx, pTwoBounds
    mov rdx, [playerTwo]
    call sfRectangleShape_getGlobalBounds

    ; Check for intersection
    mov rcx, ballBounds
    mov rdx, pOneBounds
    call sfFloatRect_intersects
    mov r10, rax

    mov rcx, ballBounds
    mov rdx, pTwoBounds
    call sfFloatRect_intersects

    or rax, r10
    cmp rax, 1
    je reverseX

    scoreCheck:
    cvtss2si rax, [ballPos]
    cmp rax, 0
    jl resetBall
    cmp rax, 1580
    jg resetBall

    jmp checkDone


    reverseY:


    cmp rax, 0
    jl moveDown
    cmp rax, 880
    jg moveUp


    moveDown:
    mov rax, 0
    jmp setPos
    moveUp:
    mov rax, 880
    jmp setPos


    setPos:
    cvtsi2ss xmm0, rax
    movss [ballPos + 4], xmm0
    mov rcx, [ball]
    mov rdx, [ballPos]
    call sfRectangleShape_setPosition
    jmp flip


    flip:
    movss xmm0, [ballVelocity + 4]
    mov eax, 0x80000000
    movd xmm1, eax
    xorps xmm0, xmm1
    movss [ballVelocity + 4], xmm0
    jmp paddleCheck


    reverseX:
    movss xmm0, [ballVelocity]
    mov eax, 0x80000000
    movd xmm1, eax
    xorps xmm0, xmm1
    movss [ballVelocity], xmm0
    jmp scoreCheck

    resetBall:
    mov rcx, [windowCenter]
    mov [ballPos], rcx
    mov rcx, [ball]
    mov rdx, [ballPos]
    call sfRectangleShape_setPosition
    mov rax, [baseBallVelocity]
    mov [ballVelocity], rax


    checkDone:
    leave
    ret


speedUpBall:
    push rbp
    mov rbp, rsp

    movss xmm0, [delta]
    movss xmm1, [ballAcceleration]
    mulss xmm0, xmm1
    movss xmm2, xmm0

    cvtss2si rax, [ballVelocity]
    test rax, rax

    jns speedUpX

    ; change sign
    mov eax, 0x80000000
    movd xmm1, eax
    xorps xmm0, xmm1

    speedUpX:
    movss xmm1, [ballVelocity]
    addss xmm1, xmm0
    movss [ballVelocity], xmm1

    ySpeed:
    movss xmm0, xmm2
    cvtss2si rax, [ballVelocity + 4]
    test rax, rax

    jns speedUpY

    ; change sign
    mov eax, 0x80000000
    movd xmm1, eax
    xorps xmm0, xmm1

    speedUpY:
    movss xmm1, [ballVelocity + 4]
    addss xmm1, xmm0
    movss [ballVelocity + 4], xmm1

    leave
    ret




movePaddles:
    push rbp
    mov rbp, rsp
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
    push rbp
    mov rbp, rsp
    mov rcx, [playerOne]
    mov rdx, [velocityOne]
    call sfRectangleShape_move

    movss xmm0, [velocityOne + 4]
    movss xmm1, [playerOnePos + 4]
    addss xmm1, xmm0
    movss [playerOnePos + 4], xmm1
    leave
    ret

    movePlayerTwo:
    push rbp
    mov rbp, rsp
    mov rcx, [playerTwo]
    mov rdx, [velocityTwo]
    call sfRectangleShape_move

    movss xmm0, [velocityTwo + 4]
    movss xmm1, [playerTwoPos + 4]
    addss xmm1, xmm0
    movss [playerTwoPos + 4], xmm1
    leave
    ret


    endMove:
    leave
    ret


render:
    push rbp
    mov rbp, rsp
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
    leave
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


    ; Registers for sfRenderWindow_create call
    lea rcx, [videoMode]
    mov rdx, windowTitle
    mov r8, 7 ; sfDefaultStyle
    mov r9, 0 ; NULL
    call sfRenderWindow_create
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
            mov rcx, [clock]
            call sfClock_restart
            mov rcx, rax
            call sfTime_asSeconds
            movss [delta], xmm0




            call movePaddles
            call moveBall
            call speedUpBall
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
