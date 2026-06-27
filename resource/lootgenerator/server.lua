--[[
    ============================================================
    Loot Generator Usage Guide
    ============================================================

    st.GenerateLoot(pool, itemCount, guaranteedRarities)

    Generates random loot from a loot pool.

    Supports two different loot pool formats:

    1. Rarity-based loot pools
    2. Flat loot pools

    It can also support:
    - Random rarity selection using global weights
    - Guaranteed rarity drops
    - Per-item rarity chances
    - Metadata copying
    - Empty/no-drop items using "_NOTHING_"


    ============================================================
    Function Parameters
    ============================================================

    @param pool table
        The loot pool to generate loot from.

    @param itemCount number|nil
        How many loot rolls should be made.
        Defaults to 1 if nil.

    @param guaranteedRarities table|nil
        Optional guaranteed rarity drops.
        Only works with rarity-based loot pools.

        Format:
        {
            ["RARITY_NAME"] = amount,
        }


    ============================================================
    Return Value
    ============================================================

    @return table
        Returns an array of generated loot entries.

        Each loot entry has this format:

        {
            name = "item_name",
            count = amount,
            metadata = {
                rarity = "COMMON",
                -- custom metadata here
            }
        }


    ============================================================
    1. Rarity-Based Loot Pool
    ============================================================

    This format separates items by rarity.

    The rarity is selected using LootRarityWeights:

        COMMON    = 800
        RARE      = 150
        EPIC      = 45
        LEGENDARY = 5

    Higher weight means higher chance.

    Example:

    local TreasureLoot = {
        COMMON = {
            { name = "bread", min = 1, max = 3 },
            { name = "water", min = 1, max = 2 },
        },

        RARE = {
            { name = "silver_ring", min = 1, max = 1 },
            { name = "gold_coin", min = 2, max = 5 },
        },

        EPIC = {
            { name = "diamond", min = 1, max = 1 },
        },

        LEGENDARY = {
            { name = "ancient_relic", min = 1, max = 1 },
        },
    }

    Usage:

    local loot = st.GenerateLoot(TreasureLoot, 3)

    This will generate 3 loot rolls.
    Each roll randomly selects a rarity based on LootRarityWeights,
    then randomly selects an item from that rarity.


    ============================================================
    2. Rarity-Based Loot Pool With Guaranteed Drops
    ============================================================

    You can force specific rarities to drop.

    Example:

    local loot = st.GenerateLoot(TreasureLoot, 5, {
        LEGENDARY = 1,
        EPIC = 1,
    })

    This means:
    - 1 guaranteed LEGENDARY item
    - 1 guaranteed EPIC item
    - 3 remaining random loot rolls

    Important:
    Guaranteed drops subtract from itemCount.

    So this:

        st.GenerateLoot(TreasureLoot, 5, {
            LEGENDARY = 1,
        })

    Gives:
    - 1 guaranteed LEGENDARY
    - 4 random rarity rolls


    ============================================================
    3. Flat Loot Pool
    ============================================================

    A flat loot pool is just a normal array of items.

    It does not use the global LootRarityWeights.
    It uses per-item 'chance' as an independent inclusion roll.
    If 'chance' is missing, default chance is 100 (guaranteed).

    Example:

    local SimpleLoot = {
        { name = "apple", min = 1, max = 3 },
        { name = "bread", min = 1, max = 2 },
        { name = "water", min = 1, max = 1 },
    }

    Usage:

    local loot = st.GenerateLoot(SimpleLoot, 2)

    This runs 2 rounds.
    In each round, every item is rolled by its own chance.
    Because each item is rolled independently, multiple items
    can be added in the same round.

    Result example:

    {
        {
            name = "apple",
            count = 2,
            metadata = {}
        },
        {
            name = "water",
            count = 1,
            metadata = {}
        },
        {
            name = "bread",
            count = 2,
            metadata = {}
        }
    }


    ============================================================
    4. Flat Loot Pool With Per-Item Rarity Chances
    ============================================================

    Flat loot pools can define rarity chances per item.

    Example:

    local WeaponLoot = {
        {
            name = "weapon_revolver",
            min = 1,
            max = 1,
            rarities = {
                COMMON = 70,
                RARE = 20,
                EPIC = 8,
                LEGENDARY = 2,
            }
        },

        {
            name = "weapon_rifle",
            min = 1,
            max = 1,
            rarities = {
                RARE = 60,
                EPIC = 30,
                LEGENDARY = 10,
            }
        },
    }

    Usage:

    local loot = st.GenerateLoot(WeaponLoot, 1)

    In each round, each item is first rolled by its own 'chance'.
    If an item is included, that item's rarity table is then rolled.

    If a rarity is selected, it is added to metadata:

    {
        name = "weapon_revolver",
        count = 1,
        metadata = {
            rarity = "RARE"
        }
    }


    ============================================================
    5. Per-Item Rarity Chance With No Rarity Chance
    ============================================================

    If total rarity chances are below 100, the remaining chance means
    the item receives no rarity metadata.

    Example:

    local Loot = {
        {
            name = "old_necklace",
            min = 1,
            max = 1,
            rarities = {
                RARE = 20,
                EPIC = 5,
            }
        }
    }

    Total chance is 25.

    This means:
    - 20% chance for RARE
    - 5% chance for EPIC
    - 75% chance for no rarity

    Usage:

    local loot = st.GenerateLoot(Loot, 1)


    ============================================================
    6. Metadata Usage
    ============================================================

    Items can include custom metadata.

    Example:

    local Loot = {
        COMMON = {
            {
                name = "gold_watch",
                min = 1,
                max = 1,
                metadata = {
                    label = "Engraved Gold Watch",
                    durability = 100,
                    serial = "WATCH_001"
                }
            }
        }
    }

    Usage:

    local loot = st.GenerateLoot(Loot, 1)

    Result example:

    {
        {
            name = "gold_watch",
            count = 1,
            metadata = {
                label = "Engraved Gold Watch",
                durability = 100,
                serial = "WATCH_001",
                rarity = "COMMON"
            }
        }
    }

    The metadata is copied before being modified.
    This prevents the original config item from being changed.


    ============================================================
    7. Empty / Nothing Drops
    ============================================================

    You can use "_NOTHING_" as an item name to create a chance for
    no item to be added to the final loot table.

    Example:

    local Loot = {
        COMMON = {
            { name = "_NOTHING_", min = 1, max = 1 },
            { name = "bread", min = 1, max = 2 },
            { name = "water", min = 1, max = 1 },
        }
    }

    Usage:

    local loot = st.GenerateLoot(Loot, 3)

    If "_NOTHING_" is selected, it is skipped and not inserted into loot.

    This means the returned loot table may contain fewer items than itemCount.


    ============================================================
    8. Amount / Count Handling
    ============================================================

    Each item can define min and max.

    Example:

    {
        name = "gold_coin",
        min = 5,
        max = 15
    }

    This means the generated count will be random between 5 and 15.

    If min or max is missing, it defaults to 1.

    Example:

    {
        name = "bread"
    }

    Same as:

    {
        name = "bread",
        min = 1,
        max = 1
    }


    ============================================================
    9. Generate One Item
    ============================================================

    local loot = st.GenerateLoot(TreasureLoot)

    Same as:

    local loot = st.GenerateLoot(TreasureLoot, 1)


    ============================================================
    10. Generate Multiple Items
    ============================================================

    local loot = st.GenerateLoot(TreasureLoot, 10)

    This performs 10 loot rolls.


    ============================================================
    11. Generate Only Guaranteed Rarities
    ============================================================

    local loot = st.GenerateLoot(TreasureLoot, 2, {
        RARE = 1,
        LEGENDARY = 1,
    })

    This creates:
    - 1 RARE item
    - 1 LEGENDARY item
    - 0 random rolls


    ============================================================
    12. Guaranteed Rarities Higher Than itemCount
    ============================================================

    local loot = st.GenerateLoot(TreasureLoot, 1, {
        RARE = 2,
        EPIC = 1,
    })

    This can still create 3 guaranteed items.

    itemCount is reduced below 0 internally,
    and the random roll loop will not run.

    Result:
    - 2 RARE items
    - 1 EPIC item
    - 0 random rolls


    ============================================================
    13. Invalid Pool Handling
    ============================================================

    If pool is not a table, an empty table is returned.

    Example:

    local loot = st.GenerateLoot(nil, 3)

    Result:

    {}


    ============================================================
    14. Missing Rarity Category
    ============================================================

    If a random rarity is selected but the pool does not contain items
    for that rarity, no item is added for that roll.

    Example:

    local Loot = {
        COMMON = {
            { name = "bread", min = 1, max = 1 },
        }
    }

    local loot = st.GenerateLoot(Loot, 5)

    If RARE, EPIC, or LEGENDARY is rolled, nothing is inserted.

    Recommended:
    Always define all rarity categories if using rarity-based pools:

    COMMON = {}
    RARE = {}
    EPIC = {}
    LEGENDARY = {}


    ============================================================
    15. Example: Chest Loot
    ============================================================

    local ChestLoot = {
        COMMON = {
            { name = "bread", min = 1, max = 3 },
            { name = "water", min = 1, max = 2 },
        },

        RARE = {
            { name = "lockpick", min = 1, max = 2 },
        },

        EPIC = {
            { name = "gold_bar", min = 1, max = 1 },
        },

        LEGENDARY = {
            { name = "rare_map", min = 1, max = 1 },
        },
    }

    local loot = st.GenerateLoot(ChestLoot, 4)


    ============================================================
    16. Example: Boss Reward With Guaranteed Legendary
    ============================================================

    local loot = st.GenerateLoot(ChestLoot, 5, {
        LEGENDARY = 1,
    })

    This gives:
    - 1 guaranteed legendary item
    - 4 random items


    ============================================================
    17. Example: Robbery Reward With Chance For Nothing
    ============================================================

    local RobberyLoot = {
        COMMON = {
            { name = "_NOTHING_", min = 1, max = 1 },
            { name = "cash", min = 10, max = 50 },
            { name = "watch", min = 1, max = 1 },
        },

        RARE = {
            { name = "gold_ring", min = 1, max = 2 },
        },

        EPIC = {
            { name = "diamond_ring", min = 1, max = 1 },
        },

        LEGENDARY = {
            { name = "ancient_coin", min = 1, max = 1 },
        },
    }

    local loot = st.GenerateLoot(RobberyLoot, 3)


    ============================================================
    18. Example: Weapon With Random Quality
    ============================================================

    local WeaponLoot = {
        {
            name = "weapon_revolver",
            min = 1,
            max = 1,
            metadata = {
                durability = 100
            },
            rarities = {
                COMMON = 60,
                RARE = 25,
                EPIC = 10,
                LEGENDARY = 5,
            }
        }
    }

    local loot = st.GenerateLoot(WeaponLoot, 1)

    Possible result:

    {
        {
            name = "weapon_revolver",
            count = 1,
            metadata = {
                durability = 100,
                rarity = "EPIC"
            }
        }
    }


    ============================================================
    Notes
    ============================================================

    - Rarity-based pools use global LootRarityWeights.
    - Flat pools do not use global LootRarityWeights.
    - Flat pools can use per-item rarities.
        - Flat pools can use per-item inclusion 'chance' (default 100).
        - Flat pools can return multiple items per roll.
    - Guaranteed rarities only work properly with rarity-based pools.
    - "_NOTHING_" creates a no-drop result.
    - Metadata is copied before rarity is added.
        - The returned loot count can be lower than itemCount if "_NOTHING_"
            or missing rarity pools are selected.
        - For flat pools, returned loot count can also be higher than itemCount
            because each roll can include more than one item.
]]

local LootRarityWeights = {
    ["COMMON"] = 800,
    ["RARE"] = 150,
    ["EPIC"] = 45,
    ["LEGENDARY"] = 5,
}

---Generates a random rarity based on global rarity weights.
---@return string
local function selectRarity()
    local totalWeight = 0

    for _, weight in pairs(LootRarityWeights) do
        totalWeight = totalWeight + weight
    end

    local randomNumber = math.random(1, totalWeight)
    local cumulativeWeight = 0

    for rarity, weight in pairs(LootRarityWeights) do
        cumulativeWeight = cumulativeWeight + weight
        if randomNumber <= cumulativeWeight then
            return rarity
        end
    end

    return "COMMON"
end

---Rolls rarity from a per-item rarity chance table.
---If total chances are below 100, the remaining chance means no rarity.
---@param rarityTable table|nil
---@return string|nil
local function selectItemRarity(rarityTable)
    if type(rarityTable) ~= "table" then
        return nil
    end

    local totalChance = 0

    for _, chance in pairs(rarityTable) do
        if type(chance) == "number" and chance > 0 then
            totalChance = totalChance + chance
        end
    end

    if totalChance <= 0 then
        return nil
    end

    local roll = math.random(1, 100)
    if roll > totalChance then
        return nil
    end

    local cumulativeChance = 0

    for rarity, chance in pairs(rarityTable) do
        if type(chance) == "number" and chance > 0 then
            cumulativeChance = cumulativeChance + chance
            if roll <= cumulativeChance then
                return rarity
            end
        end
    end

    return nil
end

---Retrieves a random item from a list.
---@param items table
---@return table|nil
local function getRandomItemFromList(items)
    if items and #items > 0 then
        return items[math.random(1, #items)]
    end

    return nil
end

---Copies metadata so config data is never mutated.
---@param metadata table|nil
---@return table
local function copyMetadata(metadata)
    if type(metadata) ~= "table" then
        return {}
    end

    local newTable = {}

    for key, value in pairs(metadata) do
        if type(value) == "table" then
            local subTable = {}
            for subKey, subValue in pairs(value) do
                subTable[subKey] = subValue
            end
            newTable[key] = subTable
        else
            newTable[key] = value
        end
    end

    return newTable
end

---Rolls inclusion chance for flat pool items.
---Missing chance defaults to 100 (guaranteed).
---@param chance number|nil
---@return boolean
local function shouldIncludeFlatPoolItem(chance)
    local numericChance = tonumber(chance)

    if not numericChance then
        numericChance = 100
    end

    if numericChance <= 0 then
        return false
    end

    if numericChance >= 100 then
        return true
    end

    return math.random(1, 100) <= numericChance
end

---Checks if the pool is a flat loot pool.
---@param pool table
---@return boolean
local function isFlatLootPool(pool)
    return type(pool) == "table" and #pool > 0 and type(pool[1]) == "table"
end

---Creates one or more loot entries.
---@param chosenItem table
---@param rarity string|nil
---@return table
local function createLootEntries(chosenItem, rarity)
    if not chosenItem or chosenItem.name == "_NOTHING_" then
        return {}
    end

    local amount = math.random(chosenItem.min or 1, chosenItem.max or 1)

    -- For flat pool items with per-item rarities, roll rarity per unit,
    -- then group units back into entries by rarity metadata.
    if not rarity and type(chosenItem.rarities) == "table" then
        local groupedCounts = {}

        for i = 1, amount do
            local rolledRarity = selectItemRarity(chosenItem.rarities)
            local rarityKey = rolledRarity or "__NONE__"
            groupedCounts[rarityKey] = (groupedCounts[rarityKey] or 0) + 1
        end

        local groupedEntries = {}
        for rarityKey, count in pairs(groupedCounts) do
            local metadata = copyMetadata(chosenItem.metadata)

            if rarityKey ~= "__NONE__" then
                metadata.rarity = rarityKey
            end

            groupedEntries[#groupedEntries + 1] = {
                name = chosenItem.name,
                count = count,
                metadata = metadata,
            }
        end

        return groupedEntries
    end

    local metadata = copyMetadata(chosenItem.metadata)

    if rarity then
        metadata.rarity = rarity
    end

    return {
        {
            name = chosenItem.name,
            count = amount,
            metadata = metadata,
        }
    }
end

---Appends generated loot entries to the final loot array.
---@param loot table
---@param lootEntries table
local function appendLootEntries(loot, lootEntries)
    for i = 1, #lootEntries do
        table.insert(loot, lootEntries[i])
    end
end

---Generates loot from a specified pool.
---@param pool table The loot pool table.
---@param itemCount number|nil The total number of items to generate. Defaults to 1.
---@param guaranteedRarities table|nil Optional guaranteed rarity drops. Format: { ["RARITY_NAME"] = count, ... }
---@return table
st.GenerateLoot = function(pool, itemCount, guaranteedRarities)
    local loot = {}

    itemCount = itemCount or 1

    if type(pool) ~= "table" then
        return loot
    end

    local flatPool = isFlatLootPool(pool)
    if flatPool then
        for i = 1, math.max(0, itemCount) do
            for itemIndex = 1, #pool do
                local chosenItem = pool[itemIndex]

                if chosenItem and shouldIncludeFlatPoolItem(chosenItem.chance) then
                    local lootEntries = createLootEntries(chosenItem, nil)
                    appendLootEntries(loot, lootEntries)
                end
            end
        end

        return loot
    end

    if guaranteedRarities and type(guaranteedRarities) == "table" then
        for rarity, guaranteedCount in pairs(guaranteedRarities) do
            local itemsOfRarity = pool[rarity]

            if itemsOfRarity and #itemsOfRarity > 0 then
                for i = 1, guaranteedCount do
                    local chosenItem = getRandomItemFromList(itemsOfRarity)
                    local lootEntries = createLootEntries(chosenItem, rarity)
                    appendLootEntries(loot, lootEntries)

                    itemCount = itemCount - 1
                end
            else
                st.print.warn(
                    ("Guaranteed rarity '%s' specified, but no items found in pool for this rarity."):format(rarity)
                )
            end
        end
    end

    for i = 1, math.max(0, itemCount) do
        local selectedRarity = selectRarity()
        local itemsOfSelectedRarity = pool[selectedRarity]

        if itemsOfSelectedRarity and #itemsOfSelectedRarity > 0 then
            local chosenItem = getRandomItemFromList(itemsOfSelectedRarity)
            local lootEntries = createLootEntries(chosenItem, selectedRarity)
            appendLootEntries(loot, lootEntries)
        end
    end

    return loot
end