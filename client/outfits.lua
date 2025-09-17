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

    -- Helper function to convert global index to collection-based and apply
    local function applyComponentWithCollection(componentId, drawable, texture)
        if drawable ~= nil then
            local collectionName = nil
            local localIndex = -1
            
            local collectionsCount = GetPedCollectionsCount(ped)
            local currentGlobalIndex = 0
            
            for i = 0, collectionsCount - 1 do
                local currentCollectionName = GetPedCollectionName(ped, i)
                local drawableVariationsCount = GetNumberOfPedCollectionDrawableVariations(ped, componentId, currentCollectionName)
                
                if drawable >= currentGlobalIndex and drawable < currentGlobalIndex + drawableVariationsCount then
                    collectionName = currentCollectionName
                    localIndex = drawable - currentGlobalIndex
                    break
                end
                
                currentGlobalIndex = currentGlobalIndex + drawableVariationsCount
            end
            
            -- Use collection-based native to prevent clothing shifting
            if collectionName and localIndex >= 0 then
                SetPedCollectionComponentVariation(ped, componentId, collectionName, localIndex, texture, 0)
            else
                SetPedComponentVariation(ped, componentId, drawable, texture, 0)
            end
        end
    end

    -- Pants
    applyComponentWithCollection(4, data["pants"] and data["pants"].item, data["pants"] and data["pants"].texture)

    -- Arms
    applyComponentWithCollection(3, data["arms"] and data["arms"].item, data["arms"] and data["arms"].texture)

    -- T-Shirt
    applyComponentWithCollection(8, data["t-shirt"] and data["t-shirt"].item, data["t-shirt"] and data["t-shirt"].texture)

    -- Vest
    applyComponentWithCollection(9, data["vest"] and data["vest"].item, data["vest"] and data["vest"].texture)

    -- Torso 2
    applyComponentWithCollection(11, data["torso2"] and data["torso2"].item, data["torso2"] and data["torso2"].texture)

    -- Shoes
    applyComponentWithCollection(6, data["shoes"] and data["shoes"].item, data["shoes"] and data["shoes"].texture)

    -- Badge
    applyComponentWithCollection(10, data["decals"] and data["decals"].item, data["decals"] and data["decals"].texture)

    -- Accessory
    local tracker = Config.TrackerClothingOptions

    if data["accessory"] ~= nil then
        if Framework.HasTracker() then
            applyComponentWithCollection(7, tracker.drawable, tracker.texture)
        else
            applyComponentWithCollection(7, data["accessory"].item, data["accessory"].texture)
        end
    else
        if Framework.HasTracker() then
            applyComponentWithCollection(7, tracker.drawable, tracker.texture)
        else
            local drawableId = GetPedDrawableVariation(ped, 7)
            
            if drawableId ~= -1 then
                local textureId = GetPedTextureVariation(ped, 7)
                if drawableId == tracker.drawable and textureId == tracker.texture then
                    SetPedComponentVariation(ped, 7, -1, 0, 2) -- Keep this special case as is
                end
            end
        end
    end

    -- Mask
    applyComponentWithCollection(1, data["mask"] and data["mask"].item, data["mask"] and data["mask"].texture)

    -- Bag
    applyComponentWithCollection(5, data["bag"] and data["bag"].item, data["bag"] and data["bag"].texture)

    -- Helper function to convert global prop index to collection-based and apply
    local function applyPropWithCollection(propId, drawable, texture)
        if drawable ~= nil and drawable ~= -1 and drawable ~= 0 then
            local collectionName = nil
            local localIndex = -1
            
            local collectionsCount = GetPedCollectionsCount(ped)
            local currentGlobalIndex = 0
            
            for i = 0, collectionsCount - 1 do
                local currentCollectionName = GetPedCollectionName(ped, i)
                local propVariationsCount = GetNumberOfPedCollectionPropDrawableVariations(ped, propId, currentCollectionName)
                
                if drawable >= currentGlobalIndex and drawable < currentGlobalIndex + propVariationsCount then
                    collectionName = currentCollectionName
                    localIndex = drawable - currentGlobalIndex
                    break
                end
                
                currentGlobalIndex = currentGlobalIndex + propVariationsCount
            end
            
            -- Use collection-based native for props
            if collectionName and localIndex >= 0 then
                SetPedCollectionPropIndex(ped, propId, collectionName, localIndex, texture, true)
            else
                SetPedPropIndex(ped, propId, drawable, texture, true)
            end
        else
            ClearPedProp(ped, propId)
        end
    end

    -- Hat
    applyPropWithCollection(0, data["hat"] and data["hat"].item, data["hat"] and data["hat"].texture)

    -- Glass
    applyPropWithCollection(1, data["glass"] and data["glass"].item, data["glass"] and data["glass"].texture)

    -- Ear
    applyPropWithCollection(2, data["ear"] and data["ear"].item, data["ear"] and data["ear"].texture)

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
