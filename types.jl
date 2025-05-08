module Types

export Component, Program, WhiteSpace, Comment, Parens, Text, addToLine

#=
    Declare Datatypes
    - Whitespace: space, tab, newline
    - Comments
        - Single line: ;; ...
        - Multi line: #| ... |#
    - Constructs:
        - deflayer: \(deflayer ...* \)
        - defalias: \(defalias (\n id \( ...* \))* \)
=#

debug = false

abstract type Component end

mutable struct Program
    parts :: AbstractArray{<:Component}
end

function Base.show(io::IO, p::Program)
    if debug print(io, "Program (") end
    for part in p.parts
        print(io, part)
    end
    if debug println(io, ")") end
end

mutable struct WhiteSpace<:Component
    contents :: AbstractString
end

function Base.show(io::IO, w::WhiteSpace)
    if debug print(io, "WhiteSpace (") end
    print(io, w.contents)
    if debug println(io, ")") end
end

struct Comment<:Component
    contents :: AbstractString
end

function Base.show(io::IO, c::Comment)
    if debug print(io, "Comment (") end
    print(io, c.contents)
    if debug println(io, ")") end
end

mutable struct Parens<:Component
    name :: AbstractString
    parts :: AbstractArray{<:Component}
    after :: WhiteSpace
end
function Parens(name::AbstractString, parts::AbstractArray{<:Component})
    return Parens(name, parts, WhiteSpace(""))
end

function Base.show(io::IO, p::Parens)
    if debug print(io, "Parens") end
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

mutable struct Text<:Component
    text :: AbstractString
    after :: WhiteSpace
end
function Text(text::AbstractString)
    return Text(text, WhiteSpace(""))
end

function Base.show(io::IO, c::Text)
    if debug print(io, "Text (") end
    print(io, c.text)
    if !isnothing(c.after)
        print(io, c.after)
    end
    if debug println(io, ")") end
end

function addToLine(w::WhiteSpace, s::AbstractString)
    if contains(s, "\n")
       w.contents = s
    else
        w.contents *= s
    end
end

end
