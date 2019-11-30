-module(generique).

        %% Folding
-export([ bottom_up/2
        , bottom_up/3
        , top_down/2
        , top_down/3

        %% Querying
        , collect/4
        , collect/3

        %% Basic features
        , map/3
        , map_query/3
        ]).

%% Folding
map(_MapType, Fun, X) when is_map(X) ->
  maps:map( fun(_, X1) -> Fun(X1) end
          , X);

map(MapType, Fun, X) when is_tuple(X) ->
  MapType(Fun, X);

map(_MapType, Fun, [X | Xs]) ->
  [Fun(X) | Fun(Xs)];

map(_MapType, Fun, X) ->
  Fun(X).

bottom_up(MapType, Fun, X) ->
  Fun(map( MapType
         , fun(X1) -> bottom_up(MapType, Fun, X1) end
         , X)).

bottom_up(Fun, X) ->
  bottom_up(fun map_arbitrary_tuple/2, Fun, X).

top_down(MapType, Fun, X) ->
  map( MapType
     , fun(X1) -> top_down(MapType, Fun, X1) end
     , Fun(X)).

top_down(Fun, X) ->
  top_down(fun map_arbitrary_tuple/2, Fun, X).


%% Querying
map_query(_MapType, Fun, X) when is_map(X) ->
  map_values(Fun, maps:iterator(X));
map_query(MapType, Fun, X) when is_tuple(X) ->
  MapType(Fun, X);
map_query(_MapType, Fun, [X | Xs]) ->
  [Fun(X) | Fun(Xs)];
map_query(_MapType, _Fun, _X) ->
  [].

collect(MapType, Combine, Fun, X) ->
  lists:foldl( Combine
             , Fun(X)
             , map_query( MapType
                        , fun(X1) -> collect(MapType, Combine, Fun, X1) end
                        , X)).

collect(Combine, Fun, X) ->
  collect( fun map_tuple_to_list/2
            , Combine
            , Fun
            , X).


%% Internal utilities
map_arbitrary_tuple(Fun, X) when is_tuple(X) ->
  list_to_tuple(map_tuple_to_list(Fun, X)).

map_tuple_to_list(Fun, Tuple) when is_tuple(Tuple) ->
  map_tuple_to_list(Fun, Tuple, 1).

map_tuple_to_list(_Fun, Tuple, Index) when Index > size(Tuple) ->
  [];
map_tuple_to_list(Fun, Tuple, Index) ->
  [ Fun(element(Index, Tuple))
  | map_tuple_to_list(Fun, Tuple, Index + 1)
  ].

map_values(Fun, Iter) ->
  case maps:next(Iter) of
    {_K, V, Iter1} ->
      [Fun(V) | map_values(Fun, Iter1)];
    none ->
      []
  end.