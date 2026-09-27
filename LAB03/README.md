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
cout: acarreo de salida, que se envía a la siguiente posición.


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

```verilog
// [Código]
```

#### 2.4 Lógica

```verilog
// [Código]
```

#### 2.5 Tabla de Verdad

| [Entrada 1] | [Entrada 2] | [Salida 1] | [Salida 2] |
| :---: | :---: | :---: | :---: |
|  |  |  |  |

#### 2.6 Ejemplo Práctico

#### 2.7 Limitaciones

### 3. [Módulo 3]

#### 3.1 Descripción

#### 3.2 Entradas y Salidas

| Señal | Tipo | Descripción |
| :--- | :--- | :--- |
|  |  |  |

#### 3.3 Funcionamiento

#### 3.4 Implementación

```verilog
// [Código]
```

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
