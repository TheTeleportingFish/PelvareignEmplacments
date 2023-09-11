include("shared.lua")



function ENT:Initialize()
	timer.Simple( 0.2, function() if IsValid(self) then
		self.Emitter = ParticleEmitter(self:GetPos())
		self.ParticleDelay = 0
		end
	end)
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:Think()

	
		if self.Emitter != nil and IsValid(self) then
		local part = self.Emitter:Add("particle/smokesprites_0003" , self:GetPos())
		part:SetStartSize(0)
		part:SetEndSize(200)
		part:SetStartAlpha(255)
		part:SetEndAlpha(0)
		part:SetDieTime(0.2)
		part:SetRoll(math.random(0, 360))
		part:SetRollDelta(0.01)
		part:SetColor(1, 1, 1)
		part:SetLighting(false)
		part:SetVelocity((self:GetVelocity()*0.01)+(VectorRand() * math.random(1,5)))
		end

end 

function ENT:OnRemove()
	if self.Emitter != nil and IsValid(self) then
	self.Emitter:Finish()
	end
end