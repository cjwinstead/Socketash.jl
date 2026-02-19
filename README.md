# Socketash: a simple interface for Sockets

Expose Julia functions to a network socket; essentially a convenience wrapper for Sockets. 

Each function must accept a String input and return a String output. Functions are "registered" using a Dict{String,Function} which is passed to the server at launch.

On the client side, a connection is opened for a single transaction. The client sends one line with the command name (i.e. function), then a string argument (can be multi-line), concluded by a final line with `//EOF`.

## Example

```julia
using Socketash

function strlen(s::String)
  "$(length(s))"
end

d = Dict{String,Function}(
	"strlen" => strlen,
	"uppercase" => uppercase
	)

start_server(d;PORT=2121)
```

The server will shut down when julia exits, so it should run in an interactive or otherwise persistent instance of julia.


## Bash front-end example

Frontend example using `bash` with `nc`:

```bash
(echo "uppercase"
 echo "abc"
 echo "//EOF") | nc localhost 2121
```

or a more compact request:

```bash
printf "uppercase\nabc\n//EOF" | nc localhost 2121
```



