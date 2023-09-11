AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
ENT.Mass = 10

if SERVER then
	util.AddNetworkString( "Client_Shockwave" )
end

function ENT:Initialize()

	self:SetModel("models/props_phx/gibs/flakgib1.mdl") 
	self:SetModelScale( 0.3, 0 )
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
	
    physenv.SetPerformanceSettings(spd)
	local trail = util.SpriteTrail( self, 0, Color( 255, 255, 255 ), true, 8, 0, 0.1, 0.01, "effects/beam_generic01" )
	local trail2 = util.SpriteTrail( self, 0, Color( 255, 0, 0 ), true, 12, 0, 0.3, 0.01, "effects/beam_generic01" )
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
	timer.Simple( 0, function() 
		if IsValid(self) and IsValid(self:GetPhysicsObject()) and data.HitEntity ~= self:GetClass() then
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
			util.BlastDamage(self, self, self:GetPos(), (2 * 52.4934),  (0.0009 * (Velocity/52.4934) ^ 3 ) )
			
			local SoundDistanceMax = 400 * 52.4934
			for k, v in pairs(ents.FindInSphere(self:GetPos(),SoundDistanceMax)) do
				if IsValid(v) and v:IsPlayer() then
					local Dist = v:WorldSpaceCenter():Distance(self:GetPos())/SoundDistanceMax
					
					local ContinationWave = ((Dist)*SoundDistanceMax)/((343+math.random(-10,150)) * 52.4934)
					
					net.Start("Client_Shockwave")
						net.WriteFloat(ContinationWave)
						net.WriteFloat(Dist)
					net.Send(v)
					
				end
			end
			
			self:Remove()
			SafeRemoveEntityDelayed(self, 10)
		end
	end)

end




