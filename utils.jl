module Utils

export Type, Value, Name, setTypes, setVars, setFuncs, getCombinations, intersperse, sub_layer!, sub_alias!, getComboName

import ..Types as TP

# Declare types
Type = String
Value = String
Name = String

function setTypes(parens::TP.Parens)
    types = Dict{Type, Array{Value}}()
    for entry in parens.parts
        if typeof(entry) != TP.Parens
            continue
        end

        type = entry.name
        values = Value[]

        for value in entry.parts
            push!(values, value.text)
        end

        types[type] = values
    end
    return types
end

function setVars(parens::TP.Parens)
    vars = Dict{Name, Type}()
    for entry in parens.parts
        if typeof(entry) != TP.Parens
            continue
        end

        vars[entry.name] = entry.parts[1].text
    end
    return vars
end

function setFuncs(parens::TP.Parens)
    funcs = Dict{Name, Dict{Name, Value}}()
    for entry in parens.parts
        if typeof(entry) != TP.Parens
            continue
        end
        func = entry.name
        mappings = Dict{Name, Value}()
        for mapping in entry.parts
            if typeof(mapping) != TP.Parens
                continue
            end
            var = mapping.name
            val = mapping.parts[1].text
            mappings[var] = val
        end
        funcs[func] = mappings
    end
    return funcs
end

function intersperse(a::Array{T}, e::T) where T
    return vcat(collect(Iterators.flatmap(x -> T[x, e], a[begin:end-1])), a[end])::Array{T}
end

function sub_layer!(part::TP.Parens, combo::Array{Value}, varOrder::Array{Name}, funcs::Dict{Name, Dict{Name, Value}})
    baseName = part.parts[1].text
    # Rename part
    part.parts[1].text = getComboName(baseName, combo)
    for subPart in part.parts[2:end]
        if typeof(subPart) == TP.Text
            varIdx = findfirst(x -> x == subPart.text, varOrder)
            if !isnothing(varIdx)
                subPart.text = combo[varIdx]
            elseif haskey(funcs, subPart.text)
                subPart.text = "(layer-switch $(getComboName(baseName, combo, varOrder, funcs[subPart.text])))"
            elseif startswith(subPart.text, '@')
                subPart.text = getComboName(subPart.text, combo)
            end
        elseif typeof(subPart) == TP.Parens
            sub_parens!(subPart, combo, varOrder, funcs)
        end
    end
end

function sub_alias!(part::TP.Parens, combos::Array{Array{Value}}, varOrder::Array{Name}, funcs::Dict{Name, Dict{Name, Value}})
    i, j = 1, 2
    while j <= length(part.parts)
        name = part.parts[i]
        alias = part.parts[j]
        deleteat!(part.parts, i)
        deleteat!(part.parts, i)
        
        # TODO: only make multiple copies if alias refers to variables or layers
        # This would be a lot of work, since then everything referring to an alias would need to know if the alias is parameterized
        # What might work is processing all the aliases before all the layers

        for combo in combos
            newName = TP.Text(getComboName(name.text, combo), name.after)
            insert!(part.parts, i, newName)
            newAlias = deepcopy(alias)
            newAlias.after = TP.WhiteSpace("\n  ")
            if typeof(newAlias) == TP.Parens
                sub_parens!(newAlias, combo, varOrder, funcs)
            end
            insert!(part.parts, j, newAlias)
            i += 2; j += 2
        end
        part.parts[end].after = TP.WhiteSpace("\n")
    end
end

function sub_parens!(part::TP.Parens, combo::Array{Value}, varOrder::Array{Name}, funcs::Dict{Name, Dict{Name, Value}})
    if part.name == "layer-switch"
        part.parts[1].text = getComboName(part.parts[1].text, combo)
        return
    end
    for subPart in part.parts
        if typeof(subPart) == TP.Text
            varIdx = findfirst(x -> x == subPart.text, varOrder)
            if !isnothing(varIdx)
                subPart.text = combo[varIdx]
            elseif haskey(funcs, subPart.text)
                subPart.text = "(layer-switch $(getComboName(baseName, combo, varOrder, funcs[subPart.text])))"
            elseif startswith(subPart.text, '@')
                subPart.text = getComboName(subPart.text, combo)
            end
        elseif typeof(subPart) == TP.Parens
            sub_parens!(subPart, combo, varOrder, funcs)
        end
    end
end

function getCombinations(types::Dict{Type, Array{Value}}, vars::Dict{Name, Type}, varOrder::Array{Name})::Array{Array{String}}
    #TODO: take in functions too in order to only return combinations that can be reached
    if length(varOrder) == 0
        return [[]]
    end
    if length(varOrder) == 1
        var = varOrder[1]
        return [[val] for val in types[vars[var]]]
    end
    currCombos = getCombinations(types, vars, [varOrder[1]])
    nextCombos = getCombinations(types, vars, varOrder[2:end])

    return [vcat(currCombo, nextCombo) for currCombo in currCombos for nextCombo in nextCombos]
end

function getComboName(baseName::Name, combo::Array{String})
    return baseName * reduce(*, intersperse(combo, ","))
end

function getComboName(baseName::Name, combo::Array{Value}, varOrder::Array{Name}, mapping::Dict{Name, Value})
    newCombo = copy(combo)
    for i in eachindex(newCombo)
        if haskey(mapping, varOrder[i])
            newCombo[i] = mapping[varOrder[i]]
        end
    end
    return getComboName(baseName, newCombo)
end

end