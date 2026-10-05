--- Remove Vanilla Anything -- retroactive sweeps for saves already in progress.
---
--- Neither of these runs unless the player opts in, because both delete things
--- that already exist in the world.
---
--- They exist because adding the mod to a running save only half works on its own:
---
---   * Loot is mostly fine. Containers fill lazily on first open, so anything the
---     player has never opened rolls from the stripped tables no matter how old the
---     chunk is. Only containers they have already opened keep their old contents.
---   * Vehicles barely work at all. IsoChunk.doLoadGridsquare() gates AddVehicles()
---     on isNewChunk() AND not VehiclesDB2.isChunkSeen(), so explored map keeps its
---     vanilla cars permanently.

RVA = RVA or {}

local function setting(name)
	local vars = SandboxVars and SandboxVars[RVA.MODULE]
	return vars and vars[name] == true
end

local function bareScript(name)
	if type(name) ~= "string" then return nil end
	local dot = string.find(name, ".", 1, true)
	if dot then return string.sub(name, dot + 1) end
	return name
end

-- ---------------------------------------------------------------------------
-- Vehicles
-- ---------------------------------------------------------------------------
local vehiclesRemoved = 0

--- Deleting a car with someone sitting in it is a good way to break a save, so an
--- occupied vehicle is always skipped and picked up on a later pass.
local function isOccupied(vehicle)
	local ok, occupied = pcall(function()
		for seat = 0, vehicle:getMaxPassengers() - 1 do
			if vehicle:getCharacter(seat) then return true end
		end
		return false
	end)
	return not ok or occupied
end

function RVA.purgeExistingVehicles()
	if not setting("PurgeExistingVehicles") then return end
	if not RVA.blockedVehicles then return end

	local cell = getCell()
	if not cell then return end
	local vehicles = cell:getVehicles()
	if not vehicles then return end

	local removed = 0
	for i = 0, vehicles:size() - 1 do
		local vehicle = vehicles:get(i)
		if vehicle then
			local script = bareScript(vehicle:getScriptName())
			if script and RVA.blockedVehicles[script] and not isOccupied(vehicle) then
				if not pcall(function() vehicle:permanentlyRemove() end) then
					pcall(function() vehicle:removeFromWorld() end)
				end
				removed = removed + 1
			end
		end
	end

	if removed > 0 then
		vehiclesRemoved = vehiclesRemoved + removed
		if setting("LogRemovals") then
			print("[RemoveVanillaAnything] purged " .. removed
				.. " vanilla vehicles already in the world (" .. vehiclesRemoved .. " total)")
		end
	end
end

-- ---------------------------------------------------------------------------
-- Already-looted containers
-- ---------------------------------------------------------------------------
-- Session-local rather than saved in ModData on purpose. One entry per visited
-- chunk would grow without bound and be serialised on every save, and persisting
-- it buys nothing: once a chunk has been purged there is nothing left in it for a
-- later pass to find, so a rescan is only the cost of walking the objects.
local purgedChunks = nil
local itemsRemoved = 0

local function chunkKey(square)
	local chunk = square:getChunk()
	if not chunk then return nil end
	return chunk:getWorldX() .. "," .. chunk:getWorldY()
end

local function purgeContainer(container, remove)
	-- Not yet opened: the normal fill path will roll it from the stripped tables,
	-- so there is nothing here to correct.
	if not container:isExplored() then return 0 end

	local items = container:getItems()
	if not items then return 0 end

	local removed = 0
	for i = items:size() - 1, 0, -1 do
		local item = items:get(i)
		if item and remove[item:getType()] then
			container:Remove(item)
			removed = removed + 1
		end
	end
	return removed
end

--- LoadGridsquare fires once per square as the world streams in -- on dedicated
--- servers too, via ServerMap$ServerCell. It is a hot path; the engine ships
--- zombie.LoadGridsquarePerformanceWorkaround specifically to keep vanilla's own
--- work off it. So: cheapest possible bail-out first, and each chunk is remembered
--- as done so walking back through an area later costs nothing.
function RVA.onLoadGridsquare(square)
	local remove = RVA.removalSet
	if not remove then return end
	if not purgedChunks then return end
	if not square then return end

	local key = chunkKey(square)
	if not key or purgedChunks[key] then return end

	local objects = square:getObjects()
	if not objects then return end

	local removed = 0
	for i = 0, objects:size() - 1 do
		local object = objects:get(i)
		if object then
			-- Only containers hanging off world objects are reachable this way, so a
			-- character's own inventory and worn bags can never turn up here. That
			-- is also why this does not call getPlayer(), which is nil on a
			-- dedicated server.
			local count = object:getContainerCount()
			for c = 0, count - 1 do
				local container = object:getContainerByIndex(c)
				if container then
					removed = removed + purgeContainer(container, remove)
				end
			end
		end
	end

	if removed > 0 then
		itemsRemoved = itemsRemoved + removed
		if setting("LogRemovals") then
			print("[RemoveVanillaAnything] purged " .. removed
				.. " items from already-looted containers (" .. itemsRemoved .. " total)")
		end
	end
end

--- Marks the square's chunk done. Kept separate from the purge so that a chunk is
--- recorded even when it held nothing to remove.
function RVA.markChunkPurged(square)
	if not purgedChunks or not square then return end
	local key = chunkKey(square)
	if key then purgedChunks[key] = true end
end

local function onLoadGridsquare(square)
	RVA.onLoadGridsquare(square)
	RVA.markChunkPurged(square)
end

-- ---------------------------------------------------------------------------
local started = false

local function start()
	if started then return end
	started = true

	if setting("PurgeExistingLoot") then
		purgedChunks = {}
		Events.LoadGridsquare.Add(onLoadGridsquare)
	end
	if setting("PurgeExistingVehicles") then
		-- Deliberately no immediate pass here. Files in lua/server load
		-- alphabetically, so this one registers its OnGameStart handler ahead of
		-- RVA_Vehicles.lua and RVA.blockedVehicles does not exist yet at this
		-- point. EveryOneMinute is roughly a second of real time at default speed,
		-- which is prompt enough, and a cell holds only a few dozen vehicles.
		Events.EveryOneMinute.Add(RVA.purgeExistingVehicles)
	end
end

Events.OnGameStart.Add(start)
Events.OnServerStarted.Add(start)
