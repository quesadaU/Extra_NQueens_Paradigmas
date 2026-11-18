% Backtracking: una reina por columna; la lista guarda filas.
:- module(nqueens_backtracking, [n_queens/2, safe_row/2]).

n_queens(N, Solution) :-
    integer(N),
    N > 0,
    place_queens(N, [], Solution).

% Coloca las reinas columna por columna.
place_queens(0, Acc, Acc).
place_queens(N, Acc, Solution) :-
    N > 0,
    between(1, N, Row),
    safe_row(Row, Acc),
    N1 is N - 1,
    place_queens(N1, [Row|Acc], Solution).

% La reina nueva está en la columna siguiente a las ya colocadas.
% Distance aumenta al recorrer las reinas anteriores.
safe_row(Row, PreviousRows) :-
    safe_row(Row, PreviousRows, 1).

safe_row(_, [], _).
safe_row(Row, [Previous|Rest], Distance) :-
    Row =\= Previous,
    abs(Row - Previous) =\= Distance,
    NextDistance is Distance + 1,
    safe_row(Row, Rest, NextDistance).
