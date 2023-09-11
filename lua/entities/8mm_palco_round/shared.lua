ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.PrintName = "TIWRound"
ENT.Author = "L337N008"
ENT.Information = "An Average TIW Round"
ENT.Spawnable = false
ENT.AdminSpawnable = false 

function ENT:SetupDataTables()
	self:SetNWEntity( "Targeted", nil )
	
end
