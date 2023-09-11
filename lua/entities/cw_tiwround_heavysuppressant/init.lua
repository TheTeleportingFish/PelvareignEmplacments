AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.BlastDamage = 30
ENT.BlastRadius = 590.55*2
ENT.BlastDamage2 = 15000
ENT.BlastRadius2 = (590.55/2)
ENT.Mass = 120

if SERVER then
	util.AddNetworkString( "Client_Shockwave_Round" )
	util.AddNetworkString( "Client_Shockwave_PressurizedExplosive" )
end

function ENT:Initialize()

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
				
				local isplayer = ent:IsPlayer()
				local isnpc = ent:IsNPC()
				local equal = ent == v
				
				local SpatialWaveFormat = 343 + math.random(-10,150)
				
				if not equal then 
					SpatialWaveFormat = SpatialWaveFormat / ( math.random( 110 , 150 ) / 100 )
					Dist = (Dist ^ math.random( 0.45 , 0.75 ) )
				end
				
				local ContinationWave = ( Dist * SoundDistanceMax ) / ( SpatialWaveFormat * 52.4934 )
				
				net.Start("Client_Shockwave_Round")
					net.WriteFloat(ContinationWave)
					net.WriteFloat(Dist)
				net.Send(v)
				
				timer.Simple( ContinationWave , function() 
					Dist = 1 - Dist
					v:SetViewPunchAngles(Angle((math.random(-100,100)/10)*((Dist)^50), (math.random(-100,100)/10)*((Dist)^50), (math.random(-100,100)/10)*((Dist)^50)))
				end)
			end
		end

end

function ENT:Think()
	local RoundPhys = self:GetPhysicsObject()
	local Targeted = self:GetNWEntity( "Targeted" )
	--print(Targeted)
	if IsValid(Targeted) then
		if self.CurrentDist <= self.Lowest then
			if self:GetPhysicsObject() != nil then
				local SteerForce = 3850 + math.random(-135,125)
				local AutoDistance = self.Owner:WorldSpaceCenter():Distance(self:GetNWEntity( "Targeted" ):WorldSpaceCenter())
				local TriggerDistance = AutoDistance - 100
				local MaxTurnDistance = 150 + math.random(-135,135)
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
		PenData.ignoreworld = true
		
		local Pentrace = util.TraceLine(PenData)
		
		local ConeData = {}
		ConeData.filter = { self }
		ConeData.start = self:WorldSpaceCenter()
		ConeData.endpos = ConeData.start + ( (Targeted:WorldSpaceCenter()-self:WorldSpaceCenter()):GetNormalized() * (500 * 52.4934) )
		
		local Conetrace = util.TraceLine(ConeData)
		
		local DegreesBetween = math.Round(math.deg(math.acos(Conetrace.Normal:Dot(Pentrace.Normal)) / (Pentrace.Normal:Length() * Conetrace.Normal:Length())),2)
		
		if IsValid(Targeted) and (self.CurrentDist < (15 * 52.4934) or (DegreesBetween <= 1 and self.CurrentDist < (150 * 52.4934))) then
			
			for i = 1, 5 do
				ParticleEffect( "Flashed", self:GetPos() + (VectorRand() * math.random(1,150)) , Angle(0,0,0) )
			end
			
			local SoundDistanceMax = 1200 * 52.4934
			for k, v in pairs(ents.FindInSphere(self:WorldSpaceCenter(),SoundDistanceMax)) do
				if IsValid(v) and v:IsPlayer() then
					local Dist = v:WorldSpaceCenter():Distance(self:WorldSpaceCenter())/SoundDistanceMax
					
					local ContinationWave = ((Dist)*SoundDistanceMax)/((343+math.random(80,150)) * 52.4934)
					
					net.Start("Client_Shockwave_PressurizedExplosive")
						net.WriteFloat(ContinationWave)
						net.WriteFloat(Dist)
					net.Send(v)
					
					timer.Simple( ContinationWave , function() 
						Dist = 1 - Dist
						v:SetViewPunchAngles(Angle((math.random(-100,100)/350)*((Dist)^8), (math.random(-100,100)/350)*((Dist)^8), (math.random(-100,100)/350)*((Dist)^8)))
					end)
				end
			end
			
			ParticleEffect( "DirtExplodeHit", self:GetPos() , Angle(0,0,0))
			util.BlastDamage(self, self, self:GetPos(), 100, 100)
			
			local d = DamageInfo()
			d:SetDamage( 2 )
			d:SetAttacker( self )
			d:SetInflictor( self.Owner )
			d:SetDamageType( DMG_DISSOLVE )
			Targeted:TakeDamageInfo( d )
			
			d:SetDamage( 16 )
			d:SetAttacker( self )
			d:SetInflictor( self.Owner )
			d:SetDamageType( DMG_RADIATION )
			Targeted:TakeDamageInfo( d )
			
			d:SetDamage( 5 )
			d:SetAttacker( self )
			d:SetInflictor( self.Owner )
			d:SetDamageType( DMG_SHOCK )
			Targeted:TakeDamageInfo( d )
			
			d:SetDamage( math.random(0.3,0.82) * (RoundPhys:GetVelocity():Length() / 52.4934) )
			d:SetAttacker( self )
			d:SetInflictor( self.Owner )
			d:SetDamageType( DMG_RADIATION )
			
			util.BlastDamageInfo(d, Targeted:GetPos(), (10 * 52.4934))
			
			for i = 1, math.random(1,3) do
				if SERVER then
					Bouncer = ents.Create("cw_tiwround_lowdensityfragment")
					
					local AngleFire = (self:GetForward() + (VectorRand() * math.random(1,10)/125)):Angle() 
					
					Bouncer:SetPos( RoundPhys:GetPos() + (VectorRand() * math.random(1,10)) )
					Bouncer:SetAngles( AngleFire )
					Bouncer:SetOwner( self.Owner )
					Bouncer:Spawn()
					
					local BouncerPhys = Bouncer:GetPhysicsObject()
					
					if IsValid(BouncerPhys) then
						BouncerPhys:SetVelocityInstantaneous(AngleFire:Forward()*math.random(7600,8900))
					end
					
				end
			end
			
			self:Remove()
			
		end
	end
	
	self:NextThink( CurTime() + 0.05 )
	return true
end 


function ENT:PhysicsUpdate(phys)

	local angles = phys:GetAngles()
	local velocity = phys:GetVelocity()

	--print(angles, angles:Forward() , velocity , velocity:Angle() ) 

	phys:SetAngles( velocity:Angle() )
	phys:SetVelocity(velocity)
	
end



function ENT:Use(activator, caller)
	return false
end

function ENT:OnRemove()
	self:StopSound("EMRP")
	return false
end 

local vel, len

local traceData = {}
traceData.mask = bit.bor(CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_DEBRIS, CONTENTS_MONSTER, CONTENTS_HITBOX, CONTENTS_WATER)

function ENT:PhysicsCollide(data, physobj)
timer.Simple( 0, function() 
	if not IsValid(self) and data.HitEntity:GetClass() ~= self:GetClass() then return end
	local Velocity = self:GetPhysicsObject():GetVelocity()
	local position = self:GetPos()
	
	ParticleEffect( "GroundCloudLarge", position , data.HitNormal:Angle():Up():Angle() )
	ParticleEffect( "GroundCloud", position , data.HitNormal:Angle():Up():Angle() )
	sound.Play( Sound("CW_HEI_Explose"), position )
	
	if data.HitEntity == self.Owner then
		return false
	end
	

	local d = DamageInfo()
	d:SetDamage( math.random(0.63,0.85) * (Velocity:Length() / 52.4934) )
	d:SetAttacker( self )
	d:SetInflictor( self.Owner )
	d:SetDamageType( DMG_RADIATION )
		
	util.BlastDamageInfo(d, position, (8 * 52.4934))
	
	local poititi = self:GetPos()
		sound.Play( Sound("main/bouncehit.wav"), poititi, 130, math.random(150,180), 1 )
	
	if data.HitEntity:IsValid() then

	local EntityToSlam = data.HitEntity
	
	if string.match(tostring(EntityToSlam),"phys*")  then 
		for k, v in pairs(ents.FindInSphere(data.HitPos,(3 * 52.4934))) do
			if string.match(tostring(v),"npc*") then
				if v:IsNPC() and v:IsValid() then
					EntityToSlam = v
					
					local d = DamageInfo()
					d:SetDamage( 125 )
					d:SetAttacker( self )
					d:SetInflictor( self.Owner )
					d:SetDamageType( DMG_BLAST )
					EntityToSlam:TakeDamageInfo( d )
							
					d:SetDamage( 20 )
					d:SetAttacker( self )
					d:SetInflictor( self.Owner )
					d:SetDamageType( DMG_DISSOLVE )
					EntityToSlam:TakeDamageInfo( d )
					
					d:SetDamage( 75 )
					d:SetAttacker( self )
					d:SetInflictor( self.Owner )
					d:SetDamageType( DMG_RADIATION )
					EntityToSlam:TakeDamageInfo( d )
					
					--print(EntityToSlam)
				end
			end
		end
	end
	
	if SERVER then
		if EntityToSlam:IsValid() then
		
			if string.match(tostring(EntityToSlam),"npc_turret_floor") and EntityToSlam:IsNPC() then
				EntityToSlam:Fire("SelfDestruct")
			elseif string.match(tostring(EntityToSlam),"npc_helicopter") and EntityToSlam:IsNPC() then
				EntityToSlam:Fire("Break")
			end
			
			for i = 1, 5 do
				ParticleEffect( "Flashed", self:GetPos() + (VectorRand() * math.random(1,150)) , Angle(0,0,0) )
			end
			
			ParticleEffect( "DirtExplodeHit", data.HitPos , data.HitNormal:Angle())
		end
	end
	
		EntityToSlam:EmitSound("player/pain.wav", 130, math.random(60,90))
		if EntityToSlam:GetPos():Distance( self.Owner:GetPos() ) < 300 then	
			local d = DamageInfo()
			d:SetDamage( 100/((EntityToSlam:GetPos():Distance( self.Owner:GetPos() )+1)/50) )
			d:SetAttacker( game.GetWorld() )
			d:SetDamageType( DMG_BURN )
			if SERVER then 
				self.Owner:TakeDamageInfo( d )
			end 
		end
		
		util.ScreenShake(self:GetPos(), 150, 9999, 0.1, (5 * 52.4934)) 
		
		self:SinuousExplosion( 400 )
		
	else
			
		if SERVER then
			util.ScreenShake( position, 999, 600, 0.5, (10 * 52.4934) )
		end
			
		for i = 1, 5 do
			ParticleEffect( "Flashed", self:GetPos() + (VectorRand() * math.random(1,150)) , Angle(0,0,0) )
		end
		
	end
	
	self:SinuousExplosion( 400 )
	
	self:Remove()
	SafeRemoveEntityDelayed(self, 10)
		
end)

end
