include("shared.lua")

function ENT:Initialize()
	if IsValid(self) then
		self.Emitter = ParticleEmitter(self:GetPos())
		self.ParticleDelay = 0
	end
	
	EMRPR = CreateSound( game.GetWorld(), "main/t_b_r.wav" )
	EMRPR:SetSoundLevel( 0 )
	DangerEMRPR = CreateSound( game.GetWorld(), "main/antispatialknock_highsavor.wav" )
	DangerEMRPR:SetSoundLevel( 0 )
	
	net.Receive( "Client_Shockwave_Round", function( len )
		local ContinationWave = net.ReadFloat()
		local Dist = ( 1 - net.ReadFloat() ) or 0
		if ContinationWave == nil then return end
		
		timer.Simple( ContinationWave , function() 
			EmitSound( "main/cbmbounce1far.wav" , Vector() , -1 , CHAN_AUTO , math.Clamp(Dist^4,0,0.4) , 90 , 0 , math.random(90,100) )
		end)
	end)
	
	net.Receive( "Client_Shockwave_PressurizedExplosive", function( len )
		local ContinationWave = net.ReadFloat()
		local Dist = ( 1 - net.ReadFloat() ) or 0
		if ContinationWave == nil then return end
		
		timer.Simple( ContinationWave , function() 
			EmitSound( "main/small_caliber_weave_jack.mp3" , Vector() , -1 , CHAN_AUTO , math.Clamp(Dist^3.8,0,0.5) , 130 , 0 , math.random(80,100) )
			EmitSound( "main/bouncehit.wav" , Vector() , -1 , CHAN_AUTO , math.Clamp(Dist^1.5,0,0.5) , 130 , 0 , math.random(40,60) )
			EmitSound( "main/small_caliber_weave_deploy_"..math.random(1,7)..".mp3" , Vector() , -1 , CHAN_AUTO , math.Clamp(Dist^8,0,1) , 130 , 0 , math.random(90,105) )
		end)
	end)
	
end



function ENT:Draw()
	self:DrawModel()
end

function ENT:Think()
		if IsValid(self) then
			if IsValid(self:GetNWEntity( "Targeted" )) then
				if DangerEMRPR:IsPlaying() then DangerEMRPR:Play() end
				if EMRPR:IsPlaying() then EMRPR:Play() end
				
				local Pitch = ( math.Round(50 / (self:GetPos():Distance(LocalPlayer():GetPos()) / 52.4934)) * 50 ) + 30
				EMRPR:ChangePitch( Pitch )
				EMRPR:ChangeVolume( (50 / (self:GetPos():Distance(LocalPlayer():GetPos()) / 52.4934)) )
				DangerEMRPR:ChangePitch( Pitch )
				DangerEMRPR:ChangeVolume( (60 / (self:GetPos():Distance(LocalPlayer():GetPos()) / 52.4934)) )
			else
				if DangerEMRPR:IsPlaying() then DangerEMRPR:Stop() end
				if EMRPR:IsPlaying() then EMRPR:Stop() end
				
			end
		end
		
		if IsValid(self.Emitter) then
			if not IsValid(self:GetNWEntity( "Targeted" )) then
				self.Emitter:Finish()
			end
		else
			if IsValid(self) then
				self.Emitter = ParticleEmitter(self:GetPos())
			end
		end
	
		if IsValid(self.Emitter) and IsValid(self) and IsValid(self:GetNWEntity( "Targeted" )) then
			local Vector = (self:GetNWEntity( "Targeted" ):GetPos() - self:GetPos()):GetNormalized()
			local part = self.Emitter:Add("particle/smokesprites_0003" , self:GetPos())
			part:SetStartSize(0)
			part:SetEndSize(250)
			part:SetStartAlpha(50)
			part:SetEndAlpha(0)
			part:SetDieTime(0.1)
			part:SetRoll( math.random(0, 360) )
			part:SetRollDelta(0.01)
			part:SetColor(255, 255, 255)
			part:SetLighting(false)
			part:SetVelocity( (self:GetVelocity()) - (Vector * self:GetVelocity():Length() / 3) )
		end
	
end 

function ENT:OnRemove()
	if IsValid(self.Emitter) then
		self.Emitter:Finish()
	end
	
	EMRPR:Stop()
	DangerEMRPR:Stop()
	
end


