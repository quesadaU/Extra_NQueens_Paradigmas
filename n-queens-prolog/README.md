# N-Reinas: Backtracking vs. Simulated Annealing

Proyecto académico en SWI-Prolog para estudiar dos enfoques del problema de las N-reinas.

## Objetivo

Implementar y comparar:

1. **Backtracking:** construye una solución columna por columna y descarta posiciones que violan las restricciones (poda temprana).
2. **Simulated annealing:** parte de un estado completo aleatorio y trata de reducir su costo mediante movimientos locales probabilísticos.

Ambos algoritmos usan la misma representación: una lista donde el índice representa la columna y el valor representa la fila de la reina.

Ejemplo: `[2,4,1,3]` representa una solución válida para N = 4.

## Requisitos

- SWI-Prolog (probado con **10.0.2**, Windows x64).
- Navegador web para abrir el HTML generado.

No se requieren bibliotecas externas.

## Estructura

```text
n-queens-prolog/
├── src/
│   ├── main.pl                   # punto de entrada: run/3
│   ├── nqueens_backtracking.pl   # n_queens/2, safe_row/2
│   ├── nqueens_annealing.pl      # solve_annealing/7 y /9, cost/2, neighbor/2
│   └── nqueens_html.pl           # write_board_html/2,3, valid_solution/1
├── tests/
│   └── test_nqueens.pl           # PLUnit (24 pruebas)
├── benchmarks/
│   └── benchmark.pl              # experimentos comparativos
├── output/                       # HTML y CSV generados (no es código fuente)
├── README.md
└── .gitignore
```

## Ejecutar

Todos los comandos se ejecutan desde la carpeta `n-queens-prolog/`.

```bash
swipl -q -s src/main.pl
```

En el intérprete:

```prolog
?- run(backtracking, 8, 'output/backtracking.html').
?- run(annealing, 8, 'output/annealing.html').
```

- Backtracking con N = 2 o N = 3 informa que agotó todas las alternativas y no genera tablero.
- Simulated annealing muestra el mejor estado, su costo, el estado de terminación (`solved`, `limit_reached` o `cooled_down`) y las iteraciones. **Solo genera HTML si `Status = solved` (costo 0).**
- `write_board_html/3` vuelve a validar la solución de forma independiente y lanza un error si recibe un estado con conflictos.

Uso directo de los predicados:

```prolog
?- n_queens(8, S).                 % pulsar ; para más soluciones
?- aggregate_all(count, n_queens(8, _), K).   % K = 92
?- solve_annealing(8, 10000, 10.0, 0.995, 0.01, S, Costo, Estado, Iter).
```

> En la consola de Git Bash los acentos pueden verse como `�`. Es solo la codificación de la terminal; los archivos HTML se escriben en UTF-8.

## Pruebas

```bash
swipl -q -s tests/test_nqueens.pl -g run_tests -t halt
```

Cubren:
- **Backtracking:** N = 1, 4 y 8; ausencia de solución para N = 2 y 3; enumeración de las 2 soluciones de N = 4 y de las 92 de N = 8; validez de todas las soluciones de N = 6; error para N = 0.
- **Annealing:** valores exactos de `cost/2`, tamaño y dominio de `neighbor/2`, regla de aceptación, determinismo (una sola respuesta), terminación por límite de iteraciones y por temperatura mínima, coherencia entre estado y costo en 30 ejecuciones, y validación de parámetros.
- **HTML:** rechaza estados inválidos y dibuja exactamente N reinas.

Las pruebas de annealing verifican propiedades. No dependen de que una semilla concreta encuentre solución.

## Benchmarks

```bash
# Comparación principal: backtracking (primera solución) vs. 30 ejecuciones de SA
swipl -q -s benchmarks/benchmark.pl -g "benchmark([4,8,12,20])" -t halt

# Igual, guardando además el CSV
swipl -q -s benchmarks/benchmark.pl -g "benchmark([4,8,12,20],'output/benchmark.csv')" -t halt

# Enumeración completa con backtracking (contar soluciones / demostrar que no hay)
swipl -q -s benchmarks/benchmark.pl -g "benchmark_all_solutions([1,2,3,4,5,6,7,8,9,10])" -t halt

# Experimentos de parámetros de SA (variando uno a la vez)
swipl -q -s benchmarks/benchmark.pl -g "benchmark_params(12, 30)" -t halt
```

Qué se mide:
- Tiempo de reloj con `get_time/1` e **inferencias** de Prolog (`statistics/2`). Las inferencias no dependen de la máquina.
- No se genera HTML durante la medición.
- Para SA, por cada N: éxitos, porcentaje de éxito, tiempo medio y máximo, costo final medio, iteraciones medias y cuántas ejecuciones terminaron en cada estado.
- La salida incluye la versión de SWI-Prolog, la fecha y los parámetros.
- `once/1` mide la búsqueda de la **primera** solución; `benchmark_all_solutions/1` mide la exploración completa del árbol.

## Cómo interpretar el costo

El costo es la cantidad de **parejas** de reinas que se atacan (misma fila o misma diagonal). Cada pareja se cuenta una sola vez, porque solo se consideran columnas `C1 < C2`.

- `0`: solución válida.
- Mayor que `0`: todavía hay conflictos.

Ejemplo: `[1,1,1,1]` tiene costo 6 = C(4,2).

## Parámetros de simulated annealing

| Parámetro | Valor por defecto | Significado |
|---|---|---|
| `MaxSteps` | 10 000 | Máximo de vecinos evaluados. Al llegar a él: `limit_reached`. |
| `InitialTemp` | 10.0 | Temperatura inicial. Más alta = acepta más movimientos peores al principio. |
| `CoolingRate` | 0.995 | En cada paso `T := T * CoolingRate` (enfriamiento geométrico). Debe estar en (0, 1). |
| `MinTemp` | 0.01 | Si `T =< MinTemp`: `cooled_down`. |

Las condiciones de parada se revisan en este orden: costo 0 → `solved`; iteraciones agotadas → `limit_reached`; temperatura mínima → `cooled_down`.

**Ojo con los valores por defecto:** con 10.0 y 0.995, la temperatura llega a 0.01 en el paso ⌈ln(0.01/10)/ln(0.995)⌉ = **1379**. Por eso el límite de 10 000 iteraciones nunca se alcanza: todas las ejecuciones fallidas terminan en `cooled_down`.

**Vecino:** se elige una columna al azar y su reina se mueve a una fila *distinta* de la actual. Así nunca se gasta una iteración en un vecino idéntico.

## Resultados medidos

Ejecutados el 2026-11-18 con SWI-Prolog 10.0.2 en Windows. Los tiempos dependen del equipo y varían entre ejecuciones; repítanlos en su máquina antes de citarlos.

### Comparación principal (`benchmark([1,2,3,4,8,12,20])`, 30 ejecuciones de SA)

| N | BT primera solución (s) | BT inferencias | SA éxito | SA tiempo medio (s) | SA costo final medio |
|---|---|---|---|---|---|
| 1 | 0.0001 | 190 | 30/30 (100 %) | 0.0002 | 0.00 |
| 2 | 0.00001 — *no existe* | 40 | 0/30 | 0.0027 | 1.00 |
| 3 | 0.00001 — *no existe* | 107 | 0/30 | 0.0041 | 1.00 |
| 4 | 0.00001 | 176 | 30/30 (100 %) | 0.0004 | 0.00 |
| 8 | 0.0003 | 8 393 | 22/30 (73 %) | 0.0105 | 0.27 |
| 12 | 0.0012 | 39 346 | 8/30 (27 %) | 0.0275 | 0.73 |
| 20 | 2.52 | 78 010 997 | 0/30 (0 %) | 0.0780 | 1.77 |

### Enumeración completa con backtracking

| N | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| Soluciones | 1 | 0 | 0 | 2 | 10 | 4 | 40 | 92 | 352 | 724 |
| Tiempo todas (s) | ~0 | ~0 | ~0 | ~0 | ~0 | 0.0002 | 0.001 | 0.005 | 0.025 | 0.128 |

### Parámetros de SA para N = 12 (`benchmark_params(12, 30)`)

| Experimento | Valor | Éxito | Tiempo medio (s) | Terminación de los fallos |
|---|---|---|---|---|
| T0 | 0.5 / 1 / 10 / 100 | 27 % / 33 % / 27 % / 13 % | 0.015 – 0.043 | todas `cooled_down` |
| Enfriamiento | 0.95 | 0 % | 0.003 | `cooled_down` en el paso 135 |
| Enfriamiento | 0.99 | 7 % | 0.018 | `cooled_down` |
| Enfriamiento | 0.995 | 33 % | 0.034 | `cooled_down` |
| Enfriamiento | 0.999 | 73 % | 0.119 | `cooled_down` |
| Enfriamiento | 0.9995 | 70 % | 0.193 | 9 `limit_reached` |
| MaxSteps (con 0.9995) | 1 000 / 5 000 / 10 000 / 50 000 | 0 % / 0 % / 83 % / 100 % | 0.02 – 0.20 | `limit_reached` |

### Lectura de los resultados

- **Backtracking** siempre acierta y además *demuestra* que N = 2 y N = 3 no tienen solución, porque agota todas las alternativas. Su costo crece muy rápido con N: de N = 12 a N = 20 pasa de unas 39 mil a 78 millones de inferencias para encontrar la primera solución.
- **SA** con los parámetros por defecto no garantiza nada. Para N = 2 y 3 se enfría sin solución, pero eso **no** prueba que no exista: solo indica que no la encontró. Su tasa de éxito baja al crecer N (73 % → 27 % → 0 %), aunque cada ejecución tarda poco.
- El factor de **enfriamiento** es el parámetro más influyente: enfriar más lento da más iteraciones y más éxito, a cambio de más tiempo. La **temperatura inicial** influye menos, y una muy alta (100) empeora el resultado porque gasta iteraciones en movimientos aleatorios.
- El **máximo de iteraciones** solo importa cuando el enfriamiento es lo bastante lento para no llegar antes a `MinTemp`.
- En N = 20 los parámetros por defecto son insuficientes para SA (0 %). Antes de concluir que SA "no sirve" para N grandes, hay que probar un enfriamiento más lento.

## Limitaciones conocidas

- SA es probabilístico: los resultados varían entre ejecuciones y no se fija una semilla.
- `cost/2` recorre todas las parejas (O(N²)) en cada iteración. Una versión incremental sería más rápida, pero menos directa de explicar.
- El vecino solo mueve una reina de fila. Un vecino por intercambio de filas (permutaciones) eliminaría los conflictos de fila desde el principio, y no se ha probado.
- Backtracking prueba las filas en orden 1..N, sin heurísticas. Por eso su tiempo es exponencial y se vuelve impracticable alrededor de N ≈ 25–30.
- El benchmark es didáctico, no un estudio exhaustivo de rendimiento.
- El HTML muestra la solución final; no es una animación del proceso de búsqueda.

## Licencia

Proyecto académico. Agreguen aquí la licencia que decida el equipo.
