AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.PrintName = "TIWRound"
ENT.Author = "The Order"
ENT.Information = "An Average TIW Round"
ENT.Spawnable = false
ENT.AdminSpawnable = false 

ENT.Density = 10000 --Kg / Meter
ENT.KaplierRating = 6000.9991 --Joules
ENT.KaplierEnergy = ENT.Density

if SERVER then
	util.AddNetworkString( "Client_Shockwave_Round" )
elseif CLIENT then
	language.Add("cw_tiwround", "TIW Round")
end

function ENT:SetupDataTables()
	self:SetNWEntity( "Targeted", nil )
	
	self:NetworkVar( "Float", 0, "Charge" )
	self:NetworkVar( "Float", 1, "Radiation" )
	self:NetworkVar( "Float", 2, "Frequency" )
	self:NetworkVar( "Float", 3, "Pressure" )
	self:NetworkVar( "Float", 4, "Temperature" )
	
	self:NetworkVar( "Float", 5, "MaxMaterialVolume" )
	
	self:NetworkVar( "String", 0, "Type" )
	
	self:NetworkVar( "Int", 0, "Particles" )
	self:NetworkVar( "Int", 1, "Formation" )
	
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

function ENT:Initialize()
	
	self.Radeonic = self
	
	self:SetFrequency( 1e+12 )
	self:SetPressure( 6 )
	
	if SERVER then
		
		self:SetModel("models/Items/AR2_Grenade.mdl") 
		self:SetModelScale( 0.325, 0 )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetCollisionGroup( COLLISION_GROUP_INTERACTIVE )
		self:SetMoveCollide( MOVECOLLIDE_DEFAULT )
		
		self.FRAGMENTED = false

		local phys = self:GetPhysicsObject()
		local MassFromDensity = self.Density * (phys:GetVolume() / 52.4934) --Calculate Mass from Density
		
		if IsValid(self:GetNWEntity( "Targeted" )) then
		self.CurrentDist = phys:GetPos():Distance(self:GetNWEntity( "Targeted" ):WorldSpaceCenter())
		self.Lowest = self.CurrentDist
		end
		
		if phys and phys:IsValid() then
			phys:Wake()
			phys:SetMass( MassFromDensity )
			phys:SetDragCoefficient( 0 )
		end
		
		self:SetMaxMaterialVolume( MassFromDensity )
		self.MaterialVolume = MassFromDensity
		
		self:GetPhysicsObject():SetBuoyancyRatio(0)
		self.Target = self:GetNWEntity( "Targeted" )
		
		spd = physenv.GetPerformanceSettings()
		spd.MaxVelocity = 1800 * 52.4934
		physenv.SetPerformanceSettings(spd)
		
		local trail = util.SpriteTrail( self, 0, Color( 255, 0, 0 ), true, 3, 0, 0.1, 0.1, "effects/beam_generic01" )
		local trail2 = util.SpriteTrail( self, 0, Color( 255, 255, 255 ), true, 2, 0, 0.05, 0.2, "effects/beam_generic01" )
		
	elseif CLIENT then
		
		if IsValid(self) then
			self.Emitter = ParticleEmitter(self:GetPos())
			self.ParticleDelay = 0
		end
		
		EMRPR = CreateSound( game.GetWorld(), "main/t_b_r.wav" )
		EMRPR:SetSoundLevel( 0 )
		DangerEMRPR = CreateSound( game.GetWorld(), "main/close_emrpr_loop.mp3" )
		DangerEMRPR:SetSoundLevel( 0 )
		
		timer.Simple( 0.1 , function()
			if IsValid(self) then
				EMRPR:Play()
				DangerEMRPR:Play()
				
				EMRPR:FadeOut( 2 )
				DangerEMRPR:FadeOut( 2 )
			end
		end)
		
		net.Receive( "Client_Shockwave_Round", function( len )
			local ContinationWave = net.ReadFloat()
			local Dist = ( 1 - net.ReadFloat() ) or 0
			if ContinationWave == nil then return end
			
			timer.Simple( ContinationWave , function() 
				EmitSound( "central_base_material/cbmbounce1far.mp3" , Vector() , -1 , CHAN_AUTO , math.Clamp(Dist^4,0,0.4) , 90 , 0 , math.random(90,100) )
			end)
		end)
		
	end
	
end

function ENT:Think()
	local owner = self:GetOwner()
	local RoundPhys = self:GetPhysicsObject()
	
	if CLIENT then
		if IsValid(self) then
			local Pitch = (math.Round(100 / (self:GetPos():Distance(LocalPlayer():GetPos()) / 52.4934))*50) + 30
			EMRPR:ChangePitch( Pitch )
			EMRPR:ChangeVolume( (220 / (self:GetPos():Distance(LocalPlayer():GetPos()) / 52.4934)) )
			DangerEMRPR:ChangePitch( Pitch )
			DangerEMRPR:ChangeVolume( (50 / (self:GetPos():Distance(LocalPlayer():GetPos()) / 52.4934)) )
			
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
			part:SetStartAlpha(250)
			part:SetEndAlpha(0)
			part:SetDieTime(0.1)
			part:SetRoll( math.random(0, 360) )
			part:SetRollDelta(0.01)
			part:SetColor(1, 1, 1)
			part:SetLighting(false)
			part:SetVelocity( (self:GetVelocity()) - (Vector * self:GetVelocity():Length() / 3) )
		end
	end
	
	if not IsValid( self.Target ) then return end
	
	if self.CurrentDist <= self.Lowest then
		if self:GetPhysicsObject() != nil and IsValid(owner) then
			local SteerForce = 4000
			local AutoDistance = owner:WorldSpaceCenter():Distance(self:GetNWEntity( "Targeted" ):WorldSpaceCenter())
			local TriggerDistance = AutoDistance - 200
			local MaxTurnDistance = 500
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
	else
	
	end
	
	
	
	self:NextThink( CurTime() + 0.1 )
	return true
end 


function ENT:PhysicsUpdate(phys)
	if not IsValid(phys) then return end
	
	local angles = phys:GetAngles()
	local velocity = phys:GetVelocity()

	--print(angles, angles:Forward() , velocity , velocity:Angle() ) 

	phys:SetAngles( velocity:Angle() )
	phys:SetVelocity(velocity)
	
end


function ENT:Draw()
	self:DrawModel()
end

function ENT:Use(activator, caller)
	return false
end

local vel, len

local traceData = {}
traceData.mask = bit.bor(CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_DEBRIS, CONTENTS_MONSTER, CONTENTS_HITBOX, CONTENTS_WATER)

function ENT:PhysicsCollide(data, physobj)
timer.Simple( 0, function() 
	
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
				local Size = 12*52.4934
				local effectdata = EffectData()
				local d = DamageInfo()
				d:SetDamage( (3 * (Velocity:Length()/52.4934) ^ 3 ) )
				d:SetAttacker( owner )
				d:SetInflictor( self )
				d:SetDamageType( DMG_AIRBOAT )
				EntityToSlam:TakeDamageInfo( d )
				
				util.BlastDamage( self, owner, position, Size, Velocity:Length()^0.5 )
				
				effectdata:SetOrigin( position )
				effectdata:SetAngles( EntityToSlam:GetAngles() )
				effectdata:SetScale( Size/52 )
				util.Effect( "MuzzleEffect", effectdata )
				
			end
			
			local d = DamageInfo()
			d:SetDamage( (3 * (Velocity:Length()/52.4934) ^ 3 ) )
			d:SetAttacker( owner )
			d:SetInflictor( self )
			d:SetDamageType( DMG_DIRECT )
			EntityToSlam:TakeDamageInfo( d )
			
			ParticleEffect( "ShockWave", position , Angle(0,0,0))
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
		
			sound.Play( Sound("main/roundhit_softmatter_"..math.random(1,9)..".wav"), position, 100, 100,0.25 )
			sound.Play( Sound("main/fragexplose"..math.random(1,3)..".wav"), position, 90, 190, 0.1 )
		
		util.ScreenShake(self:GetPos(), 10, 0.01, 0.6, 1000)
		self:SinuousExplosion( 650 )
		
	end
		
		local RandHitPos = position
		local VeloRicochet = math.random(500,15000)
		local RandomNormal = MaxPen + (VectorRand()/3)
		
		if VeloRicochet < 12000 then
			sound.Play( Sound("central_base_material/cbmarmor_shed_"..math.random(1,3)..".mp3"), position, 90, math.random(80,140),0.8)
		else
			sound.Play( Sound("central_base_material/cbmarmor_elasticdeform_"..math.random(1,5)..".mp3"), position, 130, math.random(50,100),1)
		end
		
		util.Decal( "FadingScorch", RandHitPos, RandHitPos + MaxPen, self )
		
		local effectdata = EffectData()
		effectdata:SetOrigin( RandHitPos )
		effectdata:SetNormal( RandomNormal )
		effectdata:SetMagnitude( math.random(1,3) )
		effectdata:SetScale( 1 )
		effectdata:SetRadius( math.random(10,15) / 3 )
		util.Effect( "Sparks", effectdata )
		
		effectdata:SetOrigin( RandHitPos )
		effectdata:SetAngles( (RandomNormal):Angle() )
		effectdata:SetScale( math.random(32,50) / 10 )
		util.Effect( "MuzzleEffect", effectdata )
		
		if SERVER then
		
		ObjectThicknessDerivative = (PenTrace.FractionLeftSolid) * MaxPen:Length()
		penetrationDerivative = math.Clamp( (self.KaplierEnergy / ((ObjectThicknessDerivative^2) / 0.524934) ) , 0 , 1 )
		
		if ( not util.IsInWorld( PenTrace.HitPos ) and (Velocity:Length() > 5)  and (penetrationDerivative > 0.01)) then 
			
			self:FireBullets( { 
			Src = RandHitPos ,
			Dir = -Velocity:GetNormalized(),
			Num = math.random( 2 , 20 ),
			Spread = Vector( math.random( 1 , 5 ) , math.random( 1 , 5 ) ),
			Damage = (Velocity:Length() ^ 0.5) / 1000,
			Force = (Velocity:Length() ^ 0.5) / 1000
			})
			
			Original_position = position
			
			local ModelMin, ModelMax = self:GetModelBounds()
			local ModelDistance = (ModelMax+(ModelMin*-1)) * self:GetModelScale()
			position = Original_position + ((ObjectThicknessDerivative + ModelDistance.x * 3) * Velocity:GetNormalized()) 
			
			sound.Play( Sound("main/ground_hit_explosive_"..math.random(1,3)..".wav"), position, 60, math.random(80,160), 1 )
			
			local owner = self:GetOwner()
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
			
			for i = 1, math.Round( math.random(1,16) / 10 ) do
				local Bouncer = ents.Create("cw_tiwround_fragment")
				local AngleFire = (MaxPen:GetNormalized() + (VectorRand()/26) ):Angle()
				
				Bouncer:SetPos( position + VectorRand() * math.random(5,60) )
				Bouncer:SetAngles( AngleFire )
				Bouncer:SetOwner( owner )
				Bouncer:Spawn()
				
				local BouncerPhys = Bouncer:GetPhysicsObject()
				
				if IsValid(BouncerPhys) then
					BouncerPhys:SetVelocityInstantaneous( AngleFire:Forward() * VeloRicochet * math.random(5,120) / 50 )
				end
			end
			
		else
			
			for i = 1, math.Round( (math.random(0,100) / 100) ^ 2 ) do
				local Bouncer = ents.Create("cw_tiwround_fragment")
				local AngleFire = (self:GetForward():GetNormalized() - (data.HitNormal/1) + (VectorRand()/4) ):Angle()
				
				Bouncer:SetPos( (position + VectorRand()) - data.HitNormal * 5 )
				Bouncer:SetAngles( AngleFire )
				Bouncer:SetOwner( owner )
				Bouncer:Spawn()
				
				local BouncerPhys = Bouncer:GetPhysicsObject()
				
				if IsValid(BouncerPhys) then
					BouncerPhys:SetVelocityInstantaneous( AngleFire:Forward() * VeloRicochet * math.random(10,50) / 50 )
				end
			end
		
		end
		end
		
		local RandHitPos = position + (VectorRand() * math.random(1,15))
		
		util.Decal( "FadingScorch", RandHitPos, RandHitPos - MaxPen, self )
		
		local effectdata = EffectData()
		effectdata:SetOrigin( RandHitPos - MaxPen/3 )
		effectdata:SetNormal( AngleRand():Forward() )
		effectdata:SetMagnitude( math.Rand(0.9,3) )
		effectdata:SetRadius( 0 )
		util.Effect( "centralbasematerial_spark", effectdata, true, true)
		
		if SERVER then
			util.ScreenShake( position, 4, 0.01, 0.5, 500 )
		end
		
		self:SinuousExplosion( 1250 )
		
		self:Remove()
		SafeRemoveEntityDelayed(self, 10)
		
end)
end

function ENT:OnRemove()
	if CLIENT then
		if IsValid(self.Emitter) then
			self.Emitter:Finish()
		end
		
		EMRPR:Stop()
		DangerEMRPR:Stop()
	end
	
end

