	 .INCLUDE"m328Pdef.inc"
        .ORG 0X000
	.def REG_ERROR = R31
	.def REG_COUNT = R30
	.def REG_PASSWORD_HIGH = R29 
	.def REG_PASSWORD_LOW = R28
	.def flag = R27
        .def temp = R26
	.def	iLoopRh = R25		; registrador interno loop high
	.def	iLoopRl = R24		; registrador interno loop low
        .def	oLoopR 	= R23		; registrador externo de loop
	.def REG_BUTTON = R22
	;.def rl0 = R21
	;.def rl1 = R20
      	.def rl4 = R17
      	.def rl3 = R18
      	.def rl2 = R19
      	.def rl1 = R20
      	.def rl0 = R21
	.equ	iVal 	= 39998		; valor interno do loop
        .equ intensidade = 100 / 100 * 255
        .equ intensidade2 = 65 / 100 * 255
	

   
	ldi R16, 0b01101100
	out DDRD, R16
	ldi R16, 0b11111111
	out DDRB, R16
	ldi R16, 0b11101111
	out DDRC, R16
	LDI R16, 0X04
      	STS ADMUX, R16 ;indica que irei carregar o valor "00000100" no registrador admux, REFS[1..0](indica que selecionarei o Aref como referencia),adlar(inidica que o resultado será ajustado para a direita),mux[3..0](indica que eu quero selecionar a porta pc4)
      	LDI R16, 0X81
      	STS ADCSRA, R16 ;indica que irei carregar o valor "10000001" no registrador adcsra,aden=1(indica que estou dando enable no conversor), 
      
	
	rjmp STATE_START

STATE_START:
cbi	PORTD,PIND2
        LDI rl4, 0b10101010
	out PORTB,rl4
	ldi rl2,10
	out PORTC,rl2
	ldi REG_COUNT, 0 ;Zera o Contador
	ldi REG_ERROR, 0 ;Zera a Flag de Erro
	rcall vermelho
	;Display Desligado
	rjmp STATE_WAIT_ON

STATE_WAIT_ON:
	rcall BUTTON_SYNC
	in REG_BUTTON, PIND ;Pega o conjunto das entradas PIND, "Botão ON" é 0000 0001
	andi REG_BUTTON, 1 ;Usa a máscara 0000 0001
	cpi REG_BUTTON, 1 ;Compara com a máscara para ver se o "Botão ON" foi pressionado
	breq STATE_WAIT_VALUE ;Pula para o lable STATE_WAIT_VALUE caso o "Botão ON" tenha sido pressionado
	rjmp STATE_WAIT_ON ;Volta para o lable STATE_WAIT_ON caso o "Botão ON" NÃO tenha sido pressionado
	
STATE_OPEN:
        ;SBI PORTD, 0B00000100
	sbi	PORTD,PIND2
	;out PORTB, R27
	LDI rl4, 0b10101010
	out PORTB,rl4
	ldi rl2,10
	out PORTC,rl2
	rcall verde
	in REG_BUTTON, PIND
	andi REG_BUTTON, 1
	cpi REG_BUTTON, 1
	breq STATE_START
	rjmp STATE_OPEN

STATE_WAIT_VALUE:
	 
	rcall BUTTON_SYNC
STATE_WAIT_VALUE_POS_BUTTON_SYNC:
	rcall azul
	rcall StartADC
	in REG_BUTTON, PIND ;Pega o conjunto das entradas PIND, "Botão ON" é 0000 0001
	andi REG_BUTTON, 1 ;Usa a máscara 0000 0001
	cpi REG_BUTTON, 1 ;Compara com a máscara para ver se o "Botão ON" foi pressionado
	breq STATE_START ;Pula para o lable STATE_STATE_ON caso o "Botão ON" tenha sido pressionado
	in REG_BUTTON, PIND ;Pega o conjunto das entradas PIND, "Botão ADD" é 0000 0010
	andi REG_BUTTON, 2 ;Usa a máscara 0000 0010
	cpi REG_BUTTON, 2 ;Compara com a máscara para ver se o "Botão ADD" foi pressionado
	breq STATE_AWAIT_CONFIRM ;Pula para o lable STATE_AWAIT_CONFIRM caso o "Botão ADD" tenha sido pressionado
	rjmp STATE_WAIT_VALUE_POS_BUTTON_SYNC ;Volta para o lable TATE_WAIT_VALUE_POS_BUTTON_SYNC caso o "Botão ON" e "Botão ADD" NÃO tenham sido pressionados

STATE_AWAIT_CONFIRM:
       ; LDI rl4, 0b10101010
	;out PORTB,rl4
	;ldi rl2,10
	;out PORTC,rl2
	rcall laranja
	ldi 	oLoopR,3;PARA 1MHZ
	rcall delay10ms
	cpi REG_ERROR, 1 ;Compara com 1 para ver se tem algum erro na senha
	breq STATE_COUNT ;Pula para o lable STATE_COUNT caso a Flag de Erro seja 1
	rjmp STATE_COMP ;Pula para o lable STATE_COMP caso a Flag de Erro seja 0
	
	
STATE_CHECK:
	cpi REG_ERROR, 1
	breq STATE_START
	rjmp STATE_OPEN

STATE_COMP:
	cpi REG_COUNT, 0
	breq DATA0
	cpi REG_COUNT, 1
	breq DATA1
	cpi REG_COUNT, 2
	breq DATA2
	rjmp STATE_COUNT
DATA0:
	ldi REG_PASSWORD_LOW, 150
	ldi REG_PASSWORD_HIGH, 0
	cp rl0, REG_PASSWORD_LOW
	brne STATE_ERROR
	cp rl1, REG_PASSWORD_HIGH
	brne STATE_ERROR
	rjmp STATE_COUNT
DATA1:
	ldi REG_PASSWORD_LOW, 144
	ldi REG_PASSWORD_HIGH, 1
	cp rl0, REG_PASSWORD_LOW
	brne STATE_ERROR
	cp rl1, REG_PASSWORD_HIGH
	brne STATE_ERROR
	rjmp STATE_COUNT
DATA2:
	ldi REG_PASSWORD_LOW, 151
	ldi REG_PASSWORD_HIGH, 3
	cp rl0, REG_PASSWORD_LOW
	brne STATE_ERROR
	cp rl1, REG_PASSWORD_HIGH
	brne STATE_ERROR
	rjmp STATE_COUNT

STATE_ERROR:
	ldi REG_ERROR, 1
	rjmp STATE_COUNT

STATE_COUNT:
	inc REG_COUNT
	cpi REG_COUNT, 3
	breq STATE_CHECK
	rjmp STATE_WAIT_VALUE




BUTTON_SYNC:
	in REG_BUTTON, PIND ;Pega o conjunto das entradas PIND, "Botão ON" é 0000 0001
	andi REG_BUTTON, 1 ;Usa a máscara 0000 0001
	cpi REG_BUTTON, 1 ;Compara com a máscara para ver se o "Botão ON" está pressionado
	breq BUTTON_SYNC ;Volta para o BUTTON_SYNC caso o botão esteja pressionado
	in REG_BUTTON, PIND ;Pega o conjunto das entradas PIND, "Botão ADD" é 0000 0010
	andi REG_BUTTON, 2 ;Usa a máscara 0000 0010
	cpi REG_BUTTON, 2 ;Compara com a máscara para ver se o "Botão ADD" está pressionado
	breq BUTTON_SYNC ;Volta para o BUTTON_SYNC caso o botão esteja pressionado
	ret

vermelho: 
	   sbi ddrd, DDD6; utilizar o pino PD6(pwm)
	   ldi temp, intensidade ; intensidade da saida
	   out OCR0A, temp
	   ldi temp, 0b10000011 ;fast pwm mode, não-invertido, timer0
	   out tccr0a, temp ; timer para controlar porta A
	   ldi temp, 0b00000001 ;sem prescalar
	   out tccr0b, temp ;timer para controlar porta B
	   ldi temp, 0b00000011 ;fast pwm mode, não-invertido, timer0
           STS tccr2a, temp ; timer para controlar porta 
	   ret
	   
verde: 
      sbi ddrd, DDD5; utilizar o pino PD5(pwm)
      ldi temp, intensidade ; intensidade da saida
      out OCR0B, temp
      ldi temp, 0b00100011 ;fast pwm mode, não-invertido, timer0
      out tccr0a, temp ; timer para controlar porta A
      ldi temp, 0b00000001 ;sem prescalar
      out tccr0b, temp ;timer para controlar porta B
      ldi temp, 0b00000011 ;fast pwm mode, não-invertido, timer0
      STS tccr2a, temp ; timer para controlar porta 
      ret
      
;laranja: full vermelho(256), parcial verde(165)       
laranja:   
           sbi ddrd, DDD5; utilizar o pino PD6(pwm)
           sbi ddrd, DDD6; pino PD5
	   ldi temp, 200 ; intensidade da saida
	   out OCR0B, temp
	   ldi temp, 255 ; intensidade da saida
	   out OCR0A, temp
	   ldi temp, 0b10100011 ;fast pwm mode, não-invertido, timer0
	   out tccr0a, temp ; timer para controlar porta 
	   ldi temp, 0b00000001 ;sem prescalar
	   out tccr0b, temp ;timer para controlar porta B
	   ldi temp, 0b00000011 ;fast pwm mode, não-invertido, timer0
         STS tccr2a, temp ; timer para controlar porta 
	   ret
	   
azul:  
       ;sbi ddrb, DDB3; utilizar o pino PB3(pwm)
       sbi ddrd, DDD3; utilizar o pino PD3(pwm)
       ldi temp, intensidade ; intensidade da saida
       sts OCR2B, temp
       ldi temp, 0b00100011 ;fast pwm mode, não-invertido, timer2
       sts tccr2a, temp ; timer para controlar porta A
       ldi temp, 0b00000001 ;sem prescalar
       sts tccr2b, temp ;timer para controlar porta B
       ldi temp, 0b00000011 ;fast pwm mode, não-invertido, timer0
       out tccr0a, temp ; timer para controlar porta A
       ret

delay10ms:
	ldi	iLoopRl,LOW(iVal)	; inicia o contador interno do loop
	ldi	iLoopRh,HIGH(iVal)	; registradores loop high e low

iLoop:	
	sbiw	iLoopRl,1		; decremento do registrador interno loop low
	brne	iLoop			; pula para iLoop se registrador iLoop for != 0
	dec	oLoopR			; decremento do registrador de saida loop
	brne	delay10ms		; pula para delay5ms se registrador oLoopR for != 0
	nop		                ; apenas para perder ciclo de clock
	
	ret				; retorno da subroutine

StartADC:    LDS R16, ADCSRA
	     ORI R16, 1<<ADSC  ;indica que irei carregar o valor '1' no pino adsc do registrador ADCSRA dando start na conversão
	     STS ADCSRA, R16   ;


KeepPolling: lds R16, ADCSRA
	     sbrs R16,	ADIF ;indica que devo dar skip na proxima instrução caso a flag ADIF seja verdadeira
	     rjmp KeepPolling
	     
	     
	     ;SBI ADCSRA, ADIF
	     ;LDS R16, ADCL
	     ;OUT PORTD, R16
	     ;LDS R16, ADCH
	    ; OUT PORTB, R16
	     


	    LDI rl4, 0 

	    LDI rl3, 0 

	    LDI rl2, 0 

	    LDS rl0, ADCL 

	    LDS rl1, ADCH 
	    
	    
	    
	    

compcent1: CPI rl1, 0 

	    BREQ compcent2 
      
	    SUBI rl0, 100

	    SBCI rl1, 0
      
	    INC rl4 

	    RJMP compcent1

compcent2: CPI rl0, 100 

	    BRLO compdez

	    SUBI rl0, 100

	    INC rl4

	    RJMP compcent2

compdez: CPI rl0, 10

	    BRLO compuni

	    SUBI rl0, 10

	    INC rl3

	    RJMP compdez

compuni: MOV rl2, rl0


	     SWAP rl4
	     OR rl4, rl3; RL4=CENT,RL3=DEZ,RL2=UNIDADE 
	    OUT PORTB, rl4

	    OUT PORTC, rl2
	    LDS rl0, ADCL 
	    LDS rl1, ADCH
	    ret
	    
	    
	    