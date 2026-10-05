--- Remove Vanilla Anything -- loot table stripping.
---
--- Runs once per world load on OnPostDistributionMerge. By the time that fires,
--- vanilla has merged every other mod's distribution table into Distributions[1],
--- published it as SuburbsDistributions and created its ~45 room aliases
--- (see media/lua/server/Items/SuburbsDistributions.lua), so one sweep covers
--- containers, corpses and vehicle interiors together.

require "Items/SuburbsDistributions"

RVA = RVA or {}

local WEAPON_DISPLAY = nil   -- filled lazily from RVA.itemCategories

-- ---------------------------------------------------------------------------
-- Sandbox settings
-- ---------------------------------------------------------------------------

--- SandboxVars does not exist until a world is loading, so every read is guarded.
function RVA.settings()
	local vars = SandboxVars and SandboxVars[RVA.MODULE]
	local enabled = {}
	if vars then
		for _, id in ipairs(RVA.itemCategoryIds) do
			if vars[id] == true then enabled[id] = true end
		end
	end
	return {
		enabled = enabled,
		corpses = vars and vars.ApplyToCorpseLoot == true,
		modded  = vars and vars.ApplyToModdedItems == true,
		log     = vars and vars.LogRemovals == true,
	}
end

local function anyEnabled(enabled)
	for _ in pairs(enabled) do return true end
	return false
end

-- ---------------------------------------------------------------------------
-- Matching items the baked vanilla table does not know about
-- ---------------------------------------------------------------------------

local function weaponDisplay()
	if WEAPON_DISPLAY then return WEAPON_DISPLAY end
	WEAPON_DISPLAY = {}
	for _, cat in ipairs(RVA.itemCategories) do
		if cat.id == "Weapons" and cat.display then WEAPON_DISPLAY = cat.display end
	end
	return WEAPON_DISPLAY
end

--- Strip the "base:" (or any mod's) namespace off a ResourceLocation.
local function bareName(value)
	if not value then return nil end
	local s = string.lower(tostring(value))
	local colon = string.find(s, ":", 1, true)
	if colon then s = string.sub(s, colon + 1) end
	return s
end

local function itemTags(item)
	local ok, tags = pcall(function() return item:getTags() end)
	if not ok or not tags then return nil end
	-- Declared separately: a local is not in scope inside its own initializer, so
	-- a closure there would capture the (nil) global `out` instead.
	local out = {}
	local ok2 = pcall(function()
		local it = tags:iterator()
		while it:hasNext() do
			local t = bareName(it:next())
			if t then out[t] = true end
		end
	end)
	if not ok2 then return nil end
	return out
end

local function subCategory(item)
	local ok, sub = pcall(function() return item.subCategory end)
	if ok and sub then return tostring(sub) end
	return nil
end

local function specialMatch(kind, item, display)
	if kind == "perishable" then
		return display == "Food" and item:getDaysFresh() > 0
	elseif kind == "nonperishable" then
		return display == "Food" and item:getDaysFresh() <= 0
	elseif kind == "fluidcontainer" then
		-- Fluid components are not visible from Lua; the DisplayCategory half of
		-- this category's rule covers drinks for modded items.
		return false
	elseif kind == "firearm" then
		return item:isRanged() == true
	elseif kind == "melee" then
		if not weaponDisplay()[display] then return false end
		local sub = subCategory(item)
		if sub then
			return sub == "Swinging" or sub == "Stab" or sub == "Spear"
		end
		return item:isRanged() ~= true
	elseif kind == "pills" then
		return display == "FirstAid" and bareName(item:getItemType()) == "food"
	elseif kind == "bandage" then
		return item:isCanBandage() == true
	end
	return false
end

--- Category ids matching an item script that is not in the baked vanilla table.
--- Used only when "Also remove modded items" is on, and as a catch-all for items
--- a game patch added since the generator last ran.
function RVA.categoriesFor(item)
	local display = item:getDisplayCategory()
	if display and RVA.forbiddenDisplay[display] then return nil end

	local body = bareName(item:getBodyLocation())
	local itype = item:getItemType() and string.lower(tostring(item:getItemType())) or nil
	local tags = nil
	local hits = nil

	for _, cat in ipairs(RVA.itemCategories) do
		local hit = false
		if cat.display and display and cat.display[display] then
			hit = true
		elseif cat.body and body and not RVA.forbiddenBody[body] and cat.body[body] then
			hit = true
		elseif cat.itype and itype and cat.itype[itype] then
			hit = true
		elseif cat.tags then
			if tags == nil then tags = itemTags(item) or false end
			if tags then
				for tag in pairs(cat.tags) do
					if tags[tag] then hit = true break end
				end
			end
		end
		if not hit and cat.special then
			hit = specialMatch(cat.special, item, display)
		end
		if hit then
			hits = hits or {}
			hits[#hits + 1] = cat.id
		end
	end
	return hits
end

-- ---------------------------------------------------------------------------
-- Building the set of item names to pull out of the tables
-- ---------------------------------------------------------------------------
function RVA.buildRemovalSet(settings)
	local remove, counts, total = {}, {}, 0

	local function add(name, cats)
		if remove[name] then return end
		remove[name] = true
		remove["Base." .. name] = true
		total = total + 1
		for _, c in ipairs(cats) do counts[c] = (counts[c] or 0) + 1 end
	end

	for name, cats in pairs(RVA.vanillaItems) do
		for _, c in ipairs(cats) do
			if settings.enabled[c] then add(name, cats) break end
		end
	end

	-- Anything the baked table does not cover: modded items, plus items added by a
	-- game patch newer than the generated data.
	local items = getScriptManager():getAllItems()
	for i = 0, items:size() - 1 do
		local item = items:get(i)
		local name = item:getName()
		if not RVA.vanillaItems[name] and not remove[name]
				and not item:getObsolete() and not item:isHidden() then
			local isVanillaModule = item:getModuleName() == "Base"
			if settings.modded or isVanillaModule then
				local cats = RVA.categoriesFor(item)
				if cats then
					for _, c in ipairs(cats) do
						if settings.enabled[c] then add(name, cats) break end
					end
				end
			end
		end
	end

	return remove, counts, total
end

-- ---------------------------------------------------------------------------
-- Sweeping the distribution tables
-- ---------------------------------------------------------------------------

--- Vanilla loot arrays are flat and interleaved: name, weight, name, weight...
--- Duplicate entries of one item are deliberate (they control stack size), so
--- every occurrence goes. Rewritten in place because many of these arrays are
--- shared by reference between dozens of tables.
local function stripItemArray(arr, remove, stats)
	local kept, i, n = {}, 1, #arr
	local removed = 0
	while i <= n do
		local name, weight = arr[i], arr[i + 1]
		if type(name) == "string" and type(weight) == "number" then
			if remove[name] then
				removed = removed + 1
			else
				kept[#kept + 1] = name
				kept[#kept + 1] = weight
			end
			i = i + 2
		else
			-- Not a name/weight pair; pass it through rather than guess.
			kept[#kept + 1] = name
			i = i + 1
		end
	end
	if removed == 0 then return end
	for k = n, 1, -1 do arr[k] = nil end
	for k = 1, #kept do arr[k] = kept[k] end
	stats.entries = stats.entries + removed
	stats.tables = stats.tables + 1
end

--- A flat array whose first two slots are string, number is a loot array whatever
--- key it sits under -- this catches ClutterTables.TrunkItems and friends, which
--- are plain arrays rather than an `items = { ... }` field.
local function isItemArray(t)
	return #t >= 2 and type(t[1]) == "string" and type(t[2]) == "number"
end

local function sweep(t, remove, seen, stats)
	if type(t) ~= "table" or seen[t] then return end
	seen[t] = true

	if isItemArray(t) then
		stripItemArray(t, remove, stats)
		return
	end

	for key, value in pairs(t) do
		if type(value) == "table" and not seen[value] then
			if key == "items" then
				seen[value] = true
				stripItemArray(value, remove, stats)
			else
				sweep(value, remove, seen, stats)
			end
		end
	end
end

--- SuburbsDistributions.all.Outfit_* holds what a zombie of that profession
--- carries in its pockets -- a badge, a pen, a lighter -- alongside the
--- inventorymale/inventoryfemale fallbacks. (The clothes a zombie wears are not
--- here at all: they live in media/clothing/clothing.xml, keyed by GUID, and no
--- amount of loot-table surgery touches them.) Marking these tables as
--- already-seen is how the default of leaving corpse loot alone is honoured --
--- the recursion simply never reaches them.
local function protectCorpseLoot(seen)
	local all = SuburbsDistributions and SuburbsDistributions.all
	if type(all) ~= "table" then return 0 end
	local n = 0
	for key, value in pairs(all) do
		if type(value) == "table" and type(key) == "string"
				and (string.sub(key, 1, 7) == "Outfit_"
					or key == "inventorymale" or key == "inventoryfemale") then
			seen[value] = true
			n = n + 1
		end
	end
	return n
end

-- ---------------------------------------------------------------------------

-- Guard against the two hooks below both doing the work. Keyed on the table
-- rather than a boolean so a fresh Lua state -- which GameLoadingState creates on
-- every game entry via LuaManager.LoadDirBase -- is always processed again.
local appliedTo = nil

function RVA.stripLoot()
	if type(SuburbsDistributions) ~= "table" then return end
	if appliedTo == SuburbsDistributions then return end

	local settings = RVA.settings()
	if not anyEnabled(settings.enabled) then return end

	local remove, counts, total = RVA.buildRemovalSet(settings)
	if total == 0 then return end

	appliedTo = SuburbsDistributions
	-- Published for RVA_Retro.lua, which reuses it to purge containers that were
	-- already looted before the mod was added.
	RVA.removalSet = remove

	local seen = {}
	local stats = { entries = 0, tables = 0 }

	local protected = 0
	if not settings.corpses then protected = protectCorpseLoot(seen) end

	-- Built with explicit inserts rather than a literal: a nil in the middle of a
	-- table constructor would silently cut the ipairs walk short, and any of these
	-- globals can be absent depending on load order.
	local roots = {}
	local function addRoot(t) if type(t) == "table" then roots[#roots + 1] = t end end
	addRoot(ProceduralDistributions and ProceduralDistributions.list)
	addRoot(SuburbsDistributions)
	addRoot(Distributions)
	addRoot(VehicleDistributions)
	addRoot(ClutterTables)
	addRoot(BagsAndContainers)

	for _, root in ipairs(roots) do
		sweep(root, remove, seen, stats)
	end

	-- ItemPickerJava.Parse() already ran during IsoWorld.init() (offset 2147),
	-- against the tables as they were before this sweep, and container filling
	-- reads that Java-side copy rather than the Lua globals. Rebuilding it is what
	-- vanilla does after a sandbox change (ISServerSandboxOptionsUI.lua:769).
	-- StoryClutter.Init() is deliberately not called alongside it: that UI needs it,
	-- this mod does not touch story clutter, and re-running it would double-register.
	-- mp clients never fill containers from the java copy; the server rebuilds its own.
	if stats.entries > 0 and not isClient() and IsoWorld and IsoWorld.parseDistributions then
		pcall(function() IsoWorld.parseDistributions() end)
	end

	if settings.log then
		print("[RemoveVanillaAnything] removed " .. total .. " item types in "
			.. stats.entries .. " loot entries across " .. stats.tables .. " tables"
			.. (protected > 0 and (", " .. protected .. " corpse loot tables left alone") or ""))
		for _, id in ipairs(RVA.itemCategoryIds) do
			if settings.enabled[id] then
				print("[RemoveVanillaAnything]   " .. id .. ": " .. (counts[id] or 0) .. " item types")
			end
		end
	end
end

-- NOT OnPostDistributionMerge, tempting as it looks. IsoWorld.init() fires the
-- three merge events at offsets 2051-2066 but does not read map_sand.bin until
-- offset 2126, where SandboxOptions.load() ends in toLua(). A handler on the merge
-- events therefore sees the player's real settings on a new game -- the new-game
-- screen ran toLua() beforehand -- and nothing but declared defaults on every
-- subsequent load of that same save. OnGameStart runs from IngameState, after
-- IsoWorld.init() returns, so both cases behave identically.
Events.OnGameStart.Add(RVA.stripLoot)
Events.OnServerStarted.Add(RVA.stripLoot)
