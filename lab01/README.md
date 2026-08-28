        
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

#### 3.2 Diagramas
![Descripción](imagenes/arquitectura.png "Tooltip")
*Figura 1. RTL dado por software Quartus para el Sumador de 4 bits*

####
![Descripción](imagenes/sumRest.png "Tooltip")
*Figura 2. RTL dado por software Quartus para el Sumador/Restador*
 
## Simulaciones 

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

