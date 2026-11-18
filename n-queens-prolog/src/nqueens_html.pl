% Genera una página HTML estática a partir de una solución.
:- module(nqueens_html, [write_board_html/2]).

write_board_html(File, State) :-
    length(State, N),
    setup_call_cleanup(
        open(File, write, Stream, [encoding(utf8)]),
        write_page(Stream, State, N),
        close(Stream)
    ).

write_page(S, State, N) :-
    format(S, '<!doctype html>~n<html lang="es"><head><meta charset="utf-8">~n', []),
    format(S, '<meta name="viewport" content="width=device-width, initial-scale=1">~n', []),
    format(S, '<title>Solución de ~d reinas</title>~n', [N]),
    format(S, '<style>body{font-family:system-ui,sans-serif;margin:2rem;background:#f5f5f5;color:#222} .board{display:grid;grid-template-columns:repeat(~d,minmax(28px,56px));width:min(90vw,~dpx);border:2px solid #333}.cell{aspect-ratio:1;display:grid;place-items:center;font-size:clamp(18px,4vw,36px)}.light{background:#eee3cf}.dark{background:#788391}.queen{color:#b42318;text-shadow:0 1px 2px #fff}</style></head><body>~n', [N, N*56]),
    format(S, '<h1>Solución para ~d reinas</h1><p>Una reina por columna. Costo: 0 conflictos.</p><div class="board">~n', [N]),
    forall(between(1, N, Row),
           forall(between(1, N, Col),
                  write_cell(S, State, Row, Col))),
    format(S, '</div></body></html>~n', []).

write_cell(S, State, Row, Col) :-
    ( 0 is (Row + Col) mod 2 -> Shade = light ; Shade = dark ),
    ( nth1(Col, State, Row) -> Piece = '<span class="queen">&#9819;</span>'
    ; Piece = ''
    ),
    format(S, '<div class="cell ~w">~s</div>~n', [Shade, Piece]).
