IDEAL
MODEL small
STACK 100h
jumps
p186 ; VERY IMPORTENT
DATASEG
;daniel dvey aharon

; --------------------------
;//game variables
col dw 0 ; 0-320
row dw 145 ; 0 -200 ; const
input db ?
bmp_backg db 'mariob1.bmp',0 ;background
marioright db 'mario.bmp',0 ;imdge of mario looking right
marioleft db 'mariol.bmp',0 ;imdge of mario looking left
enemy db 'enemy.bmp',0 ;mushroom enemy picture
win db 'win.bmp',0 ;win background
gameover db 'gameover.bmp',0 ;lose background
count db 4 ;amount of times for jump loop
enemy1col dw 160
enemy1row dw 153
enemy2col dw 160
enemy2row dw 153
enemy1direction db 0 ;0 for right, 1 for left(bool)
enemy2direction db 0 ;0 for right, 1 for left(bool)
direction db 0 ;0 for right, 1 for left(bool)
;//time variables
const_1 db 1 ; const fo the num 1
const_10 db 10 ; const for the num 10
const_100 db 100 ; const for the num 100
startsec db ?
startm db ?
timer db ?
toprint db ?
const_timerrow db 0;time row is at const hight
timercol db ? ; changing
; --------------------------
CODESEG
start:
	mov ax, @data
	mov ds, ax
; --------------------------
	
	;switch to graphic mode
	mov ax, 13h
	int 10h
	
	;loads the background
	call loadbackground
	
	;saves starting seconds and starting minuits, for later timer calc
	mov ah, 2ch
	int 21h	
	mov [startsec], dh
	mov [startm], cl
;//////////////////////////game loop
gameloop:
	;loads the background to remove previous entities(player, enemys, timer)
	call loadbackground
	
	;update the timer and prints it
	call update_timer
	
	;draws the bird - if there was an input the col / row were updated last run 
	call drawmario
	
	
	; check for interaciton between player and enemies
	call interaction
	
	;(timer = 50) == true; then moves enemy number 2
	call enemy2birdmovement
	
	;either way moves enemy number 1
	call enemy1birdmovement
	
	; check for input without waiting - return 1 if there is something on the keyboard buffer(Like a waiting list) else returns 1. if exsisitng no need to wait for input and it put it in al right away
	mov ah, 01h
	int 16h
	
	; if we have input - proces input else start over the loop after waiting 100 ms
	jz skipinput
	
	;because there is an input - it calls the procedure that procces the input it update location the playes without printing it 
	call yesinput
	;check if input = w because if jumping we dont need a break
	cmp [input], 'w'
	je restart
	
	;wait 100 ms because if there are a lot of thing on the buffer it woulf make enemy bird move realy fast
	mov ax, 100
	call MOR_SLEEP

	;restart the game loop
	jmp restart
skipinput:
	; wait 100 ms, because we dont want the loop to run 2 much times a day
	mov ax, 100
	call MOR_SLEEP
restart:
	;check if timer reached a 100, if yes anounce win
	cmp [timer], 75
	je win1
	jmp gameloop
win1:
	;prints victory screen
	mov cx, 0
	mov dx, 0
	mov ax, offset win
	call MOR_LOAD_BMP
	
	;wait 4 seconds
	mov ax, 4000
	call MOR_SLEEP
	
	;finish game
	jmp exit
;///////////////////////////////end game loop
; --------------------------
	
exit:
	mov ax, 4c00h
	int 21h
	
include "MOR_LIB.ASM"
proc drawmario
;==============================================
;   drawmario - check the direction of the player and prints the player accordingly
;   IN: none
;   OUT: none
;	AFFECTED REGISTERS AND VARIABLES: none
; ==============================================
	;check the direction of the player, 1 for left, 0 for right
	pusha
	;check what direction the player is looking at
	cmp [direction], 1
	jne drawmarioright
	
	;prints player if he is looking to the left
	mov cx, [col]
	mov dx, [row]
	mov ax, offset marioleft
	call MOR_LOAD_BMP
	popa
	ret
	
	drawmarioright:
	;prints player if he is looking to the right
	mov cx, [col]
	mov dx, [row]
	mov ax, offset marioright
	call MOR_LOAD_BMP
	popa
	ret
endp

proc loadbackground
;==============================================
;   loadbackground - loads the background
;   IN: none
;   OUT: none
;	AFFECTED REGISTERS AND VARIABLES: none
; ==============================================
	;load the background
	pusha
	mov cx,0
	mov dx,0
	mov ax, offset bmp_backg
	call MOR_LOAD_BMP
	popa
	ret
endp
proc clearbuffer
;==============================================
;   clearbuffer - clears the keyboard buffer mainly to avoid double clicks
;   IN: input
;   OUT: none
;	AFFECTED REGISTERS AND VARIABLES: none
; ==============================================
	pusha
	more:
	mov  ah, 01h        ;check if there is input
	int  16h           
	jz   done          ;cant use(buffer is emety)
	mov  ah, 00h        ; uses input(and deltes it from buffer)
	int  16h           
	jmp  more          ;repet in case there are more
	done:
	popa
	ret
endp
proc yesinput
;==============================================
;   yesinput - moves the player according to the input
;   IN: input in keyboard buffer
;   OUT: none
;	AFFECTED REGISTERS AND VARIABLES: col, row, al, ah, cx, dx, ax, direction
; ==============================================
	;Get the input to al.	
	mov ah, 0h
	int 16h
	mov [input], al
	
	call clearbuffer
	
	;clears the keyboard buffer
	cmp al, 'w'
	je jump
	cmp al, 'a'
	je a
	cmp al, 'd'
	je right
	
	;if input is invalid
	ret
right:
	;direction = 0, if input = d, then set player to look right
	mov [direction], 0
	
	;moves the player
	add [col], 8
	
	;check if it left eage, if yes then dont let it move
	cmp [col], 296
	jbe noteage
	;at left eage = true
	mov [col], 296
noteage:
	;at left eage = false
	ret
jump:
	;to remove previous entities
	call loadbackground
	
	;jumps 4 pixel high
	dec [count]
	
	;moves the player up
	sub [row], 8 ;Going up
	
	;draws the player
	call drawmario
	
	;moves enemy bird1
	call enemy1birdmovement
	
	;if enemybird2 needs to move
	call enemy2birdmovement
	
	;check for interaction
	call interaction
	
	;update timer
	call update_timer
	
	; wait 100 ms
	mov ax, 100
	call MOR_SLEEP
		
	;check if loop is finished
	cmp [count], 0
	jne jump
	
	;moves 4 for next loop
	mov [count], 4
	
	call loadbackground
down:
	dec [count]
	
	;moves the player
	add [row], 8
	;draws mario
	call drawmario
	
	;moves enemy bird 
	call enemy1birdmovement
	
	;moves enemy2
	call enemy2birdmovement

	;check for interaction
	call interaction
	
	;update timer
	call update_timer
	
	;wait for 100 ms
	mov ax, 100
	call MOR_SLEEP
	
	;load the background
	call loadbackground
	
	;check if loops is finished
	cmp [count], 0
	jne down
	
	;update timer
	call update_timer
	
	;might be intraction on last one
	call interaction
	
	;to reset the loop for next jump
	mov [count], 4
	ret
a:
	;set direction to look to the left
	mov [direction], 1
	
	;moves the player
	sub [col], 8
	
	;check if at eadge,
	cmp [col],320 ;if [col] is above 320 it meanas that it went under 0 and turned into the bigges num dw can hold
	jbe noteage ;ret
	
	mov [col],0
	ret
endp
proc interaction
;==============================================
;   interaction - check for interaciton between player and enemy1, if timer > 50 check also interaction between player and enemy2. if interacted then reset the game and if q is pressed quit the game.
;   IN: none
;   OUT: none
;	AFFECTED REGISTERS AND VARIABLES: lives, row, enemy1col, enemy1row, enem2col, enemy2row, timer, direction, enemy1direction, enemy2direction, count.
; ==============================================
;note: if we have player and enemy at the same col, we dont need to check otherr enemy becuase the enemys are never on the same col
	;check if col is same if false then jump back else jump to next check 
	pusha
	mov ax, [col]
	mov bx, [enemy1col]
	
	;compare the enemys location with the range of the player(24 * 24)
	cmp ax, bx
	je touch
	
	add ax, 8
	cmp ax, bx
	je touch
	
	add ax, 8
	cmp ax, bx
	je touch
	
	add ax, 8
	cmp ax, bx
	jne check2
	
touch:
	;add 8 becuase the hight of the enemybird is 8 pixesls higher 
	mov ax, [row]
	add ax, 8
	cmp ax, 153
	
	;becuase enemys are not on the same col ever, then we dont need to check both if one of them is same col
	jne uninteracted
	jmp gameover1
check2:
	;checks if enemy2 started moving
	cmp [timer], 50
	jbe uninteracted
	
	
	;compares enemy2 with the range of the player(24 * 24)
	mov ax, [col]
	mov bx, [enemy2col]
	
	cmp ax, bx
	je touch
	
	add ax, 8
	cmp ax, bx
	je touch
	
	add ax, 8
	cmp ax, bx
	je touch
	
	add ax, 8
	cmp ax, bx
	je touch
	jmp uninteracted
gameover1:
	;loads the lose screen
	mov cx,0
	mov dx,0
	mov ax, offset gameover
	call MOR_LOAD_BMP
	
	;waits 4 second
	mov ax, 1000
	call MOR_SLEEP
	
	;reset the variables for next round
	mov [col], 0
	mov [row], 145
	mov [enemy1col], 160
	mov [enemy1row], 153
	mov [enemy2col], 160
	mov [enemy2row], 153
	mov [timer], 0
	;mov [direction], 0
	mov [enemy1direction], 0
	mov [enemy2direction], 0
	mov [count], 4
		
	; Wait for input - the games restarts if pressed
	mov ah, 0h
	int 16h
	
	cmp al, 'q'
	je exit
	
	call clearbuffer
	
	;gets starting seconds and starting minuits, for later timer calc
	mov ah, 2ch
	int 21h	
	mov [startsec], dh
	mov [startm], cl
	
	popa
	jmp gameloop
uninteracted:
	popa
	ret
endp
proc enemy1birdmovement
;==============================================
;   enemy1birdmovement - check if enemy is at eage if it is change enemy direction. and then moves it according to the direction in the bool enemy1direction and then prints it.
;   IN: bool
;   OUT: None
;	AFFECTED REGISTERS AND VARIABLES: enemy1direction, enemy1col, cx, dx, ax
; ==============================================
	;checks if the bird is going left or right
	cmp [enemy1direction], 1
	je goleft
	;moves the bird
	add [enemy1col], 8
	;check if at the right corener
	cmp [enemy1col],  296
	jbe noteageenemy1
	;if it at max, start moving to the left
	mov [enemy1direction], 1
	jmp noteageenemy1
	;if it is at the eage of the screen go to the start
goleft:	
	;moves the bird
	sub [enemy1col], 8
	;check if at left corner
	cmp [enemy1col], 0
	ja noteageenemy1
	;if it is at the let corner start moving to the right
	mov [enemy1direction], 0
noteageenemy1:
	;draws the bird
	mov cx, [enemy1col]
	mov dx, [enemy1row]
	mov ax, offset enemy
	call MOR_LOAD_BMP
	ret
	endp
	
proc enemy2birdmovement
;==============================================
;   enemy2birdmovement - check if enemy is at eage if it is change enemy direction. and then moves it according to the direction in the bool enemy2direction and then prints it.
;   IN: bool
;   OUT: None
;	AFFECTED REGISTERS AND VARIABLES: enemy2direction, enemy2col, cx, dx, ax
; ==============================================
	cmp [timer], 50
	jbe return
	;checks if the bird is going left or right
	cmp [enemy2direction], 1
	je goleft2
	;moves the bird
	add [enemy2col], 8
	;check if at the right corener
	cmp [enemy2col], 296
	jne noteageenemy2
	;if it at max, start moving to the left
	mov [enemy2direction], 1
	jmp noteageenemy2

	;if it is at the eage of the screen go to the start
goleft2:	
	;moves the bird
	sub [enemy2col], 8
	;check if at left corner
	cmp [enemy2col], 0
	jne noteageenemy2
	;if it is at the let corner start moving to the right
	mov [enemy2direction], 0
noteageenemy2:
	;draws the bird
	mov cx, [enemy2col]
	mov dx, [enemy2row]
	mov ax, offset enemy
	call MOR_LOAD_BMP
return:
	ret
	endp


	proc calcandprint
	;==============================================
;   print_al - takes al, and turn in into three seperate numbers(26 = 0, 2, 6) then calls a proc to print each num in its place
;   IN: al
;   OUT: graphic
;	AFFECTED REGISTERS AND VARIABLES: timercol, toprint
; ==============================================
	;
	pusha
	; dived by 100 to get the hundredss
    xor ah, ah
	DIV [const_100]; al-/   ah=%
	
	;print hundreds
	MOV dx,ax
	ADD dl,'0'
	mov [timercol], 2 ;;mov col
	mov [toprint], dl
	call print_timer
	
	xor ax, ax
	mov al, dh
	div [const_10]
	; dived by 10 to get two digits	
	;print ASHAROT
	MOV DX,AX
	ADD DL,'0'
	ADD DH,'0'
	mov [timercol], 3 ;;mov col
	mov [toprint], dl
	call print_timer
	
	;PRINT YECHIDOT 
	MOV DL,DH
	mov [timercol], 4 ;;mov col
	mov [toprint], dl
	call print_timer
	popa
	ret
	endp
	
	proc update_timer
;==============================================
;   updat_timer - calculate timer using the start time.
;   IN: start time
;   OUT: timer
;	AFFECTED REGISTERS AND VARIABLE: timer
; ==============================================
	pusha
	;check what is the time
	mov ah, 2ch
	int 21h	

	;check if dh(seconds) < startsec
	cmp dh, [startsec]
	jb dhsmaller
	
	; here dh >= [startsec]	
	sub dh, [startsec]
	jmp minutes
dhsmaller: 
	;explain: like in חיסור אנכי when you take 1 עשרות and turn it into 10 יחידות for calc
    ; here dh < [startsec]
	add dh, 60
	
	;turn 1 min into 60sec
	sub cl, 1
	sub dh, [startsec]
	
minutes:
    sub cl, [startm]
	mov ax, 60
	mul cl
	;conver to db
	div [const_1]
	; add to seconds	
	add al, dh
	mov [timer], al
	call calcandprint
	popa
	ret
	endp
	
	proc print_timer
	;==============================================
;   print_timer - prints the nums from calcandprint
;   IN: const_timerrow, const_timercol, toprint
;   OUT: none
;	AFFECTED REGISTERS AND VARIABLES: none
; ==============================================
	;it assumes that col is in dl and row is in dh
	pusha
	;set location
	mov dh, [const_timerrow]
	mov dl, [timercol]
	mov bh, 0
	mov ah, 2
	int 10h
	
	;prints the letter that was sent in  [toprint]
	mov ah, 9 ; 9 = print character with color
	mov al, [toprint] ; al = character to display
	xor bx, bx
	mov bx, 13;color
	mov cx, 1 ; cx = number of times to write character
	int 10h
	popa
	ret
	endp
END start



