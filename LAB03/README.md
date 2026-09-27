# Lab03: Multiplicador de 3 bits usando Máquina de Estados

# Integrantes
* [Paula Andrea Cortés](https://github.com/Cortes271) 
* [Santiago Leonardo Molina Bogotá](https://github.com/SaintGao-cmd)
* [Andrés Felipe Muñoz Martinez](https://github.com/Andresfmm2007) 
* [Laura Ximena Rojas Pachon](https://github.com/LauXRS) 

# Informe

Índice:

1. [Documentación del diseño implementado](#documentación-del-diseño-implementado)
2. [Simulaciones](#simulaciones)
3. [Evidencias de implementación](#evidencias-de-implementación)
4. [Preguntas](#preguntas)
5. [Conclusiones](#conclusiones)
6. [Referencias](#referencias)

## Documentación del diseño implementado

### 1. [Módulo 1]

#### 1.1 Módulo full_adder_1bit
Este módulo se encarga de sumar dos bits (a y b) teniendo en cuenta un posible acarreo de entrada (cin). El resultado se entrega mediante dos salidas: sum, que representa el resultado de la suma, y cout, que representa el acarreo que pasa a la siguiente posición. 

#### 1.2 Declaración del Módulo y Puertos

```verilog
module full_adder_1bit (
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire sum,
    output wire cout
)
```
a: primer bit que se quiere sumar.

b: segundo bit que se quiere sumar.

cin: acarreo de entrada. Es el bit que viene de la suma anterior.

sum: resultado de la suma.

sout: acarreo de salida, que se envía a la siguiente posición.


#### 1.3 Cables Internos
Este módulo no requiere cables internos adicionales, implementándose directamente mediante expresiones lógicas combinacionales

#### 1.4 Lógica

```verilog
assign sum  = a ^ b ^ cin;
assign cout = (a & b) | (b & cin) | (a & cin);
```
Explicación:  La salida sum se calcula mediante la función XOR entre los tres bits de entrada (a ^ b ^ cin). El acarreo de salida cout se activa si al menos dos de las tres entradas están en nivel alto (1).

#### 1.5 Tabla de Verdad

| BCD (`bcd`) | Segmentos `[g f e d c b a]` | Hexadecimal | Dígito Muestral |
| :---: | :---: | :---: | :---: |
| `0000` (0) | `1000000` | `0x40` | 0 |
| `0001` (1) | `1111001` | `0x79` | 1 |
| `0101` (5) | `0010010` | `0x12` | 5 |
| `1001` (9) | `0010000` | `0x10` | 9 |
| Otros (>9) | `1111111` | `0x7F` | Apagado |

#### 1.6 Ejemplo Práctico

#### 1.7 Limitaciones

### 2. Módulo sumador_8bit_ripple

#### 2.1 Descripción
Implementa un sumador por propagación de acarreo (Ripple Carry Adder) de 8 bits a partir de la instanciación en cascada de 8 sumadores completos de 1 bit (full_adder_1bit).

#### 2.2 Declaración del Módulo y Puertos

```
module sumador_8bit_ripple (
    input  wire [7:0] A,
    input  wire [7:0] B,
    input  wire       cin,
    output wire [7:0] suma,
    output wire       cout
);
```
A, B: Bus de operandos de 8 bits (0 a 255).

cin: Acarreo inicial de entrada.

suma: Bus del resultado de la suma en 8 bits.

cout: Acarreo final de salida del bit más significativo.

#### 2.3 Cables Internos

```
wire [7:0] c; // Interconexión en cascada de acarreos entre etapas
```

#### 2.4 Lógica

```
full_adder_1bit fa0 (.a(A[0]), .b(B[0]), .cin(cin),  .sum(suma[0]), .cout(c[0]));
full_adder_1bit fa1 (.a(A[1]), .b(B[1]), .cin(c[0]), .sum(suma[1]), .cout(c[1]));
full_adder_1bit fa2 (.a(A[2]), .b(B[2]), .cin(c[1]), .sum(suma[2]), .cout(c[2]));
full_adder_1bit fa3 (.a(A[3]), .b(B[3]), .cin(c[2]), .sum(suma[3]), .cout(c[3]));
full_adder_1bit fa4 (.a(A[4]), .b(B[4]), .cin(c[3]), .sum(suma[4]), .cout(c[4]));
full_adder_1bit fa5 (.a(A[5]), .b(B[5]), .cin(c[4]), .sum(suma[5]), .cout(c[5]));
full_adder_1bit fa6 (.a(A[6]), .b(B[6]), .cin(c[5]), .sum(suma[6]), .cout(c[6]));
full_adder_1bit fa7 (.a(A[7]), .b(B[7]), .cin(c[6]), .sum(suma[7]), .cout(cout));
```
Explicación: Cada etapa i calcula el bit de suma suma[i] y pasa su acarreo c[i] como entrada cin de la etapa i+1.

#### 2.5 Tabla de Verdad

Dado que el módulo posee 17 bits de entrada en total ($8 + 8 + 1$), la tabla de verdad completa consta de 131,072 combinaciones. A continuación se presentan los casos  clave del sumador:

| A (Decimal) | B (Decimal) | cin | suma (Binario) | suma (Decimal) | cout | Interpretación / Estado |
| :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| `00000000` (0) | `00000000` (0) | 0 | `00000000` | 0 | 0 | Suma mínima sin acarreo |
| `00000101` (5) | `00000011` (3) | 0 | `00001000` | 8 | 0 | Suma estándar ($5 + 3 = 8$) |
| `00000101` (5) | `00000011` (3) | 1 | `00001001` | 9 | 0 | Suma con acarreo entrante ($5 + 3 + 1 = 9$) |
| `01111111` (127) | `10000000` (128) | 0 | `11111111` | 255 | 0 | Valor máximo sin desbordamiento |
| `11111111` (255) | `00000001` (1) | 0 | `00000000` | 0 | 1 | Desbordamiento de 8 bits ($255 + 1 = 256$) |
| `11111111` (255) | `11111111` (255) | 1 | `11111111` | 255 | 1 | Valor máximo con acarreo ($255 + 255 + 1 = 511$) |

#### 2.6 Ejemplo Práctico

#### 2.7 Limitaciones

### 3. Módulo multiplicador

#### 3.1 Descripción
Este módulo realiza la multiplicación sin signo de dos números de 4 bits (A y B). Genera un resultado de 8 bits (producto) mediante la generación de productos parciales y su adición acumulativa con el sumador de 8 bits.

#### 3.2 Declaración del Módulo y Puertos
```
module multiplicador (
    input  wire [3:0] A,
    input  wire [3:0] B,
    output wire [7:0] producto
);
```
A, B: Operandos de entrada de 4 bits (0 a 15).

producto: Resultado de la multiplicación de 8 bits (0 a 225)

#### 3.3 Cables Internos
```
wire [7:0] p0, p1, p2, p3;  // Productos parciales alineados
wire [7:0] s1, s2;          // Resultados intermedios de sumas
wire c_dummy1, c_dummy2, c_dummy3;
#### 3.4 Implementación
```

#### 3.4 Lógica


#### 3.5 Diagramas

### 4. Diagramas

![Descripción](ruta/imagen.png)
*Figura 1. [Descripción de la figura.]*

## Simulaciones

### 1. Simulación de [Módulo 1]

#### 1.1 Inclusión de Archivos y Timescale

```verilog
`include "[archivo].v"
`timescale [unidad]/[precisión]
```

#### 1.2 Declaración del Módulo y Señales

```verilog
// [Código]
```

#### 1.3 Instancia del DUT

```verilog
// [Código]
```

#### 1.4 Volcado de Formas de Onda

```verilog
// [Código]
```

#### 1.5 Proceso Principal de Pruebas

```verilog
// [Código]
```

#### 1.6 Modelo de Referencia

#### 1.7 Salida Esperada en Consola

```text
[Salida esperada]
```

#### 1.8 Resultados

### 2. Simulación de [Módulo 2]

#### 2.1 Inclusión de Archivos y Timescale

```verilog
`include "[archivo].v"
`timescale [unidad]/[precisión]
```

#### 2.2 Declaración de Señales y Variables

| Señal / Variable | Tipo | Descripción |
| :--- | :--- | :--- |
|  |  |  |

#### 2.3 Instancia del DUT

```verilog
// [Código]
```

#### 2.4 Volcado VCD

```verilog
// [Código]
```

#### 2.5 Proceso Principal de Pruebas

```verilog
// [Código]
```

#### 2.6 Salida Esperada en Consola

```text
[Salida esperada]
```

#### 2.7 Diagramas de Simulación

![Descripción](ruta/grafica.png)
*Figura 2. [Descripción de la gráfica.]*

### 3. Simulación de [Módulo 3]

#### 3.1 Verificación mediante Testbench

#### 3.2 Resultado de la Simulación

```text
[Salida obtenida]
```

#### 3.3 Posibles Errores y Depuración

```text
[Errores comunes]
```

#### 3.4 Diagramas

![Descripción](ruta/grafica1.png)
*Figura 3. [Descripción de la gráfica.]*

## Evidencias de implementación

## Preguntas

1. [Pregunta 1]
   - [Respuesta.]

2. [Pregunta 2]
   - [Respuesta.]

## Conclusiones

- [Conclusión 1.]
- [Conclusión 2.]
- [Conclusión 3.]

## Referencias

- [Autor. Título. Año. URL.]
- [Autor. Título. Año. URL.]
