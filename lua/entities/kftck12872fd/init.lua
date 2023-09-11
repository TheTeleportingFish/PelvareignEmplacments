AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
ENT.Mass = 3200
ENT.NextImpact = 0

-- appreciation
function Mod_AeroDrag(ent, forward, mult)
	if (constraint.HasConstraints(ent)) then return end
	if (ent:IsPlayerHolding()) then return end
	local Phys = ent:GetPhysicsObject()
	local Vel = Phys:GetVelocity()
	local Spd = Vel:Length()
	local Stabilization = ent:GetRight():Dot(Vel) / Spd
	if (Spd < 300) then return end
	mult = mult or 1
	local Pos, Mass = Phys:LocalToWorld(Phys:GetMassCenter()), Phys:GetMass()
	Phys:ApplyForceOffset((Vel * Mass / 6 * mult) / math.abs(1 + Stabilization), (Pos + forward))
	Phys:ApplyForceOffset((-Vel * Mass / 6 * mult) / math.abs(1 + Stabilization), (Pos - forward))
	Phys:AddAngleVelocity( -Phys:GetAngleVelocity() / math.Clamp(ent:GetRight():Dot(Vel)^0.5,2,12) )
end

-- appreciation
function Mod_AeroGuide(ent, forward, targetPos, turnMult, thrustMult, angleDragMult, spdReq)

	local Phys = ent:GetPhysicsObject()
	local Vel = Phys:GetVelocity()
	local Spd = Vel:Length()

	local Pos, Mass = Phys:LocalToWorld(Phys:GetMassCenter()), Phys:GetMass()
	local TargetVec = targetPos - ent:GetPos()
	local TargetDir = TargetVec:GetNormalized()

	Phys:ApplyForceOffset(TargetDir * Mass * turnMult * 5000, Pos + forward)
	Phys:ApplyForceOffset(-TargetDir * Mass * turnMult * 5000, Pos - forward)
	Phys:AddAngleVelocity(-Phys:GetAngleVelocity() * angleDragMult * 3)

	Phys:ApplyForceCenter(forward * 20000 * thrustMult) -- todo: make this function fucking work ARGH
end

function ENT:SpawnFunction(ply, tr)

	local SpawnPos=tr.HitPos+tr.HitNormal*16
	local ent = ents.Create("kftck12872fd")
	ent:SetPos(SpawnPos)
	ent:Spawn()
	ent:Activate()
	
	local effectdata=EffectData()
	effectdata:SetEntity(ent)
	util.Effect("propspawn",effectdata)
	
	return ent

end

function ENT:Initialize()
	self:SetModel("models/pelvareign_bombs/kftck12872fd.mdl") 
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	local phys = self:GetPhysicsObject()
	
	self.WindCrackle = CreateSound( self, "main/wind_breaking.mp3")
	self.WindCrackle:SetSoundLevel( 110 )

	if phys and phys:IsValid() then
		phys:Wake()
		phys:SetMass( self.Mass )
		phys:SetDragCoefficient( 1e-9 )
	end
	
	self:GetPhysicsObject():SetBuoyancyRatio(110)
	self.ArmTime = CurTime() 
	
	spd = physenv.GetPerformanceSettings()
    spd.MaxVelocity = 18000
	
    physenv.SetPerformanceSettings(spd)

end

function ENT:Think()
	local velocity = self:GetVelocity()
	
	self:NextThink( CurTime() + 0.1 )
	return true
end 

function ENT:PhysicsUpdate(phys)
	local velocity = phys:GetVelocity()
	
	Mod_AeroDrag( self , self:GetRight() , 2 )
	phys:AddAngleVelocity( (Vector(0,1,0) * (self:GetRight():Dot(velocity)/10)) )
	--debugoverlay.Line( self:GetPos(), self:GetPos() + (self:GetRight():Dot(velocity) * self:GetRight()), 0.1, Color( 255, 255, 255 ) )
	--print( self:GetRight():Dot(velocity) )
	
	local VelocityInMeters = (velocity:Length()/52.4934)
	
	if self.WindCrackle then
		self.WindCrackle:Play()
		self.WindCrackle:ChangePitch( math.Clamp( VelocityInMeters / 5 , 10 , 240 ) )
		self.WindCrackle:ChangeVolume( math.Clamp( VelocityInMeters / 200 , 0 , 1 ) )
	end
	
	CompressionWave = CurTime()
	if self.NextCompressionTick == nil or CompressionWave > self.NextCompressionTick then
		if velocity:Length() > (100 * 52.4934) then
			if IsValid(self.compressiontrail) then
				self.compressiontrail:Remove()
			end
			self.compressiontrail = util.SpriteTrail( self, 0, Color( 255, 255, 255, math.Clamp( (VelocityInMeters / 100) * 10 , 0 , 255 ) ), true, 100, 800, 0.05, 10, "effects/beam_generic01" )
		else
			if IsValid(self.compressiontrail) then
				self.compressiontrail:Remove()
			end
		end
		self.NextCompressionTick = CompressionWave + 0.25
	end
	
end

function ENT:PlantEffect(entity,pos,direction)
	local Bellit={
		Attacker=entity,
		Damage=55,
		Force=20,
		Num=1,
		Tracer=1,
		Dir=direction,
		Spread=Vector(0,0,0),
		Src=pos
	}
	entity:FireBullets(Bellit)
end

function ENT:Use(activator, caller)
	return false
end

function ENT:OnRemove()
	return false
end 

local vel, len, CT

local traceData = {}
traceData.mask = bit.bor(CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_DEBRIS, CONTENTS_MONSTER, CONTENTS_HITBOX, CONTENTS_WATER)

function ENT:PhysicsCollide(data, physobj)
	timer.Simple( 0, function() 
	if (self:GetPhysicsObject():GetVelocity():Length() < 500) then return end
	if not IsValid(self) and data.HitEntity:GetClass() ~= self:GetClass() then return end
	local Velocity = self:GetPhysicsObject():GetVelocity()
	local position = self:GetPos()
	
	ParticleEffect( "GroundCloudLarge", position , data.HitNormal:Angle():Up():Angle() )
	ParticleEffect( "GroundCloud", position , data.HitNormal:Angle():Up():Angle() )
	sound.Play( Sound("CW_HEI_Explose"), position )
	
	if data.HitEntity == self.Owner then
	return false
	end
	
	--print(data.HitEntity)
	
	local d = DamageInfo()
	d:SetDamage( math.random(9.10,11.32) * (Velocity:Length() / 52.4934) )
	d:SetDamageType( DMG_RADIATION )
			
	util.BlastDamageInfo(d, position, (30 * 52.4934))
	
	if ( data.HitEntity:IsNPC() or data.HitEntity:IsPlayer() or string.match(tostring(data.HitEntity),"npc*") or string.match(tostring(data.HitEntity),"phys*") ) and data.HitEntity:IsValid() then

	local EntityToSlam = data.HitEntity
	local ExplodeRadius = 20
	local ExplodeDamage = 1000
	
	if string.match(tostring(EntityToSlam),"phys*")  then 
		for k, v in pairs(ents.FindInSphere(data.HitPos,200)) do
			if string.match(tostring(v),"npc*") then
				if v:IsNPC() and v:IsValid() then
					EntityToSlam = v
					
					local d = DamageInfo()
					d:SetDamage( 1250 )
					d:SetAttacker( self )
					d:SetInflictor( self )
					d:SetDamageType( DMG_BLAST )
					EntityToSlam:TakeDamageInfo( d )
							
					d:SetDamage( 120 )
					d:SetAttacker( self )
					d:SetInflictor( self )
					d:SetDamageType( DMG_DISSOLVE )
					EntityToSlam:TakeDamageInfo( d )
					d:SetDamage( 2310 )
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
			ParticleEffect( "ShockWave", data.HitPos , Angle(0,0,0))
		end
	end
	
		EntityToSlam:EmitSound("player/pain.wav", 130, math.random(60,90))
		if not IsValid(EntityToSlam) then return end
		if EntityToSlam:GetPos():Distance( self.Owner:GetPos() ) < 300 then	
			local d = DamageInfo()
			d:SetDamage( 100/((EntityToSlam:GetPos():Distance( self.Owner:GetPos() )+1)/50) )
			d:SetAttacker( game.GetWorld() )
			d:SetDamageType( DMG_BURN )
			if SERVER then 
				self.Owner:TakeDamageInfo( d )
			end 
		end
	
	
			sound.Play( Sound("main/explodeair0_4.wav"), position, 100, 90, 0.9 )
			
			local poititi = self:GetPos()
			sound.Play( Sound("weapons/13mmtiw/electricexplose.wav"), poititi, 300, 60, 1 )
			
			util.ScreenShake(self:GetPos(), 150, 9999, 0.1, 1000) 
			
			
			local SoundDistanceMax = 10000
			for k, v in pairs(ents.FindInSphere(self:GetPos(),SoundDistanceMax)) do
				if v:IsPlayer() or v:IsNPC()  then
					if v then
					
					obj = v
					
					local Dist = ( 1 - (v:GetPos():Distance(self:GetPos())/SoundDistanceMax) )
					local SmallDist = ( 1 - (v:GetPos():Distance(self:GetPos())/SoundDistanceMax*2) )
					local Time = ( (v:GetPos():Distance(self:GetPos())/8000) )
					local positedplayer = v:WorldSpaceCenter()
					
					direction = (positedplayer - (poititi + data.HitNormal:Angle():Forward()*-100)):GetNormal()
					
					traceData.filter = {Bouncer,self}
					traceData.start = poititi + data.HitNormal:Angle():Forward()*-100
					traceData.endpos = traceData.start + direction * SoundDistanceMax
					
					local trace = util.TraceLine(traceData)
					
					ent = trace.Entity
					fract = trace.Fraction
					
					local isplayer = ent:IsPlayer()
					local isnpc = ent:IsNPC()
					local equal = ent == v
					
					timer.Simple( Time*0.5, function() 
					
						if (isplayer) then
							v:EmitSound( "weapons/13mmtiw/electricexplose.wav", 75, 200, Dist/2, CHAN_AUTO )
							
							if equal then
								v:EmitSound( "main/airshockwave.wav", 75, 90, Dist, CHAN_AUTO ) 
								v:EmitSound( "weapons/13mmtiw/electricexplose.wav", 75, 250, Dist/2, CHAN_AUTO )
								for i = 1, 5 do
									timer.Simple( i*0.01, function() 
										v:SetViewPunchAngles(Angle(math.random(-1,1)*Dist, math.random(-1,1)*Dist, math.random(-1,1)*Dist))
									end) 
								end
							end
							
							if SmallDist > 0 then 
								v:EmitSound( "weapons/13mmtiw/electricexplose.wav", 75, 250, SmallDist/2, CHAN_AUTO )
								if equal then
									v:EmitSound( "main/airshockwave.wav", 75, 20, SmallDist, CHAN_AUTO ) 
									for i = 1, 5 do
										timer.Simple( i*0.01, function() 
											v:SetViewPunchAngles(Angle((math.random(-5,5)/50)*(SmallDist+1)^5, (math.random(-5,5)/50)*(SmallDist+1)^5, (math.random(-5,5)/50)*(SmallDist+1)^5))
										end) 
									end
								end
								
							end
						end
					
					end)
					
					
				end
			end
		end
			
	else
	
		sound.Play( Sound("main/cbmbounce1.mp3"), position, 100, 90,0.5)		
		
		local SoundDistanceMax = 20000
		for k, v in pairs(ents.FindInSphere(position,SoundDistanceMax)) do
			if v:IsPlayer() then
				if v then
					local Dist = ( 1 - (v:GetPos():Distance(position)/SoundDistanceMax) )
					timer.Simple( 0.2, function() 
						v:EmitSound( "main/cbmbounce1far.mp3", 75, 80, Dist, CHAN_AUTO ) 			
					end)
				end
			end
		end
			
		if SERVER then
			util.ScreenShake( position, 9, 600, 0.5, 500 )
		end
		
			local SoundDistanceMax = (500 * 52.4934)
			for k, v in pairs(ents.FindInSphere(self:WorldSpaceCenter(),SoundDistanceMax)) do
				if v:IsPlayer() then
					if v then
						local Dist = ( 1 - (v:WorldSpaceCenter():Distance(self:WorldSpaceCenter())/SoundDistanceMax) )
						timer.Simple( ((v:WorldSpaceCenter():Distance(self:WorldSpaceCenter())/SoundDistanceMax)*SoundDistanceMax)/(343 * 52.4934) , function() 
							sound.Play( Sound("main/bouncehit.wav"), v:WorldSpaceCenter() , 60, math.random(60,80)*Dist, Dist^2 )
							v:SetViewPunchAngles(Angle((math.random(-5,5)/50)*(Dist+1)^5, (math.random(-5,5)/50)*(Dist+1)^5, (math.random(-5,5)/50)*(Dist+1)^5))
						end)
					end
				end
			end
			
			for i = 1, 5 do
				ParticleEffect( "Flashed", self:GetPos() + (VectorRand() * math.random(1,150)) , Angle(0,0,0) )
			end
		
		ParticleEffect( "ShockWave", data.HitPos , Angle(0,0,0))
		
		for i = 1, math.random(50,70) do
			if SERVER then
				local Bouncer = ents.Create("esbm_fragmentation")
				
				local AngleFire = ( -(data.HitNormal/2) + (VectorRand()/2) ):Angle()
				
				Bouncer:SetPos( position - data.HitNormal * 5 )
				Bouncer:SetAngles( AngleFire )
				Bouncer:SetOwner( self.Owner )
				Bouncer:Spawn()
				
				local BouncerPhys = Bouncer:GetPhysicsObject()
				
				if IsValid(BouncerPhys) then
					BouncerPhys:SetVelocityInstantaneous( AngleFire:Forward()*math.random(7500,10000) )
				end
				
			end
		end
	end

	self:Remove()
	SafeRemoveEntityDelayed(self, 10)
		
	end)
end
