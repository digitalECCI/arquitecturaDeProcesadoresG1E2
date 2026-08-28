        
# Lab01 - Sumador/Restador de 4 bits

# Integrantes
* [Paula Andrea Cortéz](https://github.com/Cortes271) 
* [Santiago Leonardo Molina Bogotá](https://github.com/SaintGao-cmd)
* [Andrés Felipe Muñoz Martinez](https://github.com/Andresfmm2007) 
* [Laura Ximena Rojas Pachon](https://github.com/LauXRS) 
# Informe

Indice:

1. [Documentación](#documentación-de-los-circuitos-implementados-implementado)
2. [Simulaciones](#simulaciones)
3. [Evidencias de implementación](#evidencias-de-implementación)
4. [Preguntas](#preguntas)
5. [Conclusiones](#conclusiones)
6. [Referencias](#referencias)

## Documentación del diseño implementado

### 1. Sumador 1 bit
####

#### 1.1 Descripción

Este módulo implementa un sumador completo de 1 bit de forma **estructural**, es decir, describiendo explícitamente las compuertas y sus conexiones. Es la base para construir sumadores de mayor ancho de bits (como sumadores de 4 u 8 bits) conectando varios de estos módulos en cascada.

#### 1.2 Declaración del Módulo y Puertos

```verilog
module sumador(
    input A,
    input B,
    input Ci,
    output S,
    output Co
);
```

- **`A`** y **`B`**: Son los dos bits de entrada que se van a sumar.
- **`Ci`** (Carry-in): Es el acarreo de entrada, proveniente de una suma anterior.
- **`S`** (Suma): Es el bit resultante de la suma.
- **`Co`** (Carry-out): Es el acarreo de salida que se genera al sumar.

#### 1.3 Cables Internos

```verilog
wire xor_ab;
wire and_ab;
wire and_b_ci;
wire and_a_ci;
wire or_w1;
```

Se declaran 5 cables (`wire`) para conectar las salidas de unas compuertas con las entradas de otras. No almacenan valor, solo transmiten señales.

| Cable | Función |
| :--- | :--- |
| `xor_ab` | Resultado de A XOR B |
| `and_ab` | Resultado de A AND B |
| `and_b_ci` | Resultado de B AND Ci |
| `and_a_ci` | Resultado de A AND Ci |
| `or_w1` | Resultado de (A AND B) OR (B AND Ci) |

#### 1.4 Lógica de la Suma (`S`)

```verilog
xor u1(xor_ab, A, B);        // XOR de A y B
xor u2(S, xor_ab, Ci);       // XOR del resultado anterior con Ci
```

La fórmula booleana para la suma es:

> **S = A ⊕ B ⊕ Ci**

Primero se calcula `xor_ab = A ⊕ B`.  
Luego, ese resultado se vuelve a aplicar XOR con `Ci` para obtener la salida `S`.

#### 1.5 Lógica del Acarreo de Salida (`Co`)

```verilog
and u3(and_ab, A, B);        // A AND B
and u4(and_b_ci, B, Ci);     // B AND Ci
and u5(and_a_ci, A, Ci);     // A AND Ci

or  u6(or_w1, and_ab, and_b_ci); // (A&B) OR (B&Ci)
or  u7(Co, or_w1, and_a_ci);     // Resultado final de Co
```

La fórmula booleana para el acarreo de salida es:

> **Co = (A · B) + (B · Ci) + (A · Ci)**

El código implementa esto en dos etapas:
1. Genera los tres productos (AND) por separado.
2. Los combina con compuertas OR para obtener la suma de productos final.

#### 1.6 Tabla de Verdad (Resumen)

| A | B | Ci | S | Co |
| :---: | :---: | :---: | :---: | :---: |
| 0 | 0 | 0 | 0 | 0 |
| 0 | 0 | 1 | 1 | 0 |
| 0 | 1 | 0 | 1 | 0 |
| 0 | 1 | 1 | 0 | 1 |
| 1 | 0 | 0 | 1 | 0 |
| 1 | 0 | 1 | 0 | 1 |
| 1 | 1 | 0 | 0 | 1 |
| 1 | 1 | 1 | 1 | 1 |

### 2. Sumador 4 bits
####

#### 2.1 Descripción

Este código describe un **sumador de 4 bits** construido en **cascada** (Ripple Carry). Está formado por la conexión en serie de 4 módulos del sumador completo de 1 bit (`sumador`) que explicamos anteriormente.

#### 2.2 Declaración del Módulo y Puertos

```verilog
module sumador4b(
    input  [3:0] A,
    input  [3:0] B,
    input        Ci,      // acarreo de entrada inicial
    output [3:0] S,
    output       Co       // acarreo de salida final
);
```

- **`A`** y **`B`** (`[3:0]`): Son buses de 4 bits (A₀ a A₃ y B₀ a B₃) que representan los dos números que se van a sumar.
- **`Ci`**: Es el acarreo de entrada inicial (generalmente va conectado a 0 para sumas normales, o a 1 para restas en complemento a 2).
- **`S`** (`[3:0]`): Es el bus de 4 bits del resultado de la suma.
- **`Co`**: Es el acarreo de salida final, que indica si la suma de los 4 bits genera un desbordamiento (overflow).

#### 2.3 Cables Internos (Propagación del Acarreo)

```verilog
wire c1, c2, c3;
```

Se declaran 3 cables internos para conectar el acarreo de salida de cada sumador de 1 bit con la entrada del siguiente. 

- **`c1`**: Acarreo que sale del Bit 0 y entra al Bit 1.
- **`c2`**: Acarreo que sale del Bit 1 y entra al Bit 2.
- **`c3`**: Acarreo que sale del Bit 2 y entra al Bit 3.

#### 2.4 Instanciación de los 4 Módulos (Conexión en Cascada)

El módulo utiliza **instancias** (copias) del sumador de 1 bit llamado `sumador`. Cada instancia procesa un par de bits (Aₙ y Bₙ) junto con un acarreo de entrada, y genera su bit de suma (Sₙ) y un acarreo de salida.

```verilog
    // Bit 0 (menos significativo): usa el acarreo de entrada Ci
    sumador b0 (
        .A  (A[0]),
        .B  (B[0]),
        .Ci (Ci),
        .S  (S[0]),
        .Co (c1)
    );

    // Bit 1
    sumador b1 (
        .A  (A[1]),
        .B  (B[1]),
        .Ci (c1),
        .S  (S[1]),
        .Co (c2)
    );

    // Bit 2
    sumador b2 (
        .A  (A[2]),
        .B  (B[2]),
        .Ci (c2),
        .S  (S[2]),
        .Co (c3)
    );

    // Bit 3 (más significativo): genera el acarreo de salida final
    sumador b3 (
        .A  (A[3]),
        .B  (B[3]),
        .Ci (c3),
        .S  (S[3]),
        .Co (Co)
    );
```

#### 2.5 Flujo de la Suma (Ripple Carry)

El apodo "Ripple Carry" (acarreo en cadena o en ondulación) viene de que el acarreo debe "viajar" o "propagarse" desde el bit menos significativo (LSB) hasta el más significativo (MSB):

1. El **Bit 0** suma `A[0] + B[0] + Ci` y genera `c1`.
2. El **Bit 1** suma `A[1] + B[1] + c1` y genera `c2`.
3. El **Bit 2** suma `A[2] + B[2] + c2` y genera `c3`.
4. El **Bit 3** suma `A[3] + B[3] + c3` y genera el acarreo final `Co`.

#### 2.6 Ejemplo Práctico

Si queremos sumar `A = 0101` (5) y `B = 0011` (3) con `Ci = 0`:

| Bit | Aₙ | Bₙ | Ci (entra) | Sₙ (resultado) | Co (sale) |
| :---: | :---: | :---: | :---: | :---: | :---: |
| b0 | 1 | 1 | 0 | 0 | 1 (`c1`) |
| b1 | 0 | 1 | 1 | 0 | 1 (`c2`) |
| b2 | 1 | 0 | 1 | 0 | 1 (`c3`) |
| b3 | 0 | 0 | 1 | 1 | 0 (`Co`) |

Resultado final: `S = 1000` (8) y `Co = 0`. ¡La suma de 5 + 3 = 8 es correcta!

> **Limitación:** Este sumador es funcional, pero su velocidad de operación está limitada porque el acarreo debe propagarse a través de los 4 sumadores secuencialmente. Para números de muchos bits, se usan sumadores con anticipación de acarreo (Carry-Lookahead) para ser más rápidos.

### 3. Sumador/Restador
#### 

#### 3.1 Descripción

Un sumador/restador de 4 bits es un circuito combinacional que ejecuta sumas y restas binarias optimizando espacio de hardware al reutilizar la misma arquitectura mediante la lógica del complemento a 2.  

#### Módulo Sumador/Restador de 4 bits

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

### Funcionamiento
Las puertas `XOR` condicionan cada bit de B con la señal Sub.
Si `Sub=1`, B se invierte (complemento a 1); el acarreo de entrada del primer sumador se fuerza a Sub, completando el complemento a 2.

Se instancian 4 sumadores de 1 bit (módulo sumador) en cascada para obtener el resultado.

### 4. Diagramas
![Descripción](imagenes/arquitectura.png "Tooltip")
*Figura 1. RTL dado por software Quartus para el Sumador de 4 bits*

####
![Descripción](imagenes/sumRest.png "Tooltip")
*Figura 2. RTL dado por software Quartus para el Sumador/Restador*
 
## Simulaciones 

### 1. Simulación del sumador de 1 bit

Este código es un **banco de pruebas** (testbench) escrito en Verilog. Su objetivo es verificar automáticamente que el módulo `sumador` (Diseño Bajo Prueba o DUT) funciona correctamente, probando todas las combinaciones posibles de entrada y comparando sus salidas con un modelo de referencia.

#### 1.1 Inclusión de Archivos y Timescale

```verilog
`include "sumador.v"  
`timescale 1ms/1ms
```

- **`include "sumador.v"`**: Le dice al simulador que incluya el código del diseño (`sumador`) para poder instanciarlo.
- **`timescale 1ms/1ms`**: Define la unidad de tiempo base y la precisión de la simulación (en este caso, 1 milisegundo para ambos). Esto afecta a los retardos como `#10`.

#### 1.2 Declaración del Módulo y Señales

```verilog
module tb_sumador;

    // Señales de estímulo y observación
    reg A, B, Ci;
    wire S, Co;

    // Variables auxiliares para el chequeo automático
    integer i;
    reg S_esperado, Co_esperado;
    integer errores;
```

- **`reg A, B, Ci`**: Son las señales de entrada que **generaremos** desde el testbench. Se declaran como `reg` porque las cambiaremos activamente.
- **`wire S, Co`**: Son las salidas del DUT. Se declaran como `wire` porque el diseño las maneja, nosotros solo las observamos.
- **`i`**: Variable de control para el bucle `for`.
- **`S_esperado` y `Co_esperado`**: Variables que almacenarán los valores correctos que deberían producirse (nuestro "modelo de referencia").
- **`errores`**: Contador de fallos para saber al final si todo salió bien.

#### 1.3 Instancia del DUT (Device Under Test)

```verilog
    sumador uut (
        .A(A),
        .B(B),
        .Ci(Ci),
        .S(S),
        .Co(Co)
    );
```

Aquí se crea una copia del módulo `sumador` llamada `uut` (Unidad Bajo Prueba). Las señales del testbench se conectan a sus puertos mediante **conexión por nombre**.

#### 1.4 Volcado de Formas de Onda (para GTKWave)

```verilog
    initial begin
        $dumpfile("sumador.vcd");
        $dumpvars(0, tb_sumador);
    end
```

Este bloque inicial crea un archivo llamado `sumador.vcd` (Value Change Dump). Es un archivo que guarda todas las variaciones de las señales del testbench (`tb_sumador`) para que puedas visualizar la simulación gráficamente con herramientas como **GTKWave**.

#### 1.5 Proceso Principal de Pruebas

Este es el corazón del testbench y se ejecuta en otro bloque `initial`.

```verilog
    initial begin
        errores = 0;

        $display("=======================================================");
        $display(" A  B  Ci |  S  Co  |  S_esp  Co_esp  | Resultado");
        $display("=======================================================");
```

- Se inicializa el contador de errores en 0.
- Se imprime una cabecera en la consola para mostrar los resultados en forma de tabla.

#### 1.6 Bucle de 8 Combinaciones

```verilog
        for (i = 0; i < 8; i = i + 1) begin
            {A, B, Ci} = i[2:0];

            #10; // Tiempo para que se propague la lógica combinacional

            // Cálculo del valor esperado (modelo de referencia)
            S_esperado  = A ^ B ^ Ci;
            Co_esperado = (A & B) | (B & Ci) | (A & Ci);
```

- El bucle recorre `i` desde 0 hasta 7, cubriendo las **8 combinaciones** posibles de entradas (000, 001, 010, ..., 111).
- **`{A, B, Ci} = i[2:0]`**: Asigna los 3 bits de `i` a las entradas `A`, `B` y `Ci` en ese orden.
- **`#10`**: Espera 10 unidades de tiempo (10 ms, debido al `timescale`) para que las compuertas lógicas del sumador tengan tiempo de estabilizar sus salidas.
- Se calcula el valor **teórico** esperado utilizando las mismas fórmulas booleanas que tiene el diseño, sirviendo esto como "modelo de referencia" (scoreboard).

#### 1.7 Comparación y Reporte

```verilog
            if ((S !== S_esperado) || (Co !== Co_esperado)) begin
                errores = errores + 1;
                $display(" %b  %b  %b  |  %b   %b  |    %b      %b    | FALLO",
                          A, B, Ci, S, Co, S_esperado, Co_esperado);
            end else begin
                $display(" %b  %b  %b  |  %b   %b  |    %b      %b    | OK",
                          A, B, Ci, S, Co, S_esperado, Co_esperado);
            end
        end
```

- Se comparan las salidas reales (`S` y `Co`) con las esperadas.
- Si coinciden, se imprime "OK". Si no, se incrementa el contador de errores y se imprime "FALLO".
- Esto permite un **chequeo automático** sin necesidad de que el usuario revise los valores a ojo.

#### 1.8 Resumen Final y Finalización

```verilog
        $display("=======================================================");
        if (errores == 0)
            $display("TODAS LAS PRUEBAS PASARON CORRECTAMENTE (8/8)");
        else
            $display("SE ENCONTRARON %0d ERRORES", errores);
        $display("=======================================================");

        $finish;
    end
```

- Al salir del bucle, se imprime el resultado global de la prueba.
- Si `errores` es 0, el testbench anuncia que todas las pruebas pasaron.
- Si hay errores, muestra cuántos se encontraron.
- **`$finish`**: Termina la simulación.

#### 1.9 Ejemplo de Salida en Consola (Simulación Exitosa)

Al ejecutar la simulación, la consola mostraría algo como:

```
=======================================================
 A  B  Ci |  S  Co  |  S_esp  Co_esp  | Resultado
=======================================================
 0  0  0  |  0   0   |    0      0     | OK
 0  0  1  |  1   0   |    1      0     | OK
 0  1  0  |  1   0   |    1      0     | OK
 0  1  1  |  0   1   |    0      1     | OK
 1  0  0  |  1   0   |    1      0     | OK
 1  0  1  |  0   1   |    0      1     | OK
 1  1  0  |  0   1   |    0      1     | OK
 1  1  1  |  1   1   |    1      1     | OK
=======================================================
TODAS LAS PRUEBAS PASARON CORRECTAMENTE (8/8)
=======================================================
```

### 2. Simulación del sumador de 4 bits

#### 2.1 Inclusión de Archivos y Timescale

```verilog
`include "sumador.v"
`include "sumador4b.v"
`timescale 1ms/1ms
```

- **`include "sumador.v"`** y **`include "sumador4b.v"`**: Incluyen los diseños del sumador de 1 bit y del sumador de 4 bits. El testbench solo instancia el de 4 bits, pero como este usa el de 1 bit internamente, ambos deben estar disponibles.
- **`timescale 1ms/1ms`**: Establece que cada unidad de tiempo (`#1`) equivale a 1 milisegundo.

#### 2.2 Declaración de Señales y Variables de Control

```verilog
module tb_sumador4b;

    reg  [3:0] A, B;
    reg        Ci;
    wire [3:0] S;
    wire       Co;

    integer i, j, k;
    reg [4:0] esperado;   // 5 bits: {Co_esp, S_esp[3:0]}
    integer errores;
    integer casos;
```

| Señal / Variable | Tipo | Descripción |
| :--- | :--- | :--- |
| `A, B` | `reg [3:0]` | Entradas de 4 bits que representan los números a sumar. Las genera el testbench. |
| `Ci` | `reg` | Acarreo de entrada inicial (0 o 1). |
| `S` | `wire [3:0]` | Salida del DUT (resultado de 4 bits). Solo se observa. |
| `Co` | `wire` | Acarreo de salida del DUT. Solo se observa. |
| `i, j, k` | `integer` | Variables de control para los bucles anidados. |
| `esperado` | `reg [4:0]` | **Modelo de referencia**: Almacena el resultado correcto de la suma en 5 bits (1 bit de acarreo + 4 bits de suma). |
| `errores` | `integer` | Contador acumulado de fallos. |
| `casos` | `integer` | Contador del número total de pruebas ejecutadas. |

> **Clave del diseño:** `esperado` tiene 5 bits porque la suma de dos números de 4 bits (`A` y `B`) más un acarreo (`Ci`) puede dar como resultado un número de hasta 5 bits (máximo 15 + 15 + 1 = 31). El bit más significativo de `esperado` (bit 4) representa el acarreo final `Co`, y los bits 3 a 0 representan la suma `S`.

#### 2.3 Instancia del DUT (Device Under Test)

```verilog
    sumador4b uut (
        .A(A),
        .B(B),
        .Ci(Ci),
        .S(S),
        .Co(Co)
    );
```

Se crea una instancia del módulo `sumador4b` llamada `uut`. Todas sus entradas y salidas están conectadas a las señales declaradas anteriormente.

#### 2.4 Volcado de Formas de Onda (VCD)

```verilog
    initial begin
        $dumpfile("sumador4b.vcd");
        $dumpvars(0, tb_sumador4b);
    end
```

Genera el archivo `sumador4b.vcd` que contiene todas las variaciones de señales del testbench. Este archivo se puede abrir con **GTKWave** para depurar visualmente si se detecta algún fallo.

#### 2.5 Proceso Principal de Pruebas (Bloque `initial`)

Este es el núcleo del testbench. Realiza una **verificación exhaustiva** (también llamada *exhaustive testing*).

### Inicialización y Cabecera

```verilog
    initial begin
        errores = 0;
        casos   = 0;

        $display("===================================================================");
        $display("  A     B    Ci |   S    Co  |  S_esp  Co_esp | Resultado");
        $display("===================================================================");
```

Se inicializan los contadores y se imprime la cabecera de la tabla de resultados en consola.

#### 2.6 Bucles Anidados (Prueba Exhaustiva de 512 Casos)

```verilog
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                for (k = 0; k < 2; k = k + 1) begin
                    A  = i[3:0];
                    B  = j[3:0];
                    Ci = k[0:0];

                    #10;

                    // Modelo de referencia: suma aritmética de 5 bits
                    esperado = A + B + Ci;
                    casos = casos + 1;
```

- **Bucle triple**: Recorre todas las combinaciones posibles:
  - `i` de 0 a 15 (todos los valores posibles de `A`).
  - `j` de 0 a 15 (todos los valores posibles de `B`).
  - `k` de 0 a 1 (todos los valores posibles de `Ci`).
- **Total**: 16 × 16 × 2 = **512 casos de prueba**, cubriendo el 100% de las posibilidades.
- **`#10`**: Espera 10 ms para que las compuertas lógicas del sumador en cascada estabilicen su salida.
- **Modelo de referencia**: `esperado = A + B + Ci` aprovecha la capacidad de Verilog para hacer sumas aritméticas. Como `esperado` es de 5 bits, el resultado se almacena correctamente con su acarreo.

#### 2.7 Comparación y Reporte de Resultados

```verilog
                    if ((S !== esperado[3:0]) || (Co !== esperado[4])) begin
                        errores = errores + 1;
                        $display(" %2d(%b) %2d(%b) %b | %2d(%b) %b | %2d(%b)  %b   | FALLO",
                                  A, A, B, B, Ci, S, S, Co,
                                  esperado[3:0], esperado[3:0], esperado[4]);
                    end else begin
                        $display(" %2d(%b) %2d(%b) %b | %2d(%b) %b | %2d(%b)  %b   | OK",
                                  A, A, B, B, Ci, S, S, Co,
                                  esperado[3:0], esperado[3:0], esperado[4]);
                    end
                end
            end
        end
```

- Se comparan:
  - `S` (salida real) con `esperado[3:0]` (suma esperada).
  - `Co` (acarreo real) con `esperado[4]` (acarreo esperado).
- Si **ambos** coinciden, se imprime "OK". Si alguno falla, se incrementa `errores` y se imprime "FALLO" para ese caso concreto.
- La sentencia `$display` muestra tanto el valor decimal como el binario para facilitar la lectura.

#### 2.8 Resumen Final de la Prueba Masiva

```verilog
        $display("===================================================================");
        if (errores == 0)
            $display("TODAS LAS PRUEBAS PASARON CORRECTAMENTE (%0d/%0d casos)", casos, casos);
        else
            $display("SE ENCONTRARON %0d ERRORES DE %0d CASOS", errores, casos);
        $display("===================================================================");
```

Al terminar los 512 casos, se imprime un resumen en consola indicando si todas las pruebas pasaron o cuántos errores se encontraron.

#### 2.9 Casos de Ejemplo Adicionales (Depuración Visual)

```verilog
        $display("");
        $display("Casos de ejemplo:");
        A = 4'd5;  B = 4'd3;  Ci = 0; #10;
        $display(" 5 + 3 + 0  = %0d  (S=%b Co=%b)", S + (Co<<4), S, Co);

        A = 4'd15; B = 4'd1;  Ci = 0; #10;
        $display("15 + 1 + 0  = %0d  (S=%b Co=%b)  <- overflow esperado", S + (Co<<4), S, Co);

        A = 4'd15; B = 4'd15; Ci = 1; #10;
        $display("15 + 15 + 1 = %0d  (S=%b Co=%b)  <- caso maximo", S + (Co<<4), S, Co);

        $finish;
    end
```

- Después de la prueba automática, el testbench ejecuta **3 casos específicos** (5+3, 15+1 y 15+15+1) para que el usuario pueda verificar visualmente en la consola el comportamiento en casos críticos, incluyendo el desbordamiento (*overflow*).
- **`$finish`**: Finaliza la simulación.

#### 2.10 Salida Esperada en Consola (Simulación Exitosa)

Al ejecutar la simulación correctamente, la consola mostrará una tabla con los 512 casos (aquí se muestran solo los primeros y últimos como referencia) y finalizará con:

```
===================================================================
TODAS LAS PRUEBAS PASARON CORRECTAMENTE (512/512 casos)
===================================================================

Casos de ejemplo:
 5 + 3 + 0  = 8  (S=1000 Co=0)
15 + 1 + 0  = 16  (S=0000 Co=1)  <- overflow esperado
15 + 15 + 1 = 31  (S=1111 Co=1)  <- caso maximo
```

### 3. Simulación del sumador/restador

#### 3.1 Verificación mediante Testbench

Para validar el correcto funcionamiento del módulo, se desarrolló un _testbench_ autoverificable que realiza un barrido exhaustivo de todas las combinaciones posibles de entradas.

El testbench realiza las siguientes comprobaciones:
- **Cobertura**: 16 valores para `A` × 16 valores para `B` × 2 valores para `Sub` = **512 casos de prueba**.
- **Cálculo esperado**: 
  - Para suma (`Sub=0`), calcula `A + B` en 5 bits.
  - Para resta (`Sub=1`), calcula `A + (~B) + 1` (complemento a 2) en 5 bits.
- **Salida**: Compara en cada caso la salida del DUT (`S` y `Co`) contra los valores esperados e informa si hay fallos.
- **Trazas**: Genera un archivo `sumadorRestador.vcd` para visualizar formas de onda en GTKWave.

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

#### 3.2 Diagrama

![Descripción](imagenes/graph_sumador.png "Tooltip")
*Figura 3. Gráfica simulación sumador de 1 bit*

![Descripción](imagenes/graph_sumador4b.png "Tooltip")
*Figura 4. Gráfica simulación sumador de 4 bits*

![Descripción](imagenes/graph_sumadorRestador.png "Tooltip")
*Figura 5. Gráfica simulación sumador/restador de 4 bits*

## Evidencias de implementación


## Conclusiones


## Referencias

