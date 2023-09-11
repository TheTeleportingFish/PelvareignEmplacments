-- use this entity as a base for your ammo entities
-- below you can see all the necessary variables that can be used for setting up an ammo entity
-- they must be defined shared (clientside and serverside, aka in this file)

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Emplacement entity base"
ENT.Author = "Dog"
ENT.Spawnable = false
ENT.AdminSpawnable = false 
ENT.Category = "Pelvareign Emplacements"

ENT.HealthAmount = 100 -- the health of this entity
ENT.Model = "" -- what model to use

function ENT:SetupDataTables()
	self:DTVar("Int", 0, "Charge")
end