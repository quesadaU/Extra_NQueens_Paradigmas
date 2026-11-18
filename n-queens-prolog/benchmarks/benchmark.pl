:- use_module('../src/nqueens_backtracking').
:- use_module('../src/nqueens_annealing').

% Ejecutar desde la raíz:
% swipl -q -s benchmarks/benchmark.pl -g "benchmark([4,8,12,20])" -t halt

benchmark(Sizes) :-
    writeln('N,algoritmo,tiempo_segundos,resultado'),
    maplist(benchmark_n, Sizes).

benchmark_n(N) :-
    get_time(T0),
    ( once(nqueens_backtracking:n_queens(N, S)) -> Result = found(S)
    ; Result = no_solution
    ),
    get_time(T1),
    BackTime is T1 - T0,
    format('~d,backtracking,~6f,~w~n', [N, BackTime, Result]),
    annealing_trials(N, 30, Successes, AverageBestCost),
    format('~d,annealing_30_trials,,successes=~d;average_best_cost=~2f~n',
           [N, Successes, AverageBestCost]).

annealing_trials(_, 0, 0, 0.0) :- !.
annealing_trials(N, Trials, Successes, AverageCost) :-
    Trials > 0,
    nqueens_annealing:solve_annealing(
        N, 10000, 10.0, 0.995, _, Cost, _
    ),
    Next is Trials - 1,
    annealing_trials(N, Next, OtherSuccesses, OtherAverage),
    ( Cost =:= 0 -> Successes is OtherSuccesses + 1
    ; Successes = OtherSuccesses
    ),
    AverageCost is (OtherAverage * Next + Cost) / Trials.
