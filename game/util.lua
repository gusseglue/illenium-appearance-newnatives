local hashesComputed = false
local PED_TATTOOS = {}
local pedModelsByHash = {}
local resolveComponentVariation
local resolvePropVariation

local DEBUG_CONVAR = "illenium-appearance:debugCollections"

local function isDebugEnabled()
    return Config.Debug or GetConvarInt(DEBUG_CONVAR, 0) == 1
end

local function debugPrint(fmt, ...)
    if not isDebugEnabled() then return end

    local message
    if type(fmt) == "string" then
        if select("#", ...) > 0 then
            message = fmt:format(...)
        else
            message = fmt
        end
    else
        message = tostring(fmt)
    end

    print(("[illenium-appearance] %s"):format(message))
end

local function tofloat(num)
    return num + 0.0
end

local function isPedFreemodeModel(ped)
    local model = GetEntityModel(ped)
    return model == `mp_m_freemode_01` or model == `mp_f_freemode_01`
end

local function computePedModelsByHash()
    for i = 1, #Config.Peds.pedConfig do
        local peds = Config.Peds.pedConfig[i].peds
        for j = 1, #peds do
            pedModelsByHash[joaat(peds[j])] = peds[j]
        end
    end
end

---@param ped number entity id
---@return string
--- Get the model name from an entity's model hash
local function getPedModel(ped)
    if not hashesComputed then
        computePedModelsByHash()
        hashesComputed = true
    end
    return pedModelsByHash[GetEntityModel(ped)]
end

---@param ped number entity id
---@return table<number, table<string, number>>
local function getComponentCollectionInfo(ped, componentId)
    local collection = GetPedDrawableVariationCollectionName(ped, componentId)
    local collectionDrawable = GetPedDrawableVariationCollectionLocalIndex(ped, componentId)

    if type(collectionDrawable) ~= "number" then
        return nil, nil
    end

    return collection, collectionDrawable
end

local function getPedComponents(ped)
    local size = #constants.PED_COMPONENTS_IDS
    local components = table.create(size, 0)

    for i = 1, size do
        local componentId = constants.PED_COMPONENTS_IDS[i]
        local drawable = GetPedDrawableVariation(ped, componentId)
        local texture = GetPedTextureVariation(ped, componentId)
        local collection, collectionDrawable = getComponentCollectionInfo(ped, componentId)
        components[i] = {
            component_id = componentId,
            drawable = drawable,
            texture = texture,
            collection = collection,
            collectionDrawable = collectionDrawable
        }
    end

    return components
end

---@param ped number entity id
---@return table<number, table<string, number>>
local function getPropCollectionInfo(ped, propId)
    local collection = GetPedPropCollectionName(ped, propId)
    local collectionDrawable = GetPedPropCollectionLocalIndex(ped, propId)

    if type(collectionDrawable) ~= "number" then
        return nil, nil
    end

    return collection, collectionDrawable
end

local function getPedProps(ped)
    local size = #constants.PED_PROPS_IDS
    local props = table.create(size, 0)

    for i = 1, size do
        local propId = constants.PED_PROPS_IDS[i]
        local drawable = GetPedPropIndex(ped, propId)
        local texture = GetPedPropTextureIndex(ped, propId)
        local collection, collectionDrawable = nil, nil
        if drawable ~= -1 then
            collection, collectionDrawable = getPropCollectionInfo(ped, propId)
        end
        props[i] = {
            prop_id = propId,
            drawable = drawable,
            texture = texture,
            collection = collection,
            collectionDrawable = collectionDrawable
        }
    end
    return props
end

local function round(number, decimalPlaces)
    return tonumber(string.format("%." .. (decimalPlaces or 0) .. "f", number))
end

---@param ped number entity id
---@return table <number, number>
---```
---{ shapeFirst, shapeSecond, shapeThird, skinFirst, skinSecond, skinThird, shapeMix, skinMix, thirdMix }
---```
local function getPedHeadBlend(ped)
    -- GET_PED_HEAD_BLEND_DATA
    local shapeFirst, shapeSecond, shapeThird, skinFirst, skinSecond, skinThird, shapeMix, skinMix, thirdMix = Citizen.InvokeNative(0x2746BD9D88C5C5D0, ped, Citizen.PointerValueIntInitialized(0), Citizen.PointerValueIntInitialized(0), Citizen.PointerValueIntInitialized(0), Citizen.PointerValueIntInitialized(0), Citizen.PointerValueIntInitialized(0), Citizen.PointerValueIntInitialized(0), Citizen.PointerValueFloatInitialized(0), Citizen.PointerValueFloatInitialized(0), Citizen.PointerValueFloatInitialized(0))

    shapeMix = tonumber(string.sub(shapeMix, 0, 4))
    if shapeMix > 1 then shapeMix = 1 end

    skinMix = tonumber(string.sub(skinMix, 0, 4))
    if skinMix > 1 then skinMix = 1 end

    if not thirdMix then
        thirdMix = 0
    end
    thirdMix = tonumber(string.sub(thirdMix, 0, 4))
    if thirdMix > 1 then thirdMix = 1 end


    return {
        shapeFirst = shapeFirst,
        shapeSecond = shapeSecond,
        shapeThird = shapeThird,
        skinFirst = skinFirst,
        skinSecond = skinSecond,
        skinThird = skinThird,
        shapeMix = shapeMix,
        skinMix = skinMix,
        thirdMix = thirdMix
    }
end

---@param ped number entity id
---@return table<number, table<string, number>>
local function getPedFaceFeatures(ped)
    local size = #constants.FACE_FEATURES
    local faceFeatures = table.create(0, size)

    for i = 1, size do
        local feature = constants.FACE_FEATURES[i]
        faceFeatures[feature] = round(GetPedFaceFeature(ped, i-1), 1)
    end

    return faceFeatures
end

---@param ped number entity id
---@return table<number, table<string, number>>
local function getPedHeadOverlays(ped)
    local size = #constants.HEAD_OVERLAYS
    local headOverlays = table.create(0, size)

    for i = 1, size do
        local overlay = constants.HEAD_OVERLAYS[i]
        local _, value, _, firstColor, secondColor, opacity = GetPedHeadOverlayData(ped, i-1)

        if value ~= 255 then
            opacity = round(opacity, 1)
        else
            value = 0
            opacity = 0
        end

        headOverlays[overlay] = {style = value, opacity = opacity, color = firstColor, secondColor = secondColor}
    end

    return headOverlays
end

---@param ped number entity id
---@return table<string, number>
local function getPedHair(ped)
    local style = GetPedDrawableVariation(ped, 2)
    local texture = GetPedTextureVariation(ped, 2)
    local collection, collectionDrawable = getComponentCollectionInfo(ped, 2)
    return {
        style = style,
        color = GetPedHairColor(ped),
        highlight = GetPedHairHighlightColor(ped),
        texture = texture,
        collection = collection,
        collectionDrawable = collectionDrawable
    }
end

local function getPedDecorationType()
    local pedModel = GetEntityModel(cache.ped)
    local decorationType

    if pedModel == `mp_m_freemode_01` then
        decorationType = "male"
    elseif pedModel == `mp_f_freemode_01` then
        decorationType = "female"
    else
        decorationType = IsPedMale(cache.ped) and "male" or "female"
    end

    return decorationType
end

local function getPedAppearance(ped)
    local eyeColor = GetPedEyeColor(ped)

    return {
        model = getPedModel(ped) or "mp_m_freemode_01",
        headBlend = getPedHeadBlend(ped),
        faceFeatures = getPedFaceFeatures(ped),
        headOverlays = getPedHeadOverlays(ped),
        components = getPedComponents(ped),
        props = getPedProps(ped),
        hair = getPedHair(ped),
        tattoos = client.getPedTattoos(),
        eyeColor = eyeColor < #constants.EYE_COLORS and eyeColor or 0
    }
end

local function setPlayerModel(model)
    if type(model) == "string" then model = joaat(model) end

    if IsModelInCdimage(model) then
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(0) end

        SetPlayerModel(cache.playerId, model)
        Wait(150)
        SetModelAsNoLongerNeeded(model)

        if isPedFreemodeModel(cache.ped) then
            SetPedDefaultComponentVariation(cache.ped)
             -- Check if the model is male or female, then change the face mix based on this.
             if model == `mp_m_freemode_01` then
                SetPedHeadBlendData(cache.ped, 0, 0, 0, 0, 0, 0, 0, 0, 0, false)
            elseif model == `mp_f_freemode_01` then
                SetPedHeadBlendData(cache.ped, 45, 21, 0, 20, 15, 0, 0.3, 0.1, 0, false)
            end
        end

        PED_TATTOOS = {}
        return cache.ped
    end

    return cache.playerId
end

local function setPedHeadBlend(ped, headBlend)
    if headBlend and isPedFreemodeModel(ped) then
        SetPedHeadBlendData(ped, headBlend.shapeFirst, headBlend.shapeSecond, headBlend.shapeThird, headBlend.skinFirst, headBlend.skinSecond, headBlend.skinThird, tofloat(headBlend.shapeMix or 0), tofloat(headBlend.skinMix or 0), tofloat(headBlend.thirdMix or 0), false)
    end
end

local function setPedFaceFeatures(ped, faceFeatures)
    if faceFeatures then
        for k, v in pairs(constants.FACE_FEATURES) do
            SetPedFaceFeature(ped, k-1, tofloat(faceFeatures[v]))
        end
    end
end

local function setPedHeadOverlays(ped, headOverlays)
    if headOverlays then
        for k, v in pairs(constants.HEAD_OVERLAYS) do
            local headOverlay = headOverlays[v]
            SetPedHeadOverlay(ped, k-1, headOverlay.style, tofloat(headOverlay.opacity))

            if headOverlay.color then
                local colorType = 1
                if v == "blush" or v == "lipstick" or v == "makeUp" then
                    colorType = 2
                end

                SetPedHeadOverlayColor(ped, k-1, colorType, headOverlay.color, headOverlay.secondColor)
            end
        end
    end
end

local function applyAutomaticFade(ped, style)
    local gender = getPedDecorationType()
    local hairDecoration = constants.HAIR_DECORATIONS[gender][style]

    if(hairDecoration) then
        AddPedDecorationFromHashes(ped, hairDecoration[1], hairDecoration[2])
    end
end

local function setTattoos(ped, tattoos, style)
    local isMale = client.getPedDecorationType() == "male"
    ClearPedDecorations(ped)
    if Config.AutomaticFade then
        tattoos["ZONE_HAIR"] = {}
        PED_TATTOOS["ZONE_HAIR"] = {}
        applyAutomaticFade(ped, style or GetPedDrawableVariation(ped, 2))
    end
    for k in pairs(tattoos) do
        for i = 1, #tattoos[k] do
            local tattoo = tattoos[k][i]
            local tattooGender = isMale and tattoo.hashMale or tattoo.hashFemale
            for _ = 1, (tattoo.opacity or 0.1) * 10 do
                AddPedDecorationFromHashes(ped, joaat(tattoo.collection), joaat(tattooGender))
            end
        end
    end
    if Config.RCoreTattoosCompatibility then
        TriggerEvent("rcore_tattoos:applyOwnedTattoos")
    end
end

local function setPedHair(ped, hair, tattoos)
    if hair then
        debugPrint(
            "setPedHair request ped=%s style=%s texture=%s collection=%s local=%s",
            ped,
            tostring(hair.style),
            tostring(hair.texture),
            tostring(hair.collection),
            tostring(hair.collectionDrawable)
        )
        local style, texture, collectionName, collectionDrawable = resolveComponentVariation(ped, 2, hair.style, hair.texture, hair.collection, hair.collectionDrawable)

        if type(collectionName) == "string" and type(collectionDrawable) == "number" then
            if IsPedCollectionComponentVariationValid(ped, 2, collectionName, collectionDrawable, texture, 0) then
                SetPedCollectionComponentVariation(ped, 2, collectionName, collectionDrawable, texture, 0)
                debugPrint(
                    "setPedHair applied collection=%s local=%s texture=%s",
                    collectionName,
                    collectionDrawable,
                    texture
                )
            else
                debugPrint(
                    "setPedHair invalid collection=%s local=%s texture=%s – falling back to legacy setter",
                    tostring(collectionName),
                    tostring(collectionDrawable),
                    tostring(texture)
                )
                SetPedComponentVariation(ped, 2, style, texture, 0)
            end
        else
            SetPedComponentVariation(ped, 2, style, texture, 0)
        end

        SetPedHairColor(ped, hair.color, hair.highlight)
        hair.style = GetPedDrawableVariation(ped, 2)
        hair.texture = GetPedTextureVariation(ped, 2)
        hair.collection, hair.collectionDrawable = getComponentCollectionInfo(ped, 2)
        if isPedFreemodeModel(ped) then
            setTattoos(ped, tattoos or PED_TATTOOS, hair.style)
        end
    end
end

local function setPedEyeColor(ped, eyeColor)
    if eyeColor then
        SetPedEyeColor(ped, eyeColor)
    end
end

resolveComponentVariation = function(ped, componentId, drawable, texture, hashOrCollection, collectionOrDrawable, maybeCollectionDrawable)
    debugPrint(
        "resolveComponentVariation start ped=%s component=%s drawable=%s texture=%s hintCollection=%s hintLocal=%s",
        ped,
        componentId,
        tostring(drawable),
        tostring(texture),
        tostring(hashOrCollection),
        tostring(collectionOrDrawable)
    )

    local collection = collectionOrDrawable
    local collectionDrawable = maybeCollectionDrawable

    if maybeCollectionDrawable == nil then
        collection = hashOrCollection
        collectionDrawable = collectionOrDrawable
    end

    local resolvedCollection = type(collection) == "string" and collection or nil
    local resolvedLocalDrawable = type(collectionDrawable) == "number" and collectionDrawable or nil

    local requestedDrawable = type(drawable) == "number" and drawable or nil
    if requestedDrawable ~= nil and requestedDrawable < 0 then
        requestedDrawable = nil
    end

    local needsLookup = false

    if resolvedCollection ~= nil and resolvedLocalDrawable ~= nil and requestedDrawable ~= nil then
        local hintedGlobal = GetPedDrawableGlobalIndexFromCollection(
            ped,
            componentId,
            resolvedCollection,
            resolvedLocalDrawable
        )

        if type(hintedGlobal) ~= "number" or hintedGlobal ~= requestedDrawable then
            debugPrint(
                "resolveComponentVariation hint mismatch ped=%s component=%s requested=%s hinted=%s",
                ped,
                componentId,
                tostring(requestedDrawable),
                tostring(hintedGlobal)
            )
            needsLookup = true
        end
    end

    if resolvedCollection == nil or resolvedLocalDrawable == nil or needsLookup then
        if requestedDrawable ~= nil and requestedDrawable >= 0 then
            local lookupCollection = GetPedCollectionNameFromDrawable(ped, componentId, requestedDrawable)
            local lookupLocal = GetPedCollectionLocalIndexFromDrawable(ped, componentId, requestedDrawable)
            if type(lookupCollection) == "string" and type(lookupLocal) == "number" then
                resolvedCollection = lookupCollection
                resolvedLocalDrawable = lookupLocal
            else
                resolvedCollection = nil
                resolvedLocalDrawable = nil
            end
        else
            resolvedCollection = nil
            resolvedLocalDrawable = nil
        end
    end

    if resolvedCollection ~= nil and resolvedLocalDrawable ~= nil then
        local drawableCount = GetNumberOfPedCollectionDrawableVariations(ped, componentId, resolvedCollection)
        if type(drawableCount) == "number" and drawableCount > 0 then
            if resolvedLocalDrawable >= drawableCount then
                resolvedLocalDrawable = drawableCount - 1
            elseif resolvedLocalDrawable < 0 then
                resolvedLocalDrawable = 0
            end

            local textureCount = GetNumberOfPedCollectionTextureVariations(ped, componentId, resolvedCollection, resolvedLocalDrawable)
            if type(textureCount) == "number" and textureCount > 0 then
                if type(texture) ~= "number" then
                    texture = 0
                elseif texture >= textureCount then
                    texture = textureCount - 1
                elseif texture < 0 then
                    texture = 0
                end
            else
                texture = 0
            end

            local globalDrawable = GetPedDrawableGlobalIndexFromCollection(
                ped,
                componentId,
                resolvedCollection,
                resolvedLocalDrawable
            )
            if type(globalDrawable) ~= "number" then
                globalDrawable = type(drawable) == "number" and drawable or 0
            end

            debugPrint(
                "resolveComponentVariation result ped=%s component=%s global=%s texture=%s collection=%s local=%s",
                ped,
                componentId,
                globalDrawable,
                texture,
                resolvedCollection,
                resolvedLocalDrawable
            )
            return globalDrawable, texture, resolvedCollection, resolvedLocalDrawable
        end
    end

    drawable = type(drawable) == "number" and drawable or 0
    local drawableCount = GetNumberOfPedDrawableVariations(ped, componentId)
    if type(drawableCount) == "number" and drawableCount > 0 then
        if drawable >= drawableCount then
            drawable = drawableCount - 1
        elseif drawable < 0 then
            drawable = 0
        end
    else
        drawable = 0
    end

    texture = type(texture) == "number" and texture or 0
    local textureCount = GetNumberOfPedTextureVariations(ped, componentId, drawable)
    if type(textureCount) == "number" and textureCount > 0 then
        if texture >= textureCount then
            texture = textureCount - 1
        elseif texture < 0 then
            texture = 0
        end
    else
        texture = 0
    end

    local fallbackCollection = GetPedCollectionNameFromDrawable(ped, componentId, drawable)
    local fallbackLocalDrawable = GetPedCollectionLocalIndexFromDrawable(ped, componentId, drawable)

    if type(fallbackCollection) == "string" and type(fallbackLocalDrawable) == "number" then
        debugPrint(
            "resolveComponentVariation fallback ped=%s component=%s global=%s texture=%s collection=%s local=%s",
            ped,
            componentId,
            drawable,
            texture,
            fallbackCollection,
            fallbackLocalDrawable
        )
        return drawable, texture, fallbackCollection, fallbackLocalDrawable
    end

    debugPrint(
        "resolveComponentVariation legacy ped=%s component=%s global=%s texture=%s",
        ped,
        componentId,
        drawable,
        texture
    )
    return drawable, texture, nil, nil
end

local function setPedComponent(ped, component)
    if component then
        if isPedFreemodeModel(ped) and (component.component_id == 0 or component.component_id == 2) and not component.force then
            debugPrint(
                "setPedComponent skipping restricted component=%s without force flag",
                component.component_id
            )
            return
        end

        debugPrint(
            "setPedComponent request ped=%s component=%s drawable=%s texture=%s collection=%s local=%s",
            ped,
            component.component_id,
            tostring(component.drawable),
            tostring(component.texture),
            tostring(component.collection),
            tostring(component.collectionDrawable)
        )
        local resolvedDrawable, resolvedTexture, resolvedCollection, resolvedLocalDrawable = resolveComponentVariation(
            ped,
            component.component_id,
            component.drawable,
            component.texture,
            component.collection,
            component.collectionDrawable
        )
        local palette = component.palette or 0

        if type(resolvedCollection) == "string" and type(resolvedLocalDrawable) == "number" then
            if IsPedCollectionComponentVariationValid(ped, component.component_id, resolvedCollection, resolvedLocalDrawable, resolvedTexture, palette) then
                SetPedCollectionComponentVariation(ped, component.component_id, resolvedCollection, resolvedLocalDrawable, resolvedTexture, palette)
                debugPrint(
                    "setPedComponent applied collection=%s local=%s texture=%s",
                    resolvedCollection,
                    resolvedLocalDrawable,
                    resolvedTexture
                )
            else
                debugPrint(
                    "setPedComponent invalid collection=%s local=%s texture=%s – using legacy setter",
                    tostring(resolvedCollection),
                    tostring(resolvedLocalDrawable),
                    tostring(resolvedTexture)
                )
                SetPedComponentVariation(ped, component.component_id, resolvedDrawable, resolvedTexture, palette)
            end
        else
            debugPrint(
                "setPedComponent legacy setter ped=%s component=%s global=%s texture=%s",
                ped,
                component.component_id,
                resolvedDrawable,
                resolvedTexture
            )
            SetPedComponentVariation(ped, component.component_id, resolvedDrawable, resolvedTexture, palette)
        end

        component.drawable = GetPedDrawableVariation(ped, component.component_id)
        component.texture = GetPedTextureVariation(ped, component.component_id)
        component.collection, component.collectionDrawable = getComponentCollectionInfo(ped, component.component_id)
        component.palette = nil
        component.force = nil
        debugPrint(
            "setPedComponent current ped component=%s drawable=%s texture=%s collection=%s local=%s",
            component.component_id,
            component.drawable,
            component.texture,
            tostring(component.collection),
            tostring(component.collectionDrawable)
        )
    end
end

local function setPedComponents(ped, components)
    if components then
        for _, v in pairs(components) do
            setPedComponent(ped, v)
        end
    end
end

resolvePropVariation = function(ped, propId, drawable, texture, hashOrCollection, collectionOrDrawable, maybeCollectionDrawable)
    if type(drawable) ~= "number" then
        drawable = -1
    end

    if drawable < 0 then
        debugPrint(
            "resolvePropVariation removing ped=%s prop=%s (requested drawable=%s)",
            ped,
            propId,
            tostring(drawable)
        )
        return -1, 0, nil, nil
    end

    local collection = collectionOrDrawable
    local collectionDrawable = maybeCollectionDrawable

    if maybeCollectionDrawable == nil then
        collection = hashOrCollection
        collectionDrawable = collectionOrDrawable
    end

    debugPrint(
        "resolvePropVariation start ped=%s prop=%s drawable=%s texture=%s hintCollection=%s hintLocal=%s",
        ped,
        propId,
        tostring(drawable),
        tostring(texture),
        tostring(collection),
        tostring(collectionDrawable)
    )

    local resolvedCollection = type(collection) == "string" and collection or nil
    local resolvedLocalDrawable = type(collectionDrawable) == "number" and collectionDrawable or nil

    local requestedDrawable = drawable >= 0 and drawable or nil
    local needsLookup = false

    if resolvedCollection ~= nil and resolvedLocalDrawable ~= nil and requestedDrawable ~= nil then
        local hintedGlobal = GetPedPropGlobalIndexFromCollection(ped, propId, resolvedCollection, resolvedLocalDrawable)
        if type(hintedGlobal) ~= "number" or hintedGlobal ~= requestedDrawable then
            debugPrint(
                "resolvePropVariation hint mismatch ped=%s prop=%s requested=%s hinted=%s",
                ped,
                propId,
                tostring(requestedDrawable),
                tostring(hintedGlobal)
            )
            needsLookup = true
        end
    end

    if resolvedCollection == nil or resolvedLocalDrawable == nil or needsLookup then
        if requestedDrawable ~= nil then
            local lookupCollection = GetPedCollectionNameFromProp(ped, propId, requestedDrawable)
            local lookupLocal = GetPedCollectionLocalIndexFromProp(ped, propId, requestedDrawable)
            if type(lookupCollection) == "string" and type(lookupLocal) == "number" then
                resolvedCollection = lookupCollection
                resolvedLocalDrawable = lookupLocal
            else
                resolvedCollection = nil
                resolvedLocalDrawable = nil
            end
        else
            resolvedCollection = nil
            resolvedLocalDrawable = nil
        end
    end

    if resolvedCollection ~= nil and resolvedLocalDrawable ~= nil then
        local drawableCount = GetNumberOfPedCollectionPropDrawableVariations(ped, propId, resolvedCollection)
        if type(drawableCount) == "number" and drawableCount > 0 then
            if resolvedLocalDrawable >= drawableCount then
                resolvedLocalDrawable = drawableCount - 1
            elseif resolvedLocalDrawable < 0 then
                resolvedLocalDrawable = 0
            end

            local textureCount = GetNumberOfPedCollectionPropTextureVariations(ped, propId, resolvedCollection, resolvedLocalDrawable)
            if type(textureCount) == "number" and textureCount > 0 then
                if type(texture) ~= "number" then
                    texture = 0
                elseif texture >= textureCount then
                    texture = textureCount - 1
                elseif texture < 0 then
                    texture = 0
                end
            else
                texture = 0
            end

            local globalDrawable = GetPedPropGlobalIndexFromCollection(
                ped,
                propId,
                resolvedCollection,
                resolvedLocalDrawable
            )
            if type(globalDrawable) ~= "number" then
                globalDrawable = drawable
            end

            debugPrint(
                "resolvePropVariation result ped=%s prop=%s global=%s texture=%s collection=%s local=%s",
                ped,
                propId,
                globalDrawable,
                texture,
                resolvedCollection,
                resolvedLocalDrawable
            )
            return globalDrawable, texture, resolvedCollection, resolvedLocalDrawable
        end
    end

    local drawableCount = GetNumberOfPedPropDrawableVariations(ped, propId)
    if type(drawableCount) == "number" and drawableCount > 0 then
        if drawable >= drawableCount then
            drawable = drawableCount - 1
        elseif drawable < 0 then
            drawable = 0
        end
    else
        return -1, 0, nil, nil
    end

    local textureCount = GetNumberOfPedPropTextureVariations(ped, propId, drawable)
    if type(textureCount) == "number" and textureCount > 0 then
        if type(texture) ~= "number" then
            texture = 0
        elseif texture >= textureCount then
            texture = textureCount - 1
        elseif texture < 0 then
            texture = 0
        end
    else
        texture = 0
    end

    local fallbackCollection = GetPedCollectionNameFromProp(ped, propId, drawable)
    local fallbackLocalDrawable = GetPedCollectionLocalIndexFromProp(ped, propId, drawable)

    if type(fallbackCollection) == "string" and type(fallbackLocalDrawable) == "number" then
        debugPrint(
            "resolvePropVariation fallback ped=%s prop=%s global=%s texture=%s collection=%s local=%s",
            ped,
            propId,
            drawable,
            texture,
            fallbackCollection,
            fallbackLocalDrawable
        )
        return drawable, texture, fallbackCollection, fallbackLocalDrawable
    end

    debugPrint(
        "resolvePropVariation legacy ped=%s prop=%s global=%s texture=%s",
        ped,
        propId,
        drawable,
        texture
    )
    return drawable, texture, nil, nil
end

local function setPedProp(ped, prop)
    if prop then
        if prop.drawable == -1 then
            ClearPedProp(ped, prop.prop_id)
            prop.texture = -1
            prop.collection = nil
            prop.collectionDrawable = nil
            prop.attach = nil
            debugPrint("setPedProp cleared ped=%s prop=%s", ped, prop.prop_id)
        else
            debugPrint(
                "setPedProp request ped=%s prop=%s drawable=%s texture=%s collection=%s local=%s",
                ped,
                prop.prop_id,
                tostring(prop.drawable),
                tostring(prop.texture),
                tostring(prop.collection),
                tostring(prop.collectionDrawable)
            )
            local drawable, texture, collectionName, collectionDrawable = resolvePropVariation(
                ped,
                prop.prop_id,
                prop.drawable,
                prop.texture,
                prop.collection,
                prop.collectionDrawable
            )
            if drawable == -1 then
                ClearPedProp(ped, prop.prop_id)
                prop.drawable = -1
                prop.texture = -1
                prop.collection = nil
                prop.collectionDrawable = nil
                prop.attach = nil
                debugPrint("setPedProp cleared after resolve ped=%s prop=%s", ped, prop.prop_id)
                return
            end

            local attach = prop.attach
            if attach == nil then
                attach = false
            end
            if type(collectionName) == "string" and type(collectionDrawable) == "number" then
                local appliedWithCollection = false
                if IsPedCollectionPropVariationValid then
                    if IsPedCollectionPropVariationValid(ped, prop.prop_id, collectionName, collectionDrawable, texture) then
                        SetPedCollectionPropIndex(ped, prop.prop_id, collectionName, collectionDrawable, texture, attach)
                        appliedWithCollection = true
                        debugPrint(
                            "setPedProp applied collection=%s local=%s texture=%s",
                            collectionName,
                            collectionDrawable,
                            texture
                        )
                    else
                        debugPrint(
                            "setPedProp invalid collection=%s local=%s texture=%s – using legacy setter",
                            tostring(collectionName),
                            tostring(collectionDrawable),
                            tostring(texture)
                        )
                    end
                else
                    SetPedCollectionPropIndex(ped, prop.prop_id, collectionName, collectionDrawable, texture, attach)
                    appliedWithCollection = true
                    debugPrint(
                        "setPedProp applied collection (no validity native) collection=%s local=%s texture=%s",
                        collectionName,
                        collectionDrawable,
                        texture
                    )
                end

                if not appliedWithCollection then
                    SetPedPropIndex(ped, prop.prop_id, drawable, texture, attach)
                end
            else
                debugPrint(
                    "setPedProp legacy setter ped=%s prop=%s global=%s texture=%s",
                    ped,
                    prop.prop_id,
                    drawable,
                    texture
                )
                SetPedPropIndex(ped, prop.prop_id, drawable, texture, attach)
            end

            local currentDrawable = GetPedPropIndex(ped, prop.prop_id)
            if currentDrawable == -1 then
                prop.drawable = -1
                prop.texture = -1
                prop.collection = nil
                prop.collectionDrawable = nil
                prop.attach = nil
                debugPrint("setPedProp current ped prop=%s cleared", prop.prop_id)
            else
                prop.drawable = currentDrawable
                prop.texture = GetPedPropTextureIndex(ped, prop.prop_id)
                prop.collection, prop.collectionDrawable = getPropCollectionInfo(ped, prop.prop_id)
                prop.attach = attach
                debugPrint(
                    "setPedProp current ped prop=%s drawable=%s texture=%s collection=%s local=%s",
                    prop.prop_id,
                    prop.drawable,
                    prop.texture,
                    tostring(prop.collection),
                    tostring(prop.collectionDrawable)
                )
            end
        end
    end
end

local function setPedProps(ped, props)
    if props then
        for _, v in pairs(props) do
            setPedProp(ped, v)
        end
    end
end

local function setPedTattoos(ped, tattoos)
    PED_TATTOOS = tattoos
    setTattoos(ped, tattoos)
end

local function getPedTattoos()
    return PED_TATTOOS
end

local function addPedTattoo(ped, tattoos)
    setTattoos(ped, tattoos)
end

local function removePedTattoo(ped, tattoos)
    setTattoos(ped, tattoos)
end

local function setPreviewTattoo(ped, tattoos, tattoo)
    local isMale = client.getPedDecorationType() == "male"
    local tattooGender = isMale and tattoo.hashMale or tattoo.hashFemale

    ClearPedDecorations(ped)
    for _ = 1, (tattoo.opacity or 0.1) * 10 do
        AddPedDecorationFromHashes(ped, joaat(tattoo.collection), tattooGender)
    end
    for k in pairs(tattoos) do
        for i = 1, #tattoos[k] do
            local aTattoo = tattoos[k][i]
            if aTattoo.name ~= tattoo.name then
                local aTattooGender = isMale and aTattoo.hashMale or aTattoo.hashFemale
                for _ = 1, (aTattoo.opacity or 0.1) * 10 do
                    AddPedDecorationFromHashes(ped, joaat(aTattoo.collection), joaat(aTattooGender))
                end
            end
        end
    end
    if Config.AutomaticFade then
        applyAutomaticFade(ped, GetPedDrawableVariation(ped, 2))
    end
end

local function setPedAppearance(ped, appearance)
    if appearance then
        setPedComponents(ped, appearance.components)
        setPedProps(ped, appearance.props)

        if appearance.headBlend and isPedFreemodeModel(ped) then setPedHeadBlend(ped, appearance.headBlend) end
        if appearance.faceFeatures then setPedFaceFeatures(ped, appearance.faceFeatures) end
        if appearance.headOverlays then setPedHeadOverlays(ped, appearance.headOverlays) end
        if appearance.hair then setPedHair(ped, appearance.hair, appearance.tattoos) end
        if appearance.eyeColor then setPedEyeColor(ped, appearance.eyeColor) end
        if appearance.tattoos then setPedTattoos(ped, appearance.tattoos) end
    end
end

local function setPlayerAppearance(appearance)
    if appearance then
        setPlayerModel(appearance.model)
        setPedAppearance(cache.ped, appearance)
    end
end

exports("getPedModel", getPedModel)
exports("getPedComponents", getPedComponents)
exports("getPedProps", getPedProps)
exports("getPedHeadBlend", getPedHeadBlend)
exports("getPedFaceFeatures", getPedFaceFeatures)
exports("getPedHeadOverlays", getPedHeadOverlays)
exports("getPedHair", getPedHair)
exports("getPedAppearance", getPedAppearance)

exports("setPlayerModel", setPlayerModel)
exports("setPedHeadBlend", setPedHeadBlend)
exports("setPedFaceFeatures", setPedFaceFeatures)
exports("setPedHeadOverlays", setPedHeadOverlays)
exports("setPedHair", setPedHair)
exports("setPedEyeColor", setPedEyeColor)
exports("setPedComponent", setPedComponent)
exports("setPedComponents", setPedComponents)
exports("setPedProp", setPedProp)
exports("setPedProps", setPedProps)
exports("resolveComponentVariation", resolveComponentVariation)
exports("resolvePropVariation", resolvePropVariation)
exports("setPlayerAppearance", setPlayerAppearance)
exports("setPedAppearance", setPedAppearance)
exports("setPedTattoos", setPedTattoos)
exports("debugPrint", debugPrint)

client = {
    getPedAppearance = getPedAppearance,
    setPlayerModel = setPlayerModel,
    setPedHeadBlend = setPedHeadBlend,
    setPedFaceFeatures = setPedFaceFeatures,
    setPedHair = setPedHair,
    setPedHeadOverlays = setPedHeadOverlays,
    setPedEyeColor = setPedEyeColor,
    setPedComponent = setPedComponent,
    setPedProp = setPedProp,
    setPlayerAppearance = setPlayerAppearance,
    setPedAppearance = setPedAppearance,
    resolveComponentVariation = resolveComponentVariation,
    resolvePropVariation = resolvePropVariation,
    getPedDecorationType = getPedDecorationType,
    isPedFreemodeModel = isPedFreemodeModel,
    setPreviewTattoo = setPreviewTattoo,
    setPedTattoos = setPedTattoos,
    getPedTattoos = getPedTattoos,
    addPedTattoo = addPedTattoo,
    removePedTattoo = removePedTattoo,
    getPedModel = getPedModel,
    setPedComponents = setPedComponents,
    setPedProps = setPedProps,
    getPedComponents = getPedComponents,
    getPedProps = getPedProps,
    debugPrint = debugPrint
}
