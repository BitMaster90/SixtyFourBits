;*********************************************************
; FallingLine 
;
;  Written in Assembly x64
; 
;  By Sarthak Shah
;  Template incorporated from Toby Opferman
;
;*********************************************************


;*********************************************************
; Assembly Options
;*********************************************************


;*********************************************************
; Included Files
;*********************************************************
include ksamd64.inc
include demovariables.inc
include master.inc
include vpal_public.inc


;*********************************************************
; External WIN32/C Functions
;*********************************************************
extern LocalAlloc:proc
extern LocalFree:proc
extern time:proc
extern srand:proc
extern rand:proc

;*********************************************************
; Structures
;*********************************************************
PARAMFRAME struct
    Param1         dq ?
    Param2         dq ?
    Param3         dq ?
    Param4         dq ?
PARAMFRAME ends

SAVEREGSFRAME struct
    SaveRdi        dq ?
    SaveRsi        dq ?
    SaveRbx        dq ?
    SaveR10        dq ?
    SaveR11        dq ?
	SaveR12        dq ?
    SaveR13        dq ?
SAVEREGSFRAME ends

BROWNIAN_FUNCTION_STRUCT struct
   ParameterFrame PARAMFRAME      <?>
   SaveFrame      SAVEREGSFRAME   <?>
BROWNIAN_FUNCTION_STRUCT ends

;*********************************************************
; Public Declarations
;*********************************************************
public Brownian_Init
public Brownian_Demo
public Brownian_Free

MAX_FRAMES EQU <2000>

;*********************************************************
; Data Segment
;*********************************************************
.DATA

   FrameCounter dd ?
   PrevFrameCounter dd ?
   GlobalRDIOffset dq ?
   ColorValue dd ?
   PlotBuffer  dq ?
   X_offset dq ?
   Y_offset dq ?
   Brownian_InitFlag dd ?
   xDirection dd ?
   yDirection dd ?
   FirstChance dd ?
   Plot_Counter dq ?
   VirtualPalleteBrownian dq ?
   VirtualColorCounter dd ?
   Temp  dd ?

.CODE

;*********************************************************
;   Brownian_Init
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY Brownian_Init, _TEXT$00
 alloc_stack(SIZEOF BROWNIAN_FUNCTION_STRUCT)
 save_reg rdi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRdi
 save_reg rsi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRsi
.ENDPROLOG 

  MOV [FrameCounter], 0
  MOV [PrevFrameCounter], 0
  MOV [GlobalRDIOffset], 0
  MOV [ColorValue], 0FF0000h
  MOV [Brownian_InitFlag], 0h
  MOV [xDirection], 01h
  MOV [yDirection], 01h
  MOV [FirstChance], 0h
  MOV [Plot_Counter], 0h
  MOV [VirtualColorCounter], 0h
  ;
  ; Initialize Random Numbers
  ;
  XOR ECX, ECX
  CALL time
  MOV ECX, EAX
  CALL srand

  MOV RSI, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRsi[RSP]
  MOV RDI, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRdi[RSP]
  ADD RSP, SIZE BROWNIAN_FUNCTION_STRUCT
  MOV EAX, 1
  RET
NESTED_END Brownian_Init, _TEXT$00



;*********************************************************
;  Brownian_Demo
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE    
;
;
;*********************************************************  
NESTED_ENTRY Brownian_Demo, _TEXT$00
 alloc_stack(SIZEOF BROWNIAN_FUNCTION_STRUCT)
 save_reg rdi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRdi
 save_reg rsi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRsi
 save_reg rbx, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRbx
 save_reg r10, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR10
 save_reg r11, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR11
 save_reg r12, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR12
 save_reg r13, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR13

.ENDPROLOG 

  MOV RSI, RCX

  ;
  ; Get the Video Buffer
  ;  
  
  CMP [Brownian_InitFlag], 1
  JE @PlotRandom
  XOR r10, r10
  XOR r13, r13

  MOV [X_offset],0200h;RDX
  MOV [Y_offset], 0120h;,RDX
  

  MOV RAX, MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  MOV R9,  MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  MUL R9
  MOV RDX, RAX
  MOV ECX, 040h ; LMEM_ZEROINIT
  CALL LocalAlloc
  MOV [PlotBuffer], RAX
  
  
  MOV RCX, [X_offset]
  MOV RDX, [Y_offset]
  CALL Brownian_PlantSeed
  
  MOV RCX, 0210h
  MOV RDX, 0B0h
  CALL Brownian_PlantSeed
  
  MOV RCX, 01F0h
  MOV RDX, 0100h
  CALL Brownian_PlantSeed
  
  MOV RCX, 0220h
  MOV RDX, 0150h
  CALL Brownian_PlantSeed
  
  ;
  ; Create Virtual Palette for Stars
  ;   
  MOV RCX, 256
  CALL VPal_Create
  TEST RAX, RAX
  JZ @Terminate

  MOV [VirtualPalleteBrownian], RAX

  XOR EAX, EAX
  XOR RDX, RDX
  MOV EAX, 000100h

@PopulateBrownianPallete:
  MOV [Temp], EAX
  MOV R8, RAX
  MOV R12, RDX
  MOV RCX, [VirtualPalleteBrownian]
  CALL VPal_SetColorIndex
  MOV EAX, [Temp]
  ADD EAX, 000100h

  MOV RDX, R12
  INC RDX
  CMP RDX, 256
  JB @PopulateBrownianPallete
  
  MOV [Brownian_InitFlag], 1
 
  
  
  @PlotRandom: 
  CMP [Plot_Counter], 03000h
  JAE @SecondSquare
  MOV rcx, 01E7h
  MOV rdx, 0219h
  MOV r8, 0300h
  MOV r9, 0B8h
  CALL Brownian_FindNextPixel
  
  
  MOV RCX, RSI
  MOV RDX, [X_offset]
  MOV r8, [Y_offset]
  CALL Brownian_DisplayPixel

  CMP [Plot_Counter], 0500h
  JAE @SecondSquare
  MOV rcx, 01DDh
  MOV rdx, 0223h
  MOV r8, 0C8h
  MOV r9, 096h
  CALL Brownian_FindNextPixel
  
  MOV RCX, RSI
  MOV RDX, [X_offset]
  MOV r8, [Y_offset]
  CALL Brownian_DisplayPixel
  
  @SecondSquare:
  CMP [Plot_Counter], 05000h
  JAE @LastSquare
  MOV rcx, 01ABh
  MOV rdx, 0255h
  MOV r8, 012Ch
  MOV r9, 0C8h
  CALL Brownian_FindNextPixel
  
  MOV RCX, RSI
  MOV RDX, [X_offset]
  MOV r8, [Y_offset]
  CALL Brownian_DisplayPixel
  
  @LastSquare:
  CMP [Plot_Counter], 0A000h
  JAE @Terminate
  MOV rcx, 0160h
  MOV rdx, 02A0h
  MOV r8, 01C2h
  MOV r9, 012Ch
  CALL Brownian_FindNextPixel
  
  MOV RCX, RSI
  MOV RDX, [X_offset]
  MOV r8, [Y_offset]
  CALL Brownian_DisplayPixel
  
  INC [Plot_Counter]
 @Terminate:
  MOV RAX, 01h  
  MOV rdi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRdi[RSP]
  MOV rsi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRsi[RSP]
  MOV rbx, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRbx[RSP]

  MOV r10, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR10[RSP]
  MOV r11, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR11[RSP]
  MOV r12, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR12[RSP]
  MOV r13, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR13[RSP]

  ADD RSP, SIZE BROWNIAN_FUNCTION_STRUCT
  RET
  
NESTED_END Brownian_Demo, _TEXT$00

NESTED_ENTRY Brownian_PlantSeed, _TEXT$00
 alloc_stack(SIZEOF BROWNIAN_FUNCTION_STRUCT)
 save_reg rdi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRdi
 save_reg rsi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRsi
 save_reg rbx, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRbx
 save_reg r10, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR10
 save_reg r11, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR11
 save_reg r12, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR12
 save_reg r13, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR13

.ENDPROLOG 

  MOV r11, rcx
  MOV r12, rdx
  MOV RAX,r12
  MOV RDX, 0400h
  MUL RDX
  ADD RAX, r11
  MOV r10, PlotBuffer
  ADD r10,RAX
  MOV AL,1
  MOV [r10], AL  
  
 @Terminate:
  MOV rdi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRdi[RSP]
  MOV rsi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRsi[RSP]
  MOV rbx, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRbx[RSP]

  MOV r10, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR10[RSP]
  MOV r11, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR11[RSP]
  MOV r12, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR12[RSP]
  MOV r13, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR13[RSP]

  ADD RSP, SIZE BROWNIAN_FUNCTION_STRUCT
  RET
NESTED_END Brownian_PlantSeed, _TEXT$00








NESTED_ENTRY Brownian_DisplayPixel, _TEXT$00
 alloc_stack(SIZEOF BROWNIAN_FUNCTION_STRUCT)
 save_reg rdi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRdi
 save_reg rsi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRsi
 save_reg rbx, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRbx
 save_reg r10, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR10
 save_reg r11, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR11
 save_reg r12, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR12
 save_reg r13, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR13

.ENDPROLOG 

  MOV RSI, RCX
  MOV r11, RDX
  MOV r12, R8
  
  MOV RAX,r12
  MOV RDX, 0400h
  MUL RDX
  ADD RAX, r11
  MOV r10, PlotBuffer
  ADD r10,RAX
  MOV DL,01h
  MOV [r10], DL
  
  MOV RDI, MASTER_DEMO_STRUCT.VideoBuffer[RSI]
  MOV RCX, RSI
  MOV RDX, r11
  MOV r8,  r12
  CALL Brownian_PlotLocation
  ADD RDI, RAX
  
  MOV RCX, VirtualPalleteBrownian
  MOV EDX, [VirtualColorCounter]
  CALL VPal_GetColorIndex
  MOV [RDI], EAX
  
  INC [VirtualColorCounter]
  CMP [VirtualColorCounter], 255
  JA @ClearCounter
  
  
  
 @Terminate:
  MOV rdi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRdi[RSP]
  MOV rsi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRsi[RSP]
  MOV rbx, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRbx[RSP]

  MOV r10, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR10[RSP]
  MOV r11, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR11[RSP]
  MOV r12, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR12[RSP]
  MOV r13, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR13[RSP]

  ADD RSP, SIZE BROWNIAN_FUNCTION_STRUCT
  RET
  
  @ClearCounter:
  MOV [VirtualColorCounter], 0
  JMP @Terminate
NESTED_END Brownian_DisplayPixel, _TEXT$00


















;*********************************************************
;  Brownian_FindNextPixel
;
;        Parameters: left, right, top and bottom bound values.
;
;        Return Value: TRUE / FALSE    
;
;
;*********************************************************  


NESTED_ENTRY Brownian_FindNextPixel, _TEXT$00
 alloc_stack(SIZEOF BROWNIAN_FUNCTION_STRUCT)
 save_reg rdi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRdi
 save_reg rsi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRsi
 save_reg rbx, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRbx
 save_reg r10, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR10
 save_reg r11, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR11
 save_reg r12, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR12
 save_reg r13, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR13

.ENDPROLOG   
  MOV rdi, rcx
  MOV rsi, rdx
  MOV rbx, r8
  MOV r13, r9
  
   
  XOR r10, r10
  XOR rcx, rcx
  
  MOV r11, rsi
  SUB r11, rdi
  MOV r12, rbx
  SUB r12, r13
  
  CALL rand
  MOV r10,r11
  DIV r10
  ADD RDX, rdi
  MOV [X_offset], RDX
  
  CALL rand
  MOV rcx,r12
  DIV rcx
  ADD RDX, r13
  MOV [Y_offset],RDX
  
  MOV r11, [X_offset]
  MOV r12, [Y_offset]
  
  @PlotRandomInternal:
  CMP [xDirection], 0
  JE @DecrementX
  INC r11
  JMP @YCompare
  @DecrementX:
  DEC r11
  
  @Ycompare:
  CMP [yDirection], 0
  JE  @DecrementY
  INC r12
  JMP @StartBoundCheck
  @DecrementY:
  DEC r12
  
  
  @StartBoundCheck:
  ;check left
  CMP r11, rdi
  JBE @ChangeLeft
  
  ;check right 
  CMP r11, rsi
  JAE @ChangeRight
  
  ;check top
  CMP r12, rbx
  JAE @ChangeTop
  
  ;check Bottom
  CMP r12, r13
  JBE @ChangeBottom
  
  MOV RCX, r11
  MOV RDX, r12
  CALL CheckBrownian_Bounds
  CMP RAX, 0
  JE @PlotRandomInternal
  
  MOV [X_offset], r11
  MOV [Y_offset], r12
  
 @Terminate:
  MOV rdi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRdi[RSP]
  MOV rsi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRsi[RSP]
  MOV rbx, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRbx[RSP]

  MOV r10, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR10[RSP]
  MOV r11, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR11[RSP]
  MOV r12, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR12[RSP]
  MOV r13, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR13[RSP]

  ADD RSP, SIZE BROWNIAN_FUNCTION_STRUCT
  RET
  
  @ChangeLeft:
  CMP [xDirection], 0
  JNE @PlotRandomInternal
  INC [xDirection]
  CALL rand
  MOV r13,10h
  DIV r13
  ADD r11, RDX
  JMP @PlotRandomInternal
  
  @ChangeRight:
  CMP [xDirection], 1
  JNE @PlotRandomInternal
  DEC [xDirection]
  CALL rand
  MOV r13,09h
  DIV r13
  SUB r11, RDX
  JMP @PlotRandomInternal
  
  @ChangeTop:
  CMP [yDirection], 1
  JNE @PlotRandomInternal
  DEC [yDirection]
  
  CALL rand
  MOV r13,20h
  DIV r13
  SUB r12, RDX
  JMP @PlotRandomInternal
  
  @ChangeBottom:
  CMP [yDirection], 0
  JNE @PlotRandomInternal
  INC [yDirection]
  
  CALL rand
  MOV r13,0fh
  DIV r13
  ADD r12, RDX
  JMP @PlotRandomInternal
  
NESTED_END Brownian_FindNextPixel, _TEXT$00






NESTED_ENTRY CheckBrownian_Bounds, _TEXT$00
 alloc_stack(SIZEOF BROWNIAN_FUNCTION_STRUCT)
 save_reg rdi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRdi
 save_reg rsi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRsi
 save_reg rbx, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRbx
 save_reg r10, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR10
 save_reg r11, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR11
 save_reg r12, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR12
 save_reg r13, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR13

.ENDPROLOG 

  MOV RSI, RCX
  MOV r11, RDX
  
  SUB RSI, 1  ; Check Left
  ;CMP RSI, 01h
  ;JBE @FoundPixel
  
  MOV RAX,r11
  MOV RDX, 0400h
  MUL RDX
  ADD RAX, RSI
  MOV r10, PlotBuffer
  ADD r10,RAX
  MOV DL, [r10]
  CMP DL, 1
  JE @FoundPixel
  
  ADD RSI, 2  ; Check Right
  ;CMP RSI, 03FEh
  ;JAE @FoundPixel
  
  MOV RAX,r11
  MOV RDX, 0400h
  MUL RDX
  ADD RAX, RSI
  MOV r10, PlotBuffer
  ADD r10,RAX
  MOV DL, [r10]
  CMP DL, 1
  JE @FoundPixel
  
  SUB RSI, 1   ;Check Bottom
  ADD r11, 1
  ;CMP r11, 02FEh
  ;JAE @FoundPixel
  
 MOV RAX,r11
  MOV RDX, 0400h
  MUL RDX
  ADD RAX, RSI
  MOV r10, PlotBuffer
  ADD r10,RAX
  MOV DL, [r10]
  CMP DL, 1
  JE @FoundPixel
  
  SUB r11, 2 ;Check Top
  ;CMP r11, 1
  ;JBE @FoundPixel
  
  MOV RAX,r11
  MOV RDX, 0400h
  MUL RDX
  ADD RAX, RSI
  MOV r10, PlotBuffer
  ADD r10,RAX
  MOV DL, [r10]
  CMP DL, 1
  JE @FoundPixel
  MOV RAX, 0
  
  
 @Terminate:
  MOV rdi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRdi[RSP]
  MOV rsi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRsi[RSP]
  MOV rbx, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRbx[RSP]

  MOV r10, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR10[RSP]
  MOV r11, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR11[RSP]
  MOV r12, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR12[RSP]
  MOV r13, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR13[RSP]

  ADD RSP, SIZE BROWNIAN_FUNCTION_STRUCT
  RET
  
  @FoundPixel:
  MOV RAX,1
  JMP @Terminate
NESTED_END CheckBrownian_Bounds, _TEXT$00








NESTED_ENTRY Brownian_PlotLocation, _TEXT$00
 alloc_stack(SIZEOF BROWNIAN_FUNCTION_STRUCT)
 save_reg rdi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRdi
 save_reg rsi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRsi
 save_reg rbx, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRbx
 save_reg r10, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR10
 save_reg r11, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR11
 save_reg r12, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR12
 save_reg r13, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR13

.ENDPROLOG 

  MOV RSI, RCX
  MOV r11, RDX
  MOV r12, R8
  
  
  MOV EBX, MASTER_DEMO_STRUCT.Pitch[RSI]
  ADD RDI, RBX
  
  
  
  SHL r11,2
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  SHL RAX,2
  SUB RBX, RAX
  ADD RAX, RBX
  MUL r12
  ADD RAX, r11
  ;
  ; Get the Video Buffer
  ;  
  
  
  
 @Terminate:
  MOV rdi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRdi[RSP]
  MOV rsi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRsi[RSP]
  MOV rbx, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRbx[RSP]

  MOV r10, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR10[RSP]
  MOV r11, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR11[RSP]
  MOV r12, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR12[RSP]
  MOV r13, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR13[RSP]

  ADD RSP, SIZE BROWNIAN_FUNCTION_STRUCT
  RET
NESTED_END Brownian_PlotLocation, _TEXT$00



;*********************************************************
;  Brownian_Free
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Brownian_Free, _TEXT$00
 alloc_stack(SIZEOF BROWNIAN_FUNCTION_STRUCT)
 save_reg rdi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRdi
 save_reg rsi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRsi
 save_reg rbx, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRbx
.ENDPROLOG 

  ; Nothing to clean up

  MOV rdi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRdi[RSP]
  MOV rsi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRsi[RSP]
  MOV rbx, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRbx[RSP]

  ADD RSP, SIZE BROWNIAN_FUNCTION_STRUCT
  RET
NESTED_END Brownian_Free, _TEXT$00


END