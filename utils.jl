module Utils

export Type, Value, Name, setTypes, setVars, setFuncs, getCombos, sub_layer!, sub_aliases!, getComboName

import ..Types as TP

# Declare types
Type = String
Value = String
Name = String

# Finds a mapping of types to list of allowed values, given a deftypes Parens block
function setTypes(parens::TP.Parens)::Dict{Type,Array{Value}}
    types = Dict{Type,Array{Value}}()
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

# Finds a mapping of variable names to type, given a defvars Parens block
function setVars(parens::TP.Parens)::Dict{Name,Type}
    vars = Dict{Name,Type}()
    for entry in parens.parts
        if typeof(entry) != TP.Parens
            continue
        end

        vars[entry.name] = entry.parts[1].text
    end
    return vars
end

# Finds a mapping of function names to mapping of variables to updated values, given a deffuncs block
function setFuncs(parens::TP.Parens)::Dict{Name,Dict{Name,Value}}
    funcs = Dict{Name,Dict{Name,Value}}()
    for entry in parens.parts
        if typeof(entry) != TP.Parens
            continue
        end
        func = entry.name
        mappings = Dict{Name,Value}()
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

# Given a deflayer block (and lots of other state), substitutes names with their variable-dependent counterpart
function sub_layer!(part::TP.Parens, combo::Array{Value}, varOrder::Array{Name}, funcs::Dict{Name,Dict{Name,Value}})
    baseName = part.parts[1].text
    # Rename part
    part.parts[1].text = getComboName(baseName, combo)
    for subPart in part.parts[2:end]
        currentCombo = copy(combo)
        if typeof(subPart) == TP.Text
            varIdx = findfirst(x -> x == subPart.text, varOrder)
            if !isnothing(varIdx)
                subPart.text = currentCombo[varIdx]
            elseif haskey(funcs, subPart.text)
                fnName = subPart.text
                subPart.text = "(layer-switch $(getComboName(baseName, currentCombo, varOrder, funcs[fnName])))"
                currentCombo = getCombo(currentCombo, varOrder, funcs[fnName])
            elseif startswith(subPart.text, '@')
                subPart.text = getComboName(subPart.text, currentCombo)
            end
        elseif typeof(subPart) == TP.Parens
            currentCombo = sub_parens!(subPart, currentCombo, varOrder, funcs, baseName)
        end
    end
end

# Given a defalias block (and lots of other state), expands each alias declaration
function sub_aliases!(part::TP.Parens, combos::Array{Array{Value}}, varOrder::Array{Name}, funcs::Dict{Name,Dict{Name,Value}})
    i, j = 1, 2
    while j <= length(part.parts)
        name = part.parts[i]
        alias = part.parts[j]
        deleteat!(part.parts, i)
        deleteat!(part.parts, i)

        for combo in combos
            newName = TP.Text(getComboName(name.text, combo), name.after)
            insert!(part.parts, i, newName)
            newAlias = deepcopy(alias)
            newAlias.after = TP.WhiteSpace("\n  ")
            if typeof(newAlias) == TP.Parens
                sub_parens!(newAlias, combo, varOrder, funcs)
            end
            insert!(part.parts, j, newAlias)
            i += 2
            j += 2
        end
        part.parts[end].after = TP.WhiteSpace("\n")
    end
end

# Given a nested Parens block (and lots of other state), substitutes names with their variable-dependent counterpart
function sub_parens!(part::TP.Parens, combo::Array{Value}, varOrder::Array{Name}, funcs::Dict{Name,Dict{Name,Value}}, baseName::Union{String,Nothing}=nothing)::Array{Value}
    if part.name == "layer-switch"
        part.parts[1].text = getComboName(part.parts[1].text, combo)
        return combo
    end
    for subPart in part.parts
        if typeof(subPart) == TP.Text
            varIdx = findfirst(x -> x == subPart.text, varOrder)
            if !isnothing(varIdx)
                subPart.text = combo[varIdx]
            elseif haskey(funcs, subPart.text)
                if (isnothing(baseName))
                    throw("Error: Referenced function inside alias (not supported as of yet)")
                end
                fnName = subPart.text
                subPart.text = "(layer-switch $(getComboName(baseName, combo, varOrder, funcs[fnName])))"
                combo = getCombo(combo, varOrder, funcs[fnName])
            elseif startswith(subPart.text, '@') && subPart.text != "@"
                subPart.text = getComboName(subPart.text, combo)
            end
        elseif typeof(subPart) == TP.Parens
            combo = sub_parens!(subPart, combo, varOrder, funcs, baseName)
        end
    end
    return combo
end

# Finds all combinations of the variables
struct VarFuncInfo
    vars::Array{Name}
    funcs::Set{Name}
end
struct VarsVals
    vars::Array{Name}
    vals::Array{Array{Value}}
end
function getCombos(types::Dict{Type,Array{Value}}, vars::Dict{Name,Type}, varOrder::Array{Name}, funcs::Dict{Name,Dict{Name,Value}})::Array{Array{String}}

    varFuncInfos::Array{VarFuncInfo} = []
    for var in varOrder
        funcsForVar::Set{Name} = Set()
        for func in keys(funcs)
            if var in keys(funcs[func])
                push!(funcsForVar, func)
            end
        end

        match = false
        for varFuncInfo in varFuncInfos
            if issetequal(varFuncInfo.funcs, funcsForVar)
                match = true
                push!(varFuncInfo.vars, var)
            end
        end

        if !match
            varFuncInfo = VarFuncInfo([var], funcsForVar)
            push!(varFuncInfos, varFuncInfo)
        end
    end

    varsVals_list::Array{VarsVals} = []
    for varFuncInfo in varFuncInfos
        varsVals = VarsVals(varFuncInfo.vars, [map(var -> types[vars[var]][1], varFuncInfo.vars)])
        for func in varFuncInfo.funcs
            vals = map(var -> funcs[func][var], varFuncInfo.vars)
            match = false
            for existingVals in varsVals.vals
                if issetequal(existingVals, vals)
                    match = true
                    break
                end
            end
            if !match
                push!(varsVals.vals, vals)
            end
        end
        push!(varsVals_list, varsVals)
    end

    combos = getCombos_rec(varsVals_list)
    realCombos::Array{Array{Value}} = []
    for combo in combos
        realCombo::Array{Value} = []
        for var in varOrder
            varsValsIdxOuter = findfirst(varsVals -> var in varsVals.vars, varsVals_list)
            varsValsIdxInner = findfirst(varsVals_var -> var == varsVals_var, varsVals_list[varsValsIdxOuter].vars)
            push!(realCombo, combo[varsValsIdxOuter][varsValsIdxInner])
        end
        push!(realCombos, realCombo)
    end
    return realCombos
end

function getCombos_rec(varsVals_list::Array{VarsVals})::Array{Array{Array{Value}}}
    if length(varsVals_list) == 0
        return []
    end
    if length(varsVals_list) == 1
        return [[vals] for vals in varsVals_list[1].vals]
    end
    currCombos = getCombos_rec(varsVals_list[1:1])
    nextCombos = getCombos_rec(varsVals_list[2:end])

    return [vcat(currCombo, nextCombo) for currCombo in currCombos for nextCombo in nextCombos]
end

function getCombo(combo::Array{Value}, varOrder::Array{Name}, mapping::Dict{Name,Value})::Array{Value}
    newCombo = copy(combo)
    for i in eachindex(newCombo)
        if haskey(mapping, varOrder[i])
            newCombo[i] = mapping[varOrder[i]]
        end
    end
    return newCombo
end

# Finds the name of a construct, given its base name and the relevant combo
function getComboName(baseName::Name, combo::Array{String})::String
    return baseName * reduce(*, intersperse(combo, ","))
end

# For expanding a function: finds the combo name, given the current layer base name, the current combo, and the variable changes in the function.
function getComboName(baseName::Name, combo::Array{Value}, varOrder::Array{Name}, mapping::Dict{Name,Value})::String
    return getComboName(baseName, getCombo(combo, varOrder, mapping))
end

# Helper function to return an array that is e inserted between each of the elements of a
function intersperse(a::Array{T}, e::T) where T
    if length(a) == 0
        return T[]::Array{T}
    end
    output = T[a[1]]
    if length(a) == 1
        return output::Array{T}
    end
    for v in a[2:end]
        push!(output, e)
        push!(output, v)
    end
    return output::Array{T}
end

end
