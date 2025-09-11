include("scanner.jl")
include("types.jl")
include("AST.jl")
include("utils.jl")

import .AST as AST
import .Types as TP
import .Utils as U
using .Utils: Type, Value, Name

infile = ARGS[1]
outfile = ARGS[2]

open(infile) do file_handle
    global progText = read(file_handle, String)
end

## Get the AST
p = AST.program(progText);

## Get the types, values, and functions
types = Dict{Type,Array{Value}}()
vars = Dict{Name,Type}()
funcs = Dict{Name,Dict{Name,Value}}()
varOrder::Array{Name} = Name[]

# Loop through the program to find types, vars, and funcs, deleting along the way
i = 1
while i <= length(p.parts)
    global i
    part = p.parts[i]

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

# Used to ensure names add variables in the same order
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

## Make multiple copies of deflayer's and defaliases
combos = U.getCombos(types, vars, varOrder, funcs)
i = 1
while i <= length(p.parts)
    global i
    part = p.parts[i]

    if part.name == "deflayer"
        deleteat!(p.parts, i)
        for combo in combos
            newPart = deepcopy(part)
            U.sub_layer!(newPart, combo, varOrder, funcs)
            insert!(p.parts, i, newPart)
            i += 1
        end
    elseif part.name == "defalias"
        U.sub_aliases!(part, combos, varOrder, funcs)
        i += 1
    else
        i += 1
        continue
    end
end

## Cleanup and output
# Add whitespace back to the program
for part in p.parts[begin:end-1]
    part.after.contents = "\n\n"
end
p.parts[end].after.contents = "\n"

#  Write out file contents
open(outfile, "w") do file_handle
    show(file_handle, p)
end
