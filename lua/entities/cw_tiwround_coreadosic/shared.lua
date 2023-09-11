ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.PrintName = "TIWCdRound"
ENT.Author = "L337N008"
ENT.Information = "A TIW Coreadosic Round"
ENT.Spawnable = false
ENT.AdminSpawnable = false 

function ENT:SetupDataTables()
	self:SetNWEntity( "Targeted", nil )
	
end