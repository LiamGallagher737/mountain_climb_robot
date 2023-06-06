#define __SFR_OFFSET 0x00
#include "avr/io.h"

.global start

start:
  SBI DDRB, 0 ; set D8 as output lmf
  SBI DDRB, 1 ; set D9 as output lmb
  SBI DDRB, 4 ; set D12 as output rmf
  SBI DDRB, 5 ; set D13 as output rmb

  CBI DDRD, 6 ; set D6 as input sonar echo
  SBI DDRD, 7 ; set D7 as output sonar trig

  RCALL forward
loop:
  
  ; sonar
  CBI PORTD, 7 ; set trig low
  LDI R24, 32 ; wait 32 cycles, 16Mhz * 2μs
  RCALL timer
  SBI PORTD, 7 ; set trig high
  LDI R24, 160 ; wait 160 cycles, 16Mhz * 10μs
  RCALL timer
  SBRC PORTD, 6 ; skip wait for high if already high
  RJMP start_timing
wait_for_high:
  SBRS PORTD, 6
  RJMP wait_for_high
start_timing:
  CLR R20
  OUT TCNT0, R20 ; start counter with 0
  LDI R20, 0b00000010
  OUT TCCR0B, R20 ; timer normal mode, scale CLK/8
check_high:
  SBRS PORTD, 6
  RJMP check_high
  IN R20, TCNT0
  LDI R21, 1000
  CP R20, R21
  BRSH stop

  RJMP loop

forward:
  SBI PORTB, 0
  SBI PORTB, 4
  CBI PORTB, 1
  CBI PORTB, 5
  RET

stop:
  CBI PORTB, 0
  CBI PORTB, 4
  CBI PORTB, 1
  CBI PORTB, 5
  RJMP stop

timer:
  CLR R20
  OUT TCNT0, R20 ; set timer to 0
  OUT OCR0A, R24 ; set comparison to R24
  CLR R24
  LDI R20, 0b00000001
  OUT TCCR0B, R20 ; timer normal mode, scale CLK
check_timer:
  IN R20, TIFR0
  SBRS R20, OCF0A ; if timer completed break
  RJMP check_timer
  CLR R20
  OUT TCCR0B, R20 ; stop timer
  LDI R20, (1<<OCF0A)
  OUT TIFR0, R20 ; reset flag
  RET

