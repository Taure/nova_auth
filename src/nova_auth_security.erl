-module(nova_auth_security).
-moduledoc ~"""
Nova security callback for route-level authentication. Returns closures
suitable for use in Nova route security configuration.

Uses the unified actor session (`nova_auth_actor`) so it works with
any auth strategy (password, OIDC, JWT) that stores an actor there.
""".

-export([require_authenticated/0, require_authenticated/1]).

-doc "Return a security fun that checks for any authenticated actor in the session.".
-spec require_authenticated() -> fun((cowboy_req:req()) -> term()).
require_authenticated() ->
    fun require_authenticated/1.

-doc "Check the session for an authenticated actor and return it or 401.".
-spec require_authenticated(cowboy_req:req()) ->
    {true, nova_auth:actor()} | {false, integer(), map(), binary()}.
require_authenticated(Req) ->
    case nova_auth_actor:fetch(Req) of
        {ok, Actor} ->
            {true, Actor};
        {error, not_found} ->
            unauthorized()
    end.

unauthorized() ->
    Body = iolist_to_binary(json:encode(#{~"error" => ~"unauthorized"})),
    {false, 401, #{~"content-type" => ~"application/json"}, Body}.
