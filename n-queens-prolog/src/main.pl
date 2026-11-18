:- use_module(nqueens_backtracking).
:- use_module(nqueens_annealing).
:- use_module(nqueens_html).

% Ejemplos:
% ?- run(backtracking, 8, 'output/backtracking.html').
% ?- run(annealing, 8, 'output/annealing.html').

run(backtracking, N, HtmlFile) :-
    once(nqueens_backtracking:n_queens(N, Solution)),
    nqueens_html:write_board_html(HtmlFile, Solution),
    format('Backtracking encontró: ~w~n', [Solution]),
    format('Tablero generado: ~w~n', [HtmlFile]).

run(annealing, N, HtmlFile) :-
    nqueens_annealing:solve_annealing(
        N, 10000, 10.0, 0.995, Solution, Cost, Status
    ),
    format('Simulated annealing: ~w~nCosto: ~d~nEstado: ~w~n',
           [Solution, Cost, Status]),
    ( Cost =:= 0 ->
        nqueens_html:write_board_html(HtmlFile, Solution),
        format('Tablero generado: ~w~n', [HtmlFile])
    ;   writeln('No se generó tablero: no se encontró solución válida.')
    ).
