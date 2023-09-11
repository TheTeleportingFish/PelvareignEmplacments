include("shared.lua")



function ENT:Initialize()
	self.Emitter = ParticleEmitter(self:GetPos())
	
	self.ParticleDelay = 0
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:Think()

		local part = self.Emitter:Add("particle/smokesprites_0003" , self:GetPos())
		part:SetStartSize(2)
		part:SetEndSize(80)
		part:SetStartAlpha(100)
		part:SetEndAlpha(0)
		part:SetDieTime(0.2)
		part:SetRoll(math.random(0, 360))
		part:SetRollDelta(0.01)	
		part:SetColor(30, 30, 30)
		part:SetLighting(false)
		part:SetVelocity((self:GetVelocity()*0.8)+(VectorRand() * math.random(1,10)/100)+self:GetAngles():Up()* math.random(-1000,1000))
end 

function ENT:OnRemove()
	self.Emitter:Finish()
end