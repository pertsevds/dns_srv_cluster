# DNSSRVCluster

Elixir clustering with DNS SRV records.

## Installation

The package can be installed by adding `dns_srv_cluster` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:dns_srv_cluster, "~> 0.1.0"}
  ]
end
```

Add to your DNS zone your SRV record (https://en.wikipedia.org/wiki/SRV_record):

```sh
_app._tcp.yourdomain.com. 86400 IN SRV 0 10 1234 node1.yourdomain.com.
_app._tcp.yourdomain.com. 86400 IN SRV 0 10 1234 node2.yourdomain.com.
_app._tcp.yourdomain.com. 86400 IN SRV 0 10 1234 node3.yourdomain.com.
_app._tcp.yourdomain.com. 86400 IN SRV 0 10 1234 node4.yourdomain.com.
```

Add to your config files (`config/prod.exs`, `config/dev.exs`):

```elixir
config :dns_srv_cluster,
  query: "_app._tcp.yourdomain.com"
```

Add this to your `rel/env.sh.eex`:

```sh
export RELEASE_DISTRIBUTION="${RELEASE_DISTRIBUTION:-"name"}"
export RELEASE_NODE="${RELEASE_NODE:-"<%= @release.name %>"}"
```

By default, nodes from the same release will have the same cookie. If you want different
applications or releases to connect to each other, then you must set the `RELEASE_COOKIE`,
either in your deployment platform or inside `rel/env.sh.eex`:

```sh
export RELEASE_COOKIE="my-app-cookie"
```

## All configuration options

  * `query` - your DNS SRV record, for example: "_app._tcp.yourdomain.com".
  * `interval` - the millisec interval between DNS queries. Defaults to `5_000`.
  * `connect_timeout` - the millisec timeout to allow discovered nodes to connect. Defaults to `10_000`.


## If you want it in your supervision tree

Do in `mix.exs`:

```elixir
def deps do
  [
    {:dns_srv_cluster, "~> 0.1.0", runtime: false}
  ]
end
```

`runtime: false` will block application from starting.

And use `DNSSRVCluster.Worker` as a child:

```elixir
children = [
  {DNSSRVCluster.Worker, query: "_app._tcp.yourdomain.com"}
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/dns_srv_cluster>.
