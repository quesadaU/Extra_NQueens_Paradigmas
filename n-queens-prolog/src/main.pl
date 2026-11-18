:- encoding(utf8).
:- use_module(nqueens_backtracking).
:- use_module(nqueens_annealing).
:- use_module(nqueens_html).

% Ejemplos (desde la raíz n-queens-prolog/):
% ?- run(backtracking, 8, 'output/backtracking.html').
% ?- run(annealing, 8, 'output/annealing.html').
%
% El HTML se escribe después de medir y solo si la solución es válida.

run(backtracking, N, HtmlFile) :-
    !,
    (   once(n_queens(N, Solution))
    ->  format('Backtracking encontró: ~w~n', [Solution]),
        write_board_html(HtmlFile, Solution, backtracking),
        format('Tablero generado: ~w~n', [HtmlFile])
    ;   format('Backtracking agotó todas las alternativas: no existe solución para N = ~d.~n', [N]),
        writeln('No se generó tablero.')
    ).
run(annealing, N, HtmlFile) :-
    !,
    solve_annealing(N, 10000, 10.0, 0.995, 0.01,
                    Solution, Cost, Status, Iterations),
    format('Simulated annealing: ~w~nCosto: ~d~nEstado: ~w~nIteraciones: ~d~n',
           [Solution, Cost, Status, Iterations]),
    (   Status == solved
    ->  write_board_html(HtmlFile, Solution, 'simulated annealing'),
        format('Tablero generado: ~w~n', [HtmlFile])
    ;   writeln('No se generó tablero: no se encontró solución válida (costo > 0).')
    ).
run(Algorithm, _, _) :-
    domain_error(backtracking_or_annealing, Algorithm).
