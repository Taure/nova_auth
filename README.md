# Nova Auth

Authentication library for the [Nova](https://github.com/novaframework/nova) ecosystem.

Session-based authentication with PBKDF2-SHA256 password hashing, token lifecycle management, rate limiting, and policy helpers — everything needed to add auth to a Nova application without duplicating logic across projects.

## Features

- **PBKDF2-SHA256 hashing** — Secure password hashing using OTP's `crypto` module with 600,000 iterations. No NIF dependencies.
- **Session tokens** — Generate, validate, and revoke database-backed session tokens via Kura.
- **Rate limiting** — Nova plugin with configurable sliding-window rate limiting (ETS-backed).
- **Email confirmation** — Token-based email confirmation flow.
- **Password reset** — Token-based password reset flow with configurable expiry.
- **Security callback** — Drop-in Nova security function for protecting route groups.
- **Policy helpers** — Composable authorization policies for nova_resource (role-based, ownership, authenticated).
- **Timing-safe** — Dummy verification on failed lookups to prevent user enumeration.

## Quick Start

Add `nova_auth` to your deps:

```erlang
{deps, [
    {nova_auth, {git, "https://github.com/novaframework/nova_auth.git", {branch, "main"}}}
]}.
```

Create a config module:

```erlang
-module(my_auth_config).
-behaviour(nova_auth).
-export([config/0]).

config() ->
    #{
        repo => my_repo,
        user_schema => my_user,
        token_schema => my_user_token
    }.
```

Protect routes:

```erlang
#{prefix => <<"/api">>,
  security => nova_auth_security:require_authenticated(my_auth_config),
  routes => [
      {<<"/me">>, fun my_user_controller:show/1, #{methods => [get]}}
  ]}
```

Register and authenticate:

```erlang
%% Register
{ok, User} = nova_auth_accounts:register(
    my_auth_config, fun my_user:registration_changeset/2, Params
).

%% Authenticate
{ok, User} = nova_auth_accounts:authenticate(
    my_auth_config, <<"user@example.com">>, <<"password123456">>
).

%% Session token
{ok, Token} = nova_auth_session:generate_session_token(my_auth_config, User).
```

## Configuration

All options with defaults:

| Option | Default | Description |
|--------|---------|-------------|
| `repo` | *required* | Kura repo module |
| `user_schema` | *required* | Kura user schema module |
| `token_schema` | *required* | Kura token schema module |
| `user_identity_field` | `email` | Field used for login lookup |
| `user_password_field` | `hashed_password` | Field storing the password hash |
| `session_validity_days` | `14` | Days before session tokens expire |
| `confirm_validity_days` | `3` | Days before confirmation tokens expire |
| `reset_validity_hours` | `1` | Hours before reset tokens expire |
| `hash_algorithm` | `pbkdf2_sha256` | Password hashing algorithm |
| `token_bytes` | `32` | Random bytes for token generation |

## Rate Limiting

Add as a Nova plugin to any route group:

```erlang
#{prefix => <<"/api">>,
  plugins => [
      {pre_request, nova_auth_rate_limit, #{
          max_requests => 10,
          window_seconds => 60
      }}
  ],
  routes => [...]}
```

## Scaffolding

Use `rebar3 nova gen_auth` to generate schemas, controllers, and a config module that delegates to nova_auth.

## Requirements

- Erlang/OTP 27+
- PostgreSQL (via Kura + pgo)

## License

MIT
