module AST

export program

import ..Types as TP
import ..Scanner as SC

function program(s::AbstractString)

    SC.init(s)
    global parts = TP.Component[]
    SC.getSym()

    while !isnothing(SC.sym)
        if typeof(SC.sym) == SC.WhiteSpace
            # push!(parts, TP.WhiteSpace(SC.sym.contents))
        elseif typeof(SC.sym) == SC.Comment
            # push!(parts, TP.Comment(SC.sym.contents))
        elseif typeof(SC.sym) == SC.LParen
            push!(parts, parens())
        else
            SC.mark("Unexpected symbol")
        end
        SC.getSym()
    end

    return TP.Program(parts)
end

function parens()
    parts = TP.Component[]

    SC.getSym()
    if typeof(SC.sym) != SC.Text
        mark("Keyword expected")
    end
    name = SC.sym.text
    SC.getSym()

    while !isnothing(SC.sym) && typeof(SC.sym) != SC.RParen
        if typeof(SC.sym) == SC.WhiteSpace
            # push!(parts, TP.WhiteSpace(SC.sym.contents))
        elseif typeof(SC.sym) == SC.Comment
            # push!(parts, TP.Comment(SC.sym.contents))
        elseif typeof(SC.sym) == SC.Text
            push!(parts, TP.Text(SC.sym.text))
        elseif typeof(SC.sym) == SC.LParen
            push!(parts, parens())
        else
            SC.mark("Unexpected symbol")
        end
        SC.getSym()
    end
    return TP.Parens(name, parts)
end

end