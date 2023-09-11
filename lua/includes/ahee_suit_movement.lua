AddCSLuaFile()

GAMEMODE_VARIABLE = gmod.GetGamemode()

function pelvareign_movement( self )
	
	Floor_Check = {}
	Velocity_Check = {}
	
	OwnerVelo = self:GetVelocity()
	GravityNum = physenv.GetGravity() 
	OwnerVeloSquared = Vector( (math.abs(OwnerVelo.x) ^ 0.5) * OwnerVelo:GetNormalized().x , (math.abs(OwnerVelo.y) ^ 0.5) * OwnerVelo:GetNormalized().y , (math.abs(OwnerVelo.z) ^ 0.5) * OwnerVelo:GetNormalized().z )
	GravityNumSquared = Vector( (math.abs(GravityNum.x) ^ 0.5) * GravityNum:GetNormalized().x , (math.abs(GravityNum.y) ^ 0.5) * GravityNum:GetNormalized().y , (math.abs(GravityNum.z) ^ 0.5) * GravityNum:GetNormalized().z ) 
	
	local Min, Max = self:GetCollisionBounds()
	Velocity_Check = {
		start = self:GetPos(),
		endpos = self:GetPos() + OwnerVeloSquared,
		filter = {self},
		mins = Min,
		maxs = Max
	}
	
	Floor_Check.start = self:GetPos()
	Floor_Check.endpos = Floor_Check.start - self:GetAngles():Up() * 200
	Floor_Check.filter = self
	
	local Floor_Response_Local = util.TraceLine(Floor_Check)
	local VelocityHit_Response_Local = util.TraceHull(Velocity_Check)
	
	if not self:IsOnGround() then
		if SERVER then
			
			local Min, Max = self:GetCollisionBounds()
			
			local Hull_Check = util.TraceHull({
				start = self:GetPos(),
				endpos = self:GetPos(),
				filter = {self,self.PlayerBody},
				mins = Min,
				maxs = Max
			})
			
			if IsValid(self) then
				if (not util.IsInWorld(self:GetPos())) or (not Hull_Check.Hit) then
					self:SetMoveType( MOVETYPE_CUSTOM )
					self:SetVelocity( GravityNumSquared/4 )
					self:SetPos( self:GetPos() + OwnerVeloSquared )
				 else
					self:SetMoveType( MOVETYPE_CUSTOM )
					self:SetPos( (self:GetPos() + VelocityHit_Response_Local.Normal*OwnerVeloSquared*0.1) )
					self:SetVelocity( (self:GetVelocity() * -0.5) )
				end
			end
		end
		
	local SlamNormal_x,SlamNormal_y,SlamNormal_z = self:GetVelocity():GetNormalized():Unpack()
	timer.Simple( 0, function() 
		if not self:IsValid() then return end 
		
		Floor_Check.start = self:GetPos()
		Floor_Check.endpos = Floor_Check.start - self:GetAngles():Up() * 200
		Floor_Check.filter = self
		
		Floor_Response = util.TraceLine(Floor_Check)
		
		local TouchingGround = Floor_Response.HitPos:Distance(self:GetPos()) < 50
		
		if self:GetVelocity():Length() > (52.4934) and(SlamNormal_z > 0.1 or SlamNormal_z < -0.1) and (TouchingGround or self:IsOnGround()) then
			local Force = (self:GetVelocity():Length()/(52.4934))
			self:SetViewPunchAngles( self:GetViewPunchAngles() + (Angle( math.Clamp(self:GetForward():Dot(self:GetVelocity()/52.4934)/5,-1,1) + math.Clamp(-self:GetUp():Dot(self:GetVelocity()/52.4934)^2,-5,5) , 0 , math.Clamp(self:GetRight():Dot(self:GetVelocity()/52.4934)/5,-1,1) )/math.pi) )
			if SERVER then
				local dmg_random = 0
				if self.DragShieldingSetting or self.DragShielding > (self.DragShieldingLimit * 0.1) then
					dmg_random = 0
				else
					dmg_random = ( self.InducedGForce / 1000 )
					
					BodyPart_DoDamage( self , 6 , dmg_random )
					BodyPart_DoDamage( self , 7 , dmg_random )
					
					net.Start( "BodyPart_DoDamage_Client" )
					net.WriteString( tostring(6) )
					net.WriteFloat( dmg_random )
					net.Send( self )
					
					net.Start( "BodyPart_DoDamage_Client" )
					net.WriteString( tostring(7) )
					net.WriteFloat( dmg_random )
					net.Send( self )
					
				end
				
				self:TakeDamage( dmg_random , game.GetWorld(), game.GetWorld() )
				
			end
		end
		
		if self:GetVelocity():Length() > (52.4934*35) and SlamNormal_z < -0.4 and (TouchingGround or self:IsOnGround()) then 
			
			local InductedForce = (self.DragShielding - (50 * ((self:GetVelocity():Length()^2)/(52.4934))))
			
			if self.DragShieldingSetting or self.DragShielding < (self.DragShieldingLimit * 0.1) then
				local DetonationWaveRadius = (math.random(60,70)/10) * 52.4934 -- One Meter
				
				
				for k, v in pairs(ents.FindInSphere( self:WorldSpaceCenter() ,DetonationWaveRadius)) do
					if IsValid(v) then
						if ( v:IsPlayer() or v:IsNPC() or v:IsNextBot() or v:GetMoveType() == MOVETYPE_VPHYSICS ) then
							local Dist = ( 1 - (v:GetPos():Distance(self:GetPos())/DetonationWaveRadius) )
							if SERVER then
								local dmginfo = DamageInfo()
								local dmg_random = ( math.random(600,13000) * Dist^3 ) 
								
								v:SetVelocity( (v:GetVelocity() + (v:GetPos() - self:GetPos() ):GetNormalized() * 200 * (self:GetVelocity():Length() * (0.0254 / 10))) * Dist^3 )
								dmginfo:SetDamage( dmg_random * (self:GetVelocity():Length() * (0.0254 / 10)) )
								dmginfo:SetAttacker( self )
								dmginfo:SetInflictor( self )
								dmginfo:SetDamageType( DMG_BLAST ) 
								dmginfo:SetDamageForce( (( v:GetPos() - self:GetPos()  ):GetNormalized() * 110000 * (self:GetVelocity():Length() * (0.0254 / 10))) * Dist^3 )
								dmginfo:SetDamagePosition( self:WorldSpaceCenter() )
								v:TakeDamageInfo( dmginfo )
							end
						end
					end
				end
				
				ParticleEffect( "Shockwave", self:GetPos() , Angle(math.random(0,360),math.random(0,360),math.random(0,360)))
				ParticleEffect( "SmokeShockFar", self:GetPos() , Angle(math.random(0,360),math.random(0,360),math.random(0,360)))
				sound.Play( Sound("high_energy_systems/caplier_faucation.wav"), self:GetPos() , 130, 90, 1 ) 
				
				if SERVER then
					DragShieldHit_Shared( self , self:WorldSpaceCenter()  , 3 , 8 )
				end
				
				if SERVER then
					local subtraction = 0
					if InductedForce < 0 then
						subtraction = InductedForce
					end
					local dmg_random = ( self.NetMass * ((self:GetVelocity():Length()^2) / (52.4934)) ) / self.DragShielding / subtraction
					BodyPart_DoDamage( self , 6 , dmg_random )
					BodyPart_DoDamage( self , 7 , dmg_random )
					
					self:TakeDamage( dmg_random / self.DragShielding, game.GetWorld(), game.GetWorld() )
					
					net.Start( "BodyPart_DoDamage_Client" )
					net.WriteString( tostring(6) )
					net.WriteFloat( dmg_random )
					net.Send( self )
					
					net.Start( "BodyPart_DoDamage_Client" )
					net.WriteString( tostring(7) )
					net.WriteFloat( dmg_random )
					net.Send( self )
				end
				
			else
				
				local DetonationWaveRadius = (math.random(10,30)/10) * 52.4934 -- One Meter
				
				for k, v in pairs(ents.FindInSphere( self:WorldSpaceCenter() ,DetonationWaveRadius)) do
					if IsValid(v) then
						if ( v:IsPlayer() or v:IsNPC() or v:IsNextBot() or v:GetMoveType() == MOVETYPE_VPHYSICS ) then
							local Dist = ( 1 - (v:GetPos():Distance(self:GetPos())/DetonationWaveRadius) )
							if SERVER then
								local dmginfo = DamageInfo()
								local dmg_random = ( math.random(600,13000) * Dist^3 ) 
								
								v:SetVelocity( (v:GetVelocity() + (v:GetPos() - self:GetPos() ):GetNormalized() * 200 * (self:GetVelocity():Length() * (0.0254 / 10))) * Dist^3 )
								dmginfo:SetDamage( dmg_random * (self:GetVelocity():Length() * (0.0254 / 10)) )
								dmginfo:SetAttacker( self )
								dmginfo:SetInflictor( self )
								dmginfo:SetDamageType( DMG_BLAST ) 
								dmginfo:SetDamageForce( (( v:GetPos() - self:GetPos()  ):GetNormalized() * 110000 * (self:GetVelocity():Length() * (0.0254 / 10))) * Dist^3 )
								dmginfo:SetDamagePosition( self:WorldSpaceCenter() )
								v:TakeDamageInfo( dmginfo )
							end
						end
					end
				end
				
				ParticleEffect( "APFSDSSCREEN", self:GetPos() , Angle(0,0,0) )
				ParticleEffect( "Flashed", self:GetPos() , Angle(0,0,0) )
				ParticleEffect( "SmallShrapnel", self:GetPos() , Angle(math.random(0,360),math.random(0,360),math.random(0,360)))
				
				if SERVER then
					local dmg_random = ( self.NetMass * ((self:GetVelocity():Length()^2) / (52.4934)) )
					BodyPart_DoDamage( self , 6 , dmg_random )
					BodyPart_DoDamage( self , 7 , dmg_random )
					
					self:TakeDamage( dmg_random, game.GetWorld(), game.GetWorld() )
					
					net.Start( "BodyPart_DoDamage_Client" )
					net.WriteString( tostring(6) )
					net.WriteFloat( dmg_random )
					net.Send( self )
					
					net.Start( "BodyPart_DoDamage_Client" )
					net.WriteString( tostring(7) )
					net.WriteFloat( dmg_random )
					net.Send( self )
				end
				
			end
		
			if self.WADSuppression <= 3 then
				sound.Play( Sound("main/airshockwave.wav"), self:GetPos() , 120, 60, 1 ) 
				sound.Play( Sound("main/bomb_explosion_"..math.random(1,3)..".mp3"), self:GetPos() , 120, 60, 1 )
				sound.Play( Sound("main/ground_hit_explosive_"..math.random(1,3)..".mp3"), self:GetPos() , 130, 60, 1 )
			else
				self:EmitSound("ahee_suit/wavelength_absorption_device_footstep_"..math.random(1,5)..".mp3", 90, math.random(80,110),1)
			end
			
			
		elseif self:GetVelocity():Length() > (52.4934*2) and SlamNormal_z < -0.1 and (TouchingGround or self:IsOnGround()) then
			
			for i = 1 , 3 do
				ParticleEffect( "GroundCloudLarge", self:GetPos() , self:GetVelocity():GetNormalized():Cross( Angle():Up() ):Angle() + (AngleRand() * 0.8) )
			end
			
			if self.WADSuppression > 2 then
				self:EmitSound("ahee_suit/a9er_footstep_"..math.random(1,3)..".mp3", 98, math.random(150,160), 0.9 )
			else
				self:EmitSound("ahee_suit/wavelength_absorption_device_footstep_"..math.random(1,5)..".mp3", 120, math.random(50,60),0.25)
			end
			
			ParticleEffect( "DirtPieces", self:GetPos() , -self:GetVelocity():GetNormalized():Angle() )
			
		elseif self:GetVelocity():Length() > (52.4934*20) and SlamNormal_z > 0.1 and (TouchingGround or self:IsOnGround()) then 
			
			for i = 1 , 7 do
				ParticleEffect( "GroundCloudLarge", self:GetPos() , Angle() + (AngleRand() * 0.8) )
			end
			
			if self.WADSuppression > 2 then
			self:EmitSound("main/roundhit_softmatter_8.mp3", 90, math.random(80,90),0.5)
			self:EmitSound("main/airshockwave.wav", 100, math.random(10,30), 0.9 )
			else
				self:EmitSound("ahee_suit/wavelength_absorption_device_footstep_"..math.random(1,5)..".mp3", 120, math.random(50,60),0.25)
			end
			
			ParticleEffect( "DirtSplash", self:GetPos() , (AngleRand() * 0.1) + self:GetVelocity():GetNormalized():Angle() )
			
		elseif self:GetVelocity():Length() > (52.4934*1) and SlamNormal_z > 0.1 and (TouchingGround or self:IsOnGround()) then 
			
			for i = 1 , 3 do
				ParticleEffect( "GroundCloudLarge", self:GetPos() , Angle() + (AngleRand() * 0.8) )
			end
			
			if self.WADSuppression > 2 then
			self:EmitSound("main/roundhit_softmatter_9.mp3", 90, math.random(110,120),0.3)
			self:EmitSound("main/airshockwave.wav", 85, math.random(30,40), 0.5 )
			else
				self:EmitSound("ahee_suit/wavelength_absorption_device_footstep_"..math.random(1,5)..".mp3", 120, math.random(50,60),0.25)
			end
			
		end
	end)
	
	else
		
		local ForwardBit = self:KeyDown( IN_FORWARD ) and 1 or 0
		local BackBit = self:KeyDown( IN_BACK ) and 1 or 0
		local RightBit = self:KeyDown( IN_MOVELEFT ) and 1 or 0
		local LeftBit = self:KeyDown( IN_MOVERIGHT ) and 1 or 0
		
		local RunningBit = self:KeyDown( IN_SPEED ) and 2 or 1
		local JumpingBit = self:KeyDown( IN_JUMP ) and 1 or 0
		
		local ForBackCalc = ForwardBit - BackBit
		local RightLeftCalc = LeftBit - RightBit
		local MovementAccelCalc = ((52.4934*18) / (1/engine.TickInterval()) ) / 0.6 * RunningBit
		local MovementCalc = (Angle( 0 , self:GetAngles().y , 0 ):Forward() * MovementAccelCalc * ForBackCalc) + (Angle( 0 , self:GetAngles().y , 0 ):Right() * MovementAccelCalc * RightLeftCalc)
		local JumpingCalc = (self:GetAngles():Up() * MovementAccelCalc * math.random(1,2) * JumpingBit)
		
		if SERVER then
			if not VelocityHit_Response_Local.Hit then
				self:SetVelocity( (self:GetVelocity() * 0.1) + MovementCalc + JumpingCalc*2 )
				--self:SetPos( (self:GetPos() + OwnerVeloSquared + JumpingCalc) )
			else
				self:SetVelocity( (self:GetVelocity() * 0.05) )
				--self:SetPos( (self:GetPos() + OwnerVeloSquared) - VelocityHit_Response_Local.Normal*OwnerVeloSquared*0.1 )
			end
			
			if self:GetMoveType() != MOVETYPE_WALK then
				self:SetMoveType( MOVETYPE_WALK )
			end
		end
		
		
		
	end
	if CLIENT then
		local VelocityVolume = math.Clamp( ( (self:GetVelocity()/52.4934) / 25 ):Length()^0.5 , 0 , 1 )
		local SubtractionVolume = LerpVol and  math.Clamp( LerpVol-(VelocityVolume^(20+VelocityVolume*19.99)) , -1 , 1 ) or 0
		local FlyVolume = (TouchingGround or self:IsOnGround()) and 0.25 or -1
		LerpVol = LerpVol and math.Clamp( LerpVol - (SubtractionVolume*0.005) , 0 , 1 ) or 0
		LerpFlyingVol = LerpFlyingVol and math.Clamp( LerpFlyingVol - (FlyVolume*0.005) , 0 , 1 ) or 0
		
		local RoundedLerp = math.Round( LerpVol , 3 )
		local RoundedFlyLerp = math.Round( LerpFlyingVol , 3 )
		if false and not ( IsValid( Music_Stinger ) ) and RoundedLerp > 0 then
			
			local VersionType = math.Round(math.random(1,7))
			local HighNotePotential = not (TouchingGround or self:IsOnGround())
			
			sound.PlayFile( "sound/music/citationcombative_activecombat_"..VersionType..".mp3", "noplay", function( music_stinger, errCode, errStr )
				if ( IsValid( music_stinger ) ) then
					if ( IsValid( Music_Stinger ) ) then Music_Stinger:Stop() end
					Music_Stinger = music_stinger
					Music_Stinger:Play()
					Music_Stinger:SetVolume( 0 )
				else
					print( "Error playing sound!", errCode, errStr )
				end
				
			end )
			
			sound.PlayFile( "sound/music/citationcombative_activecombat_hardnotes_"..VersionType..".mp3", "noplay", function( music_stinger_2, errCode, errStr )
				if ( IsValid( music_stinger_2 ) ) then
					if ( IsValid( Music_Stinger_2 ) ) then Music_Stinger_2:Stop() end
					Music_Stinger_2 = music_stinger_2
					Music_Stinger_2:Play()
					Music_Stinger_2:SetVolume( 0 )
				else
					print( "Error playing sound!", errCode, errStr )
				end
				
			end )
			
			sound.PlayFile( "sound/music/citationcombative_activecombat_highnotes_"..VersionType..".mp3", "noplay", function( music_stinger_3, errCode, errStr )
				if ( IsValid( music_stinger_3 ) ) then
					if ( IsValid( Music_Stinger_3 ) ) then Music_Stinger_3:Stop() end
					Music_Stinger_3 = music_stinger_3
					Music_Stinger_3:Play()
					Music_Stinger_3:SetVolume( 0 )
				else
					print( "Error playing sound!", errCode, errStr )
				end
				
			end )
			
		elseif ( IsValid( Music_Stinger ) ) then
			if Music_Stinger then
					Music_Stinger:SetVolume( (RoundedLerp^0.5) - RoundedFlyLerp )
				if (Music_Stinger:GetState()==GMOD_CHANNEL_STOPPED) then Music_Stinger = nil end
			end
			
			if Music_Stinger_2 then
				Music_Stinger_2:SetVolume( RoundedFlyLerp )
				
				if (Music_Stinger_2:GetState()==GMOD_CHANNEL_STOPPED) then Music_Stinger_2 = nil end
			end
			
			if Music_Stinger_3 then
				Music_Stinger_3:SetVolume( RoundedLerp^6 )
				if (Music_Stinger_3:GetState()==GMOD_CHANNEL_STOPPED) then Music_Stinger_3 = nil end
			end
		end
		
		-- if not MusicStinger then
			-- MusicStinger = CreateSound( self,"main/citationcombative_stinger_2.mp3")
			-- MusicStinger:PlayEx( VelocityVolume )
		-- elseif MusicStinger:IsPlaying() then
			-- MusicStinger:ChangeVolume( VelocityVolume )
		-- else
			-- MusicStinger = CreateSound( self,"main/citationcombative_stinger_2.mp3")
			-- MusicStinger:PlayEx( VelocityVolume )
		-- end
		
	end
	
end






















