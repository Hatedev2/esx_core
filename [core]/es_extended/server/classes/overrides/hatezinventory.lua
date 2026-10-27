if Config.CustomInventory ~= "hate-dzinventory" then
    return
end

local inventory = exports["hate-dzinventory"]

local function itemCount(item)
    return item and (tonumber(item.count or item.amount) or 0) or 0
end

-- Weapon helpers act on inventory rows by id, so ignore copies that sit inside backpacks.
local function getWeaponItem(source, weaponName)
    for _, item in ipairs(inventory:GetItemsByName(source, string.lower(weaponName)) or {}) do
        if not item.backpackId then return item end
    end
    return nil
end

Core.PlayerFunctionOverrides.HateDzInventory = {
    getInventory = function(self)
        return function(minimal)
            local items = inventory:GetInventory(self.source)
            if not minimal then return items end

            local result = {}
            for _, item in ipairs(items) do
                if itemCount(item) > 0 then
                    result[item.name] = (result[item.name] or 0) + itemCount(item)
                end
            end
            return result
        end
    end,

    getInventoryItem = function(self)
        return function(name)
            local found = inventory:GetItemByName(self.source, string.lower(name))
            if not found then
                local definition = ESX.Items[name] or {}
                return { name = name, label = definition.label or name, count = 0, amount = 0, weight = definition.weight or 0 }
            end
            return found
        end
    end,

    addInventoryItem = function(self)
        return function(name, count, metadata, slot)
            return inventory:AddItem(self.source, name, count or 1, metadata, slot)
        end
    end,

    removeInventoryItem = function(self)
        return function(name, count, metadata, slot)
            return inventory:RemoveItem(self.source, name, count or 1, slot)
        end
    end,

    setInventoryItem = function(self)
        return function(name, count, metadata)
            count = math.max(0, ESX.Math.Round(tonumber(count) or 0))
            local current = self.getInventoryItem(name)
            local currentCount = itemCount(current)
            if count > currentCount then
                return inventory:AddItem(self.source, name, count - currentCount, metadata)
            elseif count < currentCount then
                return inventory:RemoveItem(self.source, name, currentCount - count)
            end
            return true
        end
    end,

    getWeight = function(self)
        return function()
            local _, weight = inventory:GetInventory(self.source)
            return weight
        end
    end,

    getMaxWeight = function(self)
        return function()
            local _, _, maxWeight = inventory:GetInventory(self.source)
            return maxWeight
        end
    end,

    canCarryItem = function(self)
        return function(name, count)
            return inventory:CanCarryItem(self.source, name, count or 1)
        end
    end,

    canSwapItem = function(self)
        return function(firstItem, firstItemCount, testItem, testItemCount)
            local first = self.getInventoryItem(firstItem)
            local test = ESX.Items[testItem]
            if not first or itemCount(first) < firstItemCount or not test then return false end
            local _, weight, maxWeight = inventory:GetInventory(self.source)
            local nextWeight = weight - ((tonumber(first.weight) or 0) * firstItemCount)
                + ((tonumber(test.weight) or 0) * testItemCount)
            return nextWeight <= maxWeight
        end
    end,

    getLoadout = function()
        return function()
            return {}
        end
    end,

    addWeapon = function(self)
        return function(weaponName, ammo)
            return inventory:AddItem(self.source, string.lower(weaponName), 1, { ammo = tonumber(ammo) or 0 })
        end
    end,

    removeWeapon = function(self)
        return function(weaponName)
            local weapon = getWeaponItem(self.source, weaponName)
            return weapon and inventory:RemoveItem(self.source, weapon.name, 1, weapon.slot) or false
        end
    end,

    hasWeapon = function(self)
        return function(weaponName)
            return getWeaponItem(self.source, weaponName) ~= nil
        end
    end,

    getWeapon = function(self)
        return function(weaponName)
            local weapon = getWeaponItem(self.source, weaponName)
            return weapon and weapon.slot or nil, weapon
        end
    end,

    addWeaponAmmo = function(self)
        return function(weaponName, ammoCount)
            local weapon = getWeaponItem(self.source, weaponName)
            return weapon and inventory:AddWeaponAmmo(self.source, weapon.id, tonumber(ammoCount) or 0) or false
        end
    end,

    removeWeaponAmmo = function(self)
        return function(weaponName, ammoCount)
            local weapon = getWeaponItem(self.source, weaponName)
            return weapon and inventory:AddWeaponAmmo(self.source, weapon.id, -(tonumber(ammoCount) or 0)) or false
        end
    end,

    updateWeaponAmmo = function(self)
        return function(weaponName, ammoCount)
            local weapon = getWeaponItem(self.source, weaponName)
            if not weapon then return false end
            local metadata = weapon.metadata or {}
            metadata.ammo = math.max(0, tonumber(ammoCount) or 0)
            return inventory:SetItemMetadata(self.source, weapon.id, metadata)
        end
    end,

    hasItem = function(self)
        return function(name)
            local item = self.getInventoryItem(name)
            local count = itemCount(item)
            if count < 1 then return false end
            return item, count
        end
    end,
}