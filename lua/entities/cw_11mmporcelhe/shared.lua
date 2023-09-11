ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.PrintName = "11mmporcelFHE"
ENT.Author = "L337N008"
ENT.Information = "An Fragmentation High Explosive Round from a 11mm Porcel Pistol"
ENT.Spawnable = false
ENT.AdminSpawnable = false 

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "Targeted")
	
end