module Scanner

export init, getSym, mark, WhiteSpace, Comment, LParen, RParen, Text

abstract type Symbol end

# Define datatypes
struct WhiteSpace <: Symbol
    contents::AbstractString
end
struct Comment <: Symbol
    contents::AbstractString
end
struct LParen <: Symbol end
struct RParen <: Symbol end
struct Text <: Symbol
    text::AbstractString
end

#= Starts the scanner. Sets the following values:
- str      : the string representation of the program
- len      : the length of str
- pos      : the current position of the cursor in the program
- char     : the character currently under the cursor, i.e. str[pos]
- nextChar : the character one ahead of the cursor, i.e. str[pos+1]
- sym      : the current symbol processed
=#
function init(s::String)
    global str = s
    global len = length(str)
    global pos = 1
    global char = ' '
    global nextChar = ' '
    global sym = nothing
    getChar()
end

# Throws an error with information about location of the error
function mark(s::AbstractString)
    brokenCode = str[1:pos]
    line = count(c -> c == '\n', brokenCode)
    position = 0
    if line > 0
        pos - findlast('\n', brokenCode)
    end
    throw("Error at line $line, position $position: $s\nsym = $sym")
end

# Gets the next character and updates various state information
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
        nextChar = str[pos+1]
    end
    pos += 1
end

# Gets the next symbol
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

# Finds the contents of a WhiteSpace symbol
function whitespace()::WhiteSpace
    start = pos - 1
    while !isnothing(char) && isspace(char)
        getChar()
    end
    return WhiteSpace(str[start:pos-2])
end

# Finds the contents of a single-line Comment symbol
function sComment()::Comment
    start = pos - 1

    # Assume that first two chars are ";;"
    getChar()
    getChar()
    while !isnothing(char) && char != '\n'
        getChar()
    end
    return Comment(str[start:pos-2])
end

# Finds the contents of a multi-line Comment symbol
function mComment()::Comment
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

# Finds the contents of a Text symbol
function text()::Text
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
