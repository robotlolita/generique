Générique
=========

An Erlang library implementing Ralf Lämmel and Simon Peyton Jones [Scrap Your Boilerplate](https://www.microsoft.com/en-us/research/wp-content/uploads/2003/01/hmap.pdf) approach to generic programming over arbitrary data structures.

The library provides `bottom_up` and `top_down` as generalisations of recursive transformations; `collect` as generalisation of recursive querying; and `map` and `map_query` as generalisations of mapping. These are the same combinators described in the aforementioned paper.

## Build

    $ rebar3 compile

## Examples

Let's imagine we have a small functional language, that can be described by the following abstract syntax:

```
Declaration ::=
  {define, atom(), list(atom()), Expr}    -- define x(...) -> Expr

Expr ::=
  {let, atom(), Expr, Expr}     -- let x = Expr in Expr           (binding)
  {if, Expr, Expr, Expr}        -- if Expr then Expr else Expr    (conditional branching)
  {lambda, list(atom()), Expr}  -- fun(...) -> Expr end           (lambda abstraction)
  {apply, Expr, Expr...}        -- Expr(...)                      (function application)
  {int, integer()}              -- 1                              (literal integer)
  {var, atom()}                 -- x                              (variable dereference)
```

So a program like the following:

```
define double(x) = x * x
```

Would have the following AST:

```
[{define, double, [x],
  {apply, '*', [{var, x}, {int, 2}]}}]
```

### Generic transformations

Compilers do many transformations in these ASTs, and it's generally a lot of work to write the recursive functions manually--but more than that, doing so obscures the algorithms, as most of the code is really only taking the structure apart and recursing on parts of it, but not really doing anything *valuable*.

For example, let's say we want to, as an optimisation, change all forms like `x * 2` to `x + x`. With the generic traversals we can simply go for the `bottom_up` transformation:

```
optimise_multiply(Ast) ->
  generique:bottom_up(
    fun({apply, '*', [{var, X}, {int, 2}]}) -> {apply, '+', [{var, X}, {var, X}]};
       ({apply, '*', [{int, 2}, {var, X}]}) -> {apply, '+', [{var, X}, {var, X}]};
       (X) -> X
    end,
    Ast
  ).
```


### Generic queries

Another thing we may want to do is querying information in a tree. Again, writing the recursion manually would lead to a lot of code whose only existence purpose is continuing to reach deeper into the tree, obscuring the intention of the algorithm.

Let's say we want to collect all of the constants in the Ast to allocate them in a separate area. We could use `collect` to write this:

```
collect_constants(Ast) ->
  generique:collect(
    fun({int, X}) -> X;
       (X) -> X
    end,
    Ast
  ).
```

