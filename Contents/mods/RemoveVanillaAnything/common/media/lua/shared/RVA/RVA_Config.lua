-- GENERATED FILE -- do not edit by hand.
-- Produced by tools/generate_vanilla_data.py from the vanilla Build 42 script files.
-- Edit tools/categories.py and re-run the generator instead.

RVA = RVA or {}

RVA.MODULE = "RVA"

-- DisplayCategory / BodyLocation values that must never be removed:
-- damage overlays, corpses and internal placeholders.
RVA.forbiddenDisplay = {
	["Animal"] = true,
	["Badger"] = true,
	["Bear"] = true,
	["Beaver"] = true,
	["Bug"] = true,
	["Bunny"] = true,
	["Corpse"] = true,
	["Dog"] = true,
	["Duck"] = true,
	["Ears"] = true,
	["Eye"] = true,
	["Fox"] = true,
	["Frog"] = true,
	["Generic"] = true,
	["Goblin"] = true,
	["Hedgehog"] = true,
	["Hidden"] = true,
	["MaleBody"] = true,
	["Mole"] = true,
	["Raccoon"] = true,
	["Spider"] = true,
	["Squirrel"] = true,
	["Tail"] = true,
	["Wound"] = true,
	["ZedDmg"] = true,
}

RVA.forbiddenBody = {
	["bandage"] = true,
	["wound"] = true,
	["zeddmg"] = true,
}

-- Item category matchers. Used at runtime only for items that are NOT in
-- RVA.vanillaItems, i.e. modded items and anything a game patch added since
-- the generator last ran.
RVA.itemCategories = {
	{
		id = "Clothing",
		display = {
			["Accessory"] = true,
			["Appearance"] = true,
			["Bag"] = true,
			["Clothing"] = true,
			["ProtectiveGear"] = true,
		},
	},
	{
		id = "Clothing_Shoes",
		body = {
			["shoes"] = true,
			["socks"] = true,
		},
	},
	{
		id = "Clothing_Pants",
		body = {
			["legs1"] = true,
			["longskirt"] = true,
			["pants"] = true,
			["pants_skinny"] = true,
			["pantsextra"] = true,
			["shortpants"] = true,
			["shortsshort"] = true,
			["skirt"] = true,
		},
	},
	{
		id = "Clothing_Shirts",
		body = {
			["fulltop"] = true,
			["jersey"] = true,
			["shirt"] = true,
			["shortsleeveshirt"] = true,
			["sweater"] = true,
			["tanktop"] = true,
			["torso1"] = true,
			["tshirt"] = true,
		},
	},
	{
		id = "Clothing_Outerwear",
		body = {
			["bathrobe"] = true,
			["jacket"] = true,
			["jacket_bulky"] = true,
			["jacket_down"] = true,
			["jackethat"] = true,
			["jackethat_bulky"] = true,
			["jacketsuit"] = true,
			["neck"] = true,
			["neck_texture"] = true,
			["scarf"] = true,
			["sweaterhat"] = true,
		},
	},
	{
		id = "Clothing_FullBody",
		body = {
			["bodycostume"] = true,
			["boilersuit"] = true,
			["dress"] = true,
			["fullsuit"] = true,
			["fullsuithead"] = true,
			["longdress"] = true,
			["torso1legs1"] = true,
		},
	},
	{
		id = "Clothing_Headwear",
		body = {
			["eyes"] = true,
			["fullhat"] = true,
			["hat"] = true,
			["lefteye"] = true,
			["mask"] = true,
			["maskeyes"] = true,
			["maskfull"] = true,
			["righteye"] = true,
		},
	},
	{
		id = "Clothing_Gloves",
		body = {
			["hands"] = true,
			["handsleft"] = true,
			["handsright"] = true,
		},
	},
	{
		id = "Clothing_Underwear",
		body = {
			["underwear"] = true,
			["underwearbottom"] = true,
			["underwearextra1"] = true,
			["underwearextra2"] = true,
			["underweartop"] = true,
		},
	},
	{
		id = "Clothing_Armor",
		body = {
			["ammostrap"] = true,
			["ankleholster"] = true,
			["calf_left"] = true,
			["calf_left_texture"] = true,
			["calf_right"] = true,
			["calf_right_texture"] = true,
			["codpiece"] = true,
			["cuirass"] = true,
			["elbow_left"] = true,
			["elbow_right"] = true,
			["forearm_left"] = true,
			["forearm_right"] = true,
			["gaiter_left"] = true,
			["gaiter_right"] = true,
			["gorget"] = true,
			["knee_left"] = true,
			["knee_right"] = true,
			["leftarm"] = true,
			["rightarm"] = true,
			["scba"] = true,
			["scbanotank"] = true,
			["shoulderholster"] = true,
			["shoulderpadleft"] = true,
			["shoulderpadright"] = true,
			["sportshoulderpad"] = true,
			["sportshoulderpadontop"] = true,
			["thigh_left"] = true,
			["thigh_right"] = true,
			["torsoextra"] = true,
			["torsoextravest"] = true,
			["torsoextravestbullet"] = true,
			["vesttexture"] = true,
			["webbing"] = true,
		},
	},
	{
		id = "Clothing_Jewelry",
		body = {
			["bellybutton"] = true,
			["belt"] = true,
			["beltextra"] = true,
			["ears"] = true,
			["eartop"] = true,
			["left_middlefinger"] = true,
			["left_ringfinger"] = true,
			["leftwrist"] = true,
			["makeup_eyes"] = true,
			["makeup_eyesshadow"] = true,
			["makeup_fullface"] = true,
			["makeup_lips"] = true,
			["necklace"] = true,
			["necklace_long"] = true,
			["nose"] = true,
			["right_middlefinger"] = true,
			["right_ringfinger"] = true,
			["rightwrist"] = true,
		},
	},
	{
		id = "Clothing_Bags",
		display = {
			["Bag"] = true,
		},
		body = {
			["back"] = true,
			["fannypackback"] = true,
			["fannypackfront"] = true,
			["satchel"] = true,
		},
	},
	{
		id = "Food",
		display = {
			["Food"] = true,
			["Water"] = true,
			["WaterContainer"] = true,
		},
	},
	{
		id = "Food_Perishable",
		special = "perishable",
	},
	{
		id = "Food_NonPerishable",
		special = "nonperishable",
	},
	{
		id = "Food_Drinks",
		display = {
			["Water"] = true,
			["WaterContainer"] = true,
		},
		special = "fluidcontainer",
	},
	{
		id = "Food_Alcohol",
		tags = {
			["alcoholicbeverage"] = true,
			["lowalcohol"] = true,
		},
	},
	{
		id = "Food_Cookware",
		display = {
			["Cooking"] = true,
			["CookingWeapon"] = true,
		},
	},
	{
		id = "Food_Seeds",
		tags = {
			["isseed"] = true,
		},
	},
	{
		id = "Weapons",
		display = {
			["Ammo"] = true,
			["AnimalPartWeapon"] = true,
			["BrokenWeapon"] = true,
			["CookingWeapon"] = true,
			["Explosives"] = true,
			["FirstAidWeapon"] = true,
			["FishingWeapon"] = true,
			["GardeningWeapon"] = true,
			["HouseholdWeapon"] = true,
			["InstrumentWeapon"] = true,
			["JunkWeapon"] = true,
			["MaterialWeapon"] = true,
			["SportsWeapon"] = true,
			["ToolWeapon"] = true,
			["VehicleMaintenanceWeapon"] = true,
			["Weapon"] = true,
			["WeaponCrafted"] = true,
			["WeaponImprovised"] = true,
			["WeaponPart"] = true,
		},
	},
	{
		id = "Weapons_Firearms",
		special = "firearm",
	},
	{
		id = "Weapons_Melee",
		special = "melee",
	},
	{
		id = "Weapons_Improvised",
		display = {
			["BrokenWeapon"] = true,
			["HouseholdWeapon"] = true,
			["JunkWeapon"] = true,
			["MaterialWeapon"] = true,
			["WeaponCrafted"] = true,
			["WeaponImprovised"] = true,
		},
	},
	{
		id = "Weapons_Ammo",
		display = {
			["Ammo"] = true,
		},
		tags = {
			["ammo"] = true,
			["ammocase"] = true,
		},
	},
	{
		id = "Weapons_Parts",
		display = {
			["WeaponPart"] = true,
		},
		tags = {
			["pistolmagazine"] = true,
			["riflemagazine"] = true,
		},
		itype = {
			["base:weaponpart"] = true,
		},
	},
	{
		id = "Weapons_Explosives",
		display = {
			["Explosives"] = true,
		},
	},
	{
		id = "Tools",
		display = {
			["Camping"] = true,
			["Communications"] = true,
			["Electronics"] = true,
			["FireSource"] = true,
			["Fishing"] = true,
			["FishingWeapon"] = true,
			["Gardening"] = true,
			["GardeningWeapon"] = true,
			["LightSource"] = true,
			["Paint"] = true,
			["Security"] = true,
			["Tool"] = true,
			["ToolWeapon"] = true,
			["Trapping"] = true,
			["VehicleMaintenance"] = true,
			["VehicleMaintenanceWeapon"] = true,
		},
	},
	{
		id = "Tools_VehicleMaintenance",
		display = {
			["VehicleMaintenance"] = true,
			["VehicleMaintenanceWeapon"] = true,
		},
	},
	{
		id = "Tools_Camping",
		display = {
			["Camping"] = true,
		},
	},
	{
		id = "Tools_Fishing",
		display = {
			["Fishing"] = true,
			["FishingWeapon"] = true,
		},
	},
	{
		id = "Tools_Trapping",
		display = {
			["Trapping"] = true,
		},
	},
	{
		id = "Tools_Gardening",
		display = {
			["Gardening"] = true,
			["GardeningWeapon"] = true,
		},
	},
	{
		id = "Tools_LightSources",
		display = {
			["FireSource"] = true,
			["LightSource"] = true,
		},
	},
	{
		id = "Tools_Electronics",
		display = {
			["Electronics"] = true,
		},
	},
	{
		id = "Tools_Communications",
		display = {
			["Communications"] = true,
		},
		itype = {
			["base:radio"] = true,
		},
	},
	{
		id = "Medical",
		display = {
			["Bandage"] = true,
			["FirstAid"] = true,
			["FirstAidWeapon"] = true,
		},
	},
	{
		id = "Medical_Pills",
		special = "pills",
	},
	{
		id = "Medical_Bandages",
		display = {
			["Bandage"] = true,
		},
		special = "bandage",
	},
	{
		id = "Literature",
		display = {
			["Cartography"] = true,
			["Entertainment"] = true,
			["Literature"] = true,
			["SkillBook"] = true,
		},
		itype = {
			["base:literature"] = true,
			["base:map"] = true,
		},
	},
	{
		id = "Literature_SkillBooks",
		display = {
			["SkillBook"] = true,
		},
	},
	{
		id = "Literature_Magazines",
		tags = {
			["magazine"] = true,
		},
	},
	{
		id = "Literature_Maps",
		display = {
			["Cartography"] = true,
		},
		itype = {
			["base:map"] = true,
		},
	},
	{
		id = "Containers",
		display = {
			["Container"] = true,
		},
		itype = {
			["base:container"] = true,
		},
	},
	{
		id = "JunkMementos",
		display = {
			["Junk"] = true,
			["Memento"] = true,
			["Teddy Bear"] = true,
		},
	},
	{
		id = "CraftingMaterials",
		display = {
			["Material"] = true,
			["RecipeResource"] = true,
		},
	},
	{
		id = "FurnitureMoveables",
		display = {
			["Furniture"] = true,
		},
		itype = {
			["base:moveable"] = true,
		},
	},
	{
		id = "AnimalParts",
		display = {
			["AnimalPart"] = true,
			["AnimalPartWeapon"] = true,
		},
	},
	{
		id = "Instruments",
		display = {
			["Instrument"] = true,
			["InstrumentWeapon"] = true,
		},
	},
	{
		id = "SportsEquipment",
		display = {
			["Sports"] = true,
			["SportsWeapon"] = true,
		},
	},
	{
		id = "HouseholdItems",
		display = {
			["Household"] = true,
			["HouseholdWeapon"] = true,
			["Paint"] = true,
		},
	},
}

RVA.itemCategoryIds = {
	"Clothing",
	"Clothing_Shoes",
	"Clothing_Pants",
	"Clothing_Shirts",
	"Clothing_Outerwear",
	"Clothing_FullBody",
	"Clothing_Headwear",
	"Clothing_Gloves",
	"Clothing_Underwear",
	"Clothing_Armor",
	"Clothing_Jewelry",
	"Clothing_Bags",
	"Food",
	"Food_Perishable",
	"Food_NonPerishable",
	"Food_Drinks",
	"Food_Alcohol",
	"Food_Cookware",
	"Food_Seeds",
	"Weapons",
	"Weapons_Firearms",
	"Weapons_Melee",
	"Weapons_Improvised",
	"Weapons_Ammo",
	"Weapons_Parts",
	"Weapons_Explosives",
	"Tools",
	"Tools_VehicleMaintenance",
	"Tools_Camping",
	"Tools_Fishing",
	"Tools_Trapping",
	"Tools_Gardening",
	"Tools_LightSources",
	"Tools_Electronics",
	"Tools_Communications",
	"Medical",
	"Medical_Pills",
	"Medical_Bandages",
	"Literature",
	"Literature_SkillBooks",
	"Literature_Magazines",
	"Literature_Maps",
	"Containers",
	"JunkMementos",
	"CraftingMaterials",
	"FurnitureMoveables",
	"AnimalParts",
	"Instruments",
	"SportsEquipment",
	"HouseholdItems",
}

RVA.vehicleCategoryIds = {
	"Vehicles_Everyday",
	"Vehicles_SportsLuxury",
	"Vehicles_PolicePrison",
	"Vehicles_Emergency",
	"Vehicles_WorkDelivery",
	"Vehicles_Trailers",
	"Vehicles_BurntCrashed",
	"Vehicles_TrafficJams",
	"Vehicles_Junkyard",
	"Vehicles_Story",
}
