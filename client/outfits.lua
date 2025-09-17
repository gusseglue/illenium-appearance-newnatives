local function typeof(var)
    local _type = type(var);
    if (_type ~= "table" and _type ~= "userdata") then
        return _type;
    end
    local _meta = getmetatable(var);
    if (_meta ~= nil and _meta._NAME ~= nil) then
        return _meta._NAME;
    else
        return _type;
    end
end

function LoadJobOutfit(oData)
    local ped = cache.ped

    local data = oData.outfitData

    if typeof(data) ~= "table" then
        data = json.decode(data)
    end

    -- Use collection-based natives for smoother outfit application
    local componentsToApply = {}
    local propsToApply = {}
    local propsToClear = {}
    
    -- Collect all components to apply
    if data["pants"] ~= nil then
        table.insert(componentsToApply, {4, data["pants"].item, data["pants"].texture})
    end
    
    if data["arms"] ~= nil then
        table.insert(componentsToApply, {3, data["arms"].item, data["arms"].texture})
    end
    
    if data["t-shirt"] ~= nil then
        table.insert(componentsToApply, {8, data["t-shirt"].item, data["t-shirt"].texture})
    end
    
    if data["vest"] ~= nil then
        table.insert(componentsToApply, {9, data["vest"].item, data["vest"].texture})
    end
    
    if data["torso2"] ~= nil then
        table.insert(componentsToApply, {11, data["torso2"].item, data["torso2"].texture})
    end
    
    if data["shoes"] ~= nil then
        table.insert(componentsToApply, {6, data["shoes"].item, data["shoes"].texture})
    end
    
    if data["decals"] ~= nil then
        table.insert(componentsToApply, {10, data["decals"].item, data["decals"].texture})
    end
    
    if data["mask"] ~= nil then
        table.insert(componentsToApply, {1, data["mask"].item, data["mask"].texture})
    end
    
    if data["bag"] ~= nil then
        table.insert(componentsToApply, {5, data["bag"].item, data["bag"].texture})
    end
    
    -- Handle accessory with tracker logic
    local tracker = Config.TrackerClothingOptions
    if data["accessory"] ~= nil then
        if Framework.HasTracker() then
            table.insert(componentsToApply, {7, tracker.drawable, tracker.texture})
        else
            table.insert(componentsToApply, {7, data["accessory"].item, data["accessory"].texture})
        end
    else
        if Framework.HasTracker() then
            table.insert(componentsToApply, {7, tracker.drawable, tracker.texture})
        else
            local drawableId = GetPedDrawableVariation(ped, 7)
            
            if drawableId ~= -1 then
                local textureId = GetPedTextureVariation(ped, 7)
                if drawableId == tracker.drawable and textureId == tracker.texture then
                    SetPedComponentVariation(ped, 7, -1, 0, 2) -- Clear tracker component immediately
                end
            end
        end
    end
    
    -- Preload and apply all components at once
    if #componentsToApply > 0 then
        for _, comp in pairs(componentsToApply) do
            SetPedPreloadVariationData(ped, comp[1], comp[2], comp[3])
        end
        ApplyPedPreloadVariationData(ped)
    end
    
    -- Handle props (hat, etc.)
    if data["hat"] ~= nil then
        if data["hat"].item ~= -1 and data["hat"].item ~= 0 then
            SetPedPreloadPropData(ped, 0, data["hat"].item, data["hat"].texture)
            table.insert(propsToApply, true)
        else
            ClearPedProp(ped, 0)
        end
    end

    -- Glass
    if data["glass"] ~= nil then
        if data["glass"].item ~= -1 and data["glass"].item ~= 0 then
            SetPedPreloadPropData(ped, 1, data["glass"].item, data["glass"].texture)
            table.insert(propsToApply, true)
        else
            ClearPedProp(ped, 1)
        end
    end

    -- Ear
    if data["ear"] ~= nil then
        if data["ear"].item ~= -1 and data["ear"].item ~= 0 then
            SetPedPreloadPropData(ped, 2, data["ear"].item, data["ear"].texture)
            table.insert(propsToApply, true)
        else
            ClearPedProp(ped, 2)
        end
    end
    
    -- Apply all preloaded props at once
    if #propsToApply > 0 then
        ApplyPedPreloadPropData(ped)
    end

    local length = 0
    for _ in pairs(data) do
        length = length + 1
    end

    if Config.PersistUniforms and length > 1 then
        TriggerServerEvent("illenium-appearance:server:syncUniform", {
            jobName = oData.jobName,
            gender = oData.gender,
            label = oData.name
        })
    end
end

RegisterNetEvent("illenium-appearance:client:loadJobOutfit", LoadJobOutfit)

RegisterNetEvent("illenium-appearance:client:openOutfitMenu", function()
    OpenMenu(nil, "outfit")
end)

RegisterNetEvent("illenium-apearance:client:outfitsCommand", function(isJob)
    local outfits = GetPlayerJobOutfits(isJob)
    TriggerEvent("illenium-appearance:client:openJobOutfitsMenu", outfits)
end)
