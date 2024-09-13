# Action Cable 8 playground

This is a support project for the Action Server adapterization happening here: [rails/rails#50979][the-pr].

This project contains examples, tests and benchmarks aiming to ensure that the refactoring goes well and brings the promised benefits.

## Usage

Install the dependencies:

```sh
bundle install
```

NOTE: You can use local dependencies (Rails, AnyCable) either by following path conventions or by providing `.xxx-path` files (see the Gemfile).

Now you should be able to run a minimal Action Cable application via one of the supported web servers. By default, Puma is used:

```sh
$ bundle exec bento

⚡️ Running Action Cable via puma

[18378] Puma starting in cluster mode...

...
```

Other servers:

```sh
# AnyCable

$ bundle exec bento --anycable

⚡️ Running Action Cable via anycable

2024-09-13 10:07:54.272 INF Starting AnyCable 1.5.3-56288f0 (pid: 37818, open file limit: 122880, gomaxprocs: 8) nodeid=NFoelH

...
```

## Tests

### Smoke tests

You can run basic smoke tests via [wsdirector][] as follows (NOTE: the server must be running):

```sh
# The default scenario is echo
$ make wsdirector

10 clients, 0 failures

# Run broadcast scenario
$ SCENARIO=broadcast make wsdirector

Group publisher: 10 clients, 0 failures
Group listener: 20 clients, 0 failures

# You can specify the scale factor, too (default: 10)
$ SCALE=20 SCENARIO=broadcast make wsdirector

Group publisher: 20 clients, 0 failures
Group listener: 40 clients, 0 failures

```

### Conformance tests

We use [AnyT][] to run Action Cable conformance tests. We use make files to encapsulate difference between different server configurations, for example:

```sh
$ make anyt-puma

Starting AnyT v1.4.0 (pid: 21243)

Subscription aknowledgement
  Client receives subscription confirmation                       PASS (0.52s)

Subscription aknowledgement
  Client receives subscription rejection                          PASS (0.51s)

...

32 tests, 80 assertions, 0 failures, 0 errors, 1 skips
```

You can run specific tests by name via the `ANYT_FILTER_TESTS=<query>` env var. To see all scenarios, run `bundle exec anyt -l`.

[the-pr]: https://github.com/rails/rails/pull/50979
[wsdirector]: https://github.com/palkan/wsdirector
[AnyT]: https://github.com/anycable/anyt
