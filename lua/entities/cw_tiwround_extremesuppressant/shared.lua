ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.PrintName = "Class 3 Suppressant Round"
ENT.Author = "Pelvareign Munitions"
ENT.Information = "A Class 3 TIW Suppressant Round"
ENT.Spawnable = false
ENT.AdminSpawnable = false 

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "Targeted")
	
end