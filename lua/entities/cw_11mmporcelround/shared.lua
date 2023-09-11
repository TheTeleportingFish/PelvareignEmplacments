ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.PrintName = "11mmPorcelRound"
ENT.Author = "L337N008"
ENT.Information = "A 11mm Porcel Round"
ENT.Spawnable = false
ENT.AdminSpawnable = false 

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "Targeted")
	
end