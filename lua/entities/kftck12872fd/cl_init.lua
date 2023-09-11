include("shared.lua")

function ENT:Initialize()
	self.Emitter = ParticleEmitter(self:GetPos())
	
	self.ParticleDelay = 0
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:Think()
	if not IsValid(self.Emitter) then return end
	local part = self.Emitter:Add("particle/smokesprites_0003" , self:GetPos())
	part:SetStartSize(1)
	part:SetEndSize(15)
	part:SetStartAlpha(255)
	part:SetEndAlpha(0)
	part:SetDieTime(0.1)
	part:SetRoll(math.random(0, 360))
	part:SetRollDelta(0.01)
	part:SetColor(16, 16, 16)
	part:SetLighting(false)
	part:SetVelocity((self:GetVelocity()*0.1))

end 

function ENT:OnRemove()
	if IsValid(self.Emitter) then
		self.Emitter:Finish()
	end
end