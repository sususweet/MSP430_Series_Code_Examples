; --COPYRIGHT--,BSD_EX
;  Copyright (c) 2012, Texas Instruments Incorporated
;  All rights reserved.
; 
;  Redistribution and use in source and binary forms, with or without
;  modification, are permitted provided that the following conditions
;  are met:
; 
;  *  Redistributions of source code must retain the above copyright
;     notice, this list of conditions and the following disclaimer.
; 
;  *  Redistributions in binary form must reproduce the above copyright
;     notice, this list of conditions and the following disclaimer in the
;     documentation and/or other materials provided with the distribution.
; 
;  *  Neither the name of Texas Instruments Incorporated nor the names of
;     its contributors may be used to endorse or promote products derived
;     from this software without specific prior written permission.
; 
;  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
;  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
;  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
;  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
;  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
;  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
;  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
;  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
;  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
;  EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
; 
; ******************************************************************************
;  
;                        MSP430 CODE EXAMPLE DISCLAIMER
; 
;  MSP430 code examples are self-contained low-level programs that typically
;  demonstrate a single peripheral function or device feature in a highly
;  concise manner. For this the code may rely on the device's power-on default
;  register values and settings such as the clock configuration and care must
;  be taken when combining code from several examples to avoid potential side
;  effects. Also see www.ti.com/grace for a GUI- and www.ti.com/msp430ware
;  for an API functional library-approach to peripheral configuration.
; 
; --/COPYRIGHT--
;******************************************************************************
;   MSP430F54xA Demo - Timer_B, PWM TB1-6, Up Mode, DCO SMCLK
;
;   Description: This program generates six PWM outputs on P4 using
;   Timer_B configured for up mode. The value in CCR0, 512-1, defines the PWM
;   period and the values in CCR1-6 the PWM duty cycles. Using ~1048kHz SMCLK
;   as TBCLK, the timer period is ~488us.
;   ACLK = 32kHz, SMCLK = MCLK = TBCLK = default DCO ~1048kHz.
;
;                MSP430F5438A
;             -----------------
;         /|\|              XIN|-
;          | |                 |  32kHz
;          --|RST          XOUT|-
;            |                 |
;            |         P4.1/TB1|--> CCR1 - 75% PWM
;            |         P4.2/TB2|--> CCR2 - 25% PWM
;            |         P4.3/TB3|--> CCR3 - 12.5% PWM
;            |         P4.4/TB4|--> CCR4 - 6.26% PWM
;            |         P4.5/TB5|--> CCR5 - 3.13% PWM
;            |         P4.6/TB6|--> CCR6 - 1.566% PWM
;
;   D. Dang
;   Texas Instruments Inc.
;   December 2009
;   Built with CCS Version: 4.0.2 
;******************************************************************************

    .cdecls C,LIST,"msp430.h"
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.

;-------------------------------------------------------------------------------
            .global _main 
            .text                           ; Assemble to Flash memory
;-------------------------------------------------------------------------------
_main
RESET       mov.w   #0x5C00,SP              ; Initialize stackpointer
            mov.w   #WDTPW + WDTHOLD,&WDTCTL; Stop WDT    
            bis.b   #0x7E,&P4SEL            ; P4 option select
            bis.b   #0x7E,&P4DIR            ; P4 outputs

            mov.w   #512-1,&TBCCR0          ; PWM Period
            mov.w   #OUTMOD_7,&TBCCTL1      ; CCR1 reset/set
            mov.w   #383,&TBCCR1            ; CCR1 PWM Duty Cycle	
            mov.w   #OUTMOD_7,&TBCCTL2      ; CCR2 reset/set
            mov.w   #128,&TBCCR2            ; CCR2 PWM duty cycle	
            mov.w   #OUTMOD_7,&TBCCTL3      ; CCR3 reset/set
            mov.w   #64,&TBCCR3             ; CCR3 PWM duty cycle	
            mov.w   #OUTMOD_7,&TBCCTL4      ; CCR4 reset/set
            mov.w   #32,&TBCCR4             ; CCR4 PWM duty cycle	
            mov.w   #OUTMOD_7,&TBCCTL5      ; CCR5 reset/set
            mov.w   #16,&TBCCR5             ; CCR5 PWM duty cycle	
            mov.w   #OUTMOD_7,&TBCCTL6      ; CCR6 reset/set
            mov.w   #8,&TBCCR6              ; CCR6 PWM duty cycle	
            mov.w   #TBSSEL_2 + MC_1 + TBCLR,&TBCTL
                                            ; SMCLK, upmode, clear TBR

            bis.w   #LPM0 + GIE,SR          ; Enter LPM0, enable interrupts
            nop                             ; For debugger

;-------------------------------------------------------------------------------
                  ; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; POR, ext. Reset
            .short  RESET
            .end
