if Config.CustomInventory ~= "hate-dzinventory" then return end

-- hate-dzinventory owns the item list (its items.lua). Mirror it into ESX.Items so
-- ESX.UseItem, ESX.GetItemLabel and xPlayer item helpers recognise those items.
local function refreshItems()
    if GetResourceState("hate-dzinventory") ~= "started" then return end
    local ok, definitions = pcall(function()
        return exports["hate-dzinventory"]:GetItemDefinition()
    end)
    if not ok or type(definitions) ~= "table" then return end

    local items = {}
    for name, definition in pairs(definitions) do
        items[name] = {
            name = name,
            label = definition.label or name,
            weight = tonumber(definition.weight) or 0,
            rare = definition.rare == true,
            canRemove = definition.canRemove ~= false,
            usable = definition.useable == true or definition.usable == true,
            description = definition.description,
        }
    end
    ESX.Items = items
end

MySQL.ready(function()
    ESXCatalog.awaitReady()
    refreshItems()
end)

AddEventHandler("onResourceStart", function(resourceName)
    if resourceName == "hate-dzinventory" then refreshItems() end
end)

AddEventHandler("hate-dzinventory:itemsReloaded", refreshItems)

---@diagnostic disable-next-line: duplicate-set-field
ESX.GetItemLabel = function(item)
    local definition = ESX.Items[item]
    return definition and definition.label or nil
end
