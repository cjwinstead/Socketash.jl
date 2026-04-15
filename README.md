# Socketash: a simple interface for Sockets

Expose Julia functions to a network socket; essentially a convenience
wrapper for Sockets.  The motivation is to deploy Julia modules as
backend services so that functions aren't frequently re-compiled.

Each exposed function must accept a String input and return a String
output. Functions are "registered" using a Dict{String,Function} which
is passed to the server at launch.

On the client side, a connection is opened for a single
transaction. The client sends one line with the command name
(i.e. function), then a string argument (can be multi-line), concluded
by a final line with `//EOF`.

## Builtin Commands

At present, the server always registers one "built-in" command, 
`Socketash.ping` which ignores its input argument and always 
responds with the string "hello". This is used to verify that a 
server is alive and listening. 


## Registering Functions and Modules

A "command dictionary" is used to define server functionality. Usually
it's convenient to organize functions into a module and then register
all of the exported functions like so:

```julia
using Socketash, MyModule

command_dictionary = Socketash.register_module(MyModule)
Socketash.start_server(command_dictionary;PORT=1234)
```

The server now recognizes command strings of the form
`MyModule.function_name`.

If you want to register a subset of commands, you can make a "wrapper"
module that only exports the desired commands from
`MyModule`. Alternatively, you can register individual functions:

```julia
using Socketash

function f(s::String)
   return string("example with argument ",s)
end

command_dictionary=Dict{String,Function}()

# The function name should be passed as a Symbol
Socketash.register_function!(command_dictionary,:f)
Socketash.start_server(command_dictionary;PORT=1234)
```

## Security Considerations

A Socketash application should usually be isolated to the local host. Any exposure to
the outside network should be done with a secure proxy layer. 


## Example Client/Server

### Backend with Socketash

```julia
using Socketash, Logging

logger = ConsoleLogger(stderr,Logging.Debug)

function strlen(s::String)
  "$(length(strip(s)))"
end

d = Dict{String,Function}(
	"strlen" => strlen,
	"uppercase" => uppercase
	)

with_logger(logger) do
    start_server(d;PORT=5432)
end
```

The server will shut down when julia exits, so it should run in an interactive or otherwise persistent instance of julia.


## Frontend with Bash

This frontend example uses `bash` with the `nc` command. The `bash` script accepts two arguments, the 
command string and the command argument.

```bash
#!/bin/bash
PORT=5432

if [ $# != 2 ]; then
    printf "    Usage:     $0 command argument\n"
    exit 1
fi

# Check is server is listening
printf "Socketash.ping\n\n//EOF\n" | nc localhost $PORT > /dev/null
if [ $? != 0 ]; then
    printf "Server not listening\n"
    exit 1
fi


if [ $1 == "uppercase" ]; then
    printf "uppercase\n%s\n//EOF\n" "$2" | nc localhost $PORT
elif [ $1 == "strlen" ]; then
    printf "strlen\n%s\n//EOF\n" "$2" | nc localhost $PORT
fi
```



