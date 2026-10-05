--- Remove Vanilla Anything -- vanilla vehicle removal.
---
--- Vehicles reach the world by three different routes, so all three are handled:
---
---   1. VehicleZoneDistribution, read by VehicleType.initNormal() straight out of
---      the Lua environment. It lazy-initialises (`if vehicles.isEmpty() init()`)
---      and VehicleType.Reset() just clears that cache, so editing the Lua table
---      and calling Reset() is enough -- no load-order race with car pack mods.
---   2. ProfessionVehicles.CheckSwap, which rewrites a vehicle's script on
---      OnSpawnVehicleStart based on the map region it spawned in.
---   3. The Java randomised vehicle stories, which place burnt and smashed scripts
---      that appear in no Lua table at all. Only a per-spawn check catches those.
---
--- Modded vehicles are never touched: every removal is gated on the script name
--- appearing in RVA.vanillaVehicles, which is baked from the vanilla script files.

RVA = RVA or {}

local MASTER = "Vehicles"

-- Guard against the three hooks below doing the work twice. Keyed on the table
-- itself rather than a boolean so a fresh Lua state (new game, new table) is
-- always processed again.
local appliedTo = nil

--- "Base.CarNormal" -> "CarNormal". Vanilla itself is inconsistent here: one
--- entry in VehicleZoneDefinition.lua ships without its module prefix.
local function bareScript(name)
	if type(name) ~= "string" then return nil end
	local dot = string.find(name, ".", 1, true)
	if dot then return string.sub(name, dot + 1) end
	return name
end

local function vehicleSettings()
	local vars = SandboxVars and SandboxVars[RVA.MODULE]
	local cats = {}
	if vars then
		for _, id in ipairs(RVA.vehicleCategoryIds) do
			if vars[id] == true then cats[id] = true end
		end
	end
	return {
		master = vars and vars[MASTER] == true,
		cats   = cats,
		log    = vars and vars.LogRemovals == true,
	}
end

local function anySet(t)
	for _ in pairs(t) do return true end
	return false
end

--- zoneKill: zones to clear of vanilla vehicles entirely.
--- scriptKill: vanilla scripts to remove from every zone, and to block on spawn.
local function killSets(settings)
	local zoneKill, scriptKill = {}, {}
	if settings.master then
		for zone in pairs(VehicleZoneDistribution) do zoneKill[zone] = true end
		for script in pairs(RVA.vanillaVehicles) do scriptKill[script] = true end
		return zoneKill, scriptKill
	end
	for id in pairs(settings.cats) do
		local cat = RVA.vehicleCategories[id]
		if cat then
			for zone in pairs(cat.zones) do zoneKill[zone] = true end
			for script in pairs(cat.scripts) do scriptKill[script] = true end
		end
	end
	return zoneKill, scriptKill
end

-- ---------------------------------------------------------------------------
-- 1. Spawn zones
-- ---------------------------------------------------------------------------
--- Returns removed-entry count, dropped-zone count, and the set of vanilla
--- scripts that can no longer spawn from any surviving zone.
local function stripZones(zoneKill, scriptKill)
	local removed = 0
	local pulled = {}

	for zoneName, zone in pairs(VehicleZoneDistribution) do
		if type(zone) == "table" and type(zone.vehicles) == "table" then
			local killAll = zoneKill[zoneName]
			for entry in pairs(zone.vehicles) do
				local script = bareScript(entry)
				if script and RVA.vanillaVehicles[script]
						and (killAll or scriptKill[script]) then
					zone.vehicles[entry] = nil
					pulled[script] = true
					removed = removed + 1
				end
			end
		end
	end

	-- A zone whose vehicle list is empty is worse than a missing one: Java would
	-- hand back a VehicleType with nothing to pick from. Deleting the key makes
	-- getRandomVehicleType return nil, which IsoChunk null-checks. This also mops
	-- up the alias zones (business2..business12, trafficjame/n/s) that share one
	-- table with the zone we just emptied.
	local dropped = 0
	for zoneName, zone in pairs(VehicleZoneDistribution) do
		if type(zone) == "table" and type(zone.vehicles) == "table"
				and not anySet(zone.vehicles) then
			VehicleZoneDistribution[zoneName] = nil
			dropped = dropped + 1
		end
	end

	-- Surviving zones must not roll for pools that no longer exist.
	local haveBurnt = VehicleZoneDistribution.normalburnt ~= nil
		or VehicleZoneDistribution.specialburnt ~= nil
	local haveParking = VehicleZoneDistribution.parkingstall ~= nil
	local haveSpecial = false
	for _, zone in pairs(VehicleZoneDistribution) do
		if type(zone) == "table" and zone.specialCar then haveSpecial = true end
	end
	for _, zone in pairs(VehicleZoneDistribution) do
		if type(zone) == "table" then
			if not haveBurnt then zone.chanceToSpawnBurnt = 0 end
			if not haveSpecial then zone.chanceToSpawnSpecial = 0 end
			if not haveParking then zone.chanceToSpawnNormal = 0 end
		end
	end

	-- A script pulled from one zone may still be reachable through another that
	-- was left alone, so only the ones with nowhere left to spawn count as banned.
	local banned = {}
	for script in pairs(scriptKill) do banned[script] = true end
	for script in pairs(pulled) do banned[script] = true end
	for _, zone in pairs(VehicleZoneDistribution) do
		if type(zone) == "table" and type(zone.vehicles) == "table" then
			for entry in pairs(zone.vehicles) do
				local script = bareScript(entry)
				if script and not scriptKill[script] then banned[script] = nil end
			end
		end
	end

	return removed, dropped, banned
end

-- ---------------------------------------------------------------------------
-- 2. Regional profession swaps
-- ---------------------------------------------------------------------------
local SKIP_KEYS = { OnCreateRegion = true, CheckSwap = true, UniqueVehicles = true }

local function filterList(list, banned)
	local removed = 0
	for i = #list, 1, -1 do
		local script = bareScript(list[i])
		if script and RVA.vanillaVehicles[script] and banned[script] then
			table.remove(list, i)
			removed = removed + 1
		end
	end
	return removed
end

--- ProfessionVehicles.CheckSwap bails out when it finds no list, so emptied
--- entries are deleted rather than left as empty tables -- OnCreateRegion would
--- otherwise index an empty array and hand a nil script to addVehicleDebug.
local function stripProfessionSwaps(banned)
	if type(ProfessionVehicles) ~= "table" then return 0 end
	local removed = 0

	for key, value in pairs(ProfessionVehicles) do
		if not SKIP_KEYS[key] and type(value) == "table" then
			if banned[key] then
				-- The vehicle this swap table hangs off can no longer spawn, so
				-- CheckSwap would never reach it anyway.
				ProfessionVehicles[key] = nil
			elseif type(value[1]) == "string" then
				-- Flat per-town list used by OnCreateRegion.
				removed = removed + filterList(value, banned)
				if #value == 0 then ProfessionVehicles[key] = nil end
			else
				-- region -> list of replacement scripts, used by CheckSwap.
				for region, list in pairs(value) do
					if type(list) == "table" then
						removed = removed + filterList(list, banned)
						if #list == 0 then value[region] = nil end
					end
				end
				if not anySet(value) then ProfessionVehicles[key] = nil end
			end
		end
	end
	return removed
end

-- ---------------------------------------------------------------------------
-- 3. Per-spawn safety net for the Java randomised vehicle stories
-- ---------------------------------------------------------------------------
local blockedOnSpawn = nil

local function onSpawnVehicleStart(vehicle)
	if not blockedOnSpawn or not vehicle then return end
	local script = bareScript(vehicle:getScriptName())
	if not script or not blockedOnSpawn[script] then return end
	if not pcall(function() vehicle:permanentlyRemove() end) then
		pcall(function() vehicle:removeFromWorld() end)
	end
end

-- ---------------------------------------------------------------------------
function RVA.stripVehicles()
	if type(VehicleZoneDistribution) ~= "table" then return end
	if appliedTo == VehicleZoneDistribution then return end

	local settings = vehicleSettings()
	if not settings.master and not anySet(settings.cats) then return end

	local zoneKill, scriptKill = killSets(settings)
	local removed, dropped, banned = stripZones(zoneKill, scriptKill)
	local swaps = stripProfessionSwaps(banned)

	blockedOnSpawn = banned
	appliedTo = VehicleZoneDistribution
	-- Published for RVA_Retro.lua, which reuses it to despawn vanilla vehicles that
	-- were already placed before the mod was added.
	RVA.blockedVehicles = banned

	-- Java caches VehicleZoneDistribution into VehicleType on first use. Clearing
	-- the cache makes it re-read the table we just edited.
	if VehicleType and VehicleType.Reset then
		pcall(function() VehicleType.Reset() end)
	end

	if settings.log then
		print("[RemoveVanillaAnything] vehicles: removed " .. removed
			.. " zone entries, dropped " .. dropped .. " empty spawn zones, "
			.. swaps .. " regional swap entries")
	end
end

-- OnInitWorld is the earliest point where SandboxVars is populated but chunks
-- have not begun streaming; the later hooks are no-ops thanks to the guard flag,
-- and exist so dedicated servers and loaded saves are covered too.
Events.OnInitWorld.Add(RVA.stripVehicles)
Events.OnGameStart.Add(RVA.stripVehicles)
Events.OnServerStarted.Add(RVA.stripVehicles)

-- Registered here, after ProfessionVehicles.lua has added CheckSwap, so a script
-- this mod blocks cannot be swapped back in behind us.
Events.OnSpawnVehicleStart.Add(onSpawnVehicleStart)
