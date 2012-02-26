.XMM
.MODEL FLAT, C

rayTracerStack	SEGMENT stack
				DB 1024 dup(0)
rayTracerStack	ENDS

rayTracerData	SEGMENT PAGE

				ALIGN 16
				ORG 0

				CameraPosition		DQ 4 dup(0)
				CameraDirection		DQ 4 dup(0)

				NearestIntersection DQ 4 dup(0)
				NearestDistance		DQ 4 dup(0)
				NearestESI			DD 4 dup(0)

				Ones4D				DQ 1.0f, 1.0f, 1.0f, 1.0f
				Ones4F				DD 1.0f, 1.0f, 1.0f, 1.0f
				Zeroes4D			DQ 0.0f, 0.0f, 0.0f, 0.0f
				Zeroes4F			DD 0.0f, 0.0f, 0.0f, 0.0f

				Threes3D			DQ 3.0f, 3.0f, 3.0f, 3.0f

				MinusOnes4D			DQ -1.0f, -1.0f, -1.0f, -1.0f

				Ones4				DD  0.99f, 0.99f, 0.99f, 0.99f
				MinusOnes4			DD -1.0f, -1.0f, -1.0f, -1.0f
				Epsilons4			DD  1.1f,  1.1f,  1.1f,  1.1f

				S_CX				DQ 0
				S_CY				DQ 0
				S_CZ				DQ 1.0
				S_Unused			DQ 0

				S_SX				DD 0
				S_SY				DD 0

				FrameWidth			DWORD 0
				FrameHeight			DWORD 0
				Screen				DWORD 0
				BackgroundRed		DWORD 0
				BackgroundGreen		DWORD 0
				BackgroundBlue		DWORD 0
				Primitives			DWORD 0
				Lights				DWORD 0

rayTracerData	ENDS

rayTracerCode	SEGMENT 'code'

Render			PROC _FrameWidth : DWORD , _FrameHeight : DWORD, _Screen : DWORD,
					 _bgRed : DWORD, _bgGreen : DWORD, _bgBlue : DWORD,
					 _prims : DWORD, _camera : DWORD, _lights: DWORD

				PUSHAD
				MOV eax, _FrameWidth
				MOV FrameWidth, eax
				MOV eax, _FrameHeight
				MOV FrameHeight, eax
				MOV eax, _Screen
				MOV Screen, Eax
				MOV eax, _bgRed
				MOV BackgroundRed, eax
				MOV eax, _bgGreen
				MOV BackgroundGreen, eax
				MOV eax, _bgBlue
				MOV BackgroundBlue, eax
				MOV eax, _prims
				MOV Primitives, eax
				MOV eax, _lights
				MOV Lights, eax

				MOV ESI, _camera
				LEA EDI, offset S_SX
				MOV EAX, [ESI]
				MOV [EDI], EAX
				MOV EAX, [ESI + 4]
				MOV [EDI + 4], EAX

				XOR EAX,EAX
				MOV dword ptr [CameraPosition], EAX
				MOV dword ptr [CameraPosition + 4], EAX
				MOV dword ptr [CameraPosition + 8], EAX
				MOV dword ptr [CameraPosition + 12], EAX
				MOV dword ptr [CameraPosition + 16], EAX
				MOV dword ptr [CameraPosition + 20], EAX
				MOV dword ptr [CameraPosition + 24], EAX
				MOV dword ptr [CameraPosition + 28], EAX

				; Czyszczenie bufora kolorów.
				CALL ClearScreen

				; Renderowanie calej sceny.
				CALL RayTraceAll

				POPAD
				RET
Render			ENDP

; Parametr: XMM0, Wyzerowac 4 qw.
Normalize		PROC
				MOVAPS xmm1, xmm0
				MOVAPS xmm2, xmm1
				MULPS  xmm1, xmm2				; XMM1 = dot product XMM0
				MOVSHDUP xmm2, xmm1				; XMM2 = y2
				ADDPS xmm1,	xmm2
				MOVHLPS xmm2, xmm1
				ADDPS xmm1,xmm2					; XMM0 = mamy dlugosc do kwadratu

				; Pierwiastek, odwrócenie i sklonowanie - potem wymnozyc przez XMM0.
				RSQRTSS xmm1, xmm1
				PSHUFD xmm1, xmm1, 0			; Klonowanie xmm1.
				MULPS xmm0, xmm1				; Dzielenie przez dlugoœæ.
				RET
Normalize		ENDP

; Parametr: XMM0
Length2			PROC
				MOVAPS xmm1, xmm0
				MULPS  xmm0, xmm1				; XMM1 = dot product XMM0
				MOVSHDUP xmm1, xmm0
				ADDPS xmm0, xmm1
				MOVHLPS xmm1, xmm0
				ADDPS xmm0, xmm1
				RET
Length2			ENDP

FLength			PROC
				MOVAPS xmm1, xmm0
				MULPS  xmm0, xmm1				; XMM1 = dot product XMM0
				MOVSHDUP xmm1, xmm0
				ADDPS xmm0, xmm1
				MOVHLPS xmm1, xmm0
				ADDPS xmm0, xmm1
				SQRTSS xmm0, xmm0
				RET
FLength			ENDP

; Parametry: XMM0, XMM1
DotProduct		PROC
				MULPS  xmm0, xmm1
				MOVSHDUP xmm1, xmm0
				ADDPS xmm0, xmm1	
				MOVHLPS xmm1, xmm0
				ADDPS xmm0, xmm1
				RET
DotProduct		ENDP

; Parametry: XMM0, XMM1 (XMM0 x XMM1)
CrossProduct	PROC
				PSHUFD xmm2, xmm1, 0C9H
				MULPS xmm2, xmm0				; W XMM2 mamy 1 mnozenie.
				PSHUFD xmm0, xmm0, 0C9H
				MULPS xmm0, xmm1				; W XMM0 mamy 2 mnozenie.
				SUBPS xmm2, xmm0
				PSHUFD xmm0, xmm2, 0C9H
				RET
CrossProduct	ENDP

; Czyszczenie bufora kolorów.
ClearScreen		PROC
				PUSHAD
	
				MOV EAX, FrameWidth
				MOV ECX, FrameHeight
				IMUL ECX
				MOV ECX, EAX
				MOV EAX, BackgroundRed
				MOV EBX, Screen
	
ClearScreenLoop:
				MOV [EBX], EAX
				INC EBX
				INC EBX
				INC EBX
				INC EBX
				MOV EDX, BackgroundGreen
				MOV [EBX], EDX
				INC EBX
				INC EBX
				INC EBX
				INC EBX
				MOV EDX, BackgroundBlue
				MOV [EBX], EDX
				ADD EBX, 8

				LOOP ClearScreenLoop

				POPAD
				RET
ClearScreen		ENDP

; Rendering ca³ej sceny.
RayTraceAll		PROC
				PUSHAD
				MOV EAX,FrameHeight
				MOV EDX,Screen
loop_through_y:
				DEC EAX
				PUSH EAX

				; ustawianie promienia
				CVTSI2SD xmm7, [FrameHeight]
				CVTSI2SD xmm6, EAX
				CVTSS2SD xmm5, [S_SY]
				MOVSD xmm4, xmm5
				ADDSD xmm4, xmm4
				MULSD xmm4, xmm6
				DIVSD xmm4, xmm7
				SUBSD xmm4, xmm5
				MOVSD [S_CY], xmm4

				MOV ECX,FrameWidth
loop_through_x:
				PUSH ECX

				; ustawianie promienia
				CVTSI2SD xmm7, [FrameWidth]
				CVTSI2SD xmm6, ECX
				CVTSS2SD xmm5, [S_SX]
				MOVSD xmm4, xmm5
				ADDSD xmm4, xmm4
				MULSD xmm4, xmm6
				DIVSD xmm4, xmm7
				SUBSD xmm4, xmm5
				MOVSD [S_CX], xmm4

				; EAX, ECX - liczniki ale tez sa na stosie.
				;	S_CX ray direction
				;	CameraPos - pozycja kamery
				;	EDX - offset tabeli z kolorami
				;		zostaje EAX, EBX, ECX :)

				; Normalizacja.
				MOVAPD xmm0, [S_CX]
				MOVAPD xmm1, [S_CX+16]
				MOVAPD xmm2, xmm0
				MOVAPD xmm3, xmm1
				MULPD xmm2, xmm2							; x^2, y^2
				MULSD xmm3, xmm3							; z^2
				HADDPD xmm2, xmm3
				HADDPD xmm2, xmm2
				SQRTPD xmm2, xmm2
				DIVPD xmm0, xmm2
				DIVSD xmm1, xmm2
				MOVAPD [CameraDirection], xmm0
				MOVAPD [CameraDirection + 16], xmm1

				Call CalcRayIntersections

				; Sprawdzone wszystkie kolizje, teraz trzeba wyswietlic.
				MOV ESI, [NearestEsi]
				OR ESI, 0
				JZ nothing_to_display

				PUSH ESI
				CALL CheckLightsRayIntersections
				POP ESI

				MOV EAX, [ESI+12]
				AND EAX, 0F00000h
				CMP EAX, 0300000h
				JNZ rta_its_not_cylinder
				MOVAPS xmm0, [ESI + 64]						; Aktualny kolor.
				JMP rta_end_color

rta_its_not_cylinder:
				CMP EAX, 0400000h
				JNZ rta_its_not_disc
				MOVAPS xmm0, [ESI + 80]						; Aktualny kolor.
				JMP rta_end_color

rta_its_not_disc:
				MOVAPS xmm0, [ESI + 48]						; Aktualny kolor.
				JMP rta_end_color

rta_end_color:
				MULPS xmm0, xmm7
				;CVTPD2PS xmm0, qword ptr [NearestIntersection]
				MOVAPS [EDX], xmm0

nothing_to_display:
				; Koniec wyswietlania.
				ADD EDX,16
				POP ECX
				LOOP loop_through_xshort
				POP EAX

				OR EAX,0
				JNZ loop_through_y

				POPAD
				RET

loop_through_xshort:
				JMP loop_through_x

RayTraceAll		ENDP

; Obliczanie przeciêæ promieni.
; Parametry: XMM7 - punkt zaczepienia, XMM6 - wektor kierunkowy.
CalcRayIntersections	PROC
						XOR EAX, EAX
						MOV [NearestESI],EAX		; Czyszczenie.

						MOV ESI, Primitives
						MOV ECX, [ESI]				; Czytamy liczbê prymitywów.

primitives_1:
						MOV EAX, [ESI + 12]			; Czytamy flage aktualnego obiektu.
						PUSH EAX

						AND EAX, 0F00000H			; Sprawdzamy rodzaj figury.
						CMP EAX, 0100000H			; Plane?
						JNZ not_plane_1

						; Plane!
						CALL CalcPlaneRayIntersection
						OR EAX, 0
						JZ end_primitives_1

						; Sprawdzenie czy aktualny jest bli¿ej od poprzedniego.
						; Najpierw sprawdzam czy zosta³o cos wczeœniej ustawione.

						MOV EAX, [NearestESI]
						OR EAX, 0
						JZ result_1					; Nie zostalo ustawione wiec od razu wpisuje.

						; Sprawdzenie odleg³oœci.
						MOVQ xmm0, [NearestDistance]
						SUBSD xmm0, xmm5
						MOVMSKPD EAX, xmm0
						AND EAX, 1
						JZ result_1

						JMP end_primitives_1
not_plane_1:
						CMP EAX, 0200000H			; Ball?
						JNZ not_ball_1

						; Ball!
						CALL CalcBallRayIntersection
						OR EAX, 0
						JZ end_primitives_1

						; Sprawdzenie czy aktualny jest bli¿ej od poprzedniego.
						; Najpierw sprawdzam czy zosta³o cos wczeœniej ustawione.
						MOV EAX, [NearestESI]
						OR EAX, 0
						JZ result_1					; Nie zostalo ustawione wiec od razu wpisuje.
			
						; Sprawdzenie odleg³oœci.
						MOVQ xmm0, [NearestDistance]
						SUBSD xmm0, xmm5
						MOVMSKPD EAX, xmm0
						AND EAX, 1
						JZ result_1
			
						JMP end_primitives_1
not_ball_1:
						CMP EAX,0300000H			; Cylinder?
						JNZ not_cylinder_1

						; Cylinder!
						CALL CalcCylinderRayIntersection
						OR EAX,0
						JZ end_primitives_1

						MOV EAX, [NearestESI]
						OR EAX,0
						JZ result_1					; Nie zostalo ustawione wiec od razu wpisuje.
			
						; Sprawdzenie odleg³oœci.
						MOVQ xmm0, [NearestDistance]
						SUBSD xmm0, xmm5
						MOVMSKPD EAX, xmm0
						AND EAX, 1
						JZ result_1

						JMP end_primitives_1
not_cylinder_1:
						CMP EAX, 0400000H			; Disc?
						JNZ not_disc_1

						; Dysk!
						CALL CalcDiscRayIntersection

						OR EAX, 0
						JZ end_primitives_1
						MOV EAX, [NearestESI]
						OR EAX, 0
						JZ result_1					; Nie zostalo ustawione wiec od razu wpisuje.

						; Sprawdzenie odleg³oœci.
						MOVQ xmm0, [NearestDistance]
						SUBSD xmm0, xmm5
						MOVMSKPD EAX, xmm0
						AND EAX,1
						JZ result_1

						JMP end_primitives_1
not_disc_1:
						JMP end_primitives_1
end_primitives_1:
						POP EAX
						AND EAX, 0FFH
						ADD ESI, EAX
						LOOP primitives_short_1
						RET

result_1:
						MOVQ [NearestDistance], xmm5
						MOVAPD [NearestIntersection], xmm6
						MOVAPD [NearestIntersection + 16], xmm7
						MOV NearestESI, ESI
						POP EAX
						AND EAX, 0FFH
						ADD ESI, EAX
						LOOP primitives_short_1
						RET

primitives_short_1:
						JMP primitives_1
CalcRayIntersections	ENDP

;--------------------------------------------------------------------------------------------------------------------------------
; Intersekcja promieñ - p³aszczyzna.
;--------------------------------------------------------------------------------------------------------------------------------
CalcPlaneRayIntersectionNormal	PROC
								CVTPS2PD xmm0, qword ptr[ESI + 16]
								CVTPS2PD xmm1, qword ptr[ESI + 24]
								RET
CalcPlaneRayIntersectionNormal	ENDP

; Parametry: XMM7 - Ÿród³o promienia, XMM6 - kierunek, ESI, XMM5 - wynik przeciêcia, XMM4 - odleg³oœci, EAX - wynik operacji.
CalcPlaneRayIntersection	PROC
							; t = -(AX0 + BY0 + CZ0 + D) / (AXd + BYd + CZd) = -(Pn dot R0 + D) / (Pn dot Rd)
							; Sprawdzamy czy: Pn dot Rd = 0.

							CVTPS2PD xmm0, qword ptr [ESI + 16]
							CVTPS2PD xmm1, qword ptr [ESI + 24]
							MOVAPD xmm2, [CameraPosition]
							MOVAPD xmm3, [CameraPosition + 16]
							MULPD xmm2, xmm0
							MULPD xmm3, xmm1
							HADDPD xmm2, xmm3
							HADDPD xmm2, xmm2							; dot Pn,R0
							CVTPS2PD xmm3, qword ptr [ESI + 32]
							MOVLHPS xmm3, xmm3
							ADDPD xmm2, xmm3
							MOVLHPS xmm2, xmm2							; (dot Pn,R0) + D
							MULPD xmm0, [CameraDirection]
							MULPD xmm1, [CameraDirection + 16]
							HADDPD xmm0, xmm1
							HADDPD xmm0, xmm0							; (Pn dot Rd)
							DIVPD xmm2, xmm0							; -t
							MULPD xmm2, [MinusOnes4D]					; t
							MOVMSKPD EAX, xmm2
							AND EAX, 1
							JNZ end_ray_intersection

							MOVAPD xmm6, [CameraDirection]
							MOVAPD xmm7, [CameraDirection + 16]
							MULPD xmm6, xmm2
							MULPD xmm7, xmm2
							ADDPD xmm6, [CameraPosition]
							ADDPD xmm7, [CameraPosition + 16]			; Intersection point!

							MOVAPD xmm4, [CameraPosition]
							MOVAPD xmm5, [CameraPosition + 16]
							SUBPD xmm4, xmm6
							SUBPD xmm5, xmm7
							MULPD xmm4, xmm4
							MULPD xmm5, xmm5
							HADDPD xmm5, xmm4
							HADDPD xmm5, xmm5							; Distance ^ 2

							INC EAX
							RET
end_ray_intersection:
							DEC EAX
							RET
CalcPlaneRayIntersection	ENDP

;--------------------------------------------------------------------------------------------------------------------------------
; Intersekcja promieñ - kula.
;--------------------------------------------------------------------------------------------------------------------------------
; Parametry: XMM0 - Intersection point, Wynik: XMM0
CalcBallRayIntersectionNormal	PROC
								MOVAPD xmm0, qword ptr [NearestIntersection]
								MOVAPD xmm1, qword ptr [NearestIntersection + 16]
								CVTPS2PD xmm2, qword ptr [ESI + 16]
								SUBPD xmm0, xmm2
								CVTPS2PD xmm2, qword ptr [ESI + 24]
								SUBPD xmm1, xmm2
								CVTPS2PD xmm2, qword ptr [ESI + 32]
								MOVLHPS xmm2, xmm2
								DIVPD xmm0, xmm2
								DIVPD xmm1, xmm2
								RET
CalcBallRayIntersectionNormal	ENDP

; Parametry: XMM7 - punkt startowy promienia, XMM6 - wektor kierunkowy, XMM5 - Intersection, Wynik: eax, esi - WskaŸnik na element.
CalcBallRayIntersection		PROC
							; Ogólny zamys³ w C++:
							;
							; Vec4 dst = ray.o - sphere.o;
							; float B = dot(dst, ray.d);			// B really equals 2.0f this value.
							; float C = dot(dst, dst) - sphere.r2;
							; float D = B*B - C;					// Discriminant.  D really equals 4.0f times this value.
							; if (D < 0)
							;		return std::numeric_limits<float>::infinity();
							; float sqrtD = sqrt(D);				// SqrtD really equals 2.0f times this value.
							; float t0 = (-B - sqrtD);				// Will always be the smaller, but may be negative.
							; return t0;

							MOVAPD xmm0, [CameraPosition]
							MOVAPD xmm1, [CameraPosition + 16]
							CVTPS2PD xmm2, qword ptr [ESI + 16]				; x,y
							CVTPS2PD xmm3, qword ptr [ESI + 24]				; z
							SUBPD xmm0, xmm2
							SUBSD xmm1, xmm3								; dst
							MOVAPD xmm2, xmm0
							MOVAPD xmm3, xmm1
							MULPD xmm2, [CameraDirection]
							MULSD xmm3, [CameraDirection + 16]
							MOVAPD xmm5, [CameraDirection]
							MOVAPD xmm6, [CameraDirection+16]
							HADDPD xmm2, xmm3
							HADDPD xmm2, xmm2								; "prawie" B

							MULPD xmm0, xmm0
							MULPD xmm1, xmm1
							HADDPD xmm0, xmm1
							HADDPD xmm0, xmm0
							CVTSS2SD xmm1, dword ptr [ESI + 32]
							MULSD xmm1, xmm1
							MOVLHPS xmm1, xmm1
							SUBPD xmm0, xmm1								; XMM0 - C

							MOVAPD xmm1, xmm2
							MULPD xmm1, xmm1
							SUBPD xmm1, xmm0								; XMM1 - D

							MOVMSKPD EAX, xmm1
							AND EAX, 1
							JNZ end_ball_intersection

							SQRTSD xmm1, xmm1								; sqrtD
							SUBSD xmm0, xmm0
							SUBSD xmm0, xmm2
							SUBSD xmm0, xmm1
							MOVLHPS xmm0, xmm0								; XMM0 = t0 (w calym rejestrze).

							; Sprawdzanie z ty³u.
							MOVMSKPD EAX, xmm0
							AND EAX, 1
							JNZ end_ball_intersection

							MOVAPD xmm6, [CameraDirection]
							MOVAPD xmm7, [CameraDirection + 16]
							MULPD xmm6, xmm0
							MULPD xmm7, xmm0
							ADDPD xmm6, [CameraPosition]
							ADDPD xmm7, [CameraPosition + 16]				; Intersection point.

							MOVAPD xmm4, [CameraPosition]
							MOVAPD xmm5, [CameraPosition + 16]
							SUBPD xmm4, xmm6
							SUBPD xmm5, xmm7
							MULPD xmm4, xmm4
							MULPD xmm5, xmm5
							HADDPD xmm5, xmm4
							HADDPD xmm5, xmm5								; Distance ^ 2.

							INC EAX
							RET

end_ball_intersection:
							DEC EAX
							RET
CalcBallRayIntersection		ENDP

;--------------------------------------------------------------------------------------------------------------------------------
; Intersekcja promieñ - cylinder.
;--------------------------------------------------------------------------------------------------------------------------------
; Parametry: XMM0, XMM1
CalcCylinderRayIntersectionNormal	PROC
									MOVAPD xmm0, qword ptr [NearestIntersection]
									MOVAPD xmm1, qword ptr [NearestIntersection + 16]
									CVTPS2PD xmm4, qword ptr [ESI + 16]
									CVTPS2PD xmm5, qword ptr [ESI + 24]					; Root.
									SUBPD xmm0, xmm4
									SUBPD xmm1, xmm5
									CVTPS2PD xmm4, qword ptr [ESI + 32]
									CVTPS2PD xmm5, qword ptr [ESI + 40]					; Direction.

									; Liczenie d³ugoœci.
									MOVAPS xmm2, xmm4
									MOVAPS xmm3, xmm5
									MULPD xmm2, xmm2
									MULPD xmm3, xmm3
									HADDPD xmm2, xmm3
									HADDPD xmm2, xmm2
									SQRTPD xmm6, xmm2

									MULPD xmm0, xmm4
									MULPD xmm1, xmm5
									HADDPD xmm0, xmm1
									HADDPD xmm0, xmm0									; t
									DIVPD xmm0, xmm6

									; Gotowy dotproduct.
									MOVAPD xmm2, xmm4
									MOVAPD xmm3, xmm5
									DIVPD xmm2, xmm6
									DIVPD xmm3, xmm6
									MULPD xmm2, xmm0
									MULPD xmm3, xmm0
									CVTPS2PD xmm4, qword ptr [ESI + 16]
									CVTPS2PD xmm5, qword ptr [ESI + 24]					; Root
									ADDPD xmm2, xmm4
									ADDPD xmm3, xmm5									; Pozycja na prostej.
									MOVAPD xmm0, qword ptr [NearestIntersection]
									MOVAPD xmm1, qword ptr [NearestIntersection + 16]
									SUBPD xmm0, xmm2
									SUBPD xmm1, xmm3
									CVTPS2PD xmm2, qword ptr [ESI + 48]					; Promieñ podstawy.
									MOVLHPS xmm2, xmm2
									DIVPD xmm0, xmm2
									DIVPD xmm1, xmm2
	
									RET
CalcCylinderRayIntersectionNormal	ENDP

CalcInfinityCylinderRayIntersection	PROC
									MOVAPD xmm0, [CameraPosition]						; O
									MOVAPD xmm1, [CameraPosition + 16]
									CVTPS2PD xmm2, qword ptr [ESI + 16]
									CVTPS2PD xmm3, qword ptr [ESI + 24]					; A
									SUBPD xmm0, xmm2
									SUBPD xmm1, xmm3									; XMM0, XMM1 = AO
									CVTPS2PD xmm2, qword ptr [ESI + 32]
									CVTPS2PD xmm3, qword ptr [ESI + 40]					; AB

									; Poczatek wektorowego AO x AB.
									PSHUFD xmm1, xmm1, 044h
									PSHUFD xmm3, xmm3, 044h
									PSHUFD xmm4, xmm2, 04Eh

									MULPD xmm3, xmm0
									MULPD xmm0, xmm4
									MULPD xmm1, xmm2
	
									MOVAPD xmm2, xmm1
									SUBPD xmm1, xmm3
									HSUBPD xmm0, xmm0									; Z
									SUBPD xmm3, xmm2

									;	X w XMM3H
									;	Y w XMM1L
									;	Z w XMM0L
									;	Pakujemy to do XMM6/XMM7.
									MOVHLPS xmm6, xmm3
									MOVLHPS xmm6, xmm1
									MOVSD xmm7, [Zeroes4D]								; Czyszczenie.
									MOVQ xmm7, xmm0										; XMM6 XMM7 = AO x AB
	
									; Przygotowanie do kolejnego iloczynu wektorowego.
									MOVAPD xmm0, qword ptr [CameraDirection]
									MOVAPD xmm1, qword ptr [CameraDirection + 16]
									CVTPS2PD xmm2, qword ptr [ESI + 32]
									CVTPS2PD xmm3, qword ptr [ESI + 40]					; AB

									; Poczatek: V x AB
									PSHUFD xmm1, xmm1, 044h
									PSHUFD xmm3, xmm3, 044h
									PSHUFD xmm4, xmm2, 04Eh

									MULPD xmm3, xmm0
									MULPD xmm0, xmm4
									MULPD xmm1, xmm2

									MOVAPD xmm2, xmm1
									SUBPD xmm1, xmm3
									HSUBPD xmm0, xmm0									; Z
									SUBPD xmm3, xmm2

									;	X w XMM3H
									;	Y w XMM1L
									;	Z w XMM0L
									MOVHLPS xmm4, xmm3
									MOVLHPS xmm4, xmm1
									MOVSD xmm5, [Zeroes4D]								; Czyszczenie.
									MOVQ xmm5, xmm0										; XMM4 XMM5 = V x AB
	
									CVTPS2PD xmm0, qword ptr [ESI + 32]
									CVTPS2PD xmm1, qword ptr [ESI + 40]					; AB
									MULPD xmm0, xmm0
									MULPD xmm1, xmm1
									HADDPD xmm0, xmm1
									HADDPD xmm0, xmm0									; AB2
	
									MOVAPD xmm1, xmm4
									MOVAPD xmm2, xmm5
									MULPD xmm1, xmm1
									MULPD xmm2, xmm2
									HADDPD xmm1, xmm2
									HADDPD xmm1, xmm1									; A
									ADDPD xmm1, xmm1									; A = 2A

									MULPD xmm4, xmm6
									MULPD xmm5, xmm7
									HADDPD xmm4, xmm5
									HADDPD xmm4, xmm4
									ADDPD xmm4, xmm4									; B

									MULPD xmm6, xmm6
									MULPD xmm7, xmm7
									HADDPD xmm6, xmm7
									HADDPD xmm6, xmm6									; "prawie" C.
									CVTPS2PD xmm7, qword ptr [ESI + 48]
									PSHUFD xmm7, xmm7, 044h
									MULPD xmm7, xmm7
									MULPD xmm7, xmm0
									SUBPD xmm6, xmm7									; C

									MOVAPD xmm0, xmm4
									MULPD xmm0, xmm0
									MOVAPD xmm2, xmm1
									MULPD xmm2, xmm6
									ADDPD xmm2, xmm2
									SUBPD xmm0, xmm2									; B^2-4AC - Magiczny wzór :P

									MOVMSKPD EAX, xmm0
									AND EAX, 1
									JNZ end_cylinder_intersection

									; XMM0	Delta
									; XMM1	2A
									; XMM4	B
									; XMM6	C
									SQRTPD xmm0, xmm0

									MOVAPD xmm2, [Zeroes4D]
									SUBPD xmm2, xmm4
									MOVAPD xmm3, xmm2
									SUBPD xmm2, xmm0
									DIVPD xmm2, xmm1									; t1

									ADDPD xmm3, xmm0
									DIVPD xmm3, xmm1									; t2

									MOVMSKPD EAX, xmm2
									AND EAX,1
									JNZ cylinder_intersect_not_t1
cylinder_intersect_set_t1:
									MOVAPD xmm6, [CameraDirection]
									MOVAPD xmm7, [CameraDirection + 16]
									MULPD xmm6, xmm2
									MULPD xmm7, xmm2
									ADDPD xmm6, [CameraPosition]
									ADDPD xmm7, [CameraPosition + 16]					; Intersection point.
									JMP cylinder_intersect_finalize

cylinder_intersect_not_t1:
									MOVMSKPD EAX, xmm3
									AND EAX,1
									JNZ cylinder_intersect_not_t2

cylinder_intersect_set_t2:
									MOVAPD xmm6, [CameraDirection]
									MOVAPD xmm7, [CameraDirection + 16]
									MULPD xmm6, xmm3
									MULPD xmm7, xmm3
									ADDPD xmm6, [CameraPosition]
									ADDPD xmm7, [CameraPosition + 16]					; Intersection point.
									JMP cylinder_intersect_finalize
cylinder_intersect_not_t2:
									CMPPD xmm2, xmm3, 1									; XMM2 = t1 -> Rozwi¹zanie.
									MOVMSKPS EAX, xmm2
									AND EAX, 1
									JNZ cylinder_intersect_set_t1
									JMP cylinder_intersect_set_t2

cylinder_intersect_finalize:
									MOVAPD xmm4, [CameraPosition]
									MOVAPD xmm5, [CameraPosition + 16]
									SUBPD xmm4, xmm6
									SUBPD xmm5, xmm7
									MULPD xmm4, xmm4
									MULPD xmm5, xmm5
									HADDPD xmm5, xmm4
									HADDPD xmm5, xmm5		; distance^2	

									XOR EAX, EAX
									INC EAX
									RET

end_cylinder_intersection:
									DEC EAX
									RET
CalcInfinityCylinderRayIntersection	ENDP

; To co wy¿ej - ale sprawdzamy zakres t: 1 > t > 0
CalcCylinderRayIntersection			PROC
									MOVAPD xmm0, [CameraPosition]						; O
									MOVAPD xmm1, [CameraPosition + 16]
									CVTPS2PD xmm2, qword ptr [ESI + 16]
									CVTPS2PD xmm3, qword ptr [ESI + 24]					; A
									SUBPD xmm0, xmm2
									SUBPD xmm1, xmm3									; XMM0, XMM1 = AO
									CVTPS2PD xmm2, qword ptr [ESI + 32]
									CVTPS2PD xmm3, qword ptr [ESI + 40]					; AB

									; Poczatek wektorowego AO x AB.
									PSHUFD xmm1, xmm1, 044h
									PSHUFD xmm3, xmm3, 044h
									PSHUFD xmm4, xmm2, 04Eh

									MULPD xmm3, xmm0
									MULPD xmm0, xmm4
									MULPD xmm1, xmm2
	
									MOVAPD xmm2, xmm1
									SUBPD xmm1, xmm3
									HSUBPD xmm0, xmm0									; Z
									SUBPD xmm3, xmm2

									;	X w XMM3H
									;	Y w XMM1L
									;	Z w XMM0L
									;	Pakujemy to do XMM6/XMM7.
									MOVHLPS xmm6, xmm3
									MOVLHPS xmm6, xmm1
									MOVSD xmm7, [Zeroes4D]								; Czyszczenie.
									MOVQ xmm7, xmm0										; XMM6 XMM7 = AO x AB
	
									; Przygotowanie do kolejnego iloczynu wektorowego.
									MOVAPD xmm0, qword ptr [CameraDirection]
									MOVAPD xmm1, qword ptr [CameraDirection + 16]
									CVTPS2PD xmm2, qword ptr [ESI + 32]
									CVTPS2PD xmm3, qword ptr [ESI + 40]					; AB

									; Poczatek: V x AB
									PSHUFD xmm1, xmm1, 044h
									PSHUFD xmm3, xmm3, 044h
									PSHUFD xmm4, xmm2, 04Eh

									MULPD xmm3, xmm0
									MULPD xmm0, xmm4
									MULPD xmm1, xmm2

									MOVAPD xmm2, xmm1
									SUBPD xmm1, xmm3
									HSUBPD xmm0, xmm0									; Z
									SUBPD xmm3, xmm2

									;	X w XMM3H
									;	Y w XMM1L
									;	Z w XMM0L
									MOVHLPS xmm4, xmm3
									MOVLHPS xmm4, xmm1
									MOVSD xmm5, [Zeroes4D]								; Czyszczenie.
									MOVQ xmm5, xmm0										; XMM4 XMM5 = V x AB

									CVTPS2PD xmm0, qword ptr [ESI + 32]
									CVTPS2PD xmm1, qword ptr [ESI + 40]					; AB
									MULPD xmm0, xmm0
									MULPD xmm1, xmm1
									HADDPD xmm0, xmm1
									HADDPD xmm0, xmm0									; AB2

									MOVAPD xmm1, xmm4
									MOVAPD xmm2, xmm5
									MULPD xmm1, xmm1
									MULPD xmm2, xmm2
									HADDPD xmm1, xmm2
									HADDPD xmm1, xmm1									; A
									ADDPD xmm1, xmm1									; A = 2A

									MULPD xmm4, xmm6
									MULPD xmm5, xmm7
									HADDPD xmm4, xmm5
									HADDPD xmm4, xmm4
									ADDPD xmm4, xmm4									; B

									MULPD xmm6, xmm6
									MULPD xmm7, xmm7
									HADDPD xmm6, xmm7
									HADDPD xmm6, xmm6									; "prawie" C
									CVTPS2PD xmm7, qword ptr [ESI + 48]
									PSHUFD xmm7, xmm7, 044h
									MULPD xmm7, xmm7
									MULPD xmm7, xmm0
									SUBPD xmm6, xmm7									; C

									MOVAPD xmm0, xmm4
									MULPD xmm0, xmm0
									MOVAPD xmm2, xmm1
									MULPD xmm2, xmm6
									ADDPD xmm2, xmm2
									SUBPD xmm0, xmm2									; Delta

									MOVMSKPD EAX, xmm0
									AND EAX, 1
									JNZ end_cylinder_rayintersection

									; XMM0	Delta
									; XMM1	2A
									; XMM4	B
									; XMM6	C
									SQRTPD xmm0, xmm0
									MOVAPD xmm2, [Zeroes4D]
									SUBPD xmm2, xmm4
									MOVAPD xmm3, xmm2
									SUBPD xmm2, xmm0
									DIVPD xmm2, xmm1									; t1
									ADDPD xmm3,xmm0
									DIVPD xmm3,xmm1										; t2

									MOVMSKPD EAX, xmm2
									AND EAX, 1
									JNZ cylinder_rayintersection_not_t1

cylinder_rayintersection_set_t1:
									MOVAPD xmm6, [CameraDirection]
									MOVAPD xmm7, [CameraDirection + 16]
									MULPD xmm6, xmm2
									MULPD xmm7, xmm2
									ADDPD xmm6, [CameraPosition]
									ADDPD xmm7, [CameraPosition + 16]					; Intersection point.
									JMP cylinder_rayintersection_finalize

cylinder_rayintersection_not_t1:
									MOVMSKPD EAX, xmm3
									AND EAX, 1
									JNZ cylinder_rayintersection_not_t2

cylinder_rayintersection_set_t2:
									MOVAPD xmm6, [CameraDirection]
									MOVAPD xmm7, [CameraDirection + 16]
									MULPD xmm6, xmm3
									MULPD xmm7, xmm3
									ADDPD xmm6, [CameraPosition]
									ADDPD xmm7, [CameraPosition + 16]					; Intersection point.
									JMP cylinder_rayintersection_finalize

cylinder_rayintersection_not_t2:
									CMPPD xmm2, xmm3, 1									; 1 = XMM2
									MOVMSKPS EAX, xmm2
									AND EAX, 1
									JNZ cylinder_rayintersection_set_t1
									JMP cylinder_rayintersection_set_t2
		
cylinder_rayintersection_finalize:
									MOVAPD xmm4, [CameraPosition]
									MOVAPD xmm5, [CameraPosition + 16]
									SUBPD xmm4, xmm6
									SUBPD xmm5, xmm7
									MULPD xmm4, xmm4
									MULPD xmm5, xmm5
									HADDPD xmm5, xmm4
									HADDPD xmm5, xmm5									; Distance ^ 2

									MOVAPS xmm0, xmm6
									MOVAPS xmm1, xmm7
									CVTPS2PD xmm2, qword ptr [ESI + 16]
									CVTPS2PD xmm3, qword ptr [ESI + 24]					; Root
									SUBPD xmm0, xmm2
									SUBPD xmm1, xmm3									; Root-intersection vector.
									CVTPS2PD xmm2, qword ptr [ESI + 32]
									CVTPS2PD xmm3, qword ptr [ESI + 40]					; Direction
									MULPD xmm0, xmm2
									MULPD xmm1, xmm3
									HADDPD xmm0, xmm1
									HADDPD xmm0, xmm0
									MOVMSKPD EAX, xmm0
									AND EAX, 1
									JNZ end_cylinder_rayintersection					; t < 0

									MULPD xmm2, xmm2
									MULPD xmm3, xmm3
									HADDPD xmm2, xmm3
									HADDPD xmm2, xmm2
									CMPPD xmm2, xmm0, 2
									MOVMSKPD EAX, xmm2
									AND EAX, 1
									JNZ end_cylinder_rayintersection

									XOR EAX, EAX
									INC EAX
									RET

end_cylinder_rayintersection:
									XOR EAX,EAX
									RET
CalcCylinderRayIntersection			ENDP

;--------------------------------------------------------------------------------------------------------------------------------
; Intersekcja promieñ - dysk.
;--------------------------------------------------------------------------------------------------------------------------------
CalcDiscRayIntersectionNormal	PROC
								CVTPS2PD xmm0, qword ptr [ESI + 32]
								CVTPS2PD xmm1, qword ptr [ESI + 40]
								RET
CalcDiscRayIntersectionNormal	ENDP

CalcDiscRayIntersection			PROC
								; Wzór: intersekcja promieñ - p³aszczyzna + ograniczenia
								CVTPS2PD xmm0, qword ptr [ESI + 32]
								CVTPS2PD xmm1, qword ptr [ESI + 40]
								MOVAPD xmm2, [CameraPosition]
								MOVAPD xmm3, [CameraPosition + 16]
								MULPD xmm2, xmm0
								MULPD xmm3, xmm1
								HADDPD xmm2, xmm3
								HADDPD xmm2, xmm2													; dot Pn,R0
								CVTPS2PD xmm3, qword ptr[ESI + 48]
								MOVLHPS xmm3, xmm3
								ADDPD xmm2, xmm3
								MOVLHPS xmm2, xmm2													; (dot Pn,R0) + D
								MULPD xmm0, [CameraDirection]
								MULPD xmm1, [CameraDirection + 16]
								HADDPD xmm0, xmm1
								HADDPD xmm0, xmm0													; (dot Pn,Rd)
								DIVPD xmm2, xmm0													; -t
								MULPD xmm2, [MinusOnes4D]											; t
								MOVMSKPD EAX, xmm2
								AND EAX, 1
								JNZ end_disc_intersection

								MOVAPD xmm6, [CameraDirection]
								MOVAPD xmm7, [CameraDirection + 16]
								MULPD xmm6, xmm2
								MULPD xmm7, xmm2
								ADDPD xmm6, [CameraPosition]
								ADDPD xmm7, [CameraPosition + 16]									; Intersection point.

								MOVAPD xmm4, [CameraPosition]
								MOVAPD xmm5, [CameraPosition + 16]
								SUBPD xmm4, xmm6
								SUBPD xmm5, xmm7
								MULPD xmm4, xmm4
								MULPD xmm5, xmm5
								HADDPD xmm5, xmm4
								HADDPD xmm5, xmm5													; Distance ^ 2

								; Sprawdzenie czy punkt nie jest dalej ni¿ kwadrat promienia.
								CVTPS2PD xmm0, qword ptr [ESI + 64]
								MULSS xmm0, xmm0													; R ^ 2
								CVTPS2PD xmm1, qword ptr [ESI + 16]
								CVTPS2PD xmm2, qword ptr [ESI + 24]
								SUBPD xmm1, xmm6
								SUBPD xmm2, xmm7
								MULPD xmm1, xmm1
								MULPD xmm2, xmm2
								HADDPD xmm1, xmm2
								HADDPD xmm1, xmm1
								CMPPD xmm1, xmm0, 5
								MOVMSKPD EAX, xmm1
								AND EAX, 1
								JNZ end_disc_intersection

								INC EAX
								RET
end_disc_intersection:
								DEC EAX
								RET
CalcDiscRayIntersection			ENDP

;--------------------------------------------------------------------------------------------------------------------------------
; Intersekcja promieñ - kula (fragment).
;--------------------------------------------------------------------------------------------------------------------------------
CheckBallSegmentIntersection		PROC
									MOVAPS xmm3, xmm7
									MOVAPS xmm4, [ESI + 16]
									SUBPS xmm3, xmm4								; XMM3 - destination
									MOVAPS xmm0, xmm6
									CALL Normalize

									MOVAPS xmm1, xmm0
									MOVAPS xmm0, xmm3
									CALL DotProduct

									MOVAPS xmm4, xmm0								; XMM4 - B
									MOVAPS xmm0, xmm3
									CALL Length2

									MOVAPS xmm3, xmm0
									MOVAPS xmm0, [ESI + 32]
									MULSS xmm0, xmm0
									SUBSS xmm3, xmm0								; XMM3 - C
									MOVAPS xmm0, xmm4
									MULSS xmm0, xmm4
									SUBSS xmm0, xmm3								; XMM0 - D
									MOVMSKPS EAX, xmm0
									AND EAX, 1
									JNZ end_ballfragment_intersection

									; Kolizja!
									; float t0 = (-B - sqrtD);
									SQRTSS xmm0, xmm0
									SUBSS xmm1, xmm1
									SUBSS xmm1, xmm4
									SUBSS xmm1, xmm0								; XMM1 - t0

									PSHUFD xmm4, xmm1, 0
									MULPS xmm4, xmm6
									ADDPS xmm4, xmm7								; XMM4 - Intersection point.

									MOVAPS xmm0, xmm6								; XMM0 - Destination point.
									ADDPS xmm0, xmm7

									MOVAPS xmm2, Epsilons4
									MOVAPS xmm1, xmm7	
									MINPS xmm1, xmm0								; MIN
									ADDPS xmm1, xmm2
									MAXPS xmm0, xmm7								; MAX
									SUBPS xmm0, xmm2

									CMPPS xmm1, xmm4, 2								; Minimum mniejsze od intersekcji.
									MOVMSKPS EAX, xmm1
									AND EAX, 7
									SUB EAX, 7
									JNZ end_ballfragment_collision
									JMP end_ballfragment_intersection

									CMPPS xmm0, xmm4, 5								; Maximum wieksze od intersekcji.
									MOVMSKPS EAX, xmm0
									AND EAX, 7
									SUB EAX, 7
									JNZ end_ballfragment_collision
									JMP end_ballfragment_intersection

end_ballfragment_collision:
									XOR EAX,EAX
									INC EAX
									RET

end_ballfragment_intersection:
									XOR EAX,EAX
									RET
CheckBallSegmentIntersection		ENDP

;--------------------------------------------------------------------------------------------------------------------------------
; Funkcja zarz¹dzaj¹ca œwiat³ami - sprawdza dostêpnoœæ œwiat³a i generuje promienie.
;--------------------------------------------------------------------------------------------------------------------------------
; Parametry: XMM7 - intersection point, XMM5 - wynik wspó³czynnika.
CheckLightsRayIntersections	PROC
							MOVAPS xmm7, dword ptr [Zeroes4D]				; Zerowanie XMM7.
							MOV EDI, Lights
							MOV ECX, [EDI]
							OR ECX, 0
							JNZ lights_2
							RET
lights_2:
							PUSH ECX
							MOV EAX, [EDI + 12]
							PUSH EAX
							MOV ESI, NearestESI
							MOV EAX, [ESI + 12]
							AND EAX, 0F00000h

							CMP EAX, 0100000h
							JNZ not_plane_3
							CALL CalcPlaneRayIntersectionNormal
							JMP skip_3

not_plane_3:
							CMP EAX, 0200000h
							JNZ not_ball_3
							CALL CalcBallRayIntersectionNormal
							JMP skip_3

not_ball_3:
							CMP EAX, 0300000h
							JNZ not_cylinder_3
							CALL CalcCylinderRayIntersectionNormal
							JMP skip_3

not_cylinder_3:
							CMP EAX, 0400000h
							JNZ skip_3
							CALL CalcDiscRayIntersectionNormal
skip_3:
							MOV EAX, [EDI + 12]
							AND EAX, 0F0000H
							CMP EAX, 010000H								; Œwiat³o punktowe?
							JNZ not_omni

							; float atten;
							; vec3 l;
							; float nDotL;
							; vec3 lightDir;
							; lightDir = (ray.direction) / radius;
							; atten = saturate(1.0f - dot(lightDir, lightDir));
							; l = normalize(lightDir);
							; nDotL = saturate(dot(vt.normal, l));
							; return color * atten * nDotL;
							;
							; nDotL = XMM0
							CVTPS2PD xmm2, qword ptr [EDI + 16]				; Pozycja œwiat³a.
							CVTPS2PD xmm3, qword ptr [EDI + 24]				; Pozycja œwiat³a.
							SUBPD xmm2, [NearestIntersection]
							SUBPD xmm3, [NearestIntersection + 16]			; Wektor œwiat³o->kolizja.
							CVTPS2PD xmm4, qword ptr [EDI + 48]
							MOVLHPS xmm4, xmm4
							DIVPD xmm2, xmm4								; lightDir
							DIVPD xmm3, xmm4								; lightDir

							; Normalizacja wektora.
							MOVAPD xmm4, xmm2
							MOVAPD xmm5, xmm3
							MULPD xmm4, xmm4
							MULPD xmm5, xmm5
							HADDPD xmm4, xmm5
							HADDPD xmm4, xmm4								; XMM3 = D³ugoœæ ^ 2 wektora.
							MOVAPD xmm5, xmm4								; XMM5 = D³ugoœæ ^ 2.
							SQRTPD xmm4, xmm4								; XMM3 = D³ugoœæ wektora.
							DIVPD xmm2, xmm4								; Wektor œwiat³o -> kolizja znormalizowany.
							DIVPD xmm3, xmm4

							MOVAPD xmm6, [Ones4D]
							SUBPD xmm6, xmm5
							MOVAPD xmm5, [Ones4D]
							MINPD xmm6, xmm5								; XMM6 = attenuation
							MOVAPD xmm5,[Zeroes4D]
							MAXPD xmm6, xmm5
							CVTPD2PS xmm6, xmm6
							PSHUFD xmm5, xmm6, 0							; XMM5 = attenuation

							; nDotL
							; XMM01 XMM23
							MULPD xmm0, xmm2
							MULPD xmm1, xmm3
							HADDPD xmm0, xmm1
							HADDPD xmm0, xmm0
							CVTPD2PS xmm0, xmm0
							PSHUFD xmm0, xmm0, 0

							MOVAPS xmm6, [EDI + 32]							; £adujemy kolor œwiate³ka.

							MOVAPS xmm1, [Ones4F]
							MINPS xmm5, xmm1
							MINPS xmm0, xmm1
							MOVAPS xmm1, [Zeroes4F]
							MAXPS xmm5, xmm1
							MAXPS xmm0, xmm1

							MULPS xmm6, xmm5
							MULPS xmm6, xmm0
							ADDPS xmm7, xmm6

							MOVAPS xmm1, [Ones4F]
							MINPS xmm7, xmm1
							MOVAPS xmm1, [Zeroes4F]
							MAXPS xmm7, xmm1
							JMP end_2
not_omni:
							CMP EAX, 020000H								; Œwiat³o globalne?
							JNZ not_world

							; float fdot;
							; if ((fdot = dot(vt.normal, direction)) > 0.0f)
							;		return vec3(0,0,0);
							; return color * (-fdot);

							CVTPS2PD xmm2, qword ptr [EDI + 16]				; Kierunek œwiat³a.
							CVTPS2PD xmm3, qword ptr [EDI + 24]
							MULPD xmm2, xmm0								; * Normal.
							MULPD xmm3, xmm1	
							HADDPD xmm2, xmm3
							HADDPD xmm2, xmm2								; XMM2 = dotproduct
							MOVAPD xmm3, [MinusOnes4D]
							MULPD xmm2, xmm3
							CVTPD2PS xmm2, xmm2
							PSHUFD xmm2, xmm2, 0							; Zamiana na float.
							MOVAPS xmm6, [EDI + 32]							; £adujemy kolor œwiate³ka.

							MULPS xmm6, xmm2
							MOVAPS xmm1, [Ones4F]
							MINPS xmm6, xmm1
							MOVAPS xmm1, [Zeroes4F]
							MAXPS xmm6, xmm1
							ADDPS xmm7, xmm6
							JMP end_2
not_world:
							CMP EAX, 030000H								; Spot?
							JNZ end_2

							; vec3 lightDir;
							; vec3 l;
							; float spotDot;
							; float spotEffect;
							; float atten;
							; lightDir = (ray.direction) / radius;
							; l = normalize(lightDir);
							; spotDot = dot(-l, direction);
							; spotEffect = smoothstep(cosAngles[0], cosAngles[1], spotDot);
							; atten = saturate(1.0f - dot(lightDir, lightDir));
							; atten *= spotEffect;
							; float nDotL = saturate(dot(vt.normal, l));
							; return color * nDotL * atten;

							CVTPS2PD xmm2, qword ptr [EDI + 16]				; Pozycja œwiat³a.
							CVTPS2PD xmm3, qword ptr [EDI + 24]				; Pozycja œwiat³a.
							SUBPD xmm2, [NearestIntersection]
							SUBPD xmm3, [NearestIntersection+16]			; Wektor swiatlo->kolizja czyli ray.direction
							; ... jeszcze L

							; nDotL
							MOVAPD xmm5, xmm2
							MOVAPD xmm6, xmm3
							MULPD xmm5, xmm5
							MULPD xmm6, xmm6
							HADDPD xmm5, xmm6
							HADDPD xmm5, xmm5
							SQRTPD xmm6, xmm5								; D³ugoœæ.
							MULPD xmm0, xmm2
							MULPD xmm1, xmm3
							DIVPD xmm0, xmm6
							DIVPD xmm1, xmm6
							HADDPD xmm0, xmm1
							HADDPD xmm0, xmm0								; nDotL

							CVTPS2PD xmm4, qword ptr [EDI + 32]
							CVTPS2PD xmm5, qword ptr [EDI + 40]
							MULPD xmm4, xmm2
							MULPD xmm5, xmm3
							DIVPD xmm4, xmm6
							DIVPD xmm5, xmm6
							HADDPD xmm4, xmm5
							HADDPD xmm4, xmm4								; spotDot
							MOVAPD xmm5, [MinusOnes4D]
							MULPD xmm4, xmm5

							; inline float smoothstep(float edge0, float edge1, float x)
							; {
							;	x = saturate((x - edge0) / (edge1 - edge0)); 
							;	return x * x * (3 - 2 * x);
							; }

							CVTPS2PD xmm5, qword ptr[EDI + 48]				; AngleOut -> edge0
							CVTPS2PD xmm6, qword ptr[EDI + 56]				; AngleIn -> edge1
							SUBPD xmm4, xmm5
							SUBPD xmm6, xmm5
							DIVPD xmm4, xmm6								; X
							MOVAPD xmm5, [Ones4D]
							MINPD xmm4, xmm5
							MOVAPD xmm5, [Zeroes4D]
							MAXPD xmm4, xmm5
							MOVAPD xmm5, [Threes3D]
							SUBPD xmm5, xmm4
							SUBPD xmm5, xmm4								; (3 - 2 * x)
							MULPD xmm4, xmm4
							MULPD xmm4, xmm5								; SmoothStep

							; ... saturacja NdotL i SmoothStep
							MOVAPD xmm5, [Ones4D]
							MINPD xmm4, xmm5
							MINPD xmm0, xmm5
							MOVAPD xmm5, [Zeroes4D]
							MAXPD xmm4, xmm5
							MAXPD xmm0, xmm5

							; Liczenie lightDir
							CVTPS2PD xmm5, qword ptr [EDI + 80]
							MOVLHPS xmm5, xmm5								; Promieñ na ca³ej linii.
							DIVPD xmm2, xmm5
							DIVPD xmm3, xmm5								; lightDir

							; Attenuation.
							MULPD xmm2, xmm2
							MULPD xmm3, xmm3
							HADDPD xmm2, xmm3
							HADDPD xmm2, xmm2
							MOVAPD xmm3, [Ones4D]
							SUBPD xmm3, xmm2								; Attenuation

							; Desaturacja.
							MOVAPD xmm5, [Ones4D]
							MINPD xmm3, xmm5
							MOVAPD xmm5, [Zeroes4D]
							MAXPD xmm3, xmm5								; Attenuation

							CVTPD2PS xmm3, xmm3
							PSHUFD xmm3, xmm3, 0							; Attenuation
							CVTPD2PS xmm0, xmm0
							PSHUFD xmm0, xmm0, 0							; nDotL
							CVTPD2PS xmm4, xmm4
							PSHUFD xmm4, xmm4, 0							; SmoothStep

							MOVAPS xmm1, [EDI + 64]
							MULPS xmm1, xmm3
							MULPS xmm1, xmm0
							MULPS xmm1, xmm4

							ADDPS xmm7, xmm1
end_2:
							POP EAX
							AND EAX, 0FFFFH
							ADD EDI, EAX
							POP ECX
							LOOP lights2_short
							RET
lights2_short:
							JMP lights_2
CheckLightsRayIntersections	ENDP

rayTracerCode	ENDS
				END