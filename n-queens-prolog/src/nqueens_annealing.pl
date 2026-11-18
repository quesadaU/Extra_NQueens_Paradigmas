% Simulated annealing para N-reinas.
:- module(nqueens_annealing,
          [ solve_annealing/7,
            solve_annealing/9,
            random_state/2,
            cost/2,
            neighbor/2,
            accept_move/2
          ]).
:- encoding(utf8).
:- use_module(library(random)).
:- use_module(library(error)).

% Temperatura mínima usada por solve_annealing/7.
default_min_temp(0.01).

% solve_annealing(+N, +MaxSteps, +InitialTemp, +CoolingRate,
%                 -BestState, -BestCost, -Status)
% Versión corta: usa la temperatura mínima por defecto (0.01).
solve_annealing(N, MaxSteps, InitialTemp, CoolingRate,
                BestState, BestCost, Status) :-
    default_min_temp(MinTemp),
    solve_annealing(N, MaxSteps, InitialTemp, CoolingRate, MinTemp,
                    BestState, BestCost, Status, _Iterations).

% solve_annealing(+N, +MaxSteps, +InitialTemp, +CoolingRate, +MinTemp,
%                 -BestState, -BestCost, -Status, -Iterations)
% Status es uno de:
%   solved        -> BestCost = 0, BestState es una solución válida.
%   limit_reached -> se hicieron MaxSteps iteraciones sin llegar a 0.
%   cooled_down   -> la temperatura bajó a MinTemp sin llegar a 0.
% Iterations es la cantidad de vecinos evaluados.
% El predicado es determinista: produce exactamente una respuesta.
solve_annealing(N, MaxSteps, InitialTemp, CoolingRate, MinTemp,
                BestState, BestCost, Status, Iterations) :-
    must_be(positive_integer, N),
    must_be(nonneg, MaxSteps),
    positive_number(initial_temp, InitialTemp),
    positive_number(min_temp, MinTemp),
    must_be(number, CoolingRate),
    (   CoolingRate > 0, CoolingRate < 1
    ->  true
    ;   domain_error(cooling_rate_between_0_and_1, CoolingRate)
    ),
    random_state(N, Initial),
    cost(Initial, InitialCost),
    anneal(Initial, InitialCost, Initial, InitialCost, InitialTemp,
           params(MaxSteps, CoolingRate, MinTemp), 0,
           BestState, BestCost, Status, Iterations).

positive_number(Name, X) :-
    must_be(number, X),
    (   X > 0 -> true ; domain_error(positive(Name), X) ).

% Estado aleatorio: cada columna recibe una fila al azar en 1..N.
random_state(N, State) :-
    length(State, N),
    maplist(random_row(N), State).

random_row(N, Row) :-
    random_between(1, N, Row).

% cost(+State, -Cost)
% Cuenta parejas de reinas que se atacan (misma fila o misma
% diagonal). Al exigir C2 > C1, cada pareja se cuenta una sola vez.
cost(State, Cost) :-
    aggregate_all(count, attacking_pair(State), Cost).

attacking_pair(State) :-
    nth1(C1, State, R1),
    nth1(C2, State, R2),
    C2 > C1,
    (   R1 =:= R2
    ->  true
    ;   abs(R1 - R2) =:= C2 - C1
    ).

% neighbor(+State, -Neighbor)
% Elige una columna al azar y mueve su reina a otra fila distinta.
% Así el vecino siempre difiere del estado actual. Para N = 1 no hay
% otra fila posible y el vecino es el mismo estado.
neighbor([Row], [Row]) :- !.
neighbor(State, Neighbor) :-
    length(State, N),
    random_between(1, N, Column),
    nth1(Column, State, OldRow),
    N1 is N - 1,
    random_between(1, N1, Pick),
    % Pick en 1..N-1 se traslada para saltar OldRow.
    (   Pick >= OldRow -> NewRow is Pick + 1 ; NewRow = Pick ),
    replace_nth1(Column, State, NewRow, Neighbor).

replace_nth1(1, [_|Tail], Value, [Value|Tail]) :- !.
replace_nth1(Index, [Head|Tail], Value, [Head|Result]) :-
    Index > 1,
    Next is Index - 1,
    replace_nth1(Next, Tail, Value, Result).

% anneal(+State, +Cost, +Best, +BestCost, +Temp, +Params, +Step,
%        -FinalBest, -FinalBestCost, -Status, -Iterations)
% Las condiciones de parada se revisan en este orden:
%   1. costo 0 -> solved
%   2. Step = MaxSteps -> limit_reached
%   3. Temp =< MinTemp -> cooled_down
% El if-then-else hace que solo una rama se ejecute (sin respuestas
% extra al pedir alternativas).
anneal(State, Cost, Best, BestCost, Temp, Params, Step,
       FinalBest, FinalBestCost, Status, Iterations) :-
    Params = params(MaxSteps, Cooling, MinTemp),
    (   BestCost =:= 0
    ->  FinalBest = Best, FinalBestCost = 0,
        Status = solved, Iterations = Step
    ;   Step >= MaxSteps
    ->  FinalBest = Best, FinalBestCost = BestCost,
        Status = limit_reached, Iterations = Step
    ;   Temp =< MinTemp
    ->  FinalBest = Best, FinalBestCost = BestCost,
        Status = cooled_down, Iterations = Step
    ;   neighbor(State, Candidate),
        cost(Candidate, CandidateCost),
        Delta is CandidateCost - Cost,
        (   accept_move(Delta, Temp)
        ->  NextState = Candidate, NextCost = CandidateCost
        ;   NextState = State,     NextCost = Cost
        ),
        (   NextCost < BestCost
        ->  NextBest = NextState, NextBestCost = NextCost
        ;   NextBest = Best,      NextBestCost = BestCost
        ),
        NextTemp is Temp * Cooling,
        NextStep is Step + 1,
        anneal(NextState, NextCost, NextBest, NextBestCost, NextTemp,
               Params, NextStep, FinalBest, FinalBestCost,
               Status, Iterations)
    ).

% accept_move(+Delta, +Temp)
% Si el movimiento no empeora (Delta =< 0) se acepta siempre.
% Si empeora, se acepta con probabilidad exp(-Delta / Temp).
accept_move(Delta, _) :-
    Delta =< 0,
    !.
accept_move(Delta, Temp) :-
    Probability is exp(-Delta / Temp),
    random(Random),
    Random < Probability.
