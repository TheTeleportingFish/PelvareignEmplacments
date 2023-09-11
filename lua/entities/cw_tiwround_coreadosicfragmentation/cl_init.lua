include("shared.lua")

function ENT:Initialize()
	
	net.Receive( "Client_Shockwave", function( len )
		local ContinationWave = net.ReadFloat()
		local Dist = ( 1 - net.ReadFloat() ) or 0
		if ContinationWave == nil then return end
		
		timer.Simple( ContinationWave , function() 
			EmitSound( "physics/cardboard/cardboard_box_impact_bullet5.wav" , Vector() , -1 , CHAN_AUTO , math.Clamp(Dist^10,0,0.5) , 130 , 0 , math.random(90,100) )
			EmitSound( "main/coreadosicfragmentexplose_dist.wav" , Vector() , -1 , CHAN_AUTO , math.Clamp(Dist,0,1) , 130 , 0 , math.random(90,105) )
		end)
	end)
	
	self.Emitter = ParticleEmitter(self:GetPos())
	self.ParticleDelay = 0
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:Think()
end 

function ENT:OnRemove()
	local Amount = math.random(20,35)
	for i = 1, Amount do
		local part = self.Emitter:Add("particle/smokesprites_0002" , self:GetPos())
		local LocalizedColor = math.random(10, 60)
		part:SetStartSize(120)
		part:SetEndSize(math.random(810, 920))
		part:SetStartAlpha(220)
		part:SetEndAlpha(0)
		part:SetDieTime(math.random(50, 120)/10)
		part:SetRoll(math.random(-360, 360))
		part:SetRollDelta(0.1)
		part:SetColor(LocalizedColor,LocalizedColor,LocalizedColor)
		part:SetLighting(false)
		part:SetVelocity((VectorRand() * math.random(70,100)))
		if i == Amount then self.Emitter:Finish() end
	end
end
