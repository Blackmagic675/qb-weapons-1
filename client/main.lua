-- Variables
local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = QBCore.Functions.GetPlayerData()
local CurrentWeaponData, CanShoot, MultiplierAmount = {}, true, 0

-- Handlers

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    QBCore.Functions.TriggerCallback("weapons:server:GetConfig", function(RepairPoints)
        for k, data in pairs(RepairPoints) do
            Config.WeaponRepairPoints[k].IsRepairing = data.IsRepairing
            Config.WeaponRepairPoints[k].RepairingData = data.RepairingData
        end
    end)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    for k in pairs(Config.WeaponRepairPoints) do
        Config.WeaponRepairPoints[k].IsRepairing = false
        Config.WeaponRepairPoints[k].RepairingData = {}
    end
end)

-- Functions

local function DrawText3Ds(x, y, z, text)
	SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    BeginTextCommandDisplayText("STRING")
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(x,y,z, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

-- Events

RegisterNetEvent("weapons:client:SyncRepairShops", function(NewData, key)
    Config.WeaponRepairPoints[key].IsRepairing = NewData.IsRepairing
    Config.WeaponRepairPoints[key].RepairingData = NewData.RepairingData
end)

RegisterNetEvent("addAttachment", function(component)
    local ped = PlayerPedId()
    local weapon = GetSelectedPedWeapon(ped)
    local WeaponData = QBCore.Shared.Weapons[weapon]
    GiveWeaponComponentToPed(ped, GetHashKey(WeaponData.name), GetHashKey(component))
end)

--[[RegisterNetEvent('weapons:client:EquipTint', function(tint)
    local player = PlayerPedId()
    local weapon = GetSelectedPedWeapon(player)
    SetPedWeaponTintIndex(player, weapon, tint)
end)]]

RegisterNetEvent('weapons:client:EquipTint', function(tint)
    local player = PlayerPedId()
    local weapon = GetSelectedPedWeapon(player)
    SetPedWeaponTintIndex(player, weapon, tint)
    TriggerServerEvent("weapons:server:ApplyTint", CurrentWeaponData, tint)
    --[[if tint == 0 then
        itemName = "weapontint_black"
    elseif tint == 1 then
        itemName = "weapontint_1"
    elseif tint == 2 then
        itemName = "weapontint_2"
    elseif tint == 3 then
        itemName = "weapontint_3"
    elseif tint == 4 then
        itemName = "weapontint_4"
    elseif tint == 5 then
        itemName = "weapontint_5"
    elseif tint == 6 then
        itemName = "weapontint_6"
    elseif tint == 7 then
        itemName = "weapontint_7"
    end

    TriggerServerEvent('weapons:server:removeWeaponTintItem', itemName)]]
end)

RegisterNetEvent('weapons:client:SetCurrentWeapon', function(data, bool)
    if data ~= false then
        CurrentWeaponData = data
    else
        CurrentWeaponData = {}
    end
    CanShoot = bool
end)

RegisterNetEvent('weapons:client:SetWeaponQuality', function(amount)
    if CurrentWeaponData and next(CurrentWeaponData) then
        TriggerServerEvent("weapons:server:SetWeaponQuality", CurrentWeaponData, amount)
    end
end)

RegisterNetEvent('weapons:client:AddAmmo', function(type, amount, itemData)
    local ped = PlayerPedId()
    local weapon = GetSelectedPedWeapon(ped)
    if CurrentWeaponData then
        if QBCore.Shared.Weapons[weapon]["name"] ~= "weapon_unarmed" and QBCore.Shared.Weapons[weapon]["ammotype"] == type:upper() then
            local total = GetAmmoInPedWeapon(ped, weapon)
            local _, maxAmmo = GetMaxAmmo(ped, weapon)
            if total < maxAmmo then
                    if QBCore.Shared.Weapons[weapon] then
                        AddAmmoToPed(ped,weapon,amount)
                        TaskReloadWeapon(ped)
                        TriggerServerEvent("weapons:server:UpdateWeaponAmmo", CurrentWeaponData, total + amount)
                        TriggerServerEvent('weapons:server:removeWeaponAmmoItem', itemData)
                        TriggerEvent('inventory:client:ItemBox', QBCore.Shared.Items[itemData.name], "remove")
                        TriggerEvent('QBCore:Notify', Lang:t('success.reloaded'), "success")
                    end
            else
                QBCore.Functions.Notify(Lang:t('error.max_ammo'), "error")
            end
        else
            QBCore.Functions.Notify(Lang:t('error.no_weapon'), "error")
        end
    else
        QBCore.Functions.Notify(Lang:t('error.no_weapon'), "error")
    end
end)

RegisterNetEvent("weapons:client:EquipAttachment", function(ItemData, attachment)
    local ped = PlayerPedId()
    local weapon = GetSelectedPedWeapon(ped)
    local WeaponData = QBCore.Shared.Weapons[weapon]
    if weapon ~= `WEAPON_UNARMED` then
        WeaponData.name = WeaponData.name:upper()
        if WeaponAttachments[WeaponData.name] then
            if WeaponAttachments[WeaponData.name][attachment]['item'] == ItemData.name then
                TriggerServerEvent("weapons:server:EquipAttachment", ItemData, CurrentWeaponData, WeaponAttachments[WeaponData.name][attachment])
            else
                QBCore.Functions.Notify(Lang:t('error.no_support_attachment'), "error")
            end
        end
    else
        QBCore.Functions.Notify(Lang:t('error.no_weapon_in_hand'), "error")
    end
end)

-- Threads

CreateThread(function()
    SetWeaponsNoAutoswap(true)
end)

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if IsPedArmed(ped, 7) == 1 and (IsControlJustReleased(0, 24) or IsDisabledControlJustReleased(0, 24)) then
            local weapon = GetSelectedPedWeapon(ped)
            local ammo = GetAmmoInPedWeapon(ped, weapon)
            TriggerServerEvent("weapons:server:UpdateWeaponAmmo", CurrentWeaponData, tonumber(ammo))
            if MultiplierAmount > 0 then
                TriggerServerEvent("weapons:server:UpdateWeaponQuality", CurrentWeaponData, MultiplierAmount)
                MultiplierAmount = 0
            end
        end
        Wait(0)
    end
end)

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if IsPedArmed(ped, 7) then
            local weapon = GetSelectedPedWeapon(ped)
            local ammo = GetAmmoInPedWeapon(ped, weapon)
            TriggerServerEvent("weapons:server:UpdateWeaponAmmo", CurrentWeaponData, tonumber(ammo))
        end
        Wait(100)
    end
end)

CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn then
            local ped = PlayerPedId()
            if CurrentWeaponData and next(CurrentWeaponData) then
                if IsPedShooting(ped) or IsControlJustPressed(0, 24) then
                    local weapon = GetSelectedPedWeapon(ped)
                    if CanShoot then
                        if weapon and weapon ~= 0 and QBCore.Shared.Weapons[weapon] then
                            QBCore.Functions.TriggerCallback('prison:server:checkThrowable', function(result)
                                if result or GetAmmoInPedWeapon(ped, weapon) <= 0 then return end
                                MultiplierAmount += 1
                            end, weapon)
                            Wait(200)
                        end
                    else
                        if weapon ~= `WEAPON_UNARMED` then
                            TriggerEvent('inventory:client:CheckWeapon', QBCore.Shared.Weapons[weapon]["name"])
                            QBCore.Functions.Notify(Lang:t('error.weapon_broken'), "error")
                            MultiplierAmount = 0
                        end
                    end
                end
            end
        end
        Wait(0)
    end
end)

CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn then
            local inRange = false
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            for k, data in pairs(Config.WeaponRepairPoints) do
                local distance = #(pos - data.coords)
                if distance < 10 then
                    inRange = true
                    if distance < 1 then
                        if data.IsRepairing then
                            if data.RepairingData.CitizenId ~= PlayerData.citizenid then
                                DrawText3Ds(data.coords.x, data.coords.y, data.coords.z, Lang:t('info.repairshop_not_usable'))
                            else
                                if not data.RepairingData.Ready then
                                    DrawText3Ds(data.coords.x, data.coords.y, data.coords.z, Lang:t('info.weapon_will_repair'))
                                else
                                    DrawText3Ds(data.coords.x, data.coords.y, data.coords.z, Lang:t('info.take_weapon_back'))
                                end
                            end
                        else
                            if CurrentWeaponData and next(CurrentWeaponData) then
                                if not data.RepairingData.Ready then
                                    local WeaponData = QBCore.Shared.Weapons[GetHashKey(CurrentWeaponData.name)]
                                    local WeaponClass = (QBCore.Shared.SplitStr(WeaponData.ammotype, "_")[2]):lower()
                                    DrawText3Ds(data.coords.x, data.coords.y, data.coords.z, Lang:t('info.repair_weapon_price', { value = Config.WeaponRepairCosts[WeaponClass] }))
                                    if IsControlJustPressed(0, 38) then
                                        QBCore.Functions.TriggerCallback('weapons:server:RepairWeapon', function(HasMoney)
                                            if HasMoney then
                                                CurrentWeaponData = {}
                                            end
                                        end, k, CurrentWeaponData)
                                    end
                                else
                                    if data.RepairingData.CitizenId ~= PlayerData.citizenid then
                                        DrawText3Ds(data.coords.x, data.coords.y, data.coords.z, Lang:t('info.repairshop_not_usable'))
                                    else
                                        DrawText3Ds(data.coords.x, data.coords.y, data.coords.z, Lang:t('info.take_weapon_back'))
                                        if IsControlJustPressed(0, 38) then
                                            TriggerServerEvent('weapons:server:TakeBackWeapon', k, data)
                                        end
                                    end
                                end
                            else
                                if data.RepairingData.CitizenId == nil then
                                    DrawText3Ds(data.coords.x, data.coords.y, data.coords.z, Lang:t('error.no_weapon_in_hand'))
                                elseif data.RepairingData.CitizenId == PlayerData.citizenid then
                                    DrawText3Ds(data.coords.x, data.coords.y, data.coords.z, Lang:t('info.take_weapon_back'))
                                    if IsControlJustPressed(0, 38) then
                                        TriggerServerEvent('weapons:server:TakeBackWeapon', k, data)
                                    end
                                end
                            end
                        end
                    end
                end
            end
            if not inRange then
                Wait(1000)
            end
        end
        Wait(0)
    end
end)
