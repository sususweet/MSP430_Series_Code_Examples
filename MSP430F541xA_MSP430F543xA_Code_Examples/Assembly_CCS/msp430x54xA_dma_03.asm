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
;  MSP430F543xA Demo - SPI TX & RX using DMA0 & DMA1 Single Transfer in Fixed
;                     Address Mode
;
;  Description: This code has to be used with MSP430F543xA_uscia0_spi_10.c as
;  slave SPI. DMA0 is used to transfer a single byte while DMA1 is used to
;  RX from slave SPI at the same time. This code will set P1.0 if RX character
;  is correct and clears P1.0 if received character is wrong. Watchdog in
;  interval mode triggers block transfer every 1000ms.
;  ACLK = REFO = 32kHz, MCLK = SMCLK = default DCO 1048576Hz
;
;                 MSP430F5438A
;             -----------------
;         /|\|              XIN|-
;          | |                 | 32768Hz
;          --|RST          XOUT|-
;            |                 |
;            |             P1.0|-> LED
;            |                 |
;            |             P3.4|-> Data Out (UCA0SIMO)
;            |                 |
;            |             P3.5|<- Data In (UCA0SOMI)
;            |                 |
;            |             P3.0|-> Serial Clock Out (UCA0CLK)
;
;   D. Dang
;   Texas Instruments Inc.
;   December 2009
;   Built with CCS Version: 4.0.2 and IAR Embedded Workbench Version: 4.11B
;******************************************************************************

    .cdecls C,LIST,"msp430.h"
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.

;-------------------------------------------------------------------------------
            .bss    TxString,1 
            .bss    RxString,1 
;-------------------------------------------------------------------------------
            .global _main 
            .text                           ; Assemble to Flash memory
;-------------------------------------------------------------------------------
_main
RESET       mov.w   #0x5C00,SP              ; Initialize stackpointer
StopWDT     mov.w   #WDT_ADLY_1000,&WDTCTL  ; WDT 1000ms, ACLK, interval timer
            bis.w   #WDTIE,&SFRIE1          ; Enable WDT interrupt
SetupP1     bic.b   #0x01,P1OUT             ; Clear P1.0
            bis.b   #0x01,P1DIR             ; P1.0 = Output
SetupP3     bis.b   #0x31,&P3SEL            ; P3.0,4,5 = USCI_A0 SPI Option
SetupUSCIA0 bis.b   #UCSWRST,&UCA0CTL1      ; **Put state machine in reset**
            mov.b   #UCMST+UCSYNC+UCCKPL+UCMSB,&UCA0CTL0
                                            ; 3-pin, 8-bit SPI master
                                            ; Clock polarity high, MSB
            mov.b   #UCSSEL_2,&UCA0CTL1     ; SMCLK
            mov.b   #0x02,&UCA0BR0          ; /2
            mov.b   #0x00,&UCA0BR1          ;
            mov.b   #0x00,&UCA0MCTL         ; No modulation
            bic.b   #UCSWRST,&UCA0CTL1      ; **Initialize USCI state machine**
                                            ;
            mov.w   #DMA1TSEL_16+DMA0TSEL_17,&DMACTL0
                                            ; DMA0 - UCA0TXIFG
                                            ; DMA1 - UCA0RXIFG
SetupDMA0   movx.a  #TxString,&DMA0SA       ; Source block address
            movx.a  #UCA0TXBUF,&DMA0DA      ; Destination single address
            mov.w   #1,&DMA0SZ              ; Block size
            mov.w   #DMASRCINCR_3+DMASBDB+DMALEVEL,&DMA0CTL ; inc src
                                            ;
SetupDMA1   movx.a  #UCA0RXBUF,&DMA1SA      ; Source block address
            movx.a  #RxString,&DMA1DA       ; Destination single address
            mov.w   #1,&DMA1SZ              ; Block size
            mov.w   #DMADSTINCR_3+DMASBDB,&DMA1CTL ; inc dst
                                            ;
            clr.b   TxString                ; Clear TxString
            clr.b   RxString                ; Clear RxString
Mainloop    bis.w   #LPM3+GIE,SR            ; Enter LPM3 w/ interrupts
            nop                             ; Required only for debugger
                                            ;
;-------------------------------------------------------------------------------
WDT_ISR ;   Trigger DMA0 & DMA1 block transfer. R15 used.
;-------------------------------------------------------------------------------
            mov.b   TxString,R15            ; if RXstring == TxString-1
            dec.b   R15
            cmp.b   R15,RxString
            jne     WDT_L1
            bis.b   #0x01,&P1OUT            ; Set P1.0 if True
            jmp     WDT_L2
WDT_L1      bic.b   #0x01,&P1OUT            ; Clear P1.0 if False
WDT_L2      inc.b   TxString                ; Increment TxString counter
            bis.w   #DMAEN,&DMA1CTL         ; DMA1 Enable
            bis.w   #DMAEN,&DMA0CTL         ; DMA0 Enable
            bic.b   #UCTXIFG,&UCA0IFG       ; Toggle TX IFG to trigger first
            bis.b   #UCTXIFG,&UCA0IFG       ; DMA transfer...
            reti                            ;
;-------------------------------------------------------------------------------
                  ; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".int58"                  ; WatchDog Timer Vector
            .short  WDT_ISR
            .sect   ".reset"                ; POR, ext. Reset
            .short  RESET
            .end
