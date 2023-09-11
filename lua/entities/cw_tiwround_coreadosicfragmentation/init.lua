AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
ENT.Mass = 32

if SERVER then
	util.AddNetworkString( "Client_Shockwave" )
end

function ENT:Initialize()

	self:SetModel("models/Items/AR2_Grenade.mdl") 
	self:SetModelScale( 0.9, 0 )
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	local phys = self:GetPhysicsObject()

	if phys and phys:IsValid() then
		phys:Wake()
		phys:SetMass( self.Mass )
		phys:SetDragCoefficient( 1 )
	end
	
	self:GetPhysicsObject():SetBuoyancyRatio(0)
	self.ArmTime = CurTime() 
	
	spd = physenv.GetPerformanceSettings()
    spd.MaxVelocity = 800 * 52.4934
	
	self.MaxCollide = math.random(1,math.random(2,6))*2
	self.CollideAmt = 0
	
    physenv.SetPerformanceSettings(spd)
	local startWidth = 2
	local endWidth = 10
	local res = 1 / ( startWidth + endWidth ) * 0.5
	local trail = util.SpriteTrail( self, 0, Color( 255, 255, 255 ), true, startWidth, endWidth, 0.05, res, "effects/beam_generic01" )
end

function ENT:Think()
	local BouncerPhys = self:GetPhysicsObject()
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
	vel = physobj:GetVelocity()
	velLen = vel:Length()
	
	timer.Simple( 0, function() 
		self.CollideAmt = self.CollideAmt + 1
		if IsValid(self) and IsValid(self:GetPhysicsObject()) and data.HitEntity ~= self:GetClass() and self.CollideAmt >= self.MaxCollide then
			local Velocity = self:GetPhysicsObject():GetVelocity():Length()
			ent = data.HitEntity	
			if ent:IsNPC() or ent:IsPlayer() then
				ent:TakeDamage( 15+math.Clamp(Velocity/1000,0,1000000), self, self )
			end
			
			local poititi = self:GetPos()
			
			sound.Play( Sound("physics/cardboard/cardboard_box_impact_bullet5.wav"), poititi, 90, 40, 1 )
			sound.Play( "physics/metal/metal_grenade_impact_hard" .. math.random(1, 3) .. ".wav" , self:GetPos(), 110, 30, 1 )
			
			util.ScreenShake(self:GetPos(), 999, 0.1, 0.5, 1000) 
			
			ParticleEffect( "DirtFireballHit", self:GetPos() , -data.HitNormal:Angle() )
			local Damage = (0.05 * (Velocity/52.4934) ^ 3 )
			local DamageRadius = (4 * 52.4934)
			util.BlastDamage(self, self, self:GetPos(), DamageRadius , Damage )
			
			local SoundDistanceMax = 400 * 52.4934
			for k, v in pairs(ents.FindInSphere(self:GetPos(),SoundDistanceMax)) do
				if IsValid(v) and v:IsPlayer() then
					local Dist = v:WorldSpaceCenter():Distance(self:GetPos())/SoundDistanceMax
					
					local ContinationWave = ((Dist)*SoundDistanceMax)/((343+math.random(-10,150)) * 52.4934)
					
					net.Start("Client_Shockwave")
						net.WriteFloat(ContinationWave)
						net.WriteFloat(Dist)
					net.Send(v)
					
					timer.Simple( ContinationWave , function() 
						if IsValid(v) then
							Dist = 1 - Dist
							v:SetViewPunchAngles(Angle((math.random(-100,100)/50)*((Dist)^10), (math.random(-100,100)/50)*((Dist)^10), (math.random(-100,100)/50)*((Dist)^10)))
						end
					end)
				end
			end
			
			self:Remove()
			SafeRemoveEntityDelayed(self, 10)
		else
			
			physobj:SetVelocity( physobj:GetVelocity() + (-data.HitNormal * physobj:GetVelocity():Length()/8) )
			
			if velLen > 100 then

				self:EmitSound("physics/metal/metal_box_impact_hard"..math.random(1,3)..".wav", 90, math.random(160,165))
				
				local effectdata = EffectData()
				effectdata:SetOrigin( data.HitPos )
				effectdata:SetAngles( Angle() )
				effectdata:SetNormal( vel:GetNormalized() )
				effectdata:SetMagnitude( 2 )
				effectdata:SetRadius( 2 )
				util.Effect( "Sparks", effectdata)
			end
			
		end
	end)

end




