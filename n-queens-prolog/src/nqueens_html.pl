% Genera una página HTML estática a partir de una solución.
:- module(nqueens_html, [write_board_html/2, write_board_html/3,
                         valid_solution/1]).
:- encoding(utf8).
:- use_module(library(error)).
:- use_module(library(lists)).

% valid_solution(+State)
% Comprobación independiente de los algoritmos: lista de enteros en
% 1..N, filas distintas y ninguna pareja en la misma diagonal.
valid_solution(State) :-
    is_list(State),
    length(State, N),
    N > 0,
    forall(member(R, State), (integer(R), between(1, N, R))),
    sort(State, Distinct),
    length(Distinct, N),
    \+ ( nth1(C1, State, R1), nth1(C2, State, R2), C2 > C1,
         abs(R1 - R2) =:= C2 - C1 ).

% write_board_html(+File, +State)
write_board_html(File, State) :-
    write_board_html(File, State, 'N-reinas').

% write_board_html(+File, +State, +Algorithm)
% Solo escribe el archivo si State es una solución válida; si no,
% lanza un error en lugar de dibujar un tablero incorrecto.
write_board_html(File, State, Algorithm) :-
    (   valid_solution(State)
    ->  true
    ;   domain_error(valid_nqueens_solution, State)
    ),
    length(State, N),
    setup_call_cleanup(
        open(File, write, Stream, [encoding(utf8)]),
        write_page(Stream, State, N, Algorithm),
        close(Stream)
    ).

write_page(S, State, N, Algorithm) :-
    Width is N * 56,
    format(S, '<!doctype html>~n<html lang="es"><head><meta charset="utf-8">~n', []),
    format(S, '<meta name="viewport" content="width=device-width, initial-scale=1">~n', []),
    format(S, '<title>Solución de ~d reinas</title>~n', [N]),
    format(S, '<style>body{font-family:system-ui,sans-serif;margin:2rem;background:#f5f5f5;color:#222} .board{display:grid;grid-template-columns:repeat(~d,minmax(28px,56px));width:min(90vw,~dpx);border:2px solid #333}.cell{aspect-ratio:1;display:grid;place-items:center;font-size:clamp(18px,4vw,36px)}.light{background:#eee3cf}.dark{background:#788391}.queen{color:#b42318;text-shadow:0 1px 2px #fff}</style></head><body>~n', [N, Width]),
    format(S, '<h1>Solución para ~d reinas</h1>~n', [N]),
    format(S, '<p>Algoritmo: ~w. Una reina por columna. Costo: 0 conflictos.</p>~n',
           [Algorithm]),
    format(S, '<p>Lista (columna &rarr; fila): ~w</p>~n<div class="board">~n', [State]),
    % Se recorre fila por fila (de arriba abajo) y en cada fila,
    % columna por columna, porque el grid CSS se llena así.
    forall(between(1, N, Row),
           forall(between(1, N, Col),
                  write_cell(S, State, Row, Col))),
    format(S, '</div></body></html>~n', []).

write_cell(S, State, Row, Col) :-
    ( 0 is (Row + Col) mod 2 -> Shade = light ; Shade = dark ),
    (   nth1(Col, State, Row)
    ->  Piece = '<span class="queen">&#9819;</span>'
    ;   Piece = ''
    ),
    format(S, '<div class="cell ~w">~w</div>~n', [Shade, Piece]).
