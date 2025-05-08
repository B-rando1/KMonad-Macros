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
        elseif typeof(SC.sym) == SC.Comment
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
    prevPart = nothing

    SC.getSym()
    if typeof(SC.sym) != SC.Text
        mark("Keyword expected")
    end
    name = SC.sym.text
    SC.getSym()

    while !isnothing(SC.sym) && typeof(SC.sym) != SC.RParen
        if typeof(SC.sym) == SC.WhiteSpace
            if !isnothing(prevPart)
                TP.addToLine(prevPart.after, SC.sym.contents)
            end
        elseif typeof(SC.sym) == SC.Comment
        elseif typeof(SC.sym) == SC.Text
            prevPart = TP.Text(SC.sym.text)
            push!(parts, prevPart)
        elseif typeof(SC.sym) == SC.LParen
            prevPart = parens()
            push!(parts, prevPart)
        else
            SC.mark("Unexpected symbol")
        end
        SC.getSym()
    end
    return TP.Parens(name, parts)
end

end
