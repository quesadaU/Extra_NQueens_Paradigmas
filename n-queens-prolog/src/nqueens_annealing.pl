% Simulated annealing para N-reinas.
:- module(nqueens_annealing,
          [ solve_annealing/7,
            random_state/2,
            cost/2,
            neighbor/2
          ]).
:- use_module(library(random)).

% solve_annealing(+N, +MaxSteps, +InitialTemp, +CoolingRate,
%                 -BestState, -BestCost, -Status).
% Status = solved | limit_reached | cooled_down.
solve_annealing(N, MaxSteps, InitialTemp, CoolingRate,
                BestState, BestCost, Status) :-
    must_be_positive_integer(N),
    integer(MaxSteps), MaxSteps >= 0,
    InitialTemp > 0,
    CoolingRate > 0, CoolingRate < 1,
    random_state(N, Initial),
    cost(Initial, InitialCost),
    anneal(Initial, InitialCost, Initial, InitialCost,
           InitialTemp, CoolingRate, MaxSteps,
           BestState, BestCost, Status).

must_be_positive_integer(N) :-
    integer(N),
    N > 0.

% Cada columna contiene exactamente una reina; cada valor es una fila.
random_state(N, State) :-
    length(State, N),
    maplist(random_row(N), State).

random_row(N, Row) :-
    random_between(1, N, Row).

% Cuenta parejas de reinas que se atacan. Cada pareja se cuenta una vez.
cost(State, Cost) :-
    findall(1, attacking_pair(State), Conflicts),
    length(Conflicts, Cost).

attacking_pair(State) :-
    nth1(C1, State, R1),
    nth1(C2, State, R2),
    C2 > C1,
    ( R1 =:= R2
    ; abs(R1 - R2) =:= C2 - C1
    ).

% Genera un vecino cambiando la fila de una columna al azar.
neighbor(State, Neighbor) :-
    length(State, N),
    random_between(1, N, Column),
    random_between(1, N, NewRow),
    replace_nth1(Column, State, NewRow, Neighbor).

replace_nth1(1, [_|Tail], Value, [Value|Tail]) :- !.
replace_nth1(Index, [Head|Tail], Value, [Head|Result]) :-
    Index > 1,
    Next is Index - 1,
    replace_nth1(Next, Tail, Value, Result).

anneal(State, 0, Best, 0, _, _, _, Best, 0, solved) :- !.
anneal(_, _, Best, BestCost, _, _, 0,
       Best, BestCost, limit_reached) :- !.
anneal(State, CurrentCost, Best, BestCost, Temp, Cooling, Steps,
       FinalBest, FinalBestCost, Status) :-
    Temp > 0.01,
    neighbor(State, Candidate),
    cost(Candidate, CandidateCost),
    Delta is CandidateCost - CurrentCost,
    ( accept_move(Delta, Temp) ->
        NextState = Candidate,
        NextCost = CandidateCost
    ;   NextState = State,
        NextCost = CurrentCost
    ),
    ( CandidateCost < BestCost ->
        NextBest = Candidate,
        NextBestCost = CandidateCost
    ;   NextBest = Best,
        NextBestCost = BestCost
    ),
    NextTemp is Temp * Cooling,
    NextSteps is Steps - 1,
    anneal(NextState, NextCost, NextBest, NextBestCost,
           NextTemp, Cooling, NextSteps,
           FinalBest, FinalBestCost, Status).
anneal(_, _, Best, BestCost, _, _, _, Best, BestCost, cooled_down).

accept_move(Delta, _) :-
    Delta =< 0,
    !.
accept_move(Delta, Temp) :-
    Probability is exp(-Delta / Temp),
    random(Random),
    Random < Probability.
