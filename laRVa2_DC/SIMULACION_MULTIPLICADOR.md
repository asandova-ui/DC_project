# Cómo Simular y Visualizar el Multiplicador

## Flujo de Trabajo

El proceso completo para probar el multiplicador de manera aislada es:

```
Testbench (.v) → Compilar (iverilog) → Ejecutable (.out) → 
Simular (vvp) → Archivo VCD (.vcd) → Visualizar (gtkwave)
```

## Paso a Paso

### 1. Compilar el Testbench
El testbench (`multiplier_4bit_tb.v`) se compila con **iverilog** para generar un ejecutable:

```bash
iverilog -o multiplier_4bit_tb.out multiplier_4bit_tb.v
```

Esto crea el archivo `multiplier_4bit_tb.out` que contiene el código compilado.

### 2. Ejecutar la Simulación
Se ejecuta el simulador **vvp** con el archivo compilado:

```bash
vvp multiplier_4bit_tb.out
```

**Durante la simulación:**
- El testbench ejecuta todas las pruebas (44 pruebas en total)
- Se generan mensajes en la consola mostrando los resultados
- Se crea el archivo `multiplier_4bit_tb.vcd` con todas las señales

El archivo `.vcd` (Value Change Dump) contiene el historial de cambios de todas las señales durante la simulación.

### 3. Visualizar con GTKWave
Se abre el archivo VCD con **gtkwave**:

```bash
gtkwave multiplier_4bit_tb.vcd
```

En GTKWave podrás:
- Ver todas las señales del multiplicador (clk, reset, a, b, ua, ub, hm, load, busy, out)
- Ver señales internas del módulo DUT
- Hacer zoom, buscar transiciones, medir tiempos
- Agregar señales a la ventana de visualización arrastrándolas desde el árbol

## Método Automático (Recomendado)

Usa el Makefile que ya tiene la regla configurada:

```bash
make sim_mult
```

Este comando hace automáticamente los 3 pasos anteriores y abre GTKWave.

## Método Manual

Si prefieres hacerlo paso a paso:

```bash
# 1. Compilar
..\tools\toolchain-iverilog\bin\iverilog -o multiplier_4bit_tb.out multiplier_4bit_tb.v

# 2. Simular (genera el .vcd)
..\tools\toolchain-iverilog\bin\vvp multiplier_4bit_tb.out

# 3. Abrir GTKWave
..\tools\tool-gtkwave\bin\gtkwave multiplier_4bit_tb.vcd
```

## Qué Ver en GTKWave

Una vez abierto GTKWave:

1. **Panel izquierdo**: Árbol de jerarquía con todas las señales
   - `multiplier_4bit_tb` (testbench)
     - `DUT` (el multiplicador)
       - Señales internas del multiplicador

2. **Señales importantes a visualizar:**
   - `clk` - Reloj
   - `reset` - Reset asíncrono
   - `a`, `b` - Operandos
   - `ua`, `ub` - Flags de signo
   - `hm` - Flag para palabra alta/baja
   - `load` - Señal de inicio
   - `busy` - Indica cuando está procesando
   - `out` - Resultado de la multiplicación

3. **Agregar señales**: Arrastra las señales desde el panel izquierdo al panel de visualización

4. **Navegación**:
   - Zoom con la rueda del mouse
   - Buscar transiciones con las flechas
   - Medir tiempos seleccionando regiones

## Notas Importantes

- El archivo `.vcd` se genera automáticamente gracias a estas líneas en el testbench (143-144):
  ```verilog
  $dumpfile("multiplier_4bit_tb.vcd");
  $dumpvars(0, multiplier_4bit_tb);
  ```

- Si quieres ver señales internas del multiplicador, puedes cambiar `$dumpvars(0, multiplier_4bit_tb)` a `$dumpvars(1, multiplier_4bit_tb)` para incluir un nivel más de profundidad.

- El testbench ejecuta 44 pruebas diferentes cubriendo casos con signo, sin signo, números grandes, ceros, etc.

