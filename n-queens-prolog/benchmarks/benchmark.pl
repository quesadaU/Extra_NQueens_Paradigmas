:- encoding(utf8).
:- use_module('../src/nqueens_backtracking').
:- use_module('../src/nqueens_annealing').
:- use_module(library(aggregate)).
:- use_module(library(apply)).
:- use_module(library(lists)).

% Ejecutar desde la raíz n-queens-prolog/:
%
%   Comparación principal (backtracking vs. 30 ejecuciones de SA):
%   swipl -q -s benchmarks/benchmark.pl -g "benchmark([4,8,12,20])" -t halt
%
%   Guardar además el CSV en un archivo:
%   swipl -q -s benchmarks/benchmark.pl -g "benchmark([4,8,12,20],'output/benchmark.csv')" -t halt
%
%   Enumerar todas las soluciones con backtracking (prueba exhaustiva):
%   swipl -q -s benchmarks/benchmark.pl -g "benchmark_all_solutions([1,2,3,4,5,6,7,8,9,10])" -t halt
%
%   Experimentos de parámetros de SA para un N:
%   swipl -q -s benchmarks/benchmark.pl -g "benchmark_params(12, 30)" -t halt
%
% Los tiempos son de reloj (get_time/1, alta resolución) y solo miden
% la búsqueda: aquí no se genera HTML. También se registran las
% inferencias de Prolog (statistics/2), que no dependen del equipo.

% Parámetros por defecto de SA: sa(MaxSteps, T0, Cooling, MinTemp).
default_sa_params(sa(10000, 10.0, 0.995, 0.01)).
default_trials(30).

%% ------------------------------------------------------------------
%% Comparación principal
%% ------------------------------------------------------------------

benchmark(Sizes) :-
    benchmark_to_stream(user_output, Sizes).

benchmark(Sizes, File) :-
    benchmark_to_stream(user_output, Sizes),
    setup_call_cleanup(open(File, write, S, [encoding(utf8)]),
                       benchmark_to_stream(S, Sizes),
                       close(S)).

benchmark_to_stream(Out, Sizes) :-
    default_sa_params(Params),
    default_trials(Trials),
    print_header(Out, Params, Trials),
    format(Out, 'N,algoritmo,ejecuciones,exitos,porcentaje_exito,tiempo_medio_s,tiempo_max_s,inferencias_medias,costo_final_medio,iteraciones_medias,solved,limit_reached,cooled_down,resultado~n', []),
    forall(member(N, Sizes),
           (   bt_row(Out, N),
               sa_row(Out, N, Trials, Params)
           )).

print_header(Out, sa(MaxSteps, T0, Cooling, MinTemp), Trials) :-
    current_prolog_flag(version, V),
    Major is V // 10000, Minor is (V // 100) mod 100, Patch is V mod 100,
    get_time(Now), format_time(atom(Date), '%Y-%m-%d %H:%M:%S', Now),
    format(Out, '# SWI-Prolog ~d.~d.~d, fecha ~w~n', [Major, Minor, Patch, Date]),
    format(Out, '# SA: max_steps=~w t0=~w cooling=~w min_temp=~w ejecuciones=~w~n',
           [MaxSteps, T0, Cooling, MinTemp, Trials]).

% Backtracking: tiempo hasta la PRIMERA solución (once/1).
bt_row(Out, N) :-
    measure(once_or_none(N, Result), Time, Inf),
    (   Result = found(S)
    ->  atomic_list_concat(S, ' ', SolAtom),
        format(Out, '~d,backtracking,1,1,100.0,~6f,~6f,~d,0,,,,,"~w"~n',
               [N, Time, Time, Inf, SolAtom])
    ;   format(Out, '~d,backtracking,1,0,0.0,~6f,~6f,~d,,,,,,no_existe_solucion~n',
               [N, Time, Time, Inf])
    ).

once_or_none(N, Result) :-
    (   once(n_queens(N, S)) -> Result = found(S) ; Result = none ).

% Simulated annealing: Trials ejecuciones independientes.
sa_row(Out, N, Trials, Params) :-
    sa_trials(N, Trials, Params, Runs),
    summarize(Runs, Summary),
    Summary = summary(Succ, Rate, AvgT, MaxT, AvgInf, AvgC, AvgI, NS, NL, NC),
    format(Out, '~d,annealing,~d,~d,~1f,~6f,~6f,~0f,~3f,~1f,~d,~d,~d,~n',
           [N, Trials, Succ, Rate, AvgT, MaxT, AvgInf, AvgC, AvgI, NS, NL, NC]).

% Cada ejecución: run(Status, Cost, Iterations, Time, Inferences).
sa_trials(N, Trials, sa(MaxSteps, T0, Cooling, MinTemp), Runs) :-
    findall(run(Status, Cost, It, Time, Inf),
            (   between(1, Trials, _),
                measure(solve_annealing(N, MaxSteps, T0, Cooling, MinTemp,
                                        _, Cost, Status, It),
                        Time, Inf)
            ),
            Runs).

summarize(Runs, summary(Succ, Rate, AvgT, MaxT, AvgInf, AvgC, AvgI,
                        NS, NL, NC)) :-
    length(Runs, Total),
    aggregate_all(count, member(run(solved, _, _, _, _), Runs), NS),
    aggregate_all(count, member(run(limit_reached, _, _, _, _), Runs), NL),
    aggregate_all(count, member(run(cooled_down, _, _, _, _), Runs), NC),
    Succ = NS,
    Rate is 100.0 * Succ / Total,
    findall(T, member(run(_, _, _, T, _), Runs), Ts),
    findall(F, member(run(_, _, _, _, F), Runs), Fs),
    findall(C, member(run(_, C, _, _, _), Runs), Cs),
    findall(I, member(run(_, _, I, _, _), Runs), Is),
    mean(Ts, AvgT), max_list(Ts, MaxT), mean(Fs, AvgInf),
    mean(Cs, AvgC), mean(Is, AvgI).

mean(L, M) :-
    sum_list(L, S), length(L, K), M is S / K.

% measure(:Goal, -Seconds, -Inferences): ejecuta Goal una vez.
measure(Goal, Seconds, Inferences) :-
    statistics(inferences, I0),
    get_time(T0),
    once(Goal),
    get_time(T1),
    statistics(inferences, I1),
    Seconds is T1 - T0,
    Inferences is I1 - I0.

% Variante que solo devuelve el tiempo.
measure_time(Goal, Seconds) :-
    measure(Goal, Seconds, _).

%% ------------------------------------------------------------------
%% Enumeración completa con backtracking
%% ------------------------------------------------------------------
% Muestra la diferencia entre encontrar una solución (once/1) y
% explorar todo el árbol: contar todas o demostrar que no hay ninguna.

benchmark_all_solutions(Sizes) :-
    print_version,
    writeln('N,soluciones_totales,tiempo_primera_s,tiempo_todas_s'),
    forall(member(N, Sizes),
           (   measure_time(once_or_none(N, _), TFirst),
               measure_time(aggregate_all(count, n_queens(N, _), Count), TAll),
               format('~d,~d,~6f,~6f~n', [N, Count, TFirst, TAll])
           )).

print_version :-
    current_prolog_flag(version, V),
    Major is V // 10000, Minor is (V // 100) mod 100, Patch is V mod 100,
    format('# SWI-Prolog ~d.~d.~d~n', [Major, Minor, Patch]).

%% ------------------------------------------------------------------
%% Experimentos de parámetros de SA
%% ------------------------------------------------------------------
% Varía un parámetro a la vez respecto a los valores por defecto.

benchmark_params(N, Trials) :-
    print_version,
    format('# N=~d, ejecuciones por configuracion=~d~n', [N, Trials]),
    writeln('experimento,max_steps,t0,cooling,min_temp,exitos,porcentaje_exito,tiempo_medio_s,costo_final_medio,iteraciones_medias,solved,limit_reached,cooled_down'),
    default_sa_params(sa(M0, T00, C0, Min0)),
    forall(member(T0, [0.5, 1.0, 10.0, 100.0]),
           param_row(temperatura_inicial, N, Trials, sa(M0, T0, C0, Min0))),
    forall(member(C, [0.95, 0.99, 0.995, 0.999, 0.9995]),
           param_row(enfriamiento, N, Trials, sa(M0, T00, C, Min0))),
    forall(member(M, [1000, 5000, 10000, 50000]),
           param_row(max_iteraciones_cooling_0_9995, N, Trials,
                     sa(M, T00, 0.9995, Min0))).

param_row(Name, N, Trials, Params) :-
    Params = sa(M, T0, C, Min),
    sa_trials(N, Trials, Params, Runs),
    summarize(Runs, summary(Succ, Rate, AvgT, _, _, AvgC, AvgI, NS, NL, NC)),
    format('~w,~w,~w,~w,~w,~d,~1f,~6f,~3f,~1f,~d,~d,~d~n',
           [Name, M, T0, C, Min, Succ, Rate, AvgT, AvgC, AvgI, NS, NL, NC]).
