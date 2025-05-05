module Scanner

export init, getSym, mark, WhiteSpace, Comment, LParen, RParen, Text

abstract type Symbol end

struct WhiteSpace <: Symbol
    contents :: AbstractString
end
struct Comment <: Symbol
    contents :: AbstractString
end
struct LParen <: Symbol end
struct RParen <: Symbol end
struct Text <: Symbol
    text :: AbstractString
end

function getChar()
    global pos, char, nextChar
    if pos > len
        char = nothing
    else
        char = str[pos]
    end
    if pos + 1 > len
        nextChar = nothing
    else
        nextChar = str[pos + 1]
    end
    pos += 1
end

function mark(s::AbstractString)
    brokenCode = str[1:pos]
    line = count(c -> c == '\n', brokenCode)
    position = 0
    if line > 0
        pos - findlast('\n', brokenCode)
    end
    throw("Error at line $line, position $position: $s\nsym = $sym")
end

function init(s::String)
    global str = s
    global len = length(str)
    global pos = 1
    global char = ' '
    global nextChar = ' '
    global sym = nothing
    getChar()
end

function getSym()
    global sym
    if isnothing(char)
        sym = nothing
    elseif isspace(char)
        sym = whitespace()
    elseif (char == ';' && nextChar == ';')
        sym = sComment()
    elseif (char == '#' && nextChar == '|')
        sym = mComment()
    elseif char == '('
        getChar()
        sym = LParen()
    elseif char == ')'
        getChar()
        sym = RParen()
    else
        sym = text()
    end
end

function whitespace()
    start = pos - 1
    while !isnothing(char) && isspace(char)
        getChar()
    end
    return WhiteSpace(str[start:pos-2])
end

function sComment()
    start = pos - 1

    # Assume that first two chars are ";;"
    getChar()
    getChar()
    while !isnothing(char) && char != '\n'
        getChar()
    end
    return Comment(str[start:pos-2])
end

function mComment()
    start = pos - 1
    
    # Assume that first two chars are "#|"
    getChar()
    getChar()
    while !isnothing(char) && !isnothing(nextChar) && (char != '|' || nextChar != '#')
        getChar()
    end
    getChar()
    getChar()
    return Comment(str[start:pos-2])
end

function text()
    start = pos - 1
    while !isnothing(char) && !isspace(char) && char != '(' && char != ')'
        if char == '\\'
            getChar()
        end
        getChar()
    end
    return Text(str[start:pos-2])
end

end