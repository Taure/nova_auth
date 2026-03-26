-module(nova_auth_claims).
-moduledoc ~"""
Claims mapping engine. Transforms provider-specific claims (e.g., OIDC
userinfo or JWT claims) into nova_auth actor maps. Supports static
key-renaming maps or callback functions for complex transformations.
""".

-export([map/2, map/3]).

-doc """
Map raw claims to an actor map using the given mapping spec.

Static map renames binary claim keys to atom keys:
```
Mapping = #{~"sub" => id, ~"email" => email, ~"groups" => roles},
Claims = #{~"sub" => ~"abc", ~"email" => ~"user@example.com"},
map(Mapping, Claims).
%% => #{id => ~"abc", email => ~"user@example.com"}
```

Callback form allows arbitrary transformation:
```
Mapping = {my_module, map_claims},
map(Mapping, Claims).
%% => my_module:map_claims(Claims)
```
""".
-spec map(Mapping, Claims) -> map() when
    Mapping :: #{binary() => atom()} | {module(), atom()},
    Claims :: map().
map({Mod, Fun}, Claims) when is_atom(Mod), is_atom(Fun) ->
    Mod:Fun(Claims);
map(Mapping, Claims) when is_map(Mapping) ->
    maps:fold(
        fun(ClaimKey, ActorKey, Acc) ->
            case maps:is_key(ClaimKey, Claims) of
                true -> Acc#{ActorKey => maps:get(ClaimKey, Claims)};
                false -> Acc
            end
        end,
        #{},
        Mapping
    ).

-doc "Map raw claims and merge into an existing actor map. New keys overwrite existing ones.".
-spec map(Mapping, Claims, Base) -> map() when
    Mapping :: #{binary() => atom()} | {module(), atom()},
    Claims :: map(),
    Base :: map().
map(Mapping, Claims, Base) ->
    Mapped = map(Mapping, Claims),
    maps:merge(Base, Mapped).
