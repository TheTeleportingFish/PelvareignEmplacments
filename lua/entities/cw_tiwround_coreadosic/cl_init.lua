include("shared.lua")

function ENT:Initialize()
	if IsValid(self) then
		self.Emitter = ParticleEmitter(self:GetPos())
		self.ParticleDelay = 0
	end
	
	net.Receive( "Client_Shockwave_Round", function( len )
		local ContinationWave = net.ReadFloat()
		local Dist = ( 1 - net.ReadFloat() ) or 0
		if ContinationWave == nil then return end
		
		timer.Simple( ContinationWave , function() 
			EmitSound( "main/caplier_faucation.wav" , Vector() , -1 , CHAN_AUTO , math.Clamp(Dist^3,0,1) , 90 , 0 , math.random(95,104) )
		end)
	end)
	
	net.Receive( "Client_Shockwave_PressurizedExplosive", function( len )
		local ContinationWave = net.ReadFloat()
		local Dist = ( 1 - net.ReadFloat() ) or 0
		if ContinationWave == nil then return end
		
		timer.Simple( ContinationWave , function() 
			EmitSound( "main/coreadosicfragmentexplose_dist.wav" , Vector() , -1 , CHAN_AUTO , math.Clamp(Dist^1.5,0,1) , 130 , 0 , math.random(100,200) )
			EmitSound( "main/coreadosicfragmentexplose_near.wav" , Vector() , -1 , CHAN_AUTO , math.Clamp(Dist^12,0,1) , 130 , 0 , math.random(90,105) )
		end)
	end)
	
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:Think()
	
	if self.Emitter != nil and IsValid(self) and IsValid(self:GetNWEntity( "Targeted" )) then
		local part = self.Emitter:Add("particle/smokesprites_0002" , self:GetPos())
		part:SetStartSize(0)
		part:SetEndSize(150)
		part:SetStartAlpha(10)
		part:SetEndAlpha(0)
		part:SetDieTime(0.1)
		part:SetRoll(math.random(0, 360))
		part:SetRollDelta(0.01)
		part:SetColor(255, 255, 255)
		part:SetLighting(false)
		part:SetVelocity((self:GetVelocity()*0.05)+(VectorRand() * math.random(25,55)))
	end
	
end 

function ENT:OnRemove()
		if IsValid(self) then
			self.DestructEmitter = ParticleEmitter(self:GetPos())
			
			for i=1,math.random(15,30) do
				local part = self.DestructEmitter:Add("particle/smokesprites_0002" , self:GetPos())
				part:SetStartSize(0)
				part:SetEndSize(math.random(240,250))
				part:SetStartAlpha(90)
				part:SetEndAlpha(0)
				part:SetDieTime(1.2)
				part:SetRoll(math.random(0, 360))
				part:SetRollDelta(0.01)
				part:SetColor(255, 255, 255)
				part:SetLighting(false)
				part:SetVelocity((-self:GetVelocity()*(math.random(5,15)/100))+(VectorRand() * math.random(100,260)))
			end
		end

	if self.Emitter != nil and IsValid(self) then
		self.Emitter:Finish()
	end
end



