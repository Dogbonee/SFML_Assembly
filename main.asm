bits 64
default rel

section .data
    rect: dd 200.0, 200.0  ; Initialize the structure
    successMsg db "Exited with no errors!", 10, 0
    windowTitle db "SFML in Assembly!", 0
    fmt db "%f"


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


%macro PRINT 1
    push rcx
    sub rsp, 8
    mov rcx, %1
    call printf
    add rsp, 8
    pop rcx
%endmacro



main:
    ; For future reference: C functions are called by passing the arguments
    ; into registers. The order of registers to parameters goes as follows:
    ; rcx, rdx, r8, r9, stack pushes in reverse order
    ; Function calls clear registers for some reason so be aware of that and set registers for each function call
    ; Useful sizes to know: Videomode struct is 12 bytes, sfVector2f is 8 bytes, sfEvent is a maximum 28 bytes (union)
    ; To create a Vector2f struct allocate the values in the data section and modify as needed, then pass directly to register
    ; Don't try to use floating point registers to create a sfVector2f on the fly it won't work

    ; Initialize stack frame
    push rbp
    mov rbp, rsp

    sub rsp, 16; allocate 16 bytes on the stack for videomode

    mov dword [rsp], 800 ; width
    mov dword [rsp + 4], 600 ; height
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

    ; Create rectangle
    call sfRectangleShape_create
    ; rectangle struct pointer now in rax
    lea r15, [rax]

    ; Set fill color to red
    lea rcx, [r15]
    mov rdx, 0xFF0000FF
    call sfRectangleShape_setFillColor


    ; set size to (200, 200)
    lea rcx, [r15]
    mov rdx, [rect]
    call sfRectangleShape_setSize

    ; set position to (200, 200)
    lea rcx, [r15]
    mov rdx, [rect]
    call sfRectangleShape_setPosition


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

            ; Clear the window
            lea rcx, [rbx]
            mov rdx, 0x0000FF00
            call sfRenderWindow_clear

            ; Draw the rectangle
            lea rcx, [rbx]
            lea rdx, [r15]
            mov r8, 0
            call sfRenderWindow_drawRectangleShape

            ; Display the window
            lea rcx, [rbx]
            call sfRenderWindow_display


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
