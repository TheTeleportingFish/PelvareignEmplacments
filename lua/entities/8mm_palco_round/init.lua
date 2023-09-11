AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Density = 32000 --Kg / Meter
ENT.KaplierRating = 925.290 --Joules
ENT.KaplierEnergy = ENT.Density

if SERVER then
	util.AddNetworkString( "Client_Shockwave_Round" )
end

function ENT:Initialize()

	self:SetModel("models/Items/AR2_Grenade.mdl") 
	self:SetModelScale( 0.4, 0 )
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE)
	self:SetMoveCollide( MOVECOLLIDE_DEFAULT )
	
	self.FRAGMENTED = false

	local phys = self:GetPhysicsObject()
	
	if IsValid(self:GetNWEntity( "Targeted" )) then
	self.CurrentDist = phys:GetPos():Distance(self:GetNWEntity( "Targeted" ):WorldSpaceCenter())
	self.Lowest = self.CurrentDist
	end
	
	if phys and phys:IsValid() then
		local MassFromDensity = self.Density * (phys:GetVolume() / 52.4934) --Calculate Mass from Density
		phys:Wake()
		phys:SetMass( MassFromDensity )
		phys:SetDragCoefficient( 1e-1 )
	end
	
	self:GetPhysicsObject():SetBuoyancyRatio(0)
	
	self.Target = self:GetNWEntity( "Targeted" )

	spd = physenv.GetPerformanceSettings()
    spd.MaxVelocity = 1200 * 52.4934
	
    physenv.SetPerformanceSettings(spd)
	local trail = util.SpriteTrail( self, 0, Color( 255, 255, 0 ), true, 4, 0, 0.025, 0.1, "effects/beam_generic01" )
	local trail2 = util.SpriteTrail( self, 0, Color( 255, 255, 255 ), true, 2, 0, 0.1, 0.2, "effects/beam_generic01" )
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
				
			end
		end

end


function ENT:Think()
	
	local owner = self:GetOwner()
	
	if IsValid( self.Target ) then
		local Targeted = self:GetNWEntity( "Targeted" )
		local RoundPhys = self:GetPhysicsObject()
		local Velocity = RoundPhys:GetVelocity()
		
		if self.CurrentDist <= self.Lowest then
			if self:GetPhysicsObject() != nil then
				local SteerForce = 3000
				local AutoDistance = owner:WorldSpaceCenter():Distance(Targeted:WorldSpaceCenter())
				local TriggerDistance = AutoDistance - 100
				local MaxTurnDistance = 200
				local MagnitudeVelocity = Vector( math.abs(Targeted:GetVelocity().x) ^ 0.5 , math.abs(Targeted:GetVelocity().y) ^ 0.5 , math.abs(Targeted:GetVelocity().z) ^ 0.5 )
				local MoveVector = ( RoundPhys:GetPos() - ( Targeted:WorldSpaceCenter() + ( MagnitudeVelocity * Targeted:GetVelocity():GetNormalized() ) )):GetNormalized() * -SteerForce
				local MoveVectorNormalized = MoveVector - (self:GetForward() * SteerForce/1.05)
				local TurnCalc = 1 - math.Clamp( (self.CurrentDist-MaxTurnDistance)/(TriggerDistance) , 0 , 1 )
				if self.CurrentDist < TriggerDistance then
					RoundPhys:AddVelocity( (MoveVectorNormalized * TurnCalc) - (physenv.GetGravity():GetNormalized() * (physenv.GetGravity():Length() ^ 0.5)) )	
				end
				--print(TurnCalc)
			end
			self.Lowest = self.CurrentDist
			self.CurrentDist = RoundPhys:GetPos():Distance(Targeted:WorldSpaceCenter())
		else
		--print("fucked")
		end
		--print(self.Lowest)
		--print(self.CurrentDist)
		
		local ConeData = {}
		ConeData.filter = { self }
		ConeData.start = self:WorldSpaceCenter()
		ConeData.endpos = ConeData.start + ( (Targeted:WorldSpaceCenter()-self:WorldSpaceCenter()):GetNormalized() )
		
		local Conetrace = util.TraceLine(ConeData)
		local Forward = self:GetVelocity():GetNormalized()
		
		local DegreesBetween = math.Round( math.deg(math.acos(Conetrace.Normal:Dot(Forward)) / (Forward:Length() * Conetrace.Normal:Length())) , 3 )
		
		if IsValid(Targeted) and ( self.CurrentDist < (25 * 52.4934) or (DegreesBetween <= 0.5 and self.CurrentDist < (350 * 52.4934)) ) then
			
			local effectdata = EffectData()
			effectdata:SetOrigin( self:WorldSpaceCenter() )
			effectdata:SetAngles( (Forward):Angle() )
			effectdata:SetScale( 20 )
			util.Effect( "MuzzleEffect", effectdata )
			
			self:FireBullets( { 
				Src = self:WorldSpaceCenter() ,
				Dir = Forward,
				Num = math.random( 35 , 60 ),
				Spread = Vector( math.random( 1 , 5 ) , math.random( 1 , 5 ) ),
				Damage = (Velocity:Length() ^ 0.5) / 1000,
				Force = (Velocity:Length() ^ 0.5) / 1000
			})
			
			local SoundDistanceMax = 400 * 52.4934
			for k, v in pairs(ents.FindInSphere(self:WorldSpaceCenter(),SoundDistanceMax)) do
				if IsValid(v) and v:IsPlayer() then
					local Dist = v:WorldSpaceCenter():Distance(self:WorldSpaceCenter())/SoundDistanceMax
					
					local ContinationWave = ((Dist)*SoundDistanceMax)/((343+math.random(80,150)) * 52.4934)
					
					net.Start("Client_Shockwave_PressurizedExplosive")
						net.WriteFloat(ContinationWave)
						net.WriteFloat(Dist)
					net.Send(v)
					
				end
			end
			
			util.BlastDamage(self, self, self:WorldSpaceCenter(), (50 * 52.4934), 5)
			
			local d = DamageInfo()
			d:SetAttacker( owner )
			d:SetInflictor( self )
			
			d:SetDamage( 260 )
			d:SetDamageType( DMG_RADIATION )
			util.BlastDamageInfo(d, self:WorldSpaceCenter(), (3 * 52.4934))
			
			d:SetDamage( 10 )
			d:SetDamageType( DMG_SHOCK )
			util.BlastDamageInfo(d, self:WorldSpaceCenter(), (7 * 52.4934))
			
			d:SetDamage( math.random(0.1,12.991) * (RoundPhys:GetVelocity():Length() / 52.4934) )
			d:SetDamageType( DMG_BLAST )
			
			util.BlastDamageInfo(d, self:WorldSpaceCenter(), (17 * 52.4934))
			
			for i = 1, math.random(1,3) do
				if SERVER then
					Bouncer = ents.Create("cw_tiwround")
					
					local AngleFire = ( self:GetForward() + ( VectorRand()/(self.CurrentDist / 52.4934) ) ):Angle()
					
					Bouncer:SetNWEntity( "Targeted" , self:GetNWEntity( "TargetSelected" ) )
					Bouncer:SetPos( RoundPhys:GetPos() + (VectorRand() * math.random(1,10)) )
					Bouncer:SetAngles( AngleFire )
					Bouncer:SetOwner( owner )
					Bouncer:Spawn()
					
					local BouncerPhys = Bouncer:GetPhysicsObject()
					
					if IsValid(BouncerPhys) then
						BouncerPhys:SetVelocityInstantaneous(AngleFire:Forward()*math.random(6000,8000))
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

local vel, len

local traceData = {}
traceData.mask = bit.bor(CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_DEBRIS, CONTENTS_MONSTER, CONTENTS_HITBOX, CONTENTS_WATER)

function ENT:PhysicsCollide(data, physobj)
	if not IsValid(self) or self.FRAGMENTED then
		return false
	end
	
	self.FRAGMENTED = true
	
	local Velocity = data.OurOldVelocity
	local position = data.HitPos
	local owner = self:GetOwner()
	
	self.KaplierEnergy = self.Density * (self.KaplierRating^2)
	
	local MaxPen = (Velocity:GetNormalized() * Velocity:Length() ^ 0.5 )
	local StartPosition = (position + Velocity:GetNormalized())
	
	local PenTrace = util.TraceLine( {
		start = StartPosition,
		endpos = StartPosition + MaxPen,
		filter = {self},
		ignoreworld = false
	} )
	
	
	
	if ( data.HitEntity:IsNPC() or data.HitEntity:IsPlayer() or string.match(tostring(data.HitEntity),"npc*") or string.match(tostring(data.HitEntity),"phys*") ) and data.HitEntity:IsValid() then
		
		local EntityToSlam = data.HitEntity
		local ExplodeRadius = 20
		local ExplodeDamage = 1000
		
		if string.match(tostring(EntityToSlam),"phys*")  then 
			for k, v in pairs(ents.FindInSphere(data.HitPos,200)) do
				if string.match(tostring(v),"npc*") then
					if v:IsNPC() and v:IsValid() then
						EntityToSlam = v
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
				
				local d = DamageInfo()
				d:SetDamage( (3 * (Velocity:Length()/52.4934) ^ 3 ) )
				d:SetAttacker( owner )
				d:SetInflictor( self )
				d:SetDamageType( DMG_DIRECT )
				EntityToSlam:TakeDamageInfo( d )
				
				for i = 1, 5 do
					ParticleEffect( "Flashed", self:GetPos() , Angle(0,0,0) )
				end
				
				ParticleEffect( "ShockWave", data.HitPos , Angle(0,0,0))
			end
		end
		
		
		if EntityToSlam:GetPos():Distance( owner:GetPos() ) < 300 then
		local d = DamageInfo()
		
		d:SetAttacker( owner )
		d:SetInflictor( self )
		d:SetDamage( 100/((EntityToSlam:GetPos():Distance( owner:GetPos() )+1)/50) )
		d:SetDamageType( DMG_BURN )
			if SERVER then 
				owner:TakeDamageInfo( d )
			end 
		end
		
			sound.Play( Sound("main/roundhit_softmatter_"..math.random(1,9)..".wav"), position, 100, 100,0.8)
			sound.Play( Sound("main/fragexplose"..math.random(1,3)..".wav"), position, 90, 90, 0.3 )
		
		for i=1, 5 do
			util.ScreenShake(position, 50, 5, 0.1, 1000) 
		end
		
		self:SinuousExplosion( 250 )
		
	else
		
		local RandHitPos = position
		local VeloRicochet = math.random(500,15000)
		local RandomNormal = MaxPen + (VectorRand()/3)
		
		sound.Play( Sound("main/small_caliber_weave_flare_"..math.random(1,7)..".mp3"), position, 130, math.random(110,130),0.3)
		
		util.Decal( "FadingScorch", RandHitPos, RandHitPos + MaxPen, self )
		
		local effectdata = EffectData()
		effectdata:SetOrigin( RandHitPos )
		effectdata:SetNormal( RandomNormal )
		effectdata:SetMagnitude( math.random(1,3) / 3 )
		effectdata:SetScale( 1 )
		effectdata:SetRadius( math.random(1,15) )
		util.Effect( "Sparks", effectdata )
		
		effectdata:SetOrigin( RandHitPos )
		effectdata:SetAngles( (RandomNormal):Angle() )
		effectdata:SetScale( math.random(5,10) )
		util.Effect( "MuzzleEffect", effectdata )
		
		if SERVER then
		
		ObjectThicknessDerivative = (PenTrace.FractionLeftSolid) * MaxPen:Length()
		penetrationDerivative = math.Clamp( (self.KaplierEnergy / ((ObjectThicknessDerivative^2) / 0.524934) ) , 0 , 1 )
		-- print("Derivative : " .. penetrationDerivative )
		-- print("Effectiveness : " .. math.Round(ObjectThicknessDerivative / 0.524934, 1) .. " Centimeters" )
		-- print("Yield : " .. math.Round(PenTrace.FractionLeftSolid * 100, 1) .. "%" )
		
		if ( not util.IsInWorld( PenTrace.HitPos ) and (Velocity:Length() > 5) and (penetrationDerivative > 0.01) ) then --Penetrate and Spawn Bullet
			
			self:FireBullets( { 
				Src = RandHitPos,
				Dir = -Velocity:GetNormalized(),
				Num = math.random( 3 , 5 ),
				Spread = Vector( math.random( 0.5 , 2 ) , math.random( 0.5 , 2 ) ),
				Damage = (Velocity:Length() ^ 0.5),
				Force = (Velocity:Length() ^ 0.5)
			})
			
			Original_position = position
			
			local ModelMin, ModelMax = self:GetModelBounds()
			local ModelDistance = (ModelMax+(ModelMin*-1)) * self:GetModelScale()
			position = Original_position + ((ObjectThicknessDerivative + ModelDistance.x * 3) * Velocity:GetNormalized()) 
			
			ParticleEffect( "Flashed", position , Angle(0,0,0))
			
			-- debugoverlay.Sphere( Original_position , 2, 5, Color( 255, 0, 0, 0 ), true )
			-- debugoverlay.Line( Original_position, position, 5,Color( 255, 100, 0, 0 ), true )
			-- debugoverlay.Line( position, PenTrace.HitPos, 5,Color( 255, 255, 255, 0 ), true )
			-- debugoverlay.Sphere( position , 1, 5, Color( 255, 255, 255, 0 ), true )
			
			sound.Play( Sound("main/ground_hit_explosive_"..math.random(1,3)..".wav"), position, 60, math.random(80,160), 1 )
			
			local Round = ents.Create( self:GetClass() )
			if ( not Round:IsValid() ) then return end
			
			Round:SetNWEntity( "Targeted" , self:GetNWEntity( "TargetSelected" ) )
			
			Round:SetPos( position + VectorRand() )
			Round:SetAngles( Velocity:GetNormalized():Angle() )
			Round:SetOwner( owner )
			Round:Spawn()
			
			local RoundPhys = Round:GetPhysicsObject()
			if ( not RoundPhys:IsValid() ) then Round:Remove() return end
			
			RoundPhys:SetVelocityInstantaneous( Velocity * penetrationDerivative )
			
			for i = 1, math.Round( math.random(1,15)/15 ) do
				local Bouncer = ents.Create("cw_tiwround_lowdensityfragment")
				local AngleFire = (MaxPen:GetNormalized() + (VectorRand()/26) ):Angle()
				
				Bouncer:SetPos( position + VectorRand() )
				Bouncer:SetAngles( AngleFire )
				Bouncer:SetOwner( owner )
				Bouncer:Spawn()
				
				local BouncerPhys = Bouncer:GetPhysicsObject()
				
				if IsValid(BouncerPhys) then
					BouncerPhys:SetVelocityInstantaneous( AngleFire:Forward() * VeloRicochet * math.random(10,250) / 50  )
				end
			end
			
		else
			
			for i = 1, math.Round( (math.random(0,200) / 100) ) do
				local Bouncer = ents.Create("cw_tiwround_lowdensityfragment")
				local AngleFire = (self:GetForward():GetNormalized() - (data.HitNormal/2) + (VectorRand()/4) ):Angle()
				
				Bouncer:SetPos( (position + VectorRand()) - data.HitNormal * 5 )
				Bouncer:SetAngles( AngleFire )
				Bouncer:SetOwner( owner )
				Bouncer:Spawn()
				
				local BouncerPhys = Bouncer:GetPhysicsObject()
				
				if IsValid(BouncerPhys) then
					BouncerPhys:SetVelocityInstantaneous( AngleFire:Forward() * VeloRicochet )
				end
			end
		
		end
		end
		
		local RandHitPos = position + (VectorRand() * math.random(1,5))
		
		if VeloRicochet < 6000 then
			sound.Play( Sound("main/small_caliber_weave_jack.mp3"), position, 120, math.random(100,140),0.8)
		else
			sound.Play( Sound("main/small_caliber_weave_flare_"..math.random(1,7)..".mp3"), position, 140, math.random(110,130),1)
		end
		
		util.Decal( "ExplosiveGunshot", RandHitPos, RandHitPos - MaxPen, self )
		
		local effectdata = EffectData()
		effectdata:SetOrigin( RandHitPos - MaxPen )
		effectdata:SetNormal( RandomNormal )
		effectdata:SetMagnitude( 2 )
		effectdata:SetScale( 1 )
		effectdata:SetRadius( math.random(1,10) / 10 )
		util.Effect( "Sparks", effectdata )
		
		effectdata:SetOrigin( RandHitPos - MaxPen )
		effectdata:SetAngles( (-MaxPen):Angle() )
		effectdata:SetScale( math.random(3,5) )
		util.Effect( "MuzzleEffect", effectdata )
		
		if SERVER then
			util.ScreenShake( position, 9, 0.01, 0.3, 400 )
		end
		
		self:SinuousExplosion( 100 )
		
	end
	
	self:Remove()
	SafeRemoveEntityDelayed(self, 10)
	
end
