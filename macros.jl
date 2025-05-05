include("scanner.jl")
include("types.jl")
include("AST.jl")
include("utils.jl")

import .AST as AST
import .Types as TP
import .Utils as U
using .Utils: Type, Value, Name

file_path = "keymap_test.kbd.tpl"

open(file_path) do file_handle
    global input = read(file_handle, String)
end

# Get the AST
p = AST.program(input);

# Get the types, values, and functions
types = Dict{Type, Array{Value}}()
vars = Dict{Name, Type}()
funcs = Dict{Name, Dict{Name, Value}}()
varOrder::Array{Name} = Name[]

i = 1
while i <= length(p.parts)
    global i
    part = p.parts[i]

    if typeof(part) == TP.WhiteSpace || typeof(part) == TP.Comment
        i += 1
        continue
    end
    
    # Assume Parens
    if part.name == "deftypes"
        merge!(types, U.setTypes(part))
        deleteat!(p.parts, i)
        continue
    elseif part.name == "defvars"
        merge!(vars, U.setVars(part))
        deleteat!(p.parts, i)
        continue
    elseif part.name == "deffuncs"
        merge!(funcs, U.setFuncs(part))
        deleteat!(p.parts, i)
    else
        i += 1
        continue
    end
end

varOrder = collect(keys(vars))

# Verify that variables use valid types and functions use valid types and variables
for (var, type) in pairs(vars)
    if !haskey(types, type)
        throw("Error: variable $var references non-existent type $type")
    end
end

for (func, mappings) in pairs(funcs)
    for (var, val) in pairs(mappings)
        if !haskey(vars, var)
            throw("Error: function $func references non-existent variable $var")
        end
        if !(val in types[vars[var]])
            throw("Error: function $func sets variable $var to invalid value $val")
        end
    end
end

# Make multiple copies of deflayer's
combos = U.getCombinations(types, vars, varOrder)
i = 1
while i <= length(p.parts)
    global i
    part = p.parts[i]

    if typeof(part) == TP.WhiteSpace || typeof(part) == TP.Comment
        i += 1
        continue
    end

    # Assume parens, make copies
    if part.name == "deflayer"
        deleteat!(p.parts, i)
        for combo in combos
            newPart = deepcopy(part)
            U.substitute!(newPart, combo, varOrder, funcs)
            insert!(p.parts, i, newPart)
            i += 1
        end
    # elseif part.name == "defalias"
        # TODO
    else
        i += 1
        continue
    end
end

# Add whitespace back to the program
p_out = TP.Program(TP.Component[])
for part in p.parts[begin:end-1]
    push!(p_out.parts, part)
    if typeof(part) == TP.Parens
        push!(p_out.parts, TP.WhiteSpace("\n\n"))
    else
        push!(p_out.parts, TP.WhiteSpace("\n"))
    end
end
push!(p_out.parts, p.parts[end])

#  Write out file contents
open("keymap_test_output.kbd", "w") do file_handle
    show(file_handle, p_out)
end
