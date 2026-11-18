:- begin_tests(nqueens).
:- use_module('../src/nqueens_backtracking').
:- use_module('../src/nqueens_annealing').

valid_solution(State) :-
    length(State, N),
    sort(State, DistinctRows),
    length(DistinctRows, N),
    forall(
        (nth1(C1, State, R1), nth1(C2, State, R2), C2 > C1),
        abs(R1 - R2) =\= C2 - C1
    ).

test(backtracking_four, [nondet]) :-
    n_queens(4, Solution),
    valid_solution(Solution).

test(backtracking_eight, [nondet]) :-
    n_queens(8, Solution),
    valid_solution(Solution).

test(no_solution_for_two, [fail]) :-
    n_queens(2, _).

test(cost_zero_for_known_solution) :-
    cost([2,4,1,3], 0).

test(cost_detects_conflict) :-
    cost([1,1,3,4], Cost),
    Cost > 0.

:- end_tests(nqueens).

% Ejecutar:
% swipl -q -s tests/test_nqueens.pl -g run_tests -t halt
