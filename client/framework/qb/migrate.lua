if not Framework.QBCore() then return end

local client = client

local function debugComponentMigration(stage, componentId, drawable, texture)
    client.debugPrint(
        "qb-migrate %s component=%s drawable=%s texture=%s",
        stage,
        componentId,
        tostring(drawable),
        tostring(texture)
    )
end

local function debugPropMigration(stage, propId, drawable, texture)
    client.debugPrint(
        "qb-migrate %s prop=%s drawable=%s texture=%s",
        stage,
        propId,
        tostring(drawable),
        tostring(texture)
    )
end

local function setComponentValue(ped, componentId, drawable, texture, force, palette)
    if drawable == nil then return end
    debugComponentMigration("set", componentId, drawable, texture)
    client.setPedComponent(ped, {
        component_id = componentId,
        drawable = drawable,
        texture = texture or 0,
        force = force,
        palette = palette
    })
end

local function applyComponentEntry(ped, componentId, entry)
    if not entry or entry.item == nil then return end
    setComponentValue(ped, componentId, entry.item, entry.texture, entry.force, entry.palette)
end

local function applyPropEntry(ped, propId, entry)
    if not entry or entry.item == nil then return end
    local drawable = entry.item
    local texture = entry.texture or 0

    if drawable == -1 or drawable == 0 then
        debugPropMigration("clear", propId, drawable, texture)
        client.setPedProp(ped, { prop_id = propId, drawable = -1 })
        return
    end

    debugPropMigration("set", propId, drawable, texture)
    client.setPedProp(ped, {
        prop_id = propId,
        drawable = drawable,
        texture = texture,
        collection = entry.collection,
        collectionDrawable = entry.collectionDrawable,
        attach = entry.attach ~= nil and entry.attach or true
    })
end

local skinData = {
    ["face2"] = {
        item = 0,
        texture = 0,
        defaultItem = 0,
        defaultTexture = 0,
    },
    ["facemix"] = {
        skinMix = 0,
        shapeMix = 0,
        defaultSkinMix = 0.0,
        defaultShapeMix = 0.0,
    },
}

RegisterNetEvent("illenium-appearance:client:migration:load-qb-clothing-skin", function(playerSkin)
    local model = playerSkin.model
    model = model ~= nil and tonumber(model) or false
    Citizen.CreateThread(function()
        lib.requestModel(model, 1000)
        SetPlayerModel(cache.playerId, model)
        Wait(150)
        setComponentValue(cache.ped, 0, 0, 0, true)
        TriggerEvent("illenium-appearance:client:migration:load-qb-clothing-clothes", playerSkin, cache.ped)
        SetModelAsNoLongerNeeded(model)
    end)
end)

RegisterNetEvent("illenium-appearance:client:migration:load-qb-clothing-clothes", function(playerSkin, ped)
    local data = json.decode(playerSkin.skin)
    if ped == nil then ped = cache.ped end

    for i = 0, 11 do
        setComponentValue(ped, i, 0, 0, true)
    end

    for i = 0, 7 do
        client.setPedProp(ped, { prop_id = i, drawable = -1 })
    end

    -- Face
    if not data["facemix"] or not data["face2"] then
        data["facemix"] = skinData["facemix"]
        data["facemix"].shapeMix = data["facemix"].defaultShapeMix
        data["facemix"].skinMix = data["facemix"].defaultSkinMix
        data["face2"] = skinData["face2"]
    end

    SetPedHeadBlendData(ped, data["face"].item, data["face2"].item, nil, data["face"].texture, data["face2"].texture, nil, data["facemix"].shapeMix, data["facemix"].skinMix, nil, true)

    -- Pants
    applyComponentEntry(ped, 4, data["pants"])

    -- Hair
    client.setPedHair(ped, {
        style = data["hair"].item,
        texture = 0,
        color = data["hair"].texture or 0,
        highlight = data["hair"].texture or 0
    })

    -- Eyebrows
    SetPedHeadOverlay(ped, 2, data["eyebrows"].item, 1.0)
    SetPedHeadOverlayColor(ped, 2, 1, data["eyebrows"].texture, 0)

    -- Beard
    SetPedHeadOverlay(ped, 1, data["beard"].item, 1.0)
    SetPedHeadOverlayColor(ped, 1, 1, data["beard"].texture, 0)

    -- Blush
    SetPedHeadOverlay(ped, 5, data["blush"].item, 1.0)
    SetPedHeadOverlayColor(ped, 5, 1, data["blush"].texture, 0)

    -- Lipstick
    SetPedHeadOverlay(ped, 8, data["lipstick"].item, 1.0)
    SetPedHeadOverlayColor(ped, 8, 1, data["lipstick"].texture, 0)

    -- Makeup
    SetPedHeadOverlay(ped, 4, data["makeup"].item, 1.0)
    SetPedHeadOverlayColor(ped, 4, 1, data["makeup"].texture, 0)

    -- Ageing
    SetPedHeadOverlay(ped, 3, data["ageing"].item, 1.0)
    SetPedHeadOverlayColor(ped, 3, 1, data["ageing"].texture, 0)

    -- Arms
    applyComponentEntry(ped, 3, data["arms"])

    -- T-Shirt
    applyComponentEntry(ped, 8, data["t-shirt"])

    -- Vest
    applyComponentEntry(ped, 9, data["vest"])

    -- Torso 2
    applyComponentEntry(ped, 11, data["torso2"])

    -- Shoes
    applyComponentEntry(ped, 6, data["shoes"])

    -- Mask
    applyComponentEntry(ped, 1, data["mask"])

    -- Badge
    applyComponentEntry(ped, 10, data["decals"])

    -- Accessory
    applyComponentEntry(ped, 7, data["accessory"])

    -- Bag
    applyComponentEntry(ped, 5, data["bag"])

    -- Hat
    applyPropEntry(ped, 0, data["hat"])

    -- Glass
    applyPropEntry(ped, 1, data["glass"])

    -- Ear
    applyPropEntry(ped, 2, data["ear"])

    -- Watch
    applyPropEntry(ped, 6, data["watch"])

    -- Bracelet
    applyPropEntry(ped, 7, data["bracelet"])

    if data["eye_color"].item ~= -1 and data["eye_color"].item ~= 0 then
        SetPedEyeColor(ped, data["eye_color"].item)
    end

    if data["moles"].item ~= -1 and data["moles"].item ~= 0 then
        SetPedHeadOverlay(ped, 9, data["moles"].item, (data["moles"].texture / 10))
    end

    SetPedFaceFeature(ped, 0, (data["nose_0"].item / 10))
    SetPedFaceFeature(ped, 1, (data["nose_1"].item / 10))
    SetPedFaceFeature(ped, 2, (data["nose_2"].item / 10))
    SetPedFaceFeature(ped, 3, (data["nose_3"].item / 10))
    SetPedFaceFeature(ped, 4, (data["nose_4"].item / 10))
    SetPedFaceFeature(ped, 5, (data["nose_5"].item / 10))
    SetPedFaceFeature(ped, 6, (data["eyebrown_high"].item / 10))
    SetPedFaceFeature(ped, 7, (data["eyebrown_forward"].item / 10))
    SetPedFaceFeature(ped, 8, (data["cheek_1"].item / 10))
    SetPedFaceFeature(ped, 9, (data["cheek_2"].item / 10))
    SetPedFaceFeature(ped, 10,(data["cheek_3"].item / 10))
    SetPedFaceFeature(ped, 11, (data["eye_opening"].item / 10))
    SetPedFaceFeature(ped, 12, (data["lips_thickness"].item / 10))
    SetPedFaceFeature(ped, 13, (data["jaw_bone_width"].item / 10))
    SetPedFaceFeature(ped, 14, (data["jaw_bone_back_lenght"].item / 10))
    SetPedFaceFeature(ped, 15, (data["chimp_bone_lowering"].item / 10))
    SetPedFaceFeature(ped, 16, (data["chimp_bone_lenght"].item / 10))
    SetPedFaceFeature(ped, 17, (data["chimp_bone_width"].item / 10))
    SetPedFaceFeature(ped, 18, (data["chimp_hole"].item / 10))
    SetPedFaceFeature(ped, 19, (data["neck_thikness"].item / 10))

    local appearance = client.getPedAppearance(ped)

    TriggerServerEvent("illenium-appearance:server:migrate-qb-clothing-skin", playerSkin.citizenid, appearance)
end)
