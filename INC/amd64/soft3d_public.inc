;****************************************
;
;  Software 3D Public Header
;
;     Toby Opferman
;
;****************************************

; Structures
TD_ROTATION STRUCT
    x   dq ?
    y   dq ?
	z   dq ?
TD_ROTATION ENDS

TD_POINT STRUCT
    x   dq ?
    y   dq ?
	z   dq ?
TD_POINT ENDS

TD_POINT_2D STRUCT
    x   dq ?
    y   dq ?
TD_POINT_2D ENDS

PIXEL_COLOR_BYTE STRUCT
    Blue    db ?
	Green   db ?
	Red     db ?  
	Alpha   db ?
PIXEL_COLOR_BYTE ENDS


PIXEL_COLOR UNION
    ColorBytes  PIXEL_COLOR_BYTE <?>
	Color       dd                ?
PIXEL_COLOR ENDS

PIXEL_COLOR_BYTE STRUCT
    Blue    db ?
	Green   db ?
	Red     db ?  
	Alpha   db ?
PIXEL_COLOR_BYTE ENDS

TD_PIXEL STRUCT
  Point      TD_POINT    <?>
  Pixel      PIXEL_COLOR  <>
TD_PIXEL ENDS



