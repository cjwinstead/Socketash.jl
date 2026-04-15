using Socketash
using Sockets
using Test

module a
function howdy(s::String)
    string("howdy ",s)
end
export howdy
end

cmd_dict=register_module(a)

@testset "Socketash: register module" begin
    
    @info "Command Dictionary: " cmd_dict
    @test haskey(cmd_dict,"a.howdy")
    @test !haskey(cmd_dict,"a.a")
    @test typeof(cmd_dict["a.howdy"]) <: Function
    @test string(cmd_dict["a.howdy"]) == "howdy"
end

hello = function(s::String) 
    string("hello ",s)
end
goodbye = function(s::String) 
    string("goodbye ",s)
end
register_function!(cmd_dict,:hello)
register_function!(cmd_dict,:goodbye)

@testset "Socketash: register function" begin
    @info "Command Dictionary: " cmd_dict
    @test haskey(cmd_dict,"hello")
    @test haskey(cmd_dict,"goodbye")
    @test typeof(cmd_dict["hello"]) <: Function
    @test cmd_dict["hello"]("there") == "hello there"
    @test cmd_dict["goodbye"]("now") == "goodbye now"
end

# d=Dict{String,Function}(
#     "hello"=>hello,
#     "goodbye"=>goodbye)

@testset "Socketash: client/server" begin    
    @info "Starting server instances on ports 1818, 1999, 2323"
    Socketash.start_server(cmd_dict;PORT=1818,dieafter=true)
    Socketash.start_server(cmd_dict;PORT=1999,dieafter=true)
    Socketash.start_server(cmd_dict;PORT=2323,dieafter=true)

    @info "Starting clients"
    
    clienta = Sockets.connect(1818)
    clientb = Sockets.connect(1999)
    clientc = Sockets.connect(2323)

    write(clienta,"hello\nsocketash\n//EOF\n")
    sa=read(clienta,String)
    
    @test strip(sa) == "hello socketash"

    # Test concurrency
    write(clientb,"goodbye\n")
    write(clientc,"ping\npong\n\n")
    write(clientb,"Norma Jean\n//EOF\n")
    write(clientc,"//EOF\n")
    
    sb=read(clientb,String)
    sc=read(clientc,String)
    
    @test strip(sb) == "goodbye Norma Jean"    
    @test strip(sc) == "bad command ping"

end
