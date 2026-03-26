# Claims Mapping

`nova_auth_claims` transforms provider-specific claims (OIDC userinfo, JWT
claims, SAML attributes) into actor maps that work with nova_auth's policies
and security callbacks.

## Static Mapping

A static mapping is a map from binary claim keys to atom actor keys:

```erlang
Mapping = #{
    ~"sub" => id,
    ~"email" => email,
    ~"name" => display_name,
    ~"groups" => roles
},

Claims = #{
    ~"sub" => ~"abc123",
    ~"email" => ~"user@example.com",
    ~"name" => ~"Jane Doe",
    ~"groups" => [~"admins", ~"developers"]
},

Actor = nova_auth_claims:map(Mapping, Claims).
%% => #{id => ~"abc123", email => ~"user@example.com",
%%       display_name => ~"Jane Doe", roles => [~"admins", ~"developers"]}
```

Missing claims are skipped (no error, no `undefined` values):

```erlang
nova_auth_claims:map(#{~"sub" => id, ~"phone" => phone}, #{~"sub" => ~"123"}).
%% => #{id => ~"123"}
%% phone is not in the result because the claim was missing
```

## Callback Mapping

For complex transformations, use a `{Module, Function}` tuple:

```erlang
-module(my_claims).
-export([map_authentik/1]).

map_authentik(Claims) ->
    Groups = maps:get(~"groups", Claims, []),
    Role = case lists:member(~"admins", Groups) of
        true -> admin;
        false -> user
    end,
    #{
        id => maps:get(~"sub", Claims),
        email => maps:get(~"email", Claims, undefined),
        role => Role,
        groups => Groups
    }.
```

Use it in your config:

```erlang
%% In nova_auth_oidc config
claims_mapping => {my_claims, map_authentik}
```

## Merging with a Base Map

`nova_auth_claims:map/3` merges mapped claims into an existing map:

```erlang
Base = #{provider => authentik},
Mapping = #{~"sub" => id, ~"email" => email},
Claims = #{~"sub" => ~"abc123", ~"email" => ~"user@example.com"},

nova_auth_claims:map(Mapping, Claims, Base).
%% => #{provider => authentik, id => ~"abc123", email => ~"user@example.com"}
```

New keys overwrite existing ones in the base map.

## Provider-Specific Claim Examples

### Authentik

```erlang
#{
    ~"sub" => id,
    ~"email" => email,
    ~"name" => display_name,
    ~"preferred_username" => username,
    ~"groups" => roles
}
```

### Google

```erlang
#{
    ~"sub" => id,
    ~"email" => email,
    ~"name" => display_name,
    ~"picture" => avatar_url
}
```

### Keycloak

```erlang
#{
    ~"sub" => id,
    ~"email" => email,
    ~"preferred_username" => username,
    ~"realm_access" => realm_access
}
```

For Keycloak's nested `realm_access.roles`, use a callback mapping to extract
the roles list.
