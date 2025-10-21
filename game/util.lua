local hashesComputed = false
local PED_TATTOOS = {}
local pedModelsByHash = {}
local getComponentCollectionData
local getPropCollectionData

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
local function getPedComponents(ped)
    local size = #constants.PED_COMPONENTS_IDS
    local components = table.create(size, 0)

    for i = 1, size do
        local componentId = constants.PED_COMPONENTS_IDS[i]
        local drawable = GetPedDrawableVariation(ped, componentId)
        local texture = GetPedTextureVariation(ped, componentId)
        local collectionName = GetPedDrawableVariationCollectionName(ped, componentId)
        local localIndex = GetPedDrawableVariationCollectionLocalIndex(ped, componentId)

        if collectionName == nil or localIndex == nil or localIndex < 0 then
            collectionName, localIndex = getComponentCollectionData(ped, componentId, drawable)
        end

        components[i] = {
            component_id = componentId,
            drawable = drawable,
            texture = texture,
            collection = collectionName or nil,
            collection_local_index = localIndex or nil,
        }
    end

    return components
end

---@param ped number entity id
---@return table<number, table<string, number>>
local function getPedProps(ped)
    local size = #constants.PED_PROPS_IDS
    local props = table.create(size, 0)

    for i = 1, size do
        local propId = constants.PED_PROPS_IDS[i]
        local drawable = GetPedPropIndex(ped, propId)
        local texture = GetPedPropTextureIndex(ped, propId)
        local collectionName = GetPedPropCollectionName(ped, propId)
        local localIndex = GetPedPropCollectionLocalIndex(ped, propId)

        if collectionName == nil or localIndex == nil or localIndex < 0 then
            collectionName, localIndex = getPropCollectionData(ped, propId, drawable)
        end

        props[i] = {
            prop_id = propId,
            drawable = drawable,
            texture = texture,
            collection = collectionName or nil,
            collection_local_index = localIndex or nil,
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
    local collectionName = GetPedDrawableVariationCollectionName(ped, 2)
    local localIndex = GetPedDrawableVariationCollectionLocalIndex(ped, 2)

    if collectionName == nil or localIndex == nil or localIndex < 0 then
        collectionName, localIndex = getComponentCollectionData(ped, 2, style)
    end

    return {
        style = style,
        color = GetPedHairColor(ped),
        highlight = GetPedHairHighlightColor(ped),
        texture = texture,
        collection = collectionName or nil,
        collection_local_index = localIndex or nil,
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
        local collectionName = hair.collection or hair.collectionName
        local localIndex = hair.collection_local_index or hair.collectionLocalIndex

        local texture = hair.texture or 0

        local collectionsCount = GetPedCollectionsCount(ped)

        if collectionName ~= nil and localIndex ~= nil then
            hair.collection = collectionName
            hair.collection_local_index = localIndex
            SetPedCollectionComponentVariation(ped, 2, collectionName, localIndex, texture, 0)
        else
            local resolvedCollection, resolvedIndex = getComponentCollectionData(ped, 2, hair.style)
            if resolvedCollection ~= nil and resolvedIndex ~= nil then
                hair.collection = resolvedCollection
                hair.collection_local_index = resolvedIndex
                SetPedCollectionComponentVariation(ped, 2, resolvedCollection, resolvedIndex, texture, 0)
            elseif not collectionsCount or collectionsCount <= 0 then
                SetPedComponentVariation(ped, 2, hair.style or 0, texture, 0)
            end
        end

        SetPedHairColor(ped, hair.color or 0, hair.highlight or 0)
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

getComponentCollectionData = function(ped, componentId, drawable)
    if not drawable or drawable < 0 then
        return nil, nil
    end

    local collectionsCount = GetPedCollectionsCount(ped)
    local remaining = drawable

    if collectionsCount and collectionsCount > 0 then
        for i = 0, collectionsCount - 1 do
            local collectionName = GetPedCollectionName(ped, i) or ""
            local drawablesInCollection = GetNumberOfPedCollectionDrawableVariations(ped, componentId, collectionName) or 0

            if remaining < drawablesInCollection then
                return collectionName, remaining
            end

            remaining = remaining - drawablesInCollection
        end
    end

    local fallbackCollection = GetPedCollectionNameFromDrawable(ped, componentId, drawable)
    if fallbackCollection ~= nil then
        local fallbackIndex = GetPedCollectionLocalIndexFromDrawable(ped, componentId, drawable)
        if fallbackIndex ~= nil and fallbackIndex >= 0 then
            return fallbackCollection, fallbackIndex
        end
    end

    return nil, nil
end

getPropCollectionData = function(ped, propId, drawable)
    if not drawable or drawable < 0 then
        return nil, nil
    end

    local collectionsCount = GetPedCollectionsCount(ped)
    local remaining = drawable

    if collectionsCount and collectionsCount > 0 then
        for i = 0, collectionsCount - 1 do
            local collectionName = GetPedCollectionName(ped, i) or ""
            local drawablesInCollection = GetNumberOfPedCollectionPropDrawableVariations(ped, propId, collectionName) or 0

            if remaining < drawablesInCollection then
                return collectionName, remaining
            end

            remaining = remaining - drawablesInCollection
        end
    end

    local fallbackCollection = GetPedCollectionNameFromProp(ped, propId, drawable)
    if fallbackCollection ~= nil then
        local fallbackIndex = GetPedCollectionLocalIndexFromProp(ped, propId, drawable)
        if fallbackIndex ~= nil and fallbackIndex >= 0 then
            return fallbackCollection, fallbackIndex
        end
    end

    return nil, nil
end

local function setPedComponent(ped, component)
    if component then
        if isPedFreemodeModel(ped) and (component.component_id == 0 or component.component_id == 2) then
            return
        end

        local collectionName = component.collection or component.collectionName
        local localIndex = component.collection_local_index or component.collectionLocalIndex

        local texture = component.texture or 0
        local collectionsCount = GetPedCollectionsCount(ped)

        if collectionName ~= nil and localIndex ~= nil then
            component.collection = collectionName
            component.collection_local_index = localIndex
            SetPedCollectionComponentVariation(ped, component.component_id, collectionName, localIndex, texture, 0)
        elseif component.drawable ~= nil then
            local resolvedCollection, resolvedIndex = getComponentCollectionData(ped, component.component_id, component.drawable)

            if resolvedCollection ~= nil and resolvedIndex ~= nil then
                component.collection = resolvedCollection
                component.collection_local_index = resolvedIndex
                SetPedCollectionComponentVariation(ped, component.component_id, resolvedCollection, resolvedIndex, texture, 0)
            elseif not collectionsCount or collectionsCount <= 0 then
                -- Fallback to traditional method if collection natives are unavailable
                SetPedComponentVariation(ped, component.component_id, component.drawable, texture, 0)
            end
        end
    end
end

local function setPedComponents(ped, components)
    if components then
        for _, v in pairs(components) do
            setPedComponent(ped, v)
        end
    end
end

local function setPedProp(ped, prop)
    if prop then
        if prop.drawable == -1 then
            ClearPedProp(ped, prop.prop_id)
            prop.collection = nil
            prop.collection_local_index = nil
        else
            local collectionName = prop.collection or prop.collectionName
            local localIndex = prop.collection_local_index or prop.collectionLocalIndex

            local texture = prop.texture or 0
            local collectionsCount = GetPedCollectionsCount(ped)

            if collectionName ~= nil and localIndex ~= nil then
                prop.collection = collectionName
                prop.collection_local_index = localIndex
                SetPedCollectionPropIndex(ped, prop.prop_id, collectionName, localIndex, texture, false)
            elseif prop.drawable ~= nil then
                local resolvedCollection, resolvedIndex = getPropCollectionData(ped, prop.prop_id, prop.drawable)

                if resolvedCollection ~= nil and resolvedIndex ~= nil then
                    prop.collection = resolvedCollection
                    prop.collection_local_index = resolvedIndex
                    SetPedCollectionPropIndex(ped, prop.prop_id, resolvedCollection, resolvedIndex, texture, false)
                elseif not collectionsCount or collectionsCount <= 0 then
                    -- Fallback to traditional method if collection natives are unavailable
                    SetPedPropIndex(ped, prop.prop_id, prop.drawable, texture, false)
                end
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
exports("getComponentCollectionData", getComponentCollectionData)
exports("getPropCollectionData", getPropCollectionData)
exports("setPlayerAppearance", setPlayerAppearance)
exports("setPedAppearance", setPedAppearance)
exports("setPedTattoos", setPedTattoos)

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
    getComponentCollectionData = getComponentCollectionData,
    getPropCollectionData = getPropCollectionData
}
