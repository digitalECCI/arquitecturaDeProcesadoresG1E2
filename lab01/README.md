        
# Lab01 - Sumador/Restador de 4 bits

# Integrantes
* [Paula Andrea Cortéz](<!-- Remplace aqui link de usario 1 de github -->) 
* [Santiago Leonardo Molina Bogotá](<!-- https://github.com/SaintGao-cmd -->)
* [Andrés Felipe Muñoz Martinez](<!-- Remplace aqui link de usario 3 de github -->) 
* [Laura Ximena Rojas Pachon](<!-- https://github.com/LauXRS -->) 
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


## Simulaciones 

### 1. Simulación del sumador/restador

#### 1.1 Descripción

#### 1.2 Diagrama


## Evidencias de implementación


## Conclusiones


## Referencias

