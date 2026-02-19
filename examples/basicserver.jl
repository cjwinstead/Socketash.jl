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
    start_server(d;PORT=2121)
end
