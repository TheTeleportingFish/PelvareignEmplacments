AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.PrintName = "TIWRigidRound"
ENT.Author = ""
ENT.Information = "A TIW Rigid Round"
ENT.Spawnable = false
ENT.AdminSpawnable = false 

ENT.BlastDamage = 30
ENT.BlastRadius = 590.55*2
ENT.BlastDamage2 = 15000
ENT.BlastRadius2 = (590.55/2)

ENT.Density = 25000 --Kg / Meter
ENT.KaplierRating = 991330.3 --Joules
ENT.KaplierEnergy = ENT.Density * (ENT.KaplierRating^2)
ENT.Mass = 220

function ENT:SetupDataTables()
	self:SetNWEntity( "Targeted", nil )
	
end

if SERVER then
	util.AddNetworkString( "Client_Shockwave_Round_Rigid" )
	util.AddNetworkString( "Client_Velocity_Prediction_Fix" )
elseif CLIENT then
	language.Add("cw_tiwrigidround", "Rigid Round")
end

net.Receive( "Client_Velocity_Prediction_Fix", function( len, ply ) --Client Prediction Stupidity
	local Float = net.ReadFloat()
	local Normal = net.ReadNormal()
	local Entity = net.ReadEntity()
	Entity.Client_Velocity = (Float * Normal)
end )

net.Receive( "Client_Shockwave_Round_Rigid", function( len )
	local Ply = LocalPlayer()
	local ContinationWave = net.ReadFloat()
	local Dist = ( 1 - net.ReadFloat() ) or 0
	local Visible = net.ReadBool() or false
	if ContinationWave == nil then return end
	
	timer.Simple( ContinationWave , function() 
		if Dist < 0.50 or not Visible then
			EmitSound( "high_energy_systems/tacklecatics_endshock.mp3", Vector() , -1 , CHAN_AUTO , math.Clamp(Dist^2,0,1) , 75 , 0 , math.random(190,195) )
			EmitSound( "main/airshockwave.wav", Vector() , -1 , CHAN_AUTO , math.Clamp(Dist,0,1) , 90 , 0 , math.random(20,30) )
			EmitSound( "high_caliber_cbm_weaponry/83mm_sebboul_distant_"..math.random(1,3)..".mp3", Vector() , -1 , CHAN_AUTO , math.Clamp(Dist,0,1) , 90 , 0 , math.random(45,55) )
			
		else
			EmitSound( "high_energy_systems/tacklecatics_beginshock.mp3", Vector() , -1 , CHAN_AUTO , math.Clamp(Dist^2,0,1) , 90 , 0 , math.random(190,200) )
			EmitSound( "high_energy_systems/plasma_anticharge_coniccrossover_"..math.random(1,8)..".mp3", Vector() , -1 , CHAN_AUTO , math.Clamp(Dist^2,0,1) , 90 , 0 , math.random(90,120) )
			EmitSound( "ahee_suit/fraise/fraiseformationshield_failure_"..math.random(1,3)..".mp3", Vector() , -1 , CHAN_AUTO , math.Clamp(Dist^2,0,1) , 90 , 0 , math.random(140,180) )
			
		end
	end)
end)

function ENT:SinuousExplosion( Original_Pos , Meters )
	local traceData = {}
	traceData.mask = bit.bor(CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_DEBRIS, CONTENTS_MONSTER, CONTENTS_HITBOX, CONTENTS_WATER)
	
	local SoundDistanceMax = Meters * 52.4934
		for k, v in pairs(ents.FindInSphere(Original_Pos,SoundDistanceMax)) do
			if IsValid(v) and v:IsPlayer() then
				local Dist = v:WorldSpaceCenter():Distance(Original_Pos)/SoundDistanceMax
				
				obj = v
				
				local positedplayer = v:WorldSpaceCenter()
				
				direction = ( positedplayer - Original_Pos )
				
				traceData.filter = {Bouncer,self}
				traceData.start = Original_Pos 
				traceData.endpos = traceData.start + direction * SoundDistanceMax
				
				local trace = util.TraceLine(traceData)
				
				local ent = trace.Entity
				local fract = trace.Fraction
				
				local isplayer = ent:IsPlayer()
				local isnpc = ent:IsNPC()
				local equal = ent == v
				
				local SpatialWaveFormat = 343 + math.random(-10,150)
				
				if not equal then 
					SpatialWaveFormat = SpatialWaveFormat / ( math.Rand( 1.10 , 1.50 ) )
					Dist = (Dist ^ math.random( 0.75 , 0.9 ) )
				end
				
				local ContinationWave = ( Dist * Meters ) / ( SpatialWaveFormat )
				
				net.Start("Client_Shockwave_Round_Rigid")
					net.WriteFloat(ContinationWave)
					net.WriteFloat(Dist)
					net.WriteBool(equal)
				net.Send(v)
				
			end
		end
end

function ENT:Initialize()
	
	self.PIERCING_OBJECT = false
	
	if SERVER then
		
		self:SetModel("models/Items/AR2_Grenade.mdl") 
		self:SetModelScale( 0.325, 0 )
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_NONE)
		self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE)
		self:SetMoveCollide( MOVECOLLIDE_DEFAULT )
		
		local phys = self:GetPhysicsObject()
		if phys and phys:IsValid() then
			phys:Wake()
			phys:SetMass( self.Mass )
			phys:SetDragCoefficient( 1e-12 )
		end
		
		if IsValid(self:GetNWEntity( "Targeted" )) then
			self.CurrentDist = phys:GetPos():Distance(self:GetNWEntity( "Targeted" ):WorldSpaceCenter())
			self.Lowest = self.CurrentDist
		end
		
		self.Target = self:GetNWEntity( "Targeted" )
		self:GetPhysicsObject():SetBuoyancyRatio(0)
		
		spd = physenv.GetPerformanceSettings()
		spd.MaxVelocity = 120000
		
		physenv.SetPerformanceSettings(spd)
		
		trail = util.SpriteTrail( self, 0, Color( 120, 120, 255, 200 ), true, 3, 35, 0.1, 0.8, "effects/beam_generic01" )
		trail2 = util.SpriteTrail( self, 0, Color( 255, 255, 255, 230 ), true, 2, 25, 0.05, 0.8, "effects/beam_generic01" )
		
	elseif CLIENT then
		if IsValid(self) then
			self.Emitter = ParticleEmitter(self:GetPos())
			self.ParticleDelay = 0
		end
		
		self.EMRPR = CreateSound( self, "main/t_b_r.wav" )
		self.EMRPR:SetSoundLevel( 140 )
		self.EMRPR:Play()
		self.DangerEMRPR = CreateSound( self, "main/close_emrpr_loop.mp3" )
		self.DangerEMRPR:SetSoundLevel( 100 )
		self.DangerEMRPR:Play()
		
		self.Client_Velocity = Vector() --Client Prediction Stupidity
		
	end
	
	
end

local traceData = {}
traceData.mask = bit.bor(CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_DEBRIS, CONTENTS_MONSTER, CONTENTS_HITBOX, CONTENTS_WATER)

function ENT:Think()
	local RoundPhys = self:GetPhysicsObject()
	local Targeted = self:GetNWEntity( "Targeted" )
	
	if SERVER then
		if IsValid(Targeted) then
			if self.CurrentDist <= self.Lowest then
				if self:GetPhysicsObject() != nil then
					local SteerForce = 5500
					local AutoDistance = self.Owner:WorldSpaceCenter():Distance(self:GetNWEntity( "Targeted" ):WorldSpaceCenter())
					local TriggerDistance = AutoDistance - 1000
					local MaxTurnDistance = 10000
					local MagnitudeVelocity = Vector( math.abs(self:GetNWEntity( "Targeted" ):GetVelocity().x) ^ 0.5 , math.abs(self:GetNWEntity( "Targeted" ):GetVelocity().y) ^ 0.5 , math.abs(self:GetNWEntity( "Targeted" ):GetVelocity().z) ^ 0.5 )
					local MoveVector = ( RoundPhys:GetPos() - ( self:GetNWEntity( "Targeted" ):WorldSpaceCenter() + ( MagnitudeVelocity * self:GetNWEntity( "Targeted" ):GetVelocity():GetNormalized() ) )):GetNormalized() * -SteerForce
					local MoveVectorNormalized = MoveVector - (self:GetForward() * SteerForce/1.05)
					local TurnCalc = 1 - math.Clamp( (self.CurrentDist-MaxTurnDistance)/(TriggerDistance) , 0 , 1 )
					if self.CurrentDist < TriggerDistance then
						RoundPhys:AddVelocity( (MoveVectorNormalized * TurnCalc) - (physenv.GetGravity():GetNormalized() * (physenv.GetGravity():Length() ^ 0.5)) )	
					end
					--print(TurnCalc)
				end
				self.Lowest = self.CurrentDist
				self.CurrentDist = RoundPhys:GetPos():Distance(self:GetNWEntity( "Targeted" ):WorldSpaceCenter())
			else
			
			end
			
			local LocalDist = Targeted:WorldSpaceCenter():Distance(self:WorldSpaceCenter()) / 52.493
			local Track = DamageInfo()
			Track:SetDamage( (LocalDist) )
			Track:SetAttacker( self )
			Track:SetInflictor( self )
			Track:SetDamageType( DMG_RADIATION )
			Targeted:TakeDamageInfo( Track )
		end
		
		net.Start( "Client_Velocity_Prediction_Fix" , true ) --Client Prediction Stupidity
			net.WriteFloat( self:GetVelocity():Length() )
			net.WriteNormal( self:GetVelocity():GetNormalized() )
			net.WriteEntity( self )
		net.Broadcast()
		
	elseif CLIENT then
		local Root_Velocity = ( self.Client_Velocity:GetNormalized() * (self.Client_Velocity:Length()^0.5) )
		
		if IsValid(self) then
			local Pitch = (math.Round(100 / (self:GetPos():Distance(LocalPlayer():GetPos()) / 52.4934))*50) + 20
			self.EMRPR:ChangePitch( Pitch )
			self.EMRPR:ChangeVolume( (150 / (self:GetPos():Distance(LocalPlayer():GetPos()) / 52.4934)) )
			self.DangerEMRPR:ChangePitch( Pitch * 2 )
			self.DangerEMRPR:ChangeVolume( 1 )
		else
			self.EMRPR:Stop()
			self.DangerEMRPR:Stop()
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
			local localized_size = math.random(6,10)
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

function ENT:ShrapnelEffect(entity,pos,direction)
	local Bellit={
		Attacker=entity,
		Damage=1500,
		Force=200,
		Num=1,
		Tracer=1,
		Dir=direction,
		Spread=Vector(0,0,0),
		Src=pos
	}
	entity:FireBullets(Bellit)
end

function ENT:PhysicsUpdate(phys)

	local angles = phys:GetAngles()
	local velocity = phys:GetVelocity()
	
	local Velocity = phys:GetVelocity()
	local position = self:GetPos()
	
	self.KaplierEnergy = self.Density * (self.KaplierRating^2)
	
	local MatterCoefficient = ((velocity:Length() / 52.4934) ^ 2.5 ) * ( 5520 / self.KaplierRating^2 )
	
	local mins = self:OBBMins()*10
	local maxs = self:OBBMaxs()*10
	local startpos = position
	local dired = self:GetForward()
	local lenned = 1000
	local endpos_dist = dired * lenned

	local Pentrace = util.TraceHull( {
		start = startpos,
		endpos = startpos + endpos_dist,
		maxs = maxs,
		mins = mins,
		filter = self,
		ignoreworld = false
	} )
	
	--debugoverlay.Line( Pentrace.StartPos, Pentrace.HitPos, 0.1, Color( 255, 0, 0 ) )
	--print((Velocity:Length() / 52.493),Pentrace.Entity,Pentrace.StartSolid)
	
	local d = DamageInfo()
	d:SetDamage( 25 )
	d:SetAttacker( self )
	d:SetInflictor( self )
	d:SetDamageType( DMG_RADIATION )
	util.BlastDamageInfo(d, self:WorldSpaceCenter(), 350)
	
	if IsValid(Pentrace.Entity) and not ((Pentrace.HitWorld or Pentrace.StartSolid) and (Velocity:Length() / 52.493) < 100) then
		
		local EntityToSlam = Pentrace.Entity
		local TarPos = EntityToSlam:WorldSpaceCenter()
		
		if string.match(tostring(EntityToSlam),"phys*")  then 
			for k, v in pairs(ents.FindInSphere(Pentrace.HitPos,200)) do
				if string.match(tostring(v),"npc*") then
					if v:IsNPC() and v:IsValid() then
						EntityToSlam = v
						--print(EntityToSlam)
					end
				end
			end
		end
		
		if SERVER then
			if EntityToSlam:IsValid() then
				
				if not EntityToSlam:GetNWBool("AHEE_EQUIPED") then
					local EMBERDIR = velocity:GetNormalized()
					
					if string.match(tostring(EntityToSlam),"npc_turret_floor") and EntityToSlam:IsNPC() then
						EntityToSlam:Fire("SelfDestruct")
					elseif string.match(tostring(EntityToSlam),"npc_helicopter") and EntityToSlam:IsNPC() then
						EntityToSlam:Fire("Break")
					end
					
					EntityToSlam:Remove()
					
					ParticleEffect( "ShockWave", TarPos , Angle(0,0,0))
					ParticleEffect( "small_caliber_nuclear_fragmentation", TarPos , EMBERDIR:Angle() )
					ParticleEffect( "fraise_explosion", self:GetPos(), Angle() )
					
					for v = 1, 10 do
						util.ScreenShake(EntityToSlam:GetPos(), 999, 9999, 1.3, 7000) 
					end
					
					local d = DamageInfo()
					
					for k, v in pairs(ents.FindInSphere(EntityToSlam:WorldSpaceCenter(),5*52.4934)) do
						if IsValid(v) then
							local EMBERDIR = ((EntityToSlam:WorldSpaceCenter()-v:WorldSpaceCenter()):GetNormalized())
							ParticleEffect( "fraise_explosion_heat", v:WorldSpaceCenter() , EMBERDIR:Angle() )
							
							local Dist = EntityToSlam:WorldSpaceCenter():Distance(v:WorldSpaceCenter())
							
							d:SetDamage( 8.01 * (Dist ^ 3) )
							d:SetAttacker( self )
							d:SetInflictor( self )
							d:SetDamageType( DMG_BLAST )
							EntityToSlam:TakeDamageInfo( d )
							
							d:SetDamage( 23 * (Dist ^ 2) )
							d:SetAttacker( self )
							d:SetInflictor( self )
							d:SetDamageType( DMG_SHOCK )
							EntityToSlam:TakeDamageInfo( d )
							
							d:SetDamage( 398.12 * (Dist ^ 2) )
							d:SetAttacker( self )
							d:SetInflictor( self )
							d:SetDamageType( DMG_RADIATION )
							util.BlastDamageInfo(d, EntityToSlam:WorldSpaceCenter(), 6100)
						end
					end
					
				end
				
				local d = DamageInfo()
				d:SetDamage( 32000 )
				d:SetAttacker( self )
				d:SetInflictor( self )
				d:SetDamageType( DMG_DISSOLVE )
				EntityToSlam:TakeDamageInfo( d )
				
				d:SetDamage( (2.01 * (Velocity:Length()/52.4934) ^ 3 ) ) 
				d:SetAttacker( self )
				d:SetInflictor( self )
				d:SetDamageType( DMG_BLAST )
				EntityToSlam:TakeDamageInfo( d )
				
				d:SetDamage( 1000 )
				d:SetAttacker( self )
				d:SetInflictor( self )
				d:SetDamageType( DMG_SHOCK )
				EntityToSlam:TakeDamageInfo( d )
				
				d:SetDamage( ( 98.12 * (Velocity:Length()/52.4934) ^ 2 ) )
				d:SetAttacker( self )
				d:SetInflictor( self )
				d:SetDamageType( DMG_RADIATION )
				util.BlastDamageInfo(d, self:GetPos(), 6100)
				
				for i=1, math.random(50,60) do
					self:ShrapnelEffect(self ,self:WorldSpaceCenter() ,(self:WorldSpaceCenter() - EntityToSlam:WorldSpaceCenter()):Angle()+(AngleRand()*0.15))
				end
				
				util.BlastDamage(self, self, EntityToSlam:GetPos(), 1100, 80000)
				
				ParticleEffect( "Flashed", self:GetPos() + (VectorRand() * math.random(1,150)) , Angle(0,0,0) )
				
				ParticleEffect( "small_caliber_nuclear_fragmentation", Pentrace.HitPos , Pentrace.HitNormal:Angle() )
				ParticleEffect( "ShockWave", Pentrace.HitPos , Angle(0,0,0))
				if math.random(1,10) == 10 then
					EntityToSlam:Ignite(20)
					EntityToSlam:TakeDamage( 2000, self, self )
				end
			end
		end
		
		EntityToSlam:EmitSound("player/pain.wav", 130, math.random(60,90))
		sound.Play( Sound("main/explodeair0_4.wav"), position, 100, 90, 0.9 )
		
		self:SinuousExplosion( position , 400 )
		util.ScreenShake(self:GetPos(), 999, 0.1, 0.7, 2000)
		
		timer.Simple( 0.1, function()
			local EMBERDIR = velocity:GetNormalized()
			ParticleEffect( "ShockWave", TarPos , Angle(0,0,0))
			sound.Play( Sound("central_base_material/cbmbounce1.mp3"), position, 110, math.random(80,110),0.6)
		end)
		
		if not self.PIERCING_OBJECT then
			
			local effectdata = EffectData() --Front Hit
			effectdata:SetOrigin( Pentrace.HitPos )
			effectdata:SetNormal( -(phys:GetVelocity()):GetNormalized() )
			effectdata:SetMagnitude( (phys:GetVelocity():Length())^0.5 )
			effectdata:SetRadius( (phys:GetVelocity():Length() / 52.4934)^0.1 )
			util.Effect( "regular_material_spark", effectdata, true, true)
			
			sound.Play( Sound("high_energy_systems/cateroushickleshrapnelpenetration_"..math.random(1,9)..".mp3"), Pentrace.HitPos, 90, math.random(150,190), 0.9 )
		end
		
		self.PIERCING_OBJECT = true
		
		self:Remove()
		SafeRemoveEntityDelayed(self, 10)
		
	elseif ((Pentrace.HitWorld or Pentrace.StartSolid) and (Velocity:Length() / 52.493) > 100) then
		
		if not self.PIERCING_OBJECT then
			local effectdata = EffectData() --Front Hit
			effectdata:SetOrigin( Pentrace.HitPos )
			effectdata:SetNormal( (phys:GetVelocity()):GetNormalized() )
			effectdata:SetMagnitude( (phys:GetVelocity():Length())^0.5 )
			effectdata:SetRadius( (phys:GetVelocity():Length() / 52.4934)^0.1 )
			util.Effect( "regular_material_spark", effectdata, true, true)
			
			sound.Play( Sound("high_energy_systems/cateroushickleshrapnelpenetration_"..math.random(1,9)..".mp3"), Pentrace.HitPos, 90, math.random(150,190), 0.9 )
			
			util.Decal( "FadingScorch", Pentrace.StartPos, Pentrace.StartPos + (phys:GetVelocity()) )
			util.Decal( "RedGlowFade", Pentrace.StartPos, Pentrace.StartPos + (phys:GetVelocity()) )
			
			self.PIERCING_OBJECT = true
		end
		
	elseif ((Pentrace.HitWorld or Pentrace.StartSolid) and (Velocity:Length() / 52.493) < 100) then
		
		ParticleEffect( "high_heat_burn_point", self:GetPos() , Angle() )
		self:Remove()
		SafeRemoveEntityDelayed(self, 10)
		
	elseif not (Pentrace.HitWorld or Pentrace.StartSolid) then
		
		if self.PIERCING_OBJECT then
			
			local effectdata = EffectData() --Front Hit
			effectdata:SetOrigin( Pentrace.StartPos )
			effectdata:SetNormal( (phys:GetVelocity()):GetNormalized() )
			effectdata:SetMagnitude( (phys:GetVelocity():Length())^0.5 )
			effectdata:SetRadius( (phys:GetVelocity():Length() / 52.4934)^0.1 )
			util.Effect( "regular_material_spark", effectdata, true, true)
			
			sound.Play( Sound("high_energy_systems/cateroushickleshrapnelpenetration_"..math.random(1,9)..".mp3"), Pentrace.StartPos, 90, math.random(150,190), 0.9 )
			
			self.PIERCING_OBJECT = false
		end
		
	end
	
	if SERVER then
		if self.PIERCING_OBJECT then
			local AngleFire = ( self:GetForward():GetNormalized() + (VectorRand()/2) ):Angle()
			local MatterVelocity = (AngleFire:Forward() * MatterCoefficient) + velocity
			local ResistanceVelocity = ( velocity * MatterCoefficient )
			local Change_Velo = (MatterVelocity:GetNormalized() * math.Clamp( (MatterVelocity-ResistanceVelocity):Length() , 0 , velocity:Length() ))
			velocity = Change_Velo
			
		end
	end
	
	phys:SetAngles( velocity:Angle() )
	phys:SetVelocity( velocity )
	
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:OnRemove()
	
	if SERVER then
		
	elseif CLIENT then
		if self.Emitter != nil and IsValid(self) then
			self.Emitter:Finish()
			self.EMRPR:Stop()
			self.DangerEMRPR:Stop()
		end
		self.EMRPR:Stop()
		self.DangerEMRPR:Stop()
		
	end
	
	
end

function ENT:Use(activator, caller)
	return false
end

