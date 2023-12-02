# JOP: an in-memory key value logger
[![Test](https://github.com/bougueil/jop_ex/actions/workflows/ci.yml/badge.svg)](https://github.com/bougueil/jop_ex/actions/workflows/ci.yml)

Logs in memory, spatially and temporally, key value events.<br>
These events, generated by multiple processes, are then flushed to disk for analysis (e.g. to detect locks).


## Installation

Add `jop` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:jop, "~> 0.1"}
  ]
end
```

## Usage
```
  iex> "myjop"
  ...> |> Jop.init()
  ...> |> Jop.log("key_1", :any_term_112)
  ...> |> Jop.log("key_2", :any_term_133)
  ...> |> Jop.flush()
log stored in jop_myjop.2020_05_12_21.42.49_dates.gz
log stored in jop_myjop.2020_05_12_21.42.49_keys.gz
#Jop<myjop:uninitialized>
```

## Performance
Excerpt from a run of the unit test :
```
througput 1267456 logs/s.
```

## Basic example
```
# prepare for logging and return a handle
myjop = Jop.init("myjop")

# log with handle event "key_1", :any_term_112
Jop.log myjop, "key_1", :any_term_112
Process.sleep 12

# clear logs
Jop.clear myjop

Jop.log myjop, "key_2", :any_term_113
Process.sleep 12

Jop.log myjop, "key_1", :any_term_112
Process.sleep 12

Jop.log myjop, "key_2", :any_term_113
# flush to disk and erase the log
Jop.flush myjop

log stored in jop_myjop.2020_05_12_21.42.49_dates.gz
log stored in jop_myjop.2020_05_12_21.42.49_keys.gz
#Jop<myjop:uninitialized>
```
will generate both a temporal (by date) and a spatial (by key) log files:

### Temporal log file
```
# list all operations by date
zcat jop_myjop.2020_05_12_21.42.49_dates.gz

00:00:00_000.482 "key_2": :any_term_113
00:00:00_014.674 "key_1": :any_term_112
00:00:00_028.568 "key_2": :any_term_113

```

### Spatial (by key) log file
```
# list all operations by key :
zcat jop_myjop.2020_05_12_21.42.49_keys.gz

"key_1": 00:00:00_014.674 :any_term_112
"key_2": 00:00:00_000.482 :any_term_113
"key_2": 00:00:00_028.568 :any_term_113
```
## Real life: multiple processes logging
Processes log in myjop as follow:
```
# Handle can be saved in process state
myjop = Jop.ref("myjop")

# Log if logging is activated
Jop.log myjop, "key_1", :any_term_112
```
Console activate / deactivate the logging:
```
# Activate the logging
# Starts the logging
myjop = Jop.init("myjop")

# Do some queries while the logging is on
inspect myjop # see how many records
Enum.count mylog
Enum.member? mylog, "mykey"
 ...

# Flush the logs on disk, keep on logging
Jop.flush myjop, :nostop

# Clear the logs, keep on logging
Jop.clear myjop  # clear all entries and continue logging

# Flush the logs on disk and deactivate the logging
Jop.flush myjop

# Start logging again
Jop.init("myjop")
```