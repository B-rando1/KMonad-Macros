module Types

export Component, Program, WhiteSpace, Parens, Text, addToAfter, componentEquals, componentToString

# Variable to print out extra information
debug = false

abstract type Component end

mutable struct WhiteSpace <: Component
    contents::AbstractString
end

function Base.show(io::IO, w::WhiteSpace)
    if debug
        print(io, "WhiteSpace (")
    end
    print(io, w.contents)
    if debug
        println(io, ")")
    end
end

mutable struct Parens <: Component
    name::AbstractString
    parts::AbstractArray{<:Component}
    after::WhiteSpace
end
function Parens(name::AbstractString, parts::AbstractArray{<:Component})
    return Parens(name, parts, WhiteSpace(""))
end

function Base.show(io::IO, p::Parens)
    if debug
        print(io, "Parens")
    end
    print(io, "($(p.name)")
    if p.name in ["defalias", "defsrc", "defcfg"]
        print(io, "\n  ")
    else
        print(io, " ")
    end
    for part in p.parts
        print(io, part)
    end
    print(io, ")")
    if !isnothing(p.after)
        print(io, p.after)
    end
end

mutable struct Text <: Component
    text::AbstractString
    after::WhiteSpace
end
function Text(text::AbstractString)
    return Text(text, WhiteSpace(""))
end

function Base.show(io::IO, c::Text)
    if debug
        print(io, "Text (")
    end
    print(io, c.text)
    if !isnothing(c.after)
        print(io, c.after)
    end
    if debug
        println(io, ")")
    end
end

# A function to add more whitespace to a whitespace component. Limits whitespace to 1 newline, as this is a good readability heuristic
function addToAfter(w::WhiteSpace, s::AbstractString)
    if contains(s, "\n")
        w.contents = s
    else
        w.contents *= s
    end
end

mutable struct Program
    parts::AbstractArray{Parens}
end

function Base.show(io::IO, p::Program)
    if debug
        print(io, "Program (")
    end
    for part in p.parts
        print(io, part)
    end
    if debug
        println(io, ")")
    end
end

function componentEquals(c1::Component, c2::Component)::Bool
    # Components of different type are not equal,
    # And WhiteSpace components are not equal.
    if typeof(c1) != typeof(c2)
        return false
    end

    if typeof(c1) == WhiteSpace
        return c1.contents == c2.contents
    end

    if typeof(c1) == Text
        return c1.text == c2.text
    end

    if typeof(c1) == Parens
        if c1.name != c2.name || length(c1.parts) != length(c2.parts)
            return false
        end
        for i in 1:length(c1.parts)
            if !(componentEquals(c1.parts[i], c2.parts[i]))
                return false
            end
        end
        return true
    end
end

function componentToString(c::Component)::String
    if typeof(c) == Text
        s = c.text
        # Uncomment when we switch to identifiers:
        # if !isnothing(c.after)
        #     s *= componentToString(c.after)
        # end
        return s
    end
    if typeof(c) == Parens
        s = "($(c.name) "
        for part in c.parts
            s *= componentToString(part)
        end
        s *= ")"
        # Uncomment when we switch to identifiers:
        # if !isnothing(c.after)
        #     s *= componentToString(c.after)
        # end
        return s
    end
    if typeof(c) == WhiteSpace
        return c.contents
    end
    return ""
end

end
