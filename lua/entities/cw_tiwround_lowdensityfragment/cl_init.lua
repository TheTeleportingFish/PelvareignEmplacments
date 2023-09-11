include("shared.lua")

function ENT:Initialize()
	
	net.Receive( "Client_Shockwave", function( len )
		local ContinationWave = net.ReadFloat()
		local Dist = ( 1 - net.ReadFloat() ) or 0
		if ContinationWave == nil then return end
		
		timer.Simple( ContinationWave , function() 
			EmitSound( "physics/cardboard/cardboard_box_impact_bullet5.wav" , Vector() , -1 , CHAN_AUTO , math.Clamp(Dist^10,0,0.5) , 130 , 0 , math.random(90,100) )
		end)
	end)
	
	self.Emitter = ParticleEmitter(self:GetPos())
	self.ParticleDelay = 0
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:Think()
	for i = 1, 3 do
		local part = self.Emitter:Add("particle/smokesprites_0003" , self:GetPos())
		local LocalizedColor = math.random(20, 260)
		part:SetStartSize(0)
		part:SetEndSize(math.random(20, 60))
		part:SetStartAlpha(90)
		part:SetEndAlpha(0)
		part:SetDieTime(0.5)
		part:SetRoll(math.random(-360, 360))
		part:SetRollDelta(0.1)
		part:SetColor(LocalizedColor,LocalizedColor,LocalizedColor)
		part:SetLighting(false)
		part:SetVelocity((self:GetVelocity()*0.05)+(VectorRand() * math.random(10,150)))
	end
end 

function ENT:OnRemove()
	self.Emitter:Finish()
end
