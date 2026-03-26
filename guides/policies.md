# Policies

`nova_auth_policy` provides composable authorization policies for use with
`nova_resource`. Each policy returns a map with an action and a condition
function that evaluates an actor.

## Available Policies

### allow_authenticated

Allow any non-undefined actor:

```erlang
nova_auth_policy:allow_authenticated()
```

### allow_role

Allow actors whose `role` field matches:

```erlang
nova_auth_policy:allow_role(admin)
nova_auth_policy:allow_role([admin, moderator])
```

### allow_claim

Allow actors with a specific claim value. Works with both single-valued and
list-valued claims:

```erlang
%% Actor has role => admin
nova_auth_policy:allow_claim(role, admin)

%% Actor has role in [admin, editor]
nova_auth_policy:allow_claim(role, [admin, editor])

%% Actor has roles => [admin, user] (list-valued claim)
nova_auth_policy:allow_claim(roles, admin)
%% Checks if admin is in the actor's roles list
```

This is useful with OIDC providers like Authentik that include group
memberships as list claims.

### allow_owner

Allow actors who own the record. For read operations, returns a query filter.
For write operations, checks the owner field:

```erlang
nova_auth_policy:allow_owner(user_id)
```

### deny_all

Deny unconditionally:

```erlang
nova_auth_policy:deny_all()
```

## Usage with nova_resource

```erlang
-module(my_resource).
-behaviour(nova_resource).

policies() ->
    [
        nova_auth_policy:allow_role(admin),
        nova_auth_policy:allow_owner(user_id)
    ].
```

## Combining allow_claim with OIDC

When using Authentik or similar providers with claims mapping:

```erlang
%% In your OIDC config
claims_mapping => #{
    ~"sub" => id,
    ~"email" => email,
    ~"groups" => roles    %% Authentik groups mapped to roles
}

%% In your resource
policies() ->
    [nova_auth_policy:allow_claim(roles, ~"admins")].
```

The `allow_claim` policy checks if `~"admins"` is in the actor's `roles`
list, which was populated from Authentik's `groups` claim via the mapping.
