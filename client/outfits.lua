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

    local collectionsCount = GetPedCollectionsCount(ped)

    -- Helper function to convert global index to collection-based and apply
    local function applyComponentWithCollection(componentId, dataEntry)
        if not dataEntry then return end

        local drawable = dataEntry.item or dataEntry.drawable
        local texture = dataEntry.texture or 0
        local collectionName = dataEntry.collection or dataEntry.collectionName
        local localIndex = dataEntry.collection_local_index or dataEntry.collectionLocalIndex

        if collectionName ~= nil and localIndex ~= nil then
            dataEntry.collection = collectionName
            dataEntry.collection_local_index = localIndex
            SetPedCollectionComponentVariation(ped, componentId, collectionName, localIndex, texture, 0)
        elseif drawable ~= nil then
            local resolvedCollection, resolvedIndex = client.getComponentCollectionData(ped, componentId, drawable)

            if resolvedCollection ~= nil and resolvedIndex ~= nil then
                dataEntry.collection = resolvedCollection
                dataEntry.collection_local_index = resolvedIndex
                SetPedCollectionComponentVariation(ped, componentId, resolvedCollection, resolvedIndex, texture, 0)
            elseif not collectionsCount or collectionsCount <= 0 then
                SetPedComponentVariation(ped, componentId, drawable, texture, 0)
            end
        end
    end

    -- Pants
    applyComponentWithCollection(4, data["pants"])

    -- Arms
    applyComponentWithCollection(3, data["arms"])

    -- T-Shirt
    applyComponentWithCollection(8, data["t-shirt"])

    -- Vest
    applyComponentWithCollection(9, data["vest"])

    -- Torso 2
    applyComponentWithCollection(11, data["torso2"])

    -- Shoes
    applyComponentWithCollection(6, data["shoes"])

    -- Badge
    applyComponentWithCollection(10, data["decals"])

    -- Accessory
    local tracker = Config.TrackerClothingOptions

    if data["accessory"] ~= nil then
        if Framework.HasTracker() then
            applyComponentWithCollection(7, tracker)
        else
            applyComponentWithCollection(7, data["accessory"])
        end
    else
        if Framework.HasTracker() then
            applyComponentWithCollection(7, tracker)
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
    applyComponentWithCollection(1, data["mask"])

    -- Bag
    applyComponentWithCollection(5, data["bag"])

    -- Helper function to convert global prop index to collection-based and apply
    local function applyPropWithCollection(propId, dataEntry)
        if not dataEntry then
            ClearPedProp(ped, propId)
            return
        end

        local drawable = dataEntry.item or dataEntry.drawable
        local texture = dataEntry.texture or 0
        local collectionName = dataEntry.collection or dataEntry.collectionName
        local localIndex = dataEntry.collection_local_index or dataEntry.collectionLocalIndex

        if drawable ~= nil and drawable ~= -1 and drawable ~= 0 then
            if collectionName ~= nil and localIndex ~= nil then
                dataEntry.collection = collectionName
                dataEntry.collection_local_index = localIndex
                SetPedCollectionPropIndex(ped, propId, collectionName, localIndex, texture, true)
            else
                local resolvedCollection, resolvedIndex = client.getPropCollectionData(ped, propId, drawable)

                if resolvedCollection ~= nil and resolvedIndex ~= nil then
                    dataEntry.collection = resolvedCollection
                    dataEntry.collection_local_index = resolvedIndex
                    SetPedCollectionPropIndex(ped, propId, resolvedCollection, resolvedIndex, texture, true)
                elseif not collectionsCount or collectionsCount <= 0 then
                    SetPedPropIndex(ped, propId, drawable, texture, true)
                end
            end
        else
            dataEntry.collection = nil
            dataEntry.collection_local_index = nil
            ClearPedProp(ped, propId)
        end
    end

    -- Hat
    applyPropWithCollection(0, data["hat"])

    -- Glass
    applyPropWithCollection(1, data["glass"])

    -- Ear
    applyPropWithCollection(2, data["ear"])

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
