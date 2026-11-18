:- module(nqueens_backtracking, [n_queens/2, safe_row/2]).
:- encoding(utf8).
% Backtracking: una reina por columna; la lista guarda filas.

% n_queens(+N, -Solution)
% Solution es una lista de N filas (una por columna) sin ataques.
% Al pedir más respuestas (;) Prolog enumera todas las soluciones.
% Si no hay ninguna (N = 2, N = 3) el predicado falla tras agotar
% todas las alternativas: eso es una demostración de que no existe.
n_queens(N, Solution) :-
    must_be(positive_integer, N),
    place_queens(N, N, [], Reversed),
    reverse(Reversed, Solution).

% place_queens(+N, +Remaining, +Placed, -Solution)
% N es el tamaño del tablero (fijo): toda reina puede ir en las
% filas 1..N. Remaining es cuántas columnas faltan por llenar.
% Placed guarda las reinas ya colocadas, la más reciente primero.
place_queens(_, 0, Placed, Placed).
place_queens(N, Remaining, Placed, Solution) :-
    Remaining > 0,
    between(1, N, Row),          % punto de elección: filas alternativas
    safe_row(Row, Placed),       % poda temprana
    Remaining1 is Remaining - 1,
    place_queens(N, Remaining1, [Row|Placed], Solution).

% safe_row(+Row, +PreviousRows)
% La reina nueva está en la columna siguiente a las ya colocadas.
% PreviousRows empieza por la columna inmediatamente anterior, así
% que Distance (diferencia de columnas) aumenta de 1 en 1.
safe_row(Row, PreviousRows) :-
    safe_row(Row, PreviousRows, 1).

safe_row(_, [], _).
safe_row(Row, [Previous|Rest], Distance) :-
    Row =\= Previous,                     % misma fila
    abs(Row - Previous) =\= Distance,     % misma diagonal
    NextDistance is Distance + 1,
    safe_row(Row, Rest, NextDistance).
