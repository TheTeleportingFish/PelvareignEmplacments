AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.PrintName = "TIWFragRound"
ENT.Author = "The Pelvareign Order"
ENT.Information = "A TIW Frag Round"
ENT.Spawnable = false
ENT.AdminSpawnable = false 

function ENT:SetupDataTables()
	self:SetNWEntity( "Targeted", nil )
	
end

ENT.BlastDamage = 30
ENT.BlastRadius = 590.55*2
ENT.BlastDamage2 = 15000
ENT.BlastRadius2 = (590.55/2)
ENT.Mass = 120

if SERVER then
	util.AddNetworkString( "FragCBMRnd_Client_Shockwave_Round" )
	util.AddNetworkString( "Client_Shockwave_PressurizedExplosive" )
elseif CLIENT then
	language.Add("cw_tiwround_frag13", "TIW Frag Round")
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:Initialize()
	
	self.Radeonic = self
	
	if SERVER then
		
		self:SetModel("models/Items/AR2_Grenade.mdl") 
		self:SetModelScale( 0.35, 0 )
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE)
		self:SetMoveCollide( MOVECOLLIDE_DEFAULT )

		local phys = self:GetPhysicsObject()
		
		local trail = util.SpriteTrail( self, 0, Color( 255, 0, 0 ), true, 2, 0, 0.1, 0.1, "effects/beam_generic01" )
		local trail2 = util.SpriteTrail( self, 0, Color( 255, 255, 255 ), true, 4, 0, 0.05, 0.2, "effects/beam_generic01" )
		
		if IsValid(self:GetNWEntity( "Targeted" )) then
		trail3 = util.SpriteTrail( self, 0, Color( 255, 255, 50 ), true, 0.4, 0, 0.25, 0.6, "effects/beam_generic01" )
		self.CurrentDist = phys:GetPos():Distance(self:GetNWEntity( "Targeted" ):WorldSpaceCenter())
		self.Lowest = self.CurrentDist
		end
		
		if phys and phys:IsValid() then
			phys:Wake()
			phys:SetMass( self.Mass )
			phys:SetDragCoefficient( 1e-8 )
		end
		
		self:EmitSound( Sound("EMRP") )
		self:GetPhysicsObject():SetBuoyancyRatio(0)
		
		spd = physenv.GetPerformanceSettings()
		spd.MaxVelocity = 800 * 52.4934
		
		physenv.SetPerformanceSettings(spd)
		
		self.FRAGMENTED = false
		
	elseif CLIENT then
		if IsValid(self) then
			self.Emitter = ParticleEmitter(self:GetPos())
			self.ParticleDelay = 0
		end
		
		EMRPR = CreateSound( self, "main/t_b_r.wav" )
		EMRPR:SetSoundLevel( 140 )
		DangerEMRPR = CreateSound( self, "tunneling_physics/tunneling_fieldbeam_noise.mp3" )
		DangerEMRPR:SetSoundLevel( 100 )
		
		self.Client_Velocity = Vector() --Client Prediction Stupidity
		
		timer.Simple( 0.1 , function()
			if IsValid(self) then
				EMRPR:Play()
				DangerEMRPR:Play()
				
				EMRPR:FadeOut( 2 )
				DangerEMRPR:FadeOut( 2 )
			end
		end)
		
		net.Receive( "FragCBMRnd_Client_Shockwave_Round", function( len )
			local ContinationWave = net.ReadFloat()
			local Dist = ( 1 - net.ReadFloat() ) or 0
			
			local VecPos = net.ReadString()
			local VelPos = net.ReadString()
			
			local VecPos_Table = string.Explode( ",", VecPos )
			local VectorPos = Vector( VecPos_Table[1] , VecPos_Table[2] , VecPos_Table[3] )
			
			local VecPos_Table = string.Explode( ",", VelPos )
			local VelocityVector = Vector( VecPos_Table[1] , VecPos_Table[2] , VecPos_Table[3] )
			
			if ContinationWave == nil then return end
			
			local dlight = DynamicLight( LocalPlayer():EntIndex() )
			if ( dlight ) then
				dlight.pos = VectorPos
				dlight.r = 255
				dlight.g = 255
				dlight.b = 255
				dlight.brightness = 3
				dlight.decay = 1000
				dlight.size = 500
				dlight.dietime = CurTime() + 0.1
			end
			
			local PenData = {}
			PenData.start = VectorPos
			PenData.endpos = PenData.start + ( VectorPos:GetNormalized() * (500 * 52.4934) )
			
			local Pentrace = util.TraceLine(PenData)
			
			local Vector_Placement = (VelocityVector:GetNormalized()-Pentrace.HitNormal/math.random(1,6))
			local Dynamic_Particle_System = CreateParticleSystemNoEntity( "high_heat_burn_point", Pentrace.StartPos-Pentrace.HitNormal, Vector_Placement:GetNormalized():Angle() )
			Dynamic_Particle_System:SetControlPoint( 1, VectorPos + (VectorRand()+Pentrace.HitNormal/2)*math.random(125,275) )
			
			if ContinationWave < 120 then
				timer.Simple( ContinationWave , function() 
					EmitSound( "central_base_material/cbm_round_deform_distant_"..math.random(1,3)..".mp3" , Vector() , -1 , CHAN_AUTO , math.Clamp(Dist^3,0,1) , 0 , 0 , math.random(90,110) )
					EmitSound( "cbm_weaponry/small_caliber_weave_deploy_"..math.random(1,5)..".mp3" , Vector() , -1 , CHAN_AUTO , math.Clamp(Dist^20,0,1) , 0 , 0 , math.random(90,100) )
				end)
			end
			
		end)
		
		net.Receive( "Client_Shockwave_PressurizedExplosive", function( len )
			local ContinationWave = net.ReadFloat()
			local Dist = ( 1 - net.ReadFloat() ) or 0
			
			local VecPos = net.ReadString()
			local VelPos = net.ReadString()
			
			local VecPos_Table = string.Explode( ",", VecPos )
			local VectorPos = Vector( VecPos_Table[1] , VecPos_Table[2] , VecPos_Table[3] )
			
			local VecPos_Table = string.Explode( ",", VelPos )
			local VelocityVector = Vector( VecPos_Table[1] , VecPos_Table[2] , VecPos_Table[3] )
			
			if ContinationWave == nil then return end
			
			local dlight = DynamicLight( LocalPlayer():EntIndex() )
			if ( dlight ) then
				dlight.pos = VectorPos
				dlight.r = 255
				dlight.g = 110
				dlight.b = 50
				dlight.brightness = 4
				dlight.decay = 2000
				dlight.size = 2000
				dlight.dietime = CurTime() + 0.3
			end
			
			if ContinationWave < 120 then
				timer.Simple( ContinationWave , function() 
					EmitSound( "ahee_suit/fraise/fraise_passive_plasmaticdetonation_heavy_"..math.random(1,3)..".mp3" , Vector() , -1 , CHAN_AUTO , math.Clamp(Dist^15,0,1) , 0 , 0 , math.random(100,200) )
					EmitSound( "cbm_weaponry/small_caliber_light_fragmentation_lead.mp3" , Vector() , -1 , CHAN_AUTO , math.Clamp(Dist^20,0,1) , 0 , 0 , math.random(90,110) )
					EmitSound( "cbm_weaponry/small_caliber_light_fragmentation_lead_far.mp3" , Vector() , -1 , CHAN_AUTO , math.Clamp(Dist^1.5,0,1) , 0 , 0 , math.random(110,135) )
					EmitSound( "cbm_weaponry/25mm_kessaal_brikna_distant_fire_"..math.random(1,4)..".mp3" , Vector() , -1 , CHAN_AUTO , math.Clamp(Dist^1.5,0,1) , 0 , 0 , math.random(90,105) )
				end)
			end
			
		end)
	end
	
end

function ENT:SinuousExplosion( Meters )

	local traceData = {}
	traceData.mask = bit.bor(CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_DEBRIS, CONTENTS_MONSTER, CONTENTS_HITBOX, CONTENTS_WATER)
	
	local SoundDistanceMax = Meters * 52.4934
		for k, v in pairs(ents.FindInSphere(self:WorldSpaceCenter(),SoundDistanceMax)) do
			if IsValid(v) and v:IsPlayer() then
				local Dist = v:WorldSpaceCenter():Distance(self:WorldSpaceCenter())/SoundDistanceMax
				
				obj = v
				
				local positedplayer = v:WorldSpaceCenter()
				
				direction = ( positedplayer - self:WorldSpaceCenter() )
				
				traceData.filter = {Bouncer,self}
				traceData.start = self:WorldSpaceCenter() 
				traceData.endpos = traceData.start + direction * SoundDistanceMax
				
				local trace = util.TraceLine(traceData)
				
				local ent = trace.Entity
				local fract = trace.Fraction
				
				local equal = ent == v
				
				local SpatialWaveFormat = 343 + math.random(-10,150)
				
				if not equal then 
					SpatialWaveFormat = SpatialWaveFormat / ( math.random( 110 , 150 ) / 100 )
					Dist = (Dist ^ math.random( 0.45 , 0.75 ) )
				end
				
				local ContinationWave = ( Dist * SoundDistanceMax ) / ( SpatialWaveFormat * 52.4934 )
				
				local VecPos = self:GetPos()
				local VelPos = self:GetPhysicsObject():GetVelocity()
				local VecPos_String = (VecPos.x)..","..(VecPos.y)..","..(VecPos.z)
				local VelPos_String = (VelPos.x)..","..(VelPos.y)..","..(VelPos.z)
				
				net.Start("FragCBMRnd_Client_Shockwave_Round")
					net.WriteFloat(ContinationWave)
					net.WriteFloat(Dist)
					net.WriteString(VecPos_String)
					net.WriteString(VelPos_String)
					
				net.Send(v)
			end
		end

end

function ENT:Special_Ent_Dmg( Ent )
	if not Ent:IsValid() then return end
	local RoundPhys = self:GetPhysicsObject()
	local Velocity = RoundPhys:GetVelocity()
	local Position = self:GetPos()
	local Ent_Class = Ent:GetClass()
	
	if Ent_Class == "npc_turret_floor" then
		Ent:Fire("SelfDestruct")
		ParticleEffectAttach( "object_vaporize_shrapnel", PATTACH_ABSORIGIN_FOLLOW, Ent, -1 )
		ParticleEffectAttach( "object_vaporize_vapor", PATTACH_ABSORIGIN_FOLLOW, Ent, -1 )
		
	elseif Ent_Class == "npc_strider" then
		
		Ent:SetSaveValue( "m_bExploding", true )
		
		local d = DamageInfo()
		d:SetDamage( Ent:Health() )
		d:SetAttacker( Ent )
		d:SetInflictor( Ent )
		d:SetDamageType( DMG_GENERIC )
		Ent:TakeDamageInfo( d )
		
		ParticleEffect( "small_caliber_heat_shrapnel", Ent:GetPos(), (Velocity:GetNormalized()-VectorRand()/math.random(2,5)):Angle() )
		ParticleEffect( "small_caliber_fragmentation_shrapnel", Ent:GetPos(), VectorRand():Angle() )
		ParticleEffect( "object_vaporize_shrapnel_large", Ent:GetPos(), Angle() )
		return true
		
	elseif Ent_Class == "npc_helicopter" then
		local Size = 12*52.4934
		local effectdata = EffectData()
		local d = DamageInfo()
		d:SetDamage( (3 * (Velocity:Length()/52.4934) ^ 3 ) )
		d:SetAttacker( self.Owner )
		d:SetInflictor( self )
		d:SetDamageType( DMG_AIRBOAT )
		Ent:TakeDamageInfo( d )
		
		util.BlastDamage( self, self.Owner, Position, Size, Velocity:Length()^0.5 )
		
		ParticleEffect( "small_caliber_fragmentation_smoke", Ent:WorldSpaceCenter(), (Velocity:GetNormalized()-VectorRand()/math.random(2,5)):Angle() )
		ParticleEffect( "object_vaporize_shrapnel_large", Ent:WorldSpaceCenter(), Angle() )
		
	end
	
	return false --Return true to indicate special damage effects only, false for normal
	
end

function ENT:Think()
	local RoundPhys = self:GetPhysicsObject()
	local Targeted = self:GetNWEntity( "Targeted" )
	if not self.Owner then return end
	--print(Targeted)
	if SERVER then
		if IsValid(Targeted) then
			if self.CurrentDist <= self.Lowest then
				if self:GetPhysicsObject() != nil then
					local SteerForce = 1500 + math.random(-1350,125)
					local AutoDistance = self.Owner:WorldSpaceCenter():Distance(self:GetNWEntity( "Targeted" ):WorldSpaceCenter())
					local TriggerDistance = AutoDistance - 100
					local MaxTurnDistance = 17000 + math.random(-1350,1350)
					local MagnitudeVelocity = Vector( math.abs(self:GetNWEntity( "Targeted" ):GetVelocity().x) ^ 0.5 , math.abs(self:GetNWEntity( "Targeted" ):GetVelocity().y) ^ 0.5 , math.abs(self:GetNWEntity( "Targeted" ):GetVelocity().z) ^ 0.5 )
					local MoveVector = ( RoundPhys:GetPos() - ( self:GetNWEntity( "Targeted" ):WorldSpaceCenter() + ( MagnitudeVelocity * self:GetNWEntity( "Targeted" ):GetVelocity():GetNormalized() ) )):GetNormalized() * -SteerForce
					local MoveVectorNormalized = MoveVector - (self:GetForward() * SteerForce/1.05)
					local TurnCalc = 1 - math.Clamp( (self.CurrentDist-MaxTurnDistance)/(TriggerDistance) , 0 , 1 )
					if self.CurrentDist < TriggerDistance then
						RoundPhys:AddVelocity( (MoveVectorNormalized * TurnCalc) - (physenv.GetGravity():GetNormalized() * (physenv.GetGravity():Length() ^ 0.5)) )	
					end
					
				end
				self.Lowest = self.CurrentDist
				self.CurrentDist = RoundPhys:GetPos():Distance(self:GetNWEntity( "Targeted" ):WorldSpaceCenter())
			end
			
			
			local PenData = {}
			PenData.filter = { self }
			PenData.start = self:WorldSpaceCenter()
			PenData.endpos = PenData.start + ( RoundPhys:GetVelocity():GetNormalized() * (500 * 52.4934) )
			
			local Pentrace = util.TraceLine(PenData)
			
			local ConeData = {}
			ConeData.filter = { self }
			ConeData.start = self:WorldSpaceCenter()
			ConeData.endpos = ConeData.start + ( (Targeted:WorldSpaceCenter()-self:WorldSpaceCenter()):GetNormalized() * (500 * 52.4934) )
			
			local Conetrace = util.TraceLine(ConeData)
			
			local DegreesBetween = math.Round(math.deg(math.acos(Conetrace.Normal:Dot(Pentrace.Normal)) / (Pentrace.Normal:Length() * Conetrace.Normal:Length())),2)
			
			if IsValid(Targeted) and (self.CurrentDist < (15 * 52.4934) or (DegreesBetween <= 0.5 and self.CurrentDist < (150 * 52.4934))) then
				
				
				
				local SoundDistanceMax = 1200 * 52.4934
				for k, v in pairs(ents.FindInSphere(self:WorldSpaceCenter(),SoundDistanceMax)) do
					if IsValid(v) and v:IsPlayer() then
						local Dist = v:WorldSpaceCenter():Distance(self:WorldSpaceCenter())/SoundDistanceMax
						
						local ContinationWave = ((Dist)*SoundDistanceMax)/((343+math.random(80,150)) * 52.4934)
						
						local VecPos = self:GetPos()
						local VelPos = self:GetPhysicsObject():GetVelocity()
						local VecPos_String = (VecPos.x)..","..(VecPos.y)..","..(VecPos.z)
						local VelPos_String = (VelPos.x)..","..(VelPos.y)..","..(VelPos.z)
						
						net.Start("Client_Shockwave_PressurizedExplosive")
							net.WriteFloat(ContinationWave)
							net.WriteFloat(Dist)
							net.WriteString(VecPos_String)
							net.WriteString(VelPos_String)
							
						net.Send(v)
					end
				end
				
				local Explose_Size = 12 * 52.4934
				for Index, Ent_Found in pairs(ents.FindInSphere(self:WorldSpaceCenter(),Explose_Size)) do
					local Dist = Ent_Found:WorldSpaceCenter():Distance(self:WorldSpaceCenter())/Explose_Size
					if Ent_Found:IsValid() then
						local Ent_Pos = Ent_Found:WorldSpaceCenter()
						local d = DamageInfo()
						
						self:Special_Ent_Dmg( Ent_Found )
						
						d:SetDamage( 320*Dist )
						d:SetAttacker( self.Owner )
						d:SetInflictor( self )
						d:SetDamageType( DMG_DISSOLVE )
						Ent_Found:TakeDamageInfo( d )
						
						d:SetDamage( 32*Dist )
						d:SetDamageType( DMG_SHOCK )
						Ent_Found:TakeDamageInfo( d )
						
						d:SetDamage( math.random(500000,750000)*Dist )
						d:SetDamageType( DMG_GENERIC )
						Ent_Found:TakeDamageInfo( d )
						
						d:SetDamage( math.Rand(91,201.5) * (RoundPhys:GetVelocity():Length() / 52.4934) )
						d:SetDamageType( DMG_RADIATION )
						Ent_Found:TakeDamageInfo( d )
						
						ParticleEffectAttach( "object_vaporize_vapor", PATTACH_ABSORIGIN_FOLLOW, Ent_Found, -1 )
						ParticleEffectAttach( "object_vaporize_shrapnel", PATTACH_ABSORIGIN_FOLLOW, Ent_Found, -1 )
						
						constraint.RemoveAll( Ent_Found )
						Ent_Found:Fire("EnableMotion")
						
						local PushVelocity = ((Ent_Found:WorldSpaceCenter()-self:WorldSpaceCenter()):GetNormalized()*(1-Dist)) * math.random(1000,3500)
						local Ent_Phys = Ent_Found:GetPhysicsObject()
						if IsValid(Ent_Phys) then Ent_Phys:SetVelocity( Ent_Phys:GetVelocity() + PushVelocity ) else
						Ent_Found:SetVelocity( Ent_Found:GetVelocity() + PushVelocity ) end
						
					end
				end
				
				ParticleEffect( "fraise_explosion", self:GetPos(), Angle() )
				ParticleEffect( "small_caliber_fragmentation", self:GetPos() , RoundPhys:GetVelocity():GetNormalized():Angle() )
				
				local d = DamageInfo()
				d:SetDamage( math.Rand(25,50.5) * (RoundPhys:GetVelocity():Length() / 52.4934) )
				d:SetAttacker( self.Owner )
				d:SetInflictor( self )
				d:SetDamageType( DMG_RADIATION )
				
				util.BlastDamageInfo(d, self:GetPos(), (30 * 52.4934))
				
				for i = 1, math.random(8,12) do
					if SERVER then
						Bouncer = ents.Create("cw_tiwround_fragment")
						
						local AngleFire = ( self:GetForward() + (VectorRand()/(self.CurrentDist / 52.4934)) ):Angle()
						
						Bouncer:SetPos( RoundPhys:GetPos() + (VectorRand() * math.random(1,10)) )
						Bouncer:SetAngles( AngleFire )
						Bouncer:SetOwner( self.Owner )
						Bouncer:Spawn()
						
						local BouncerPhys = Bouncer:GetPhysicsObject()
						
						if IsValid(BouncerPhys) then
							BouncerPhys:SetVelocityInstantaneous(AngleFire:Forward()*math.random(26000,39000))
						end
						
					end
				end
				
				self:Remove()
				
			end
		end
		
		net.Start( "Client_Velocity_Prediction_Fix" , true ) --Client Prediction Stupidity
			net.WriteFloat( self:GetVelocity():Length() )
			net.WriteNormal( self:GetVelocity():GetNormalized() )
			net.WriteEntity( self )
		net.Broadcast()
		
	elseif CLIENT then
		local Root_Velocity = ( self.Client_Velocity:GetNormalized() * (self.Client_Velocity:Length()^0.5) )
		if IsValid(self) then
			local Pitch = (math.Round(100 / (self:GetPos():Distance(LocalPlayer():GetPos()) / 52.4934))*150) + 100
			EMRPR:ChangePitch( Pitch )
			EMRPR:ChangeVolume( (150 / (self:GetPos():Distance(LocalPlayer():GetPos()) / 52.4934)) )
			DangerEMRPR:ChangePitch( Pitch )
			DangerEMRPR:ChangeVolume( (150 / (self:GetPos():Distance(LocalPlayer():GetPos()) / 52.4934)) )
		else
			EMRPR:Stop()
			DangerEMRPR:Stop()
		end
		
		local part = self.Emitter:Add( "sprites/glow04_noz" , self:GetPos() + (VectorRand() * 0.2) ) -- Create a new particle at pos
		if ( part ) then
			part:SetDieTime( 0.05 )
			
			part:SetStartAlpha( 220 )
			part:SetEndAlpha( 0 )
			
			part:SetStartSize( math.random( 50 , 80 ) * math.abs(math.sin(RealTime()*5)) )
			part:SetEndSize( 0 )
			
			part:SetColor( math.random( 10 , 60 ), math.random( 70 , 255 ), math.random( 50 , 190 ) )
		end
		
		for i=1, math.random(0.2,1.6) do
			local part = self.Emitter:Add( "sprites/glow04_noz" , self:GetPos() + (VectorRand() * 0.1) - Root_Velocity ) -- Create a new particle at pos
			local velocity_amt = (self.Client_Velocity * math.Rand(0.1, 0.5))
			local localized_size = math.random(16,20)
			if ( part ) then
				part:SetDieTime( math.random( 1 , 5 ) / 10 )
				
				part:SetStartAlpha( 220 )
				part:SetEndAlpha( 150 )
				
				part:SetStartSize( localized_size )
				part:SetStartLength( localized_size * 10 )
				part:SetEndSize( 0 )
				part:SetEndLength( 0 )
				
				part:SetColor( math.random( 110 , 160 ), math.random( 170 , 255 ), math.random( 150 , 200 ) )
				part:SetVelocity( velocity_amt + (VectorRand() * velocity_amt:Length()/math.random(3,25)) )
			end
		end
		
		if IsValid(self.Emitter) and IsValid(self:GetNWEntity( "Targeted" )) then
			local Vector_Dir = (self:GetNWEntity( "Targeted" ):GetPos() - self:GetPos()):GetNormalized()
			local Vector_Velocity = (Vector_Dir * self:GetVelocity():Length() / 4)
			
			local part = self.Emitter:Add("particle/smokesprites_0003" , self:GetPos())
			if ( part ) then
				part:SetStartSize(0)
				part:SetEndSize(150)
				
				part:SetStartAlpha(50)
				part:SetEndAlpha(0)
				
				part:SetDieTime(0.1)
				
				part:SetRoll( math.random(0, 360) )
				part:SetRollDelta(0.01)
				part:SetColor(1, 1, 1)
				
				part:SetLighting(false)
				part:SetVelocity( self:GetVelocity() - Vector_Velocity )
			end
			
			for i=1, math.random(0.2,1.6) do
				local part = self.Emitter:Add( "sprites/glow04_noz" , self:GetPos() + (VectorRand()*0.1) ) -- Create a new particle at pos
				local size = math.Rand(10,20)
				local spark_velocity = (-Vector_Velocity * math.Rand(0.1, 0.95)) + (VectorRand()*size)
				
				if ( part ) then
					part:SetDieTime( math.Rand(0.1,0.2) )
					
					part:SetStartAlpha( 255 )
					part:SetEndAlpha( 200 )
					
					part:SetColor( 255, math.random(230,255), math.random(190,230) )
					
					part:SetGravity( Vector( 0 , 0 , -600 ) )
					part:SetVelocity( spark_velocity + (VectorRand() * spark_velocity:Length()/math.random(5,20)) )
					
					part:SetStartSize( size )
					part:SetEndSize( 0 )
					
					part:SetBounce( math.Rand(0.1,0.5) )
					part:SetAirResistance( 1000 / size )
					part:SetCollide( true )
				end
			end
		end
		
	end
	
	self:NextThink( CurTime() + 0.05 )
	return true
end 


function ENT:PhysicsUpdate(phys)

	local angles = phys:GetAngles()
	local velocity = phys:GetVelocity()

	phys:SetAngles( velocity:Angle() )
	phys:SetVelocity(velocity)
	
end

function ENT:Use(activator, caller)
	return false
end

function ENT:OnRemove()
	if CLIENT then
		if IsValid(self) then
			self.DestructEmitter = ParticleEmitter(self:GetPos())
			
			for i=1,math.random(15,30) do
				local part = self.DestructEmitter:Add("particle/smokesprites_0002" , self:GetPos())
				part:SetStartSize(0)
				part:SetEndSize(math.random(240,250))
				part:SetStartAlpha(20)
				part:SetEndAlpha(0)
				part:SetDieTime(1.2)
				part:SetRoll(math.random(0, 360))
				part:SetRollDelta(0.01)
				part:SetColor(200, 95, 95)
				part:SetLighting(true)
				part:SetVelocity( VectorRand() * math.random(125,260) )
			end
		end
		
		if self.Emitter != nil and IsValid(self) then
			self.Emitter:Finish()
			EMRPR:Stop()
			DangerEMRPR:Stop()
		end
		EMRPR:Stop()
		DangerEMRPR:Stop()
	end
	
	self:StopSound("EMRP")
	return false
end 

local vel, len

local traceData = {}
traceData.mask = bit.bor(CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_DEBRIS, CONTENTS_MONSTER, CONTENTS_HITBOX, CONTENTS_WATER)

function ENT:PhysicsCollide(data, physobj)
timer.Simple( 0, function() 
	
	if IsValid(data.HitEntity) and data.HitEntity:GetClass() == self:GetClass() then 
		return false
	end
	
	if not IsValid(self) or self.FRAGMENTED then
		return false
	end
	
	self.FRAGMENTED = true
	
	local EntityToSlam = data.HitEntity
	local Velocity = self:GetPhysicsObject():GetVelocity()
	local position = self:GetPos()
	
	util.Decal( "FadingScorch", data.HitPos, data.HitPos + data.OurOldVelocity, self )
	
	sound.Play( Sound("central_base_material/cbm_round_deform_close_"..math.random(1,3)..".mp3"), position, 130, math.random(90,110), 1 )
	ParticleEffect( "small_caliber_shrapnel_premature", data.HitPos-data.HitNormal, (Velocity:GetNormalized()-data.HitNormal/math.random(1,6)):Angle() )
	
	if IsValid(EntityToSlam) then
		
		if not self:Special_Ent_Dmg( EntityToSlam ) then
			
			ParticleEffect( "small_caliber_shrapnel", position, (Velocity:GetNormalized()+data.HitNormal/2):Angle() )
			ParticleEffectAttach( "object_vaporize_shrapnel", PATTACH_ABSORIGIN_FOLLOW, EntityToSlam, -1 )
			
		end
		
		EntityToSlam:EmitSound("player/pain.wav", 130, math.random(60,90))
		
		util.ScreenShake(self:GetPos(), 150, 9999, 0.1, 1000) 
		self:SinuousExplosion( 400 )
		
	else
			
		if SERVER then
			util.ScreenShake( position, 9, 600, 0.5, 500 )
		end
		
		if math.random(0,3) == 3 then
			for i = 1, math.Round(math.random(0,300)/100) do
				if SERVER then
					local Bouncer = ents.Create("cw_tiwround_fragment")
					
					local AngleFire = ( (self:GetForward():GetNormalized() - (data.HitNormal/3)) + (VectorRand()/2) ):Angle()
					
					Bouncer:SetPos( position - data.HitNormal * 5 )
					Bouncer:SetAngles( AngleFire )
					Bouncer:SetOwner( self.Owner )
					Bouncer:Spawn()
					
					local BouncerPhys = Bouncer:GetPhysicsObject()
					
					if IsValid(BouncerPhys) then
						BouncerPhys:SetVelocityInstantaneous( AngleFire:Forward()*math.random(500,3500) )
					end
					
				end
			end
		end
		
	end
	
	local Explose_Size = 4 * 52.4934
	for Index, Ent_Found in pairs(ents.FindInSphere(data.HitPos,Explose_Size)) do
		local Dist = Ent_Found:WorldSpaceCenter():Distance(data.HitPos)/Explose_Size
		if Ent_Found:IsValid() then
			
			self:Special_Ent_Dmg( Ent_Found )
			
			local d = DamageInfo()
			d:SetDamage( 3600*Dist )
			d:SetAttacker( self.Owner )
			d:SetInflictor( self )
			d:SetDamageType( DMG_GENERIC )
			Ent_Found:TakeDamageInfo( d )
					
			d:SetDamage( 120*Dist )
			d:SetDamageType( DMG_DISSOLVE )
			Ent_Found:TakeDamageInfo( d )
			
			d:SetDamage( 2310*Dist )
			d:SetDamageType( DMG_RADIATION )
			Ent_Found:TakeDamageInfo( d )
			
			ParticleEffectAttach( "object_vaporize_shrapnel", PATTACH_ABSORIGIN_FOLLOW, Ent_Found, -1 )
			ParticleEffectAttach( "object_vaporize_vapor", PATTACH_ABSORIGIN_FOLLOW, Ent_Found, -1 )
			
			constraint.RemoveAll( Ent_Found )
			
			local PushVelocity = ((Ent_Found:WorldSpaceCenter()-data.HitPos):GetNormalized()*(1-Dist)) * math.random(500,800)
			local Ent_Phys = Ent_Found:GetPhysicsObject()
			if IsValid(Ent_Phys) then Ent_Phys:SetVelocity( Ent_Phys:GetVelocity() + PushVelocity ) else
			Ent_Found:SetVelocity( Ent_Found:GetVelocity() + PushVelocity ) end
			
		end
	end
	
	local d = DamageInfo()
	d:SetDamage( math.random(9.10,11.32) * (Velocity:Length() / 52.4934) )
	d:SetAttacker( self.Owner )
	d:SetInflictor( self )
	d:SetDamageType( DMG_RADIATION )
	util.BlastDamageInfo(d, position, (15 * 52.4934))
	
	self:SinuousExplosion( 400 )
	
	self:Remove()
	SafeRemoveEntityDelayed(self, 10)
		
end)
end
