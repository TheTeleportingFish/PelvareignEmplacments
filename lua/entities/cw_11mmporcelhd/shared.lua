ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.PrintName = "11mmporcelHighDensity"
ENT.Author = "L337N008"
ENT.Information = "A High Density Round from a 11mm Porcel Pistol"
ENT.Spawnable = false
ENT.AdminSpawnable = false 

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "Targeted")
	
end