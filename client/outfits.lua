local client = client

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

    local function applyComponent(componentId, slot)
        if not slot or slot.item == nil then return end

        local component = {
            component_id = componentId,
            drawable = slot.item,
            texture = slot.texture or 0,
            collection = slot.collection,
            collectionDrawable = slot.collectionDrawable,
            palette = slot.palette
        }

        client.debugPrint(
            "LoadJobOutfit component=%s drawable=%s texture=%s collection=%s local=%s",
            componentId,
            tostring(component.drawable),
            tostring(component.texture),
            tostring(component.collection),
            tostring(component.collectionDrawable)
        )

        client.setPedComponent(ped, component)
    end

    local function applyProp(propId, slot)
        if not slot then return end

        local drawable = slot.item
        if drawable == nil then return end

        if drawable == -1 or drawable == 0 then
            client.setPedProp(ped, { prop_id = propId, drawable = -1 })
            return
        end

        local prop = {
            prop_id = propId,
            drawable = drawable,
            texture = slot.texture or 0,
            collection = slot.collection,
            collectionDrawable = slot.collectionDrawable,
            attach = slot.attach ~= nil and slot.attach or true
        }

        client.debugPrint(
            "LoadJobOutfit prop=%s drawable=%s texture=%s collection=%s local=%s",
            propId,
            tostring(prop.drawable),
            tostring(prop.texture),
            tostring(prop.collection),
            tostring(prop.collectionDrawable)
        )

        client.setPedProp(ped, prop)
    end

    applyComponent(4, data["pants"])
    applyComponent(3, data["arms"])
    applyComponent(8, data["t-shirt"])
    applyComponent(9, data["vest"])
    applyComponent(11, data["torso2"])
    applyComponent(6, data["shoes"])
    applyComponent(10, data["decals"])
    applyComponent(1, data["mask"])
    applyComponent(5, data["bag"])

    local tracker = Config.TrackerClothingOptions
    if Framework.HasTracker() then
        client.setPedComponent(ped, {
            component_id = 7,
            drawable = tracker.drawable,
            texture = tracker.texture,
            collection = tracker.collection,
            collectionDrawable = tracker.collectionDrawable
        })
    else
        local accessory = data["accessory"]
        if accessory then
            applyComponent(7, accessory)
        else
            local drawableId = GetPedDrawableVariation(ped, 7)
            local textureId = GetPedTextureVariation(ped, 7)
            if drawableId == tracker.drawable and textureId == tracker.texture then
                client.setPedComponent(ped, {
                    component_id = 7,
                    drawable = 0,
                    texture = 0
                })
            end
        end
    end

    applyProp(0, data["hat"])
    applyProp(1, data["glass"])
    applyProp(2, data["ear"])

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
