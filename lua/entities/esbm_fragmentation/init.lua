AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
ENT.Mass = 60
ENT.NextImpact = 0

function ENT:Initialize()

	self:SetModel("models/props_phx/gibs/flakgib1.mdl") 
	self:SetModelScale( math.random(0.25,0.3) , 0 )
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
	
	spd = physenv.GetPerformanceSettings()
    spd.MaxVelocity = 100000
	
    physenv.SetPerformanceSettings(spd)
	local trail = util.SpriteTrail( self, 0, Color( 255, math.random(255,50), 0 ), true, 3, 0, 0.2, 100, "effects/beam_generic01" )
	local trail2 = util.SpriteTrail( self, 0, Color( 255, 255, 255 ), true, 40, 0, 0.1, 1, "effects/beam_generic01" )
end

function ENT:Think()
	local BouncerPhys = self:GetPhysicsObject()
	BouncerPhys:AddVelocity( (physenv.GetGravity()*2) + ( VectorRand() * math.random(100,320) ) )	
end 

function ENT:PlantEffect(entity,pos,direction)
	local Bellit={
		Attacker=entity,
		Damage=15,
		Force=2000,
		Num=1,
		Tracer=6,
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
	if not IsValid(self) then return end
	if IsValid(self:GetPhysicsObject()) and IsValid(self) then
		local Velocity = self:GetPhysicsObject():GetVelocity():Length()
		ent = data.HitEntity	
		if ent:IsNPC() or ent:IsPlayer() then
			ent:TakeDamage( 15+math.Clamp(Velocity/1000,0,100000), game.GetWorld(), game.GetWorld() )
			ent:EmitSound("main/roundhit_softmatter_"..math.random(1,9)..".wav", 80, math.random(140,150),1)
			ParticleEffect( "DirtFireballHit", self:GetPos() , data.HitNormal:Angle():Up():Angle() )
			util.BlastDamage(self, game.GetWorld(), self:GetPos(), 200, 20)
			self:Remove()
		end
		
		CT = CurTime()
		
		if CT > self.NextImpact then
			
			ParticleEffect( "DirtFireballHit", self:GetPos() , data.HitNormal:Angle():Up():Angle() )
			sound.Play( "ambient/explosions/explode_4.wav", self:GetPos(), 70, math.random(150,200))
			
			for i=1,math.random(8,12) do
				self:PlantEffect(self,self:GetPos(),-self:GetPhysicsObject():GetVelocity():GetNormalized()-data.HitNormal+VectorRand()/5)
			end
			
			local effectdata = EffectData()
			effectdata:SetOrigin( self:GetPos() )
			effectdata:SetAngles( Angle() )
			effectdata:SetNormal( data.HitNormal )
			effectdata:SetMagnitude( 2 )
			effectdata:SetRadius( 2 )
			util.Effect( "Sparks", effectdata)
			
			if Velocity < 2500 then
				util.ScreenShake(self:GetPos(), 150, 0.0001, 0.1, 100) 
				sound.Play( "main/groundslicklight" .. math.random(1, 3) .. ".wav" , self:GetPos(), 80, 100, 1 )
				util.BlastDamage(self, game.GetWorld(), self:GetPos(), 30, 20)
			elseif Velocity > 2500 and Velocity < 5000 then
				util.ScreenShake(self:GetPos(), 250, 0.0001, 0.1, 1100) 
				sound.Play( "main/rigidpeirce.wav" , self:GetPos(), 90, math.random(190,200), 1 )
				ParticleEffect( "Flashed", self:GetPos() , Angle(0,0,0) )
				ParticleEffect( "DirtFireballHit", self:GetPos() , data.HitNormal:Angle():Up():Angle() )
				util.BlastDamage(self, game.GetWorld(), self:GetPos(), 100, 100)
			end
			
			self.NextImpact = CT + 0.1
		end
		
		if math.random( 1 , 100 ) > 95 then
			self:Remove()
		else
			local PhysObj= self:GetPhysicsObject()
			PhysObj:SetVelocity((PhysObj:GetVelocity()*0.9)+(data.HitNormal*(PhysObj:GetVelocity()*math.random(2,6)))+VectorRand())
		end
	end
	SafeRemoveEntityDelayed(self, 10)
end)
end
