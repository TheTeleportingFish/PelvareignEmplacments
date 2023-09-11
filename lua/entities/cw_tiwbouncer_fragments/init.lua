AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
ENT.Mass = 60

function ENT:Initialize()

	self:SetModel("models/props_phx/gibs/flakgib1.mdl") 
	self:SetModelScale( 0.2, 0 )
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	local phys = self:GetPhysicsObject()

	if phys and phys:IsValid() then
		phys:Wake()
		phys:SetMass( self.Mass )
		phys:SetDragCoefficient( 0.0001 )
	end
	
	self:GetPhysicsObject():SetBuoyancyRatio(0)
	self.ArmTime = CurTime()
	self.FRAGMENTED = false
	
	spd = physenv.GetPerformanceSettings()
    spd.MaxVelocity = 300000
	
    physenv.SetPerformanceSettings(spd)
	local trail = util.SpriteTrail( self, 0, Color( 255, 220, 100 ), true, 5, 0, 0.2, 0.2, "effects/beam_generic01" )
end

function ENT:Think()
	local BouncerPhys = self:GetPhysicsObject()
		BouncerPhys:AddVelocity(Vector(math.cos(math.random(-100,100))*math.random(-10000,10000),math.sin(math.random(-100,100))*math.random(-10000,10000),-500)/10)	

end 


function ENT:Use(activator, caller)
	return false
end

function ENT:OnRemove()
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
		
		local owner = self:GetOwner()
		local Velocity = data.OurOldVelocity
		local position = data.HitPos
		local ent = data.HitEntity
		
		if self:GetPhysicsObject() != nil and self != nil then
			
			if ent:IsNPC() or ent:IsPlayer() then
				ent:TakeDamage( 15+math.Clamp(Velocity:Length()/1000,0,10000), game.GetWorld(), game.GetWorld() )
				ent:EmitSound("player/pain.wav", 110, math.random(60,90))
			end
			
			
			if ent:IsValid() then
				if string.match(tostring(ent),"npc_turret_floor") and ent:IsNPC() then
					if SERVER then ent:Fire("SelfDestruct") end
				end
				
				local Size = math.random(2,7) * 52.4934
				
				if SERVER then
					local d = DamageInfo()
					d:SetDamage( 0.1 * (Velocity:Length()/52.4934) )
					d:SetAttacker( owner )
					d:SetInflictor( self )
					d:SetDamageType( DMG_AIRBOAT )
					ent:TakeDamageInfo( d )
					
					util.BlastDamage( self, owner, position, Size, math.random(30,120) )
					
					local d = DamageInfo()
					d:SetDamage( (0.1 * (Velocity:Length()/52.4934) ^ 0.5 ) )
					d:SetAttacker( owner )
					d:SetInflictor( self )
					d:SetDamageType( DMG_DIRECT )
					ent:TakeDamageInfo( d )
				end
				
				ParticleEffect( "Flashed", position , Angle(0,0,0) )
				ParticleEffect( "ShockWave", position , Angle(0,0,0))
			end
			
			sound.Play( Sound("high_energy_systems/cateroushickleshrapnelpenetration_"..math.random(1,9)..".mp3"), position, 110, math.random(80,95),0.2)
			
			if Velocity:Length() < 2500 then
				
				util.ScreenShake(position, 2, 300, 0.9, 200) 
				
				sound.Play( "physics/metal/metal_grenade_impact_hard"..math.random(1,3)..".wav" , position, 80, 100, 1 )
				ParticleEffect( "DirtExplodeHit", position , Angle() )
				util.BlastDamage(self, game.GetWorld(), position, 50, 100)
			elseif Velocity:Length() > 2500 and Velocity:Length() < 5000 then
				
				util.ScreenShake(position, 5, 55, 0.7, 300) 
				
				sound.Play( "main/groundslicklight"..math.random(1, 3)..".wav" , position, 110, 60, 1 )
				ParticleEffect( "ShockWave", position, Angle() )
				util.BlastDamage(self, game.GetWorld(), position, 130, 500)
			elseif Velocity:Length() > 5000 then 
				
				util.ScreenShake(position, 10, 0.02, 0.2, 900) 
				
				sound.Play( "central_base_material/cbmarmor_hitnone_"..math.random(1,3)..".mp3", position, 130, math.random(80,140),1)
				ParticleEffect( "DirtExplodeHit", position , Angle() )
				util.BlastDamage(self, game.GetWorld(), position, 340, 1000)
			end
			
			
		end
		
		local effectdata = EffectData()
		effectdata:SetOrigin( position )
		effectdata:SetAngles( self:GetAngles() )
		effectdata:SetScale( 52.5 * math.random(3,15) )
		util.Effect( "MuzzleEffect", effectdata )
		
		self:Remove()
		SafeRemoveEntityDelayed(self, 10)
	end)
end
