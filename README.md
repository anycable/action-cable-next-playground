# Action Cable 8 playground

This is a support project for the Action Server adapterization happening here: [rails/rails#50979][the-pr].

This project contains examples, tests and benchmarks aiming to ensure that the refactoring goes well and brings the promised benefits.

## Requirements

- Ruby 3.1+
- Redis (we test all implementations with Redis pub/sub adapters)

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

# Iodine
$ bundle exec bento --iodine

⚡️ Running Action Cable via iodine

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

## Benchmarks

The primary purpose of running benchmarks within this repo is to ensure there is no degradation (and no hidden problems occur at higher loads). We use two benchmarking tools: [websocket-bench][] and [k6][] (with the [xk6-cable][] plugin).

Example runs:

```sh
# First, start a server
bundle exec bento --puma

# Then, from another terminal session
make websocket-bench

# or
make k6
```

To run a Rails server using a stable Rails version (7.2), use the following command:

```sh
RAILS_VERSION=7 bundle exec bento --puma
```

Example results:

```sh
================= websocket-bench ====================

# bundle exec bento --puma
clients:   200    95per-rtt:  65ms    min-rtt:   2ms    median-rtt:  26ms    max-rtt:  89ms
clients:   400    95per-rtt: 151ms    min-rtt:   1ms    median-rtt:  43ms    max-rtt: 247ms
clients:   600    95per-rtt: 211ms    min-rtt:   1ms    median-rtt:  66ms    max-rtt: 267ms
clients:   800    95per-rtt: 243ms    min-rtt:   1ms    median-rtt:  94ms    max-rtt: 458ms
clients:  1000    95per-rtt: 683ms    min-rtt:   0ms    median-rtt:  88ms    max-rtt: 977ms
clients:  1200    95per-rtt: 726ms    min-rtt:   1ms    median-rtt: 119ms    max-rtt: 1460ms
clients:  1400    95per-rtt: 657ms    min-rtt:   1ms    median-rtt: 172ms    max-rtt: 1129ms
clients:  1600    95per-rtt: 628ms    min-rtt:   0ms    median-rtt: 181ms    max-rtt: 1195ms
clients:  1800    95per-rtt: 657ms    min-rtt:   1ms    median-rtt: 198ms    max-rtt: 1338ms
clients:  2000    95per-rtt: 879ms    min-rtt:   0ms    median-rtt: 236ms    max-rtt: 1552ms


# RAILS_VERSION=7 bundle exec bento --puma
clients:   200    95per-rtt:  71ms    min-rtt:   2ms    median-rtt:  23ms    max-rtt:  95ms
clients:   400    95per-rtt: 124ms    min-rtt:   1ms    median-rtt:  50ms    max-rtt: 195ms
clients:   600    95per-rtt: 211ms    min-rtt:   1ms    median-rtt:  66ms    max-rtt: 279ms
clients:   800    95per-rtt: 301ms    min-rtt:   1ms    median-rtt: 103ms    max-rtt: 530ms
clients:  1000    95per-rtt: 313ms    min-rtt:   2ms    median-rtt: 113ms    max-rtt: 499ms
clients:  1200    95per-rtt: 540ms    min-rtt:   0ms    median-rtt: 121ms    max-rtt: 756ms
clients:  1400    95per-rtt: 565ms    min-rtt:   2ms    median-rtt: 121ms    max-rtt: 1917ms
clients:  1600    95per-rtt: 848ms    min-rtt:   1ms    median-rtt: 182ms    max-rtt: 1101ms
clients:  1800    95per-rtt: 734ms    min-rtt:   1ms    median-rtt: 212ms    max-rtt: 940ms
clients:  2000    95per-rtt: 625ms    min-rtt:   1ms    median-rtt: 226ms    max-rtt: 927ms

================= k6 ====================

# bundle exec bento --puma

  ✓ successful connection
  ✓ successful subscription

  acks_rcvd............: 7869    19.019325/s
  broadcast_duration...: avg=38.79ms min=1ms      med=19ms  max=1.76s    p(90)=85ms    p(95)=124ms
  broadcasts_rcvd......: 9058969 21895.472898/s
  broadcasts_sent......: 7869    19.019325/s
  data_received........: 1.3 GB  3.2 MB/s
  data_sent............: 2.1 MB  5.0 kB/s
  rtt..................: avg=21.52ms min=0s       med=2ms   max=1.72s    p(90)=56ms    p(95)=89ms
  ws_connecting........: avg=17.09ms min=621.91µs med=1.8ms max=683.41ms p(90)=43.15ms p(95)=97.4ms
  ws_msgs_received.....: 9127832 22061.914349/s
  ws_msgs_sent.........: 9804    23.696208/s
  ws_sessions..........: 1935    4.676883/s


# RAILS_VERSION=7 bundle exec bento --puma

  ✓ successful connection
  ✓ successful subscription

  acks_rcvd............: 7908    19.056033/s
  broadcast_duration...: avg=27.09ms min=1ms      med=16ms   max=368ms    p(90)=63ms    p(95)=86ms
  broadcasts_rcvd......: 9063601 21840.70347/s
  broadcasts_sent......: 7908    19.056033/s
  data_received........: 1.3 GB  3.2 MB/s
  data_sent............: 2.1 MB  5.0 kB/s
  rtt..................: avg=13.93ms min=0s       med=2ms    max=340ms    p(90)=42ms    p(95)=63ms
  ws_connecting........: avg=12.86ms min=720.45µs med=2.04ms max=361.15ms p(90)=25.64ms p(95)=74.02ms
  ws_msgs_received.....: 9131981 22005.479843/s
  ws_msgs_sent.........: 9855    23.74775/s
  ws_sessions..........: 1947    4.691717/s
```

[the-pr]: https://github.com/rails/rails/pull/50979
[wsdirector]: https://github.com/palkan/wsdirector
[AnyT]: https://github.com/anycable/anyt
[websocket-bench]: https://github.com/anycable/websocket-bench
[k6]: https://k6.io
[xk6-cable]: https://github.com/anycable/xk6-cable
