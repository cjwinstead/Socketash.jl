using Socketash
using Sockets
using Test

hello = function(s::String) 
    string("hello ",s)
end
goodbye = function(s::String) 
    string("goodbye ",s)
end
d=Dict{String,Function}(
    "hello"=>hello,
    "goodbye"=>goodbye)
Socketash.start_server(d;PORT=1818,dieafter=true)
Socketash.start_server(d;PORT=1999,dieafter=true)
Socketash.start_server(d;PORT=2323,dieafter=true)

@testset "Socketash.jl" begin    


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
