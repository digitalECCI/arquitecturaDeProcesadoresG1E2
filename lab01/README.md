        
# Lab01 - Sumador/Restador de 4 bits

# Integrantes
* [Paula Andrea Cortéz](<!-- Remplace aqui link de usario 1 de github -->) 
* [Santiago Leonardo Molina Bogotá](<!-- https://github.com/SaintGao-cmd -->)
* [Andrés Felipe Muñoz Martinez](<!-- Remplace aqui link de usario 3 de github -->) 
* [Laura Ximena Rojas Pachon]( https://github.com/LauXRS) 
# Informe

Indice:

1. [Documentación](#documentación-de-los-circuitos-implementados-implementado)
2. [Simulaciones](#simulaciones)
3. [Evidencias de implementación](#evidencias-de-implementación)
4. [Preguntas](#preguntas)
5. [Conclusiones](#conclusiones)
6. [Referencias](#referencias)

## Documentación del diseño implementado

### 1. Sumador/Restador
#### 

#### 1.1 Descripción

Un sumador/restador de 4 bits es un circuito combinacional que ejecuta sumas y restas binarias optimizando espacio de hardware al reutilizar la misma arquitectura mediante la lógica del complemento a 2.  

### Módulo Sumador/Restador de 4 bits

Este módulo implementa una suma o resta de dos números de 4 bits (A y B) dependiendo de la señal `Sub`.  
- Si `Sub = 0`, realiza `S = A + B`.  
- Si `Sub = 1`, realiza `S = A - B` (usando complemento a 2).  

## Entradas y salidas
| Señal | Tipo   | Descripción                          |
|-------|--------|--------------------------------------|
| A     | input  | Operando A (4 bits)                  |
| B     | input  | Operando B (4 bits)                  |
| Sub   | input  | Control: 0 suma, 1 resta             |
| S     | output | Resultado de la operación (4 bits)   |
| Co    | output | Acarreo de salida (bit más significativo) |

## Código Verilog
```verilog
module sumadorRestador(
    input  [3:0] A,
    input  [3:0] B,
    input        Sub,     // 0 = suma (A+B), 1 = resta (A-B)
    output [3:0] S,
    output       Co
);

    // Cables para B condicionado (invertido si Sub=1)
    wire [3:0] B_xor;

    // Cables internos para propagar el acarreo entre etapas
    wire c1, c2, c3;

    // XOR de cada bit de B con Sub: si Sub=1, invierte B (complemento a 1)
    xor x0(B_xor[0], B[0], Sub);
    xor x1(B_xor[1], B[1], Sub);
    xor x2(B_xor[2], B[2], Sub);
    xor x3(B_xor[3], B[3], Sub);

    // Instancia 0: bit menos significativo
    // Ci = Sub -> suma el "+1" del complemento a 2 cuando se resta
    sumador u0 (
        .A(A[0]),
        .B(B_xor[0]),
        .Ci(Sub),
        .S(S[0]),
        .Co(c1)
    );

    // Instancia 1
    sumador u1 (
        .A(A[1]),
        .B(B_xor[1]),
        .Ci(c1),
        .S(S[1]),
        .Co(c2)
    );

    // Instancia 2
    sumador u2 (
        .A(A[2]),
        .B(B_xor[2]),
        .Ci(c2),
        .S(S[2]),
        .Co(c3)
    );

    // Instancia 3: bit más significativo
    sumador u3 (
        .A(A[3]),
        .B(B_xor[3]),
        .Ci(c3),
        .S(S[3]),
        .Co(Co)
    );

endmodule
```
### Funcionamiento
Las puertas `XOR` condicionan cada bit de B con la señal Sub.
Si `Sub=1`, B se invierte (complemento a 1); el acarreo de entrada del primer sumador se fuerza a Sub, completando el complemento a 2.

Se instancian 4 sumadores de 1 bit (módulo sumador) en cascada para obtener el resultado.

#### 1.2 Diagramas
![pic](scr/imagenes/arquitectura.png)

## Simulaciones 

### 1. Simulación del sumador/restador

#### 1.1 Descripción
## Verificación mediante Testbench

Para validar el correcto funcionamiento del módulo, se desarrolló un _testbench_ autoverificable que realiza un barrido exhaustivo de todas las combinaciones posibles de entradas.

El testbench realiza las siguientes comprobaciones:
- **Cobertura**: 16 valores para `A` × 16 valores para `B` × 2 valores para `Sub` = **512 casos de prueba**.
- **Cálculo esperado**: 
  - Para suma (`Sub=0`), calcula `A + B` en 5 bits.
  - Para resta (`Sub=1`), calcula `A + (~B) + 1` (complemento a 2) en 5 bits.
- **Salida**: Compara en cada caso la salida del DUT (`S` y `Co`) contra los valores esperados e informa si hay fallos.
- **Trazas**: Genera un archivo `sumadorRestador.vcd` para visualizar formas de onda en GTKWave.

#### Código del Testbench

```verilog
`include "sumador.v"
`include "sumadorRestador.v"
`timescale 1ms/1ms

module tb_sumadorRestador;

    reg  [3:0] A, B;
    reg        Sub;
    wire [3:0] S;
    wire       Co;

    integer i, j, k;
    integer errores;

    // Valores esperados calculados con aritmetica normal de Verilog
    reg [4:0] esperado_suma;   // 5 bits: incluye el acarreo/borrow
    reg [3:0] S_esp;
    reg       Co_esp;
    reg [3:0] B_neg;           // ~B calculado en 4 bits (evita que el
                                // operador ~ tome el ancho del contexto
                                // de 5 bits y produzca un resultado erroneo)

    // Instancia del DUT (Device Under Test)
    sumadorRestador DUT (
        .A(A),
        .B(B),
        .Sub(Sub),
        .S(S),
        .Co(Co)
    );

    // Dump para GTKWave
    initial begin
        $dumpfile("sumadorRestador.vcd");
        $dumpvars(0, tb_sumadorRestador);
    end

    initial begin
        errores = 0;

        $display("========================================================");
        $display(" Simulacion exhaustiva: sumadorRestador (4 bits)");
        $display("========================================================");
        $display(" %-4s %-4s %-4s | %-4s %-4s | %-8s %-8s | %-4s",
                  "A", "B", "Sub", "S", "Co", "S_esp", "Co_esp", "OK?");
        $display("--------------------------------------------------------");

        // Barrido exhaustivo: A (0-15) x B (0-15) x Sub (0-1) = 512 casos
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                for (k = 0; k < 2; k = k + 1) begin
                    A   = i[3:0];
                    B   = j[3:0];
                    Sub = k[0:0];

                    #10; // tiempo para que se propague la logica

                    if (Sub == 1'b0) begin
                        // Suma: A + B, resultado de 5 bits (S + Co)
                        esperado_suma = A + B;
                        S_esp  = esperado_suma[3:0];
                        Co_esp = esperado_suma[4];
                    end else begin
                        // Resta: A - B en complemento a 2
                        // {Co_esp, S_esp} = A + (~B, en 4 bits) + 1
                        B_neg = ~B;
                        esperado_suma = A + B_neg + 1'b1;
                        S_esp  = esperado_suma[3:0];
                        // Co_esp = 1 indica "no hubo prestamo" (A >= B)
                        Co_esp = esperado_suma[4];
                    end

                    if ((S !== S_esp) || (Co !== Co_esp)) begin
                        errores = errores + 1;
                        $display(" %-4d %-4d %-4d | %-4d %-4d | %-8d %-8d | %-4s  <-- FALLO",
                                  A, B, Sub, S, Co, S_esp, Co_esp, "NO");
                    end
                end
            end
        end

        $display("--------------------------------------------------------");
        if (errores == 0)
            $display(" RESULTADO: Todos los 512 casos pasaron correctamente.");
        else
            $display(" RESULTADO: %0d casos fallaron de 512.", errores);
        $display("========================================================");

        $finish;
    end

endmodule
```
#### Resultado de la simulación (esperado)
Al ejecutar este testbench en el simulador `Icarus Verilog`, la consola mostrará un resumen final indicando si todos los casos fueron exitosos. 

```
 > vvp sumadorRestador_tb.v.out 

VCD info: dumpfile sumadorRestador.vcd opened for output.
========================================================
 Simulacion exhaustiva: sumadorRestador (4 bits)
========================================================
 A    B    Sub  | S    Co   | S_esp    Co_esp   | OK? 
--------------------------------------------------------
--------------------------------------------------------
 RESULTADO: Todos los 512 casos pasaron correctamente.
========================================================
sumadorRestador_tb.v:89: $finish called at 5120 (1ms)
Execution finished with exit code 0
```

En caso de fallos, el testbench detalla exactamente qué combinación de entradas produjo un resultado incorrecto, facilitando la depuración.

```
> iverilog   -o build\sumadorRestador_tb.v.out sumadorRestador_tb.v 

./sumadorRestador.v:23: error: Unknown module type: sumador
./sumadorRestador.v:32: error: Unknown module type: sumador
./sumadorRestador.v:41: error: Unknown module type: sumador
./sumadorRestador.v:50: error: Unknown module type: sumador
5 error(s) during elaboration.
*** These modules were missing:
        sumador referenced 4 times.
***
Compilation finished with exit code 5
```

#### 1.2 Diagrama


## Evidencias de implementación


## Conclusiones


## Referencias

