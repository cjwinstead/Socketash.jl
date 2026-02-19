#= Socketash.jl

A simple server interface using Sockets

=#

module Socketash

using Sockets,Logging



"""
start_server(d::Dict{String,Function};PORT=2121)

Initiate a network socket backend server for the
commands exposed in dictionary d. Each command
should accept a String input and return a String
output (empty Strings allowed).

The client should perform a single transaction
where the first line is the command name,
subsequent lines are the String input, and the
final line is the string //EOF

The server answers with the function's output
String, then closes the connection.
"""
function start_server(d::Dict{String,Function};PORT=2121,dieafter=false)
errormonitor(
    Threads.@spawn begin
        server=listen(PORT)
        alive=true
        while alive
            sock   = accept(server)
            
            Threads.@spawn begin
                s      = String("")
                line   = 1
                cmd    = nothing
                cmdstr = ""
                while isopen(sock)
                    data = readline(sock,keep=true)
                    
                    if line == 1
                        cmdstr = strip(data)
                        @debug "> " cmdstr
                        
                        cmd = get(d,cmdstr,nothing)
                        @info "Command: " cmdstr                    
                    elseif contains(data,"//EOF")
                        @debug "Argument " s
                        if !isnothing(cmd)
                            @info "Running command"
                            m = cmd(s)
                            @debug "Reply " m 
                            write(sock,m)                    
                        else
                            @error "bad command: " cmdstr
                            write(sock,"bad command $(cmdstr)\n")
                        end
                        @info "Closing socket"
                        close(sock)                
                    else
                        @debug "> " data                    
                        s = s*String(data)
                    end

                    line += 1
                end
                alive=!dieafter
            end
        end
        @info "Shutting down server"
    end
        
    )
end

export start_server

end
