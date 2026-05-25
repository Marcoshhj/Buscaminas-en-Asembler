.data
bienvenida:         .asciz "Bienvenido al Buscaminas\n"
pedir_nombre_msg:   .asciz "Ingrese su nombre: "
dificultad:         .asciz "Seleccione la dificultad,1 (FACIL),2 (MEDIO),3 (DIFICIL):"
mapa_msg:           .asciz "Selecciona mapa, 1 = 8x8 o 2 = 12x12: "
pedir_col_msg_8: .asciz "Seleccione el numero de columna (1-8): "
pedir_col_msg_12: .asciz "Seleccione el numero de columna (1-12): "
pedir_fila_msg_8: .asciz "\nSeleccione fila (1-8): "
pedir_fila_msg_12: .asciz "\nSeleccione fila (1-12): "
rango_invalido_msg: .asciz "Esto no esta en el rango, intente de nuevo.\n"
faltan_celdas_msg: .asciz "\nCeldas seguras restantes para ganar:"
faltan_buf:        .space 4
objetivo_ganar: .word 0
msg_objetivo: .asciz "\nCeldas seguras necesarias para ganar: "
casilla_repetida_msg:.asciz "\nYa seleccionaste esa casilla. Intenta otra vez.\n"
mensaje_perdiste:   .asciz "\nBOOM! Tocaste una mina. Perdiste.\n"
newline:            .asciz "\n"
ganaste_msg: .asciz "\n¡GANASTE! Descubriste todas las celdas seguras.\n"
cant_minas:         .word 0
msg_faltan: .asciz "\nCeldas seguras restantes para ganar: "
reveal_count:       .word 0  
tv: .space 8              
rojo:  .asciz "\033[31m"
violeta: .asciz "\033[35m"
verde:      .asciz "\033[32m"
azul: .asciz "\033[34m"

reset: .asciz "\033[0m"
msg_minas_mapa: .asciz "MINAS EN MAPA: "
flood_head:        .word 0
flood_tail:        .word 0
flood_q:           .space 576    

@ Definición de constantes para el ranking
RANKING_ENTRY_SIZE = 36
MAX_RANKING_ENTRIES = 10

ranking_filename:   .asciz "ranking.txt"
ranking_buffer:     .space 512      @ para leer el contenido completo
linea_ranking:      .space 64       @ línea tipo "nombre: 12 seg\n"
ranking_header:  .asciz "\n--- MEJORES 3 TIEMPOS ---\n"
ranking_empty_msg: .asciz "Aún no hay récords. ¡Sé el primero!\n"
tv_inicio:          .space 8
tv_fin:             .space 8
tiempo_jugador:     .word 0
newline_txt:        .asciz "\n"
puntos_sep:      .asciz ": "
seg_unidades:    .asciz " seg\n"



offsets8:
    .word -9, -8, -7, -1, 1, 7, 8, 9
offsets12:
    .word -13, -12, -11, -1, 1, 11, 12, 13
char_buf:           .space 4


seed:               .word 12345678
minas_distribuidas: .space 144
buffer:             .space 32
dif_buf:            .space 2
mapa_opcion:        .space 1
mapa_tam:           .word 0
columna_input:      .space 3
fila_input:         .space 3
msg_juego_azul: .asciz "\033[34m\nEl juego ha empezado\n\033[0m"
.bss
mapa_oculto:        .space 144
mapa_visible: .space 144

bufnum: .space 16

ranking_parsed:   .space RANKING_ENTRY_SIZE * MAX_RANKING_ENTRIES
ranking_entry_count: .word 0  
victoria_flag: .space 4





.text
contar_minas_mapa_oculto:
.fnstart
    PUSH {R0-R4, LR}

    LDR R0, =mapa_oculto      
    LDR R1, =mapa_tam
    LDR R1, [R1]
    MOV R2, #0
    MOV R3, #0
.ltorg

contar_loop:
    CMP R2, R1
    BEQ mostrar_cantidad

    LDRB R4, [R0, R2]
    CMP R4, #'*'
    ADDNE R3, R3, #0
    ADDEQ R3, R3, #1

    ADD R2, R2, #1
    B contar_loop

mostrar_cantidad:
    LDR R0, =msg_minas_mapa
    MOV R1, R0
    MOV R2, #16
    MOV R7, #4
    MOV R0, #1
    SVC #0

    MOV R0, R3
    BL print_num

    LDR R0, =newline
    MOV R1, R0
    MOV R2, #1
    MOV R7, #4
    MOV R0, #1
    SVC #0

    POP {R0-R4, LR}
    BX LR
.fnend

print_num:
.fnstart
    PUSH {R0-R6, LR}
    MOV R1, R0
    LDR R2, =bufnum
    ADD R2, R2, #15
    MOV R3, #0

    CMP R1, #0
    BNE printnum_loop
    MOV R4, #'0'
    SUB R2, R2, #1
    STRB R4, [R2]
    MOV R3, #1
    B printnum_done
.ltorg

printnum_loop:
    MOV R4, #10
    MOV R5, #0
    MOV R6, R1

divloop_printnum:
    CMP R6, R4
    BLT divfin_printnum
    SUB R6, R6, R4
    ADD R5, R5, #1
    B divloop_printnum

divfin_printnum:
    ADD R6, R6, #'0'
    SUB R2, R2, #1
    STRB R6, [R2]
    MOV R1, R5
    ADD R3, R3, #1
    CMP R1, #0
    BNE printnum_loop

printnum_done:
    MOV R0, #1
    MOV R1, R2
    MOV R2, R3
    MOV R7, #4
    SVC #0

    POP {R0-R6, LR}
    BX LR
.fnend

mostrar_celdas_restantes:
.fnstart
    PUSH {R0-R3, LR}

    LDR R0, =objetivo_ganar
    LDR R1, [R0]
    LDR R0, =reveal_count
    LDR R2, [R0]
    SUB R1, R1, R2

    LDR R0, =msg_faltan
    MOV R1, R0
    MOV R2, #38
    MOV R7, #4
    MOV R0, #1
    SVC #0

    MOV R0, R1
    LDR R0, =objetivo_ganar
    LDR R1, [R0]
    LDR R0, =reveal_count
    LDR R2, [R0]
    SUB R1, R1, R2
    MOV R0, R1
    BL print_num

    POP {R0-R3, LR}
    BX LR
.fnend

dividir_mod_simple_msj:
.fnstart
    MOV R1, #0
    MOV R2, R5
div_loop_msj:
    CMP R2, R4
    BLT fin_div_simple_msj
    SUB R2, R2, R4
    ADD R1, R1, #1
    B div_loop_msj
fin_div_simple_msj:
    BX LR
.fnend

repetir_turno:
.fnstart
    LDR R0, =newline
    MOV R1, R0
    MOV R2, #1
    MOV R7, #4
    MOV R0, #1
    SVC #0

    BL pedir_columna
    BL pedir_fila
    BL buscar_elemento_en_posicion
    MOV R12, R0

    LDR R0, =mapa_visible
    ADD R0, R0, R12
    LDRB R1, [R0]
    CMP R1, #'_'
    BNE verificar_repetida

    LDR R0, =mapa_oculto
    ADD R0, R0, R12
    LDRB R1, [R0]
    CMP R1, #'*'
    BEQ tocaste_mina

    LDR R0, =reveal_count
    LDR R1, [R0]
    CMP R1, #0
    BNE .no_es_primera_jugada
    BL medir_tiempo_inicio
.no_es_primera_jugada:

    LDR  R0, =reveal_count
    LDR  R1, [R0]
    ADD  R1, R1, #1
    STR  R1, [R0]

    BL   minas_cercanas
    @ Siempre poner el número, aunque sea 0
    B poner_numero_normal

.ltorg

poner_numero_normal:
    ADD  R0, R0, #'0'
    LDR  R1, =mapa_visible
    ADD  R1, R1, R12
    STRB R0, [R1]

    LDR R2, =objetivo_ganar
    LDR R2, [R2]
    LDR R0, =reveal_count
    LDR R1, [R0]
    CMP R1, R2
    BEQ ganar

    BL mostrar_mapa_dinamico
    BL mostrar_celdas_restantes   @ <--- Restaurado aquí
    B  repetir_turno

.ltorg

verificar_repetida:
    LDR R0, =casilla_repetida_msg
    MOV R1, R0
    MOV R2, #50
    MOV R7, #4
    MOV R0, #1
    SVC #0
    B repetir_turno
.ltorg

ganar:
    LDR   r0, =verde
    MOV   r1, r0
    MOV   r2, #5
    MOV   r7, #4
    MOV   r0, #1
    SVC   #0
    LDR   r0, =ganaste_msg
    MOV   r1, r0
    MOV   r2, #50
    MOV   r7, #4
    MOV   r0, #1
    SVC   #0
    LDR   r0, =reset
    MOV   r1, r0
    MOV   r2, #4
    MOV   r7, #4
    MOV   r0, #1
    SVC   #0
    LDR R0, =victoria_flag
    MOV R1, #1
    STR R1, [R0]
    B     fin
.fnend
.ltorg
mostrar_minas:
.fnstart
    PUSH {R0-R4, LR}
    LDR R0, =mapa_oculto
    LDR R1, =mapa_visible
    LDR R2, =mapa_tam
    LDR R3, [R2]
    MOV R4, #0
.ltorg

revelar_minas_loop:
    CMP R4, R3
    BEQ revelar_minas_fin
    LDRB R5, [R0, R4]
    CMP R5, #'*'
    BNE no_mina_en_visible
    STRB R5, [R1, R4]
.ltorg

no_mina_en_visible:
    ADD R4, R4, #1
    B revelar_minas_loop
.ltorg

revelar_minas_fin:
    POP {R0-R4, LR}
    BX LR
.fnend
.ltorg

mostrar_bienvenida:
.fnstart
    LDR R0, =bienvenida
    MOV R1, R0
    MOV R2, #25
    MOV R7, #4
    MOV R0, #1
    SVC #0
    BX LR
.fnend
.ltorg

pedir_nombre:
.fnstart
    LDR R0, =pedir_nombre_msg
    MOV R1, R0
    MOV R2, #20
    MOV R7, #4
    MOV R0, #1
    SVC #0
    BX LR
.fnend
.ltorg

leer_nombre:
.fnstart
    LDR R0, =buffer
    MOV R1, R0
    MOV R2, #32
    MOV R7, #3
    MOV R0, #0
    SVC #0
    BX LR
.fnend
.ltorg
pedir_dificultad:
.fnstart
    LDR R0, =dificultad
    MOV R1, R0
    MOV R2, #58
    MOV R7, #4
    MOV R0, #1
    SVC #0
    BX LR
.fnend
.ltorg
leer_dificultad:
.fnstart
leer_dificultad_intentar:
    LDR R0, =dif_buf
    MOV R1, R0
    MOV R2, #2
    MOV R7, #3
    MOV R0, #0
    SVC #0
    LDR R0, =dif_buf
    LDRB R1, [R0]
    CMP R1, #'1'
    BEQ dificultad_ok
    CMP R1, #'2'
    BEQ dificultad_ok
    CMP R1, #'3'
    BEQ dificultad_ok
    LDR R0, =rango_invalido_msg
    MOV R1, R0
    MOV R2, #45
    MOV R7, #4
    MOV R0, #1
    SVC #0
    B leer_dificultad_intentar

dificultad_ok:
    BX LR
.fnend
.ltorg
calcular_minas:
.fnstart
    PUSH   {R1-R4, LR}
    LDR    R0, =mapa_tam
    LDR    R1, [R0]
    LDR    R0, =dif_buf
    LDRB   R2, [R0]
    SUB    R2, R2, #'0'
    MOV    R3, #20
    CMP    R2, #2
    BEQ    medio
    CMP    R2, #3
    BEQ    dificil
    B      pct_hecho
medio:
    MOV R3, #30
    B      pct_hecho

dificil:
    MOV R3, #50

pct_hecho:
    MUL R6, R1, R3
    MOV    R3, #100
    BL     dividir_mod_simple
    MOV    R0, R1

    POP    {R1-R4, LR}
    BX     LR
.fnend

pedir_mapa:
.fnstart
    LDR R0, =mapa_msg
    MOV R1, R0
    MOV R2, #39
    MOV R7, #4
    MOV R0, #1
    SVC #0
    BX LR
.fnend

leer_mapa:
.fnstart
leer_mapa_intentar:
    LDR   R0, =mapa_opcion
    MOV   R1, R0
    MOV   R2, #2
    MOV   R7, #3
    MOV   R0, #0
    SVC   #0

    LDR   R0, =mapa_opcion
    LDRB  R1, [R0]
    CMP   R1, #'1'
    BEQ   mapa_ok
    CMP   R1, #'2'
    BEQ   mapa_ok

    LDR   R0, =rango_invalido_msg
    MOV   R1, R0
    MOV   R2, #45
    MOV   R7, #4
    MOV   R0, #1
    SVC   #0
    B     leer_mapa_intentar

mapa_ok:
    BX    LR
.fnend

asignar_mapa_tam:
.fnstart
    PUSH {R0-R2, LR}
    LDR R0, =mapa_opcion
    LDRB R1, [R0]
    CMP R1, #'1'
    BEQ set_64
    CMP R1, #'2'
    BEQ set_144
    B end_mapa_tam

set_64:
    LDR R0, =mapa_tam
    MOV R1, #64
    STR R1, [R0]
    B end_mapa_tam

set_144:
    LDR R0, =mapa_tam
    MOV R1, #144
    STR R1, [R0]

end_mapa_tam:
    POP {R0-R2, LR}
    BX LR
.fnend

generar_random:
.fnstart
    PUSH {R1-R4, LR}
    LDR R1, =seed
    LDR R0, [R1]
    LDR R2, =1664525
    MUL R3, R0, R2
    LDR R2, =1013904223
    ADD R0, R3, R2
    STR R0, [R1]
    POP {R1-R4, LR}
    BX LR
.fnend

dividir_modulo:
.fnstart
    CMP R1, #0
    BEQ divmod_fin
    MOV R2, R0
    CMP R2, #0
    BGE divmod_loop
    RSBS R2, R2, #0
divmod_loop:
    CMP R2, R1
    BLT divmod_fin
    SUB R2, R2, R1
    B divmod_loop
divmod_fin:
    MOV R0, R2
    BX LR
.fnend

distribuir:
.fnstart
    PUSH {R0-R9, LR}
    LDR R4, =minas_distribuidas
    MOV R5, #0
    LDR R6, [R10]
loop_distribuir:
    CMP R5, R6
    BEQ end_distribuir

    BL generar_random
    LDR R2, =mapa_tam
    LDR R1, [R2]
    BL dividir_modulo

    MOV R2, #0
    MOV R3, R4
    MOV R7, #0

buscar_duplicado:
    CMP R2, R5
    BEQ agregar_nueva
    LDRB R1, [R3, R2]
    CMP R1, R0
    BEQ es_duplicado
    ADD R2, R2, #1
    B buscar_duplicado

es_duplicado:
    MOV R7, #1
    B repetir_random

agregar_nueva:
    MOV R7, #0

repetir_random:
    CMP R7, #1
    BEQ loop_distribuir

    STRB R0, [R4, R5]
    ADD R5, R5, #1
    B loop_distribuir

end_distribuir:
    POP {R0-R9, LR}
    BX LR
.fnend

construir_mapa_oculto:
.fnstart
    PUSH {R0-R4, LR}
    LDR R0, =mapa_oculto
    MOV R1, #'_'
    LDR R2, =mapa_tam
    LDR R3, [R2]
    MOV R4, #0
loop_inicializar:
    CMP R4, R3
    BEQ loop_minas
    STRB R1, [R0, R4]
    ADD R4, R4, #1
    B loop_inicializar

loop_minas:
    LDR R0, =mapa_oculto
    LDR R1, =minas_distribuidas
    LDR R2, [R10]
    MOV R3, #0
loop_insertar:
    CMP R3, R2
    BEQ fin_oculto
    LDRB R4, [R1, R3]
    MOV R5, #'*'
    STRB R5, [R0, R4]
    ADD R3, R3, #1
    B loop_insertar

fin_oculto:
    POP {R0-R4, LR}
    BX LR
.fnend

pedir_fila:
.fnstart
pedir_fila_intentar:
    LDR R0, =mapa_opcion
    LDRB R1, [R0]
    CMP R1, #'1'
    LDREQ R0, =pedir_fila_msg_8
    LDRNE R0, =pedir_fila_msg_12
    MOV R1, R0
    MOV R2, #25
    MOV R7, #4
    MOV R0, #1
    SVC #0

    LDR R0, =fila_input
    MOV R1, R0
    MOV R2, #3
    MOV R7, #3
    MOV R0, #0
    SVC #0

    LDR R0, =fila_input
    LDRB R1, [R0]
    SUB R1, R1, #'0'
    LDRB R2, [R0, #1]
    CMP R2, #'0'
    BLT fila_parse_done
    CMP R2, #'9'
    BGT fila_parse_done
    SUB R2, R2, #'0'
    MOV R3, #10
    MUL R0, R1, R3
    MOV R1, R0
    ADD R1, R1, R2
fila_parse_done:

    LDR R0, =mapa_opcion
    LDRB R0, [R0]
    CMP R0, #'1'
    LDREQ R2, =8
    LDRNE R2, =12
    CMP R1, #1
    BLT fila_fuera_rango
    CMP R1, R2
    BGT fila_fuera_rango
    BX LR

fila_fuera_rango:
    LDR R0, =rango_invalido_msg
    MOV R1, R0
    MOV R2, #45
    MOV R7, #4
    MOV R0, #1
    SVC #0
    B pedir_fila_intentar
.fnend

pedir_columna:
.fnstart
pedir_columna_intentar:
    LDR R0, =mapa_opcion
    LDRB R1, [R0]
    CMP R1, #'1'
    LDREQ R0, =pedir_col_msg_8
    LDRNE R0, =pedir_col_msg_12
    MOV R1, R0
    MOV R2, #40
    MOV R7, #4
    MOV R0, #1
    SVC #0

    LDR R0, =columna_input
    MOV R1, R0
    MOV R2, #3
    MOV R7, #3
    MOV R0, #0
    SVC #0

    LDR R0, =columna_input
    LDRB R1, [R0]
    SUB R1, R1, #'0'
    LDRB R2, [R0, #1]
    CMP R2, #'0'
    BLT col_parse_done
    CMP R2, #'9'
    BGT col_parse_done
    SUB R2, R2, #'0'
    MOV R3, #10
    MUL R0, R1, R3
    MOV R1, R0
    ADD R1, R1, R2
col_parse_done:

    LDR R0, =mapa_opcion
    LDRB R0, [R0]
    CMP R0, #'1'
    LDREQ R2, =8
    LDRNE R2, =12
    CMP R1, #1
    BLT columna_fuera_rango
    CMP R1, R2
    BGT columna_fuera_rango
    BX LR

columna_fuera_rango:
    LDR R0, =rango_invalido_msg
    MOV R1, R0
    MOV R2, #45
    MOV R7, #4
    MOV R0, #1
    SVC #0
    B pedir_columna_intentar
.fnend

buscar_elemento_en_posicion:
.fnstart
    PUSH {R1,R2,R3,R4,R5,R6,LR}
    LDR  R0, =mapa_opcion
    LDRB R1, [R0]
    SUB  R1, R1, #'0'
    MOV  R2, #8
    CMP  R1, #2
    MOVEQ R2, #12

    LDR  R0, =fila_input
    LDRB R3, [R0]
    SUB  R3, R3, #'0'
    LDRB R4, [R0, #1]
    CMP  R4, #'0'
    BLT  fila_done
    CMP  R4, #'9'
    BGT  fila_done
    SUB  R4, R4, #'0'
    MOV  R5, #10
    MUL  R6, R3, R5
    MOV  R3, R6
    ADD  R3, R3, R4

fila_done:
    SUB  R3, R3, #1

    LDR  R0, =columna_input
    LDRB R4, [R0]
    SUB  R4, R4, #'0'
    LDRB R5, [R0, #1]
    CMP  R5, #'0'
    BLT  col_done
    CMP  R5, #'9'
    BGT  col_done
    SUB  R5, R5, #'0'
    MOV  R6, #10
    MUL  R1, R4, R6
    MOV  R4, R1
    ADD  R4, R4, R5
col_done:
    SUB  R4, R4, #1

    MUL  R1, R3, R2
    ADD  R0, R1, R4
    POP  {R1,R2,R3,R4,R5,R6,LR}
    BX   LR
.fnend

tocaste_mina:
.fnstart
    LDR R0, =rojo
    MOV R1, R0
    MOV R2, #5
    MOV R7, #4
    MOV R0, #1
    SVC #0

    LDR R0, =mensaje_perdiste
    MOV R1, R0
    MOV R2, #38
    MOV R7, #4
    MOV R0, #1
    SVC #0

    LDR R0, =reset
    MOV R1, R0
    MOV R2, #4
    MOV R7, #4
    MOV R0, #1
    SVC #0

    BL mostrar_minas
    BL mostrar_mapa_dinamico
    BL fin
.fnend



mostrar_mapa_dinamico:
.fnstart
    PUSH {R0-R9, LR}
    LDR R0, =violeta
    MOV R1, R0
    MOV R2, #5
    MOV R7, #4
    MOV R0, #1
    SVC #0

    LDR R0, =mapa_opcion
    LDRB R1, [R0]
    CMP R1, #'1'
    BEQ set_tam_8
    CMP R1, #'2'
    BEQ set_tam_12
    MOV R8, #8
    B continuar_config

set_tam_8:
    MOV R8, #8
    B continuar_config

set_tam_12:
    MOV R8, #12

continuar_config:
    LDR R0, =newline
    MOV R1, R0
    MOV R2, #1
    MOV R7, #4
    MOV R0, #1
    SVC #0
    LDR R0, =char_buf
    MOV R1, #' '
    STRB R1, [R0]
    STRB R1, [R0, #1]
    STRB R1, [R0, #2]
    MOV R1, #'|'
    STRB R1, [R0, #3]
    MOV R1, R0
    MOV R2, #4
    MOV R7, #4
    MOV R0, #1
    SVC #0
    MOV R4, #0
header_loop:
    CMP R4, R8
    BEQ header_done
    ADD R5, R4, #1
    MOV R6, R5
    MOV R3, #10
    BL dividir_mod_simple
    ADD R1, R1, #'0'
    ADD R2, R2, #'0'
    LDR R0, =char_buf
    STRB R1, [R0]
    STRB R2, [R0, #1]
    MOV R1, #' '
    STRB R1, [R0, #2]
    MOV R1, R0
    MOV R2, #3
    MOV R7, #4
    MOV R0, #1
    SVC #0
    ADD R4, R4, #1
    B header_loop

header_done:
    LDR R0, =newline
    MOV R1, R0
    MOV R2, #1
    MOV R7, #4
    MOV R0, #1
    SVC #0
    LDR R0, =char_buf
    MOV R1, #' '
    STRB R1, [R0]
    STRB R1, [R0, #1]
    STRB R1, [R0, #2]
    MOV R1, #'+' 
    STRB R1, [R0, #3]
    MOV R1, R0
    MOV R2, #4
    MOV R7, #4
    MOV R0, #1
    SVC #0
    MOV R4, #0
sep_loop:
    CMP R4, R8
    BEQ sep_done
    MOV R1, #'-'
    LDR R0, =char_buf
    STRB R1, [R0]
    STRB R1, [R0, #1]
    STRB R1, [R0, #2]
    MOV R1, R0
    MOV R2, #3
    MOV R7, #4
    MOV R0, #1
    SVC #0
    ADD R4, R4, #1
    B sep_loop

sep_done:
    LDR R0, =newline
    MOV R1, R0
    MOV R2, #1
    MOV R7, #4
    MOV R0, #1
    SVC #0
    MOV R4, #0
fila_loop:
    CMP R4, R8
    BEQ mapa_fin
    ADD R5, R4, #1
    MOV R6, R5
    MOV R3, #10
    BL dividir_mod_simple
    ADD R1, R1, #'0'
    ADD R2, R2, #'0'
    LDR R0, =char_buf
    STRB R1, [R0]
    STRB R2, [R0, #1]
    MOV R1, #' '
    STRB R1, [R0, #2]
    MOV R1, #'|'
    STRB R1, [R0, #3]
    MOV R1, R0
    MOV R2, #4
    MOV R7, #4
    MOV R0, #1
    SVC #0
    MOV R6, #0
col_loop:
    CMP R6, R8
    BEQ fila_nl

    MUL R2, R4, R8
    ADD R2, R2, R6

    LDR R0, =mapa_visible
    ADD R0, R0, R2
    LDRB R1, [R0]

    LDR R0, =char_buf
    STRB R1, [R0]
    MOV R2, #' '
    STRB R2, [R0, #1]
    MOV R2, #' '
    STRB R2, [R0, #2]

    MOV R1, R0
    MOV R2, #3
    MOV R7, #4
    MOV R0, #1
    SVC #0

    ADD R6, R6, #1
    B col_loop

fila_nl:
    LDR R0, =newline
    MOV R1, R0
    MOV R2, #1
    MOV R7, #4
    MOV R0, #1
    SVC #0

    ADD R4, R4, #1
    B fila_loop

mapa_fin:
    LDR R0, =reset
    MOV R1, R0
    MOV R2, #4
    MOV R7, #4
    MOV R0, #1
    SVC #0

    POP {R0-R9, LR}
    BX LR
.fnend

mostrar_mapa:
.fnstart
    PUSH {R0-R3, LR}
    LDR R0, =mapa_visible
    MOV R1, #'_'
    LDR R2, =mapa_tam
    LDR R3, [R2]
    MOV R2, #0
init_vis_loop:
    CMP R2, R3
    BEQ fin_init_vis
    STRB R1, [R0, R2]
    ADD R2, R2, #1
    B init_vis_loop
fin_init_vis:
    POP {R0-R3, LR}
    BX LR
.fnend

dividir_mod_simple:
.fnstart
    MOV R1, #0
    MOV R2, R6
div_loop_simple:
    CMP R2, R3
    BLT fin_div_simple
    SUB R2, R2, R3
    ADD R1, R1, #1
    B div_loop_simple

fin_div_simple:
    BX LR
.fnend

minas_cercanas:
.fnstart
    PUSH {R1-R7, LR}

    LDR   R0, =mapa_opcion
    LDRB  R0, [R0]
    SUB   R0, R0, #'0'
    MOV   R1, #8
    CMP   R0, #2
    BNE   .offsets_ready
    MOV   R1, #12
.offsets_ready:

    LDR   R2, =offsets8
    CMP   R0, #2
    BNE   .count_start
    LDR   R2, =offsets12
.count_start:

    MOV   R3, #0
    MOV   R4, #8

.loop:
    LDR   R5, [R2], #4
    ADD   R6, R12, R5

    CMP   R6, #0
    BLT   .skip
    LDR   R7, =mapa_tam
    LDR   R7, [R7]
    CMP   R6, R7
    BGE   .skip

    PUSH  {R1, R2, R3}
    PUSH  {R1, R6}
    MOV   R6, R12
    MOV   R3, R1
    BL    dividir_mod_simple
    MOV   R8, R2
    POP   {R1, R6}

    MOV   R3, R1
    BL    dividir_mod_simple
    MOV   R9, R2

    SUB   R9, R9, R8
    CMP   R9, #0
    RSBLT R9, R9, #0

    POP   {R1, R2, R3}
    CMP   R9, #1
    BGT   .skip

    LDR   R7, =mapa_oculto
    ADD   R7, R7, R6
    LDRB  R7, [R7]
    CMP   R7, #'*'
    ADDEQ R3, R3, #1

.skip:
    SUBS  R4, R4, #1
    BNE   .loop

    CMP   R3, #3
    MOVGT R3, #3
    MOV   R0, R3
    POP   {R1-R7, LR}
    BX    LR
.fnend

sembrar_semilla:
.fnstart
    LDR   R0, =tv
    MOV   R1, #0
    MOV   R7, #78
    SVC   #0
    LDR   R1, =tv
    LDR   R0, [R1, #4]
    LDR   R1, =seed
    STR   R0, [R1]
    BX    LR
.fnend


medir_tiempo_inicio:
    .fnstart
    LDR R0, =tv_inicio
    MOV R1, #0
    MOV R7, #78         
    SVC #0
    BX LR
    .fnend

medir_tiempo_fin:
    .fnstart
    LDR R0, =tv_fin
    MOV R1, #0
    MOV R7, #78
    SVC #0
    BX LR
    .fnend

calcular_tiempo_transcurrido:
    .fnstart
    @ R0 = tiempo en segundos = tv_fin - tv_inicio
    LDR R1, =tv_inicio
    LDR R2, =tv_fin
    LDR R3, [R2]        @ tv_sec fin
    LDR R4, [R1]        @ tv_sec inicio
    SUB R0, R3, R4
    LDR R5, =tiempo_jugador
    STR R0, [R5]
    BX LR
    .fnend

escribir_ranking:
    .fnstart
    PUSH {R4-R11, LR}

    @ Paso 1: Leer el archivo de ranking a un buffer de texto.
    BL leer_ranking_a_buffer

    @ Paso 2: Parsear el buffer de texto y llenar nuestra estructura ranking_parsed.
    BL parsear_buffer_ranking

    @ Paso 3: Añadir el récord del jugador actual a la estructura en memoria.
    BL anadir_record_actual

    @ Paso 4: Ordenar la estructura de récords completa.
    BL ordenar_ranking

    @ Paso 5: Reescribir el archivo ranking.txt con la lista ordenada desde la memoria.
    BL escribir_ranking_ordenado_al_disco

    POP {R4-R11, LR}
    BX LR
    .fnend

@FUNCIONES AUXILIARES PARA escribir_ranking

leer_ranking_a_buffer:
    .fnstart
    @ lee el archivo a ranking_buffer
    PUSH {R4-R6, LR}
    LDR R0, =ranking_filename
    MOV R1, #0  
    MOV R2, #0
    MOV R7, #5  
    SVC #0
    CMP R0, #0
    BLT fin_lectura_buffer
    MOV R6, R0
    LDR R1, =ranking_buffer
    LDR R2, =511
    MOV R7, #3 
    SVC #0    
    LDR R1, =ranking_buffer
    ADD R1, R1, R0
    MOV R2, #0
    STRB R2, [R1] 
    MOV R0, R6
    MOV R7, #6 
    SVC #0
fin_lectura_buffer:
    POP {R4-R6, LR}
    BX LR
    .fnend

parsear_buffer_ranking:
    .fnstart
    @ Esta función no cambia, parsea el buffer a la estructura
    PUSH {R4-R8, LR}
    LDR R4, =ranking_buffer
    LDR R5, =ranking_parsed
    LDR R8, =ranking_entry_count
    MOV R6, #0
    STR R6, [R8]
parse_loop:
    LDRB R7, [R4]
    CMP R7, #0
    BEQ fin_parseo
    MOV R0, R4
    MOV R1, R5
    BL parsear_una_linea_ranking
    ADD R6, R6, #1
    LDR R8, =ranking_entry_count
    STR R6, [R8]
    B parse_loop
fin_parseo:
    POP {R4-R8, LR}
    BX LR
    .fnend    

parsear_una_linea_ranking:
    .fnstart
    @ Entrada: R0 puntero a la línea de texto a parsear 
    @          R1  puntero a la estructura de destino en ranking_parsed
    @ Salida:  Actualiza R4 y R5 para la siguiente iteración del bucle de parseo.
    PUSH {R0-R3, R6, R7, LR}
    MOV R6, R1 
    MOV R7, #0 

parse_nombre:
    LDRB R2, [R0], #1 
    CMP R2, #':'
    BEQ fin_parse_nombre
    CMP R2, #0
    BEQ fin_parse_nombre_error 
    STRB R2, [R6, R7] 
    ADD R7, R7, #1
    B parse_nombre

fin_parse_nombre_error:
    SUB R0, R0, #1 @ Retroceder por si acaso

fin_parse_nombre:
    MOV R2, #0
    STRB R2, [R6, R7] 

skip_spaces:
    LDRB R2, [R0]
    CMP R2, #' '
    ADDEQ R0, R0, #1
    BNE parse_numero_start
    B skip_spaces

parse_numero_start:
    MOV R3, #0         @ R3 = acumulador para el número

parse_numero_loop:
    LDRB R2, [R0]        @ "Espiar" el siguiente caracter sin avanzar
    CMP R2, #'0'
    BLT fin_parse_numero_loop 
    CMP R2, #'9'
    BGT fin_parse_numero_loop
    ADD R0, R0, #1      @ Ahora sí avanzamos el puntero
    SUB R2, R2, #'0'    @ Convertir caracter a número    
    MOV R1, #10
    MUL R1, R3, R1      
    
    @ LA CORRECCIÓN FINAL Y DEFINITIVA
    ADD R3, R1, R2      
    B parse_numero_loop

fin_parse_numero_loop:
    @ Guardar el tiempo (ya como número) en la estructura
    STR R3, [R6, #32] 

find_newline_robust:
    LDRB R2, [R0], #1
    CMP R2, #0        
    BEQ find_newline_end
    CMP R2, #'\n'
    BNE find_newline_robust

find_newline_end:
    MOV R4, R0             @ R4 (puntero de texto) apunta a la siguiente línea
    ADD R5, R6, #36        @ R5 (puntero de struct) apunta a la siguiente struct
    POP {R0-R3, R6, R7, LR}
    BX LR
    .fnend

anadir_record_actual:
    .fnstart
    PUSH {R0-R5, LR}
    LDR R4, =ranking_entry_count
    LDR R0, [R4]                          @ R0 = numero de entradas actuales
    CMP R0, #MAX_RANKING_ENTRIES            @ Usamos la constante
    BGE fin_anadir 

    @ Calcular la dirección de la siguiente estructura vacía en ranking_parsed
    LDR R2, =ranking_parsed
    MOV R3, #RANKING_ENTRY_SIZE @ Usamos la constante
    MUL R1, R0, R3
    ADD R2, R2, R1 @ R2 apunta a la nueva struct vacía

    @ Bucle de copia de nombre con terminación NULA
    LDR R1, =buffer        @ Origen: el nombre que ingresó el usuario
    MOV R3, #0       

copy_loop_anadir:
    LDRB R4, [R1, R3]       @ Cargar un caracter del nombre de origen
    CMP R4, #'\n'           @ Si es el salto de línea, terminamos
    BEQ end_copy_anadir
    
    STRB R4, [R2, R3]       @ Guardar el caracter en la struct de destino
    ADD R3, R3, #1
    CMP R3, #31             @ Límite de seguridad para no desbordar los 32 bytes del nombre
    BLT copy_loop_anadir

end_copy_anadir:
    MOV R4, #0
    STRB R4, [R2, R3]     
    @Fin del bucle de copia 
    @ Copiar el tiempo del jugador
    LDR R3, =tiempo_jugador
    LDR R3, [R3]
    STR R3, [R2, #32] @ Guardar tiempo en el offset correspondiente

    @ Incrementar el contador de entradas
    LDR R4, =ranking_entry_count
    LDR R0, [R4]
    ADD R0, R0, #1
    STR R0, [R4]

fin_anadir:
    POP {R0-R5, LR}
    BX LR
    .fnend

ordenar_ranking:
    .fnstart
    PUSH {R4-R11, LR}
    LDR R4, =ranking_entry_count
    LDR R5, [R4] 
    CMP R5, #1
    BLE fin_ordenar 
    MOV R6, #0 


outer_loop:
    SUB R11, R5, #1
    CMP R6, R11
    BGE fin_ordenar
    MOV R7, #0 

inner_loop:
    SUB R8, R5, R6
    SUB R8, R8, #1
    CMP R7, R8
    BGE fin_inner_loop
    LDR R9, =ranking_parsed
    MOV R10, #36 
    MUL R11, R7, R10
    ADD R9, R9, R11 
    ADD R11, R9, R10 
    LDR R0, [R9, #32]  
    LDR R1, [R11, #32] 
    CMP R0, R1
    BLE no_swap 
    MOV R2, #0 @ Offset para el bucle de swap

swap_loop:
    CMP R2, #36
    BEQ fin_swap_loop
    LDR R3, [R9, R2]  @ Carga 4 bytes de la primera struct
    LDR R4, [R11, R2] @ Carga 4 bytes de la segunda
    STR R3, [R11, R2] @ Guarda en la segunda
    STR R4, [R9, R2]  @ Guarda en la primera
    ADD R2, R2, #4
    B swap_loop
fin_swap_loop:

no_swap:
    ADD R7, R7, #1
    B inner_loop

fin_inner_loop:
    ADD R6, R6, #1
    B outer_loop

fin_ordenar:
    POP {R4-R11, LR}
    BX LR
    .fnend

escribir_ranking_ordenado_al_disco:
    .fnstart
    PUSH {R4-R8, LR}
    LDR R0, =ranking_filename
    LDR R1, =577 
    MOV R2, #0644 
    MOV R7, #5 
    SVC #0
    MOV R8, R0 
    LDR R4, =ranking_entry_count
    LDR R5, [R4]
    MOV R6, #0 @ i = 0
    LDR R7, =ranking_parsed 
escribir_loop:
    CMP R6, R5
    BEQ fin_escribir
    @ Construir la línea "Nombre: XX seg\n"
    LDR R0, =linea_ranking
    MOV R1, R7              @ El nombre está al inicio de la struct
    BL strcpy_null    
    LDR R2, =puntos_sep
    BL agregar_string
    LDR R1, [R7, #32] 
    BL convertir_numero_a_ascii
    LDR R2, =seg_unidades
    BL agregar_string
    LDR R1, =linea_ranking
    BL strlen
    MOV R2, R0
    MOV R0, R8 @ file descriptor 
    PUSH {R7}         @ Guardamos el puntero del bucle R7 en la pila
    MOV R7, #4        @ Ponemos el número de la syscall en R7
    SVC #0
    POP {R7}          @ Restauramos el puntero del bucle R7 desde la pila
    ADD R7, R7, #36 
    ADD R6, R6, #1  
    B escribir_loop

fin_escribir:
    MOV R0, R8 
    MOV R7, #6 
    SVC #0
    POP {R4-R8, LR}
    BX LR
    .fnend

strcpy_null:
    .fnstart
strcpy_null_loop:
    LDRB R2, [R1], #1 @ Carga un byte del origen y avanza el puntero de origen
    STRB R2, [R0], #1 @ Guarda el byte en el destino y avanza el puntero de destino
    CMP R2, #0        @ Si el byte era 0 (el terminador nulo), terminamos
    BNE strcpy_null_loop
    
    SUB R0, R0, #1    
    BX LR    
    .fnend         

leer_ranking:
    .fnstart
    PUSH {R4-R8, LR}

    @ Imprimir la cabecera del ranking
    LDR R0, =ranking_header
    BL imprimir_string_simple
    LDR R0, =ranking_filename
    MOV R1, #0  
    MOV R7, #5  
    SVC #0
    CMP R0, #0
    BLT fin_leer_ranking_simple
    MOV R8, R0 

    @ Leer todo el archivo a nuestro buffer global
    LDR R1, =ranking_buffer
    LDR R2, =511
    MOV R7, #3  @ syscall read
    SVC #0
    MOV R4, R0 

    @ Asegurarse de que el buffer termina en null
    LDR R1, =ranking_buffer
    ADD R1, R1, R4
    MOV R2, #0
    STRB R2, [R1]
    MOV R0, R8
    MOV R7, #6
    SVC #0
    @ Si no se leyó nada, mostrar mensaje de vacío
    CMP R4, #0
    BEQ mostrar_ranking_vacio
    LDR R5, =ranking_buffer
    MOV R6, #0 @ R6 = Contador de líneas mostradas
    MOV R8, #0 @ R8 = Contador de bytes mostrados (usamos R8, es seguro)

mostrar_linea_loop:
    CMP R6, #3  
    BEQ fin_leer_ranking_simple
    CMP R8, R4  
    BGE fin_leer_ranking_simple
    @ Imprimir caracter por caracter
    LDRB R0, [R5], #1
    LDR R1, =char_buf
    STRB R0, [R1]
    MOV R2, #1
    MOV R7, #4
    MOV R0, #1
    SVC #0
    @ Incrementar contador de bytes mostrados
    ADD R8, R8, #1
    LDRB R0, [R5, #-1]
    CMP R0, #'\n'
    ADDEQ R6, R6, #1
    B mostrar_linea_loop

mostrar_ranking_vacio:
    LDR R0, =ranking_empty_msg
    BL imprimir_string_simple

fin_leer_ranking_simple:
    POP {R4-R8, LR}
    BX LR
    .fnend

@Se necesita esta función de utilidad 
imprimir_string_simple:
    .fnstart
    PUSH {R0-R2, R7, LR}
    MOV R1, R0
    BL strlen
    MOV R2, R0
    MOV R0, #1
    MOV R1, R1
    MOV R7, #4
    SVC #0
    POP {R0-R2, R7, LR}
    BX LR
    .fnend

strlen:
    .fnstart
    PUSH {R1-R2}
    MOV R2, R1
    MOV R0, #0
strlen_loop:
    LDRB R1, [R2], #1
    CMP R1, #0
    BEQ strlen_fin
    ADD R0, R0, #1
    B strlen_loop
strlen_fin:
    POP {R1-R2}
    BX LR
    .fnend

copiar_nombre:
    .fnstart
copiar_nombre_loop:
    LDRB R2, [R1]
    CMP R2, #'\n'
    BEQ copiar_fin
    STRB R2, [R0], #1   
    ADD R1, R1, #1
    B copiar_nombre_loop
copiar_fin:
    BX LR 
    .fnend

agregar_string:
     .fnstart
    @ R0 = destino, R2 = string de origen (terminado en null)
    @ Devuelve en R0 el puntero al final de lo agregado

agregar_str_loop:
    LDRB R3, [R2], #1   @ Carga y avanza el puntero de origen
    CMP R3, #0
    BEQ agregar_fin
    STRB R3, [R0], #1   @ Almacena y avanza el puntero de destino
    B agregar_str_loop

agregar_fin:
    BX LR @ R0 ahora apunta al siguiente espacio libre
    .fnend

convertir_numero_a_ascii:   
    .fnstart
    PUSH {R1-R7, LR}
    MOV R4, R0              @ R4 = puntero al búfer de destino.
    MOV R2, R1              @ R2 = número a convertir.
    MOV R6, #0              @ R6 = contador de dígitos.
    CMP R2, #0
    BNE conversion_loop
    MOV R0, #'0'            @ Si el número es 0, pone '0' en la pila.
    PUSH {R0}
    ADD R6, R6, #1
    B pop_loop_start

conversion_loop:
    CMP R2, #0
    BEQ pop_loop_start      @ Si el cociente es 0, terminamos de obtener dígitos.
    MOV R5, #10             @ Divisor para obtener el último dígito.   
    MOV R1, #0
    MOV R3, R2

div_loop_for_convert:
    CMP R3, R5
    BLT fin_div_for_convert
    SUB R3, R3, R5
    ADD R1, R1, #1
    B div_loop_for_convert

fin_div_for_convert:
    
    ADD R3, R3, #'0'        @ Convertir el resto (dígito) a su carácter ASCII.
    PUSH {R3}               @ Guardar el dígito en la pila.
    ADD R6, R6, #1          @ Incrementar el contador de dígitos.
    MOV R2, R1              @ El nuevo número para la siguiente iteración es el cociente.
    B conversion_loop

pop_loop_start:
    MOV R2, R6              @ R2 = número de dígitos a extraer de la pila.
pop_loop:
    CMP R2, #0
    BEQ conversion_fin
    POP {R3}                @ Sacar el dígito de la pila (en orden inverso).
    STRB R3, [R4], #1       @ Guardarlo en el búfer y avanzar el puntero.
    SUB R2, R2, #1          @ Decrementar el contador.
    B pop_loop

conversion_fin:
    MOV R0, R4              @ Devolver el puntero actualizado en R0.
    POP {R1-R7, LR}
    BX LR
    .fnend


fin:
    .fnstart
    LDR R0, =victoria_flag      @ Cargar la dirección de la bandera
    LDR R1, [R0]                @ Cargar el valor de la bandera en R1
    CMP R1, #1                  @ Comparar si es 1 (victoria)
    BNE solo_salir              @ Si no es 1, saltar la lógica del ranking

    BL medir_tiempo_fin
    BL calcular_tiempo_transcurrido
    BL escribir_ranking      @ Primero, actualiza el archivo con el nuevo récord.
    BL leer_ranking          @ Luego, lee y muestra el top 3 del archivo actualizado.

solo_salir:
    MOV R7, #1      
    MOV R0, #0      
    SVC #0
    .fnend



.global main

main:
    BL   mostrar_bienvenida
    BL   pedir_nombre
    BL   leer_nombre
    BL   pedir_dificultad
    BL   leer_dificultad

    @ fijás el objetivo de celdas seguras
    LDR   R0, =dif_buf
    LDRB  R1, [R0]
    CMP   R1, #'1'
    MOVEQ R2, #10
    CMP   R1, #'2'
    MOVEQ R2, #20
    CMP   R1, #'3'
    MOVEQ R2, #25
    LDR   R0, =objetivo_ganar
    STR   R2, [R0]

    BL   pedir_mapa
    BL   leer_mapa
    BL   asignar_mapa_tam

    BL   calcular_minas
    LDR  R10, =cant_minas
    STR  R0, [R10]

    LDR   R0, =reveal_count      
    MOV   R1, #0
    STR   R1, [R0]

    BL   sembrar_semilla         
    LDR R0, =seed
    LDR R0, [R0]
    MOV R1, R0
    MOV R2, #1
    MOV R7, #4
    MOV R0, #1
    SVC #0


    BL   distribuir
    BL   construir_mapa_oculto
    BL   contar_minas_mapa_oculto
    BL   mostrar_mapa
    LDR  R0, =msg_juego_azul
    BL   imprimir_string_simple
    BL   mostrar_mapa_dinamico
    BL   mostrar_celdas_restantes
    
    B    repetir_turno 
