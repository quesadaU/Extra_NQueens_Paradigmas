:- encoding(utf8).
:- use_module('../src/nqueens_backtracking').
:- use_module('../src/nqueens_annealing').
:- use_module('../src/nqueens_html').

% Ejecutar desde la raíz n-queens-prolog/:
% swipl -q -s tests/test_nqueens.pl -g run_tests -t halt
%
% valid_solution/1 (de nqueens_html) es una comprobación independiente:
% no reutiliza safe_row/2 ni cost/2.

:- begin_tests(backtracking).

test(n1) :-
    once(n_queens(1, S)),
    assertion(S == [1]).

test(n4) :-
    once(n_queens(4, S)),
    assertion(valid_solution(S)).

test(n8) :-
    once(n_queens(8, S)),
    assertion(valid_solution(S)).

test(no_solution_n2, [fail]) :-
    n_queens(2, _).

test(no_solution_n3, [fail]) :-
    n_queens(3, _).

% Enumerar todas las soluciones: cantidades conocidas.
test(all_solutions_n4, [true(L == [[2,4,1,3],[3,1,4,2]])]) :-
    findall(S, n_queens(4, S), L).

test(count_n8, [true(K == 92)]) :-
    aggregate_all(count, n_queens(8, _), K).

test(every_solution_valid_n6) :-
    forall(n_queens(6, S), valid_solution(S)).

test(invalid_n, [error(type_error(positive_integer, 0))]) :-
    n_queens(0, _).

:- end_tests(backtracking).

:- begin_tests(annealing).

test(cost_zero_known_solution) :-
    cost([2,4,1,3], 0).

% [1,1,3,4]: (1,2) misma fila, (3,4) diagonal, (1,3)? |1-3|=2=3-1 sí.
% (2,3)? |1-3|=2 vs 1 no. (1,4)? |1-4|=3=3 sí. (2,4)? |1-4|=3 vs 2 no.
test(cost_counts_pairs_once, [true(C == 4)]) :-
    cost([1,1,3,4], C).

% Todas las reinas en la misma fila: C(4,2) = 6 parejas.
test(cost_same_row, [true(C == 6)]) :-
    cost([1,1,1,1], C).

% Diagonal principal: también 6 parejas.
test(cost_diagonal, [true(C == 6)]) :-
    cost([1,2,3,4], C).

test(neighbor_size_and_domain) :-
    forall(between(1, 200, _),
           (   random_state(8, S),
               neighbor(S, V),
               length(V, 8),
               forall(member(R, V), between(1, 8, R)),
               % difiere exactamente en una columna
               aggregate_all(count, (nth1(I, S, A), nth1(I, V, B), A \== B), 1)
           )).

test(neighbor_n1) :-
    neighbor([1], V),
    V == [1].

test(accept_better_always) :-
    accept_move(-3, 0.0001),
    accept_move(0, 0.0001).

test(deterministic_single_answer, [true(K == 1)]) :-
    aggregate_all(count, solve_annealing(6, 200, 10.0, 0.99, _, _, _), K).

test(zero_steps_limit) :-
    solve_annealing(8, 0, 10.0, 0.995, 0.01, S, C, Status, It),
    assertion(It == 0),
    (   Status == solved -> assertion(C == 0), assertion(valid_solution(S))
    ;   assertion(Status == limit_reached), assertion(C > 0)
    ).

test(cooled_down_immediately) :-
    % Temperatura inicial ya menor que la mínima.
    solve_annealing(8, 1000, 0.005, 0.995, 0.01, _, C, Status, It),
    assertion(It == 0),
    (   Status == solved -> assertion(C == 0)
    ;   assertion(Status == cooled_down), assertion(C > 0)
    ).

% Propiedad: en muchas ejecuciones, el estado reportado es coherente
% con el costo (no depende de que una semilla concreta tenga éxito).
test(status_consistent_with_cost) :-
    forall(between(1, 30, _),
           (   solve_annealing(8, 300, 10.0, 0.98, 0.01, S, C, Status, It),
               cost(S, C2),
               assertion(C2 == C),
               assertion(It =< 300),
               (   Status == solved
               ->  assertion(C == 0), assertion(valid_solution(S))
               ;   assertion(memberchk(Status, [limit_reached, cooled_down])),
                   assertion(C > 0)
               )
           )).

test(n1_trivially_solved) :-
    solve_annealing(1, 10, 10.0, 0.9, [1], 0, solved).

test(invalid_cooling, [error(domain_error(_, 1.5))]) :-
    solve_annealing(8, 10, 10.0, 1.5, _, _, _).

:- end_tests(annealing).

:- begin_tests(html).

test(rejects_invalid_state, [error(domain_error(valid_nqueens_solution, _))]) :-
    tmp_file(board, F),
    write_board_html(F, [1,1,3,4]).

test(writes_valid_board) :-
    tmp_file(board, F),
    write_board_html(F, [2,4,1,3]),
    read_file_to_string(F, Html, [encoding(utf8)]),
    once(sub_string(Html, _, _, _, "Solución para 4 reinas")),
    aggregate_all(count, sub_string(Html, _, _, _, "class=\"queen\""), 4),
    delete_file(F).

:- end_tests(html).
