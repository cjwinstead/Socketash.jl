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
    register_function!(d,"Socketash.ping",Socketash.ping)
    @info "registered commands: " d
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


function ping(s::String)
    return string("hello")
end


#= register_module(module_name::String)

Expose all exported functions from the specified module
as server commands
=#
function register_module(m::Module)
    command_dict = Dict{String,Function}()
    register_module!(command_dict,m)
end

#= register_module(command_dict::Dict,module_name::String)

Expose all exported functions from the specified module
as server commands
=#
function register_module!(command_dict::Dict{String,Function},m::Module)    
    for x in names(m)
        #        if typeof(getfield(m,x)) <: Function
        register_function!(command_dict,m,getfield(m,x))
#        command_dict[string(nameof(m),".",x)]=getfield(m,x)
#        end
    end
    return command_dict
end

function register_function!(command_dict::Dict{String,Function},m::Module,f::Function)
    @info "Registering symbol " f
    command_dict[string(nameof(m),".",f)] = f
end

function register_function!(command_dict::Dict{String,Function},f::Symbol)
    @info "Registering symbol " f
    register_function!(command_dict, string(f), getfield(Main,f))
end

function register_function!(command_dict::Dict{String,Function},fname::String,f::Function)
    @info "Registering symbol " f
    command_dict[fname] = f
end

function register_function!(command_dict::Dict{String,Function},f::Any)
    @info "Ignoring symbol " f
end

function register_function!(command_dict::Dict{String,Function},m::Module,f::Any)
    @info "Ignoring symbol $(f) in module $(m)"
end


export register_function!
export register_module
export register_module!
export ping
export start_server

end
