local function printFullCollectionInfo(ped, collectionName)
    collectionName = collectionName or ''
    print(string.format('   Name: "%s"', collectionName))

    print('   Number of drawable variations per component number:')
    for componentId = 0, 12 do
        local drawableCount = GetNumberOfPedCollectionDrawableVariations(ped, componentId, collectionName) or 0
        print(string.format('       For component %d: %d', componentId, drawableCount))
    end

    print('   Number of drawable variations per anchor point:')
    for anchorId = 0, 12 do
        local propCount = GetNumberOfPedCollectionPropDrawableVariations(ped, anchorId, collectionName) or 0
        print(string.format('       For anchor %d: %d', anchorId, propCount))
    end
end

local function printFullCollectionsInfo(ped)
    local collectionsCount = GetPedCollectionsCount(ped) or 0
    print(string.format('Found %d collections', collectionsCount))

    for index = 0, collectionsCount - 1 do
        local collectionName = GetPedCollectionName(ped, index)
        print(string.format('Collection %d', index))
        printFullCollectionInfo(ped, collectionName)
    end
end

RegisterCommand('PrintFullPlayerPedCollectionsInfo', function()
    local playerPed = PlayerPedId()
    printFullCollectionsInfo(playerPed)
end, true)

local function setLook(ped)
    SetPedCollectionComponentVariation(ped, 0, '', 27, 0, 0)
    SetPedCollectionComponentVariation(ped, 4, 'female_heist', 9, 3, 0)
    SetPedCollectionPropIndex(ped, 0, 'mp_f_bikerdlc_01', 0, 0, false)
end

local function testInvalidComponentVariation(ped)
    SetPedCollectionComponentVariation(ped, 11, 'female_freemode_beach', 999999, 0, 0)

    if not IsPedCollectionComponentVariationValid(ped, 11, 'female_freemode_beach', 999999, 0, 0) then
        print('Invalid component drawable variation was requested.')
    end
end

RegisterCommand('SetPlayerPedLook', function()
    local playerPed = PlayerPedId()
    setLook(playerPed)
    testInvalidComponentVariation(playerPed)
end, true)

local function printPedLookInfo(ped, componentId)
    print(string.format('For component id %d, the following drawable is used:', componentId))

    local collectionName = GetPedDrawableVariationCollectionName(ped, componentId) or ''
    local collectionLocalIndex = GetPedDrawableVariationCollectionLocalIndex(ped, componentId)
    collectionLocalIndex = type(collectionLocalIndex) == 'number' and collectionLocalIndex or -1

    print(string.format('   Collection name: "%s"', collectionName))
    print(string.format('   Local drawable index: %d', collectionLocalIndex))

    local globalDrawableIndex = GetPedDrawableGlobalIndexFromCollection(ped, componentId, collectionName, collectionLocalIndex) or -1
    print(string.format('   Which corresponds to global drawable index: %d', globalDrawableIndex))
end

RegisterCommand('PrintPlayerPantsInfo', function()
    local playerPed = PlayerPedId()
    printPedLookInfo(playerPed, 4)
end, true)
