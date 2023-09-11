AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.PrintName = "TIWFrag"
ENT.Author = ""
ENT.Information = "A TIW Round Fragment"
ENT.Spawnable = false
ENT.AdminSpawnable = false 
ENT.Mass = 10

function ENT:Draw()
	self:DrawModel()
end

if SERVER then
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

function ENT:Initialize()
	self:SetModel("models/gibs/helicopter_brokenpiece_02.mdl") 
	self:SetModelScale( math.Rand(0.1,0.35), 0 )
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	
	self:GetPhysicsObject():SetBuoyancyRatio(0)
	self.ArmTime = CurTime() 
	
	self.Owner = self:GetOwner()
	
	if SERVER then
		local phys = self:GetPhysicsObject()
		
		if phys and phys:IsValid() then
			phys:Wake()
			phys:SetMass( self.Mass )
			phys:SetDragCoefficient( math.Rand(0.01,0.1) )
		end
		
		spd = physenv.GetPerformanceSettings()
		spd.MaxVelocity = 5000 * 52.4934
		
		physenv.SetPerformanceSettings(spd)
		
		trail = util.SpriteTrail( self, 0, Color( 255, 255, 255 , 25 ), true, 5, 20, 0.1, 0.1, "effects/beam_generic01" )
		
	elseif CLIENT then
		self.Emitter = ParticleEmitter(self:GetPos())
		self.ParticleDelay = 0
		
		self.Client_Velocity = Vector() --Client Prediction Stupidity
		
	end
	
	
	self.ModelSize_Min, self.ModelSize_Max = self:GetModelBounds()
end

function ENT:Think()
	local BouncerPhys = self:GetPhysicsObject()
	local Diagonal_Size = self.ModelSize_Max:Distance(self.ModelSize_Min)
	
	if SERVER then
		
		net.Start( "Client_Velocity_Prediction_Fix" , true ) --Client Prediction Stupidity
			net.WriteFloat( self:GetVelocity():Length() )
			net.WriteNormal( self:GetVelocity():GetNormalized() )
			net.WriteEntity( self )
		net.Broadcast()
		
	elseif CLIENT then
		local Root_Velocity = ( self.Client_Velocity:GetNormalized() * (self.Client_Velocity:Length()^0.5) )
		if IsValid(self.Emitter) then
			if math.random(1,10) == 1 then
				local part = self.Emitter:Add("sprites/heatwave" , self:GetPos() + (VectorRand()*1.5))
				local LocalizedColor = math.random(220, 250)
				part:SetStartSize( 5 )
				part:SetEndSize( math.random(15,25) )
				part:SetDieTime( math.Rand(0.05,0.3) )
				part:SetRoll( math.random(-360, 360) )
				part:SetRollDelta( 0.1 )
				part:SetGravity( Vector( 0 , 0 , math.random(200,1000) ) )
				
				part:SetColor(LocalizedColor,LocalizedColor,LocalizedColor)
				part:SetLighting(false)
				part:SetVelocity( (VectorRand() * math.Rand(0.1,1) * 52.49) )
			end
			
			for s=1, math.random(0.2,1.6) do
				local part = self.Emitter:Add( "effects/spark_noz" , self:GetPos() + (VectorRand()*0.25) - Root_Velocity ) -- Create a new particle at pos
				local size = math.Rand(3.5,9)
				local spark_velocity = (self.Client_Velocity * math.Rand(0.25, 0.9)) + (VectorRand()*size)
				
				if ( part ) then
					part:SetDieTime( math.Rand(0.25,0.8) )
					
					part:SetStartAlpha( 255 )
					part:SetEndAlpha( 200 )
					
					part:SetColor( 255, math.Clamp(math.random(50,145)*size,0,255), math.Clamp(math.random(8,50)*size,0,255) )
					
					part:SetGravity( Vector( 0 , 0 , -600 ) )
					part:SetVelocity( spark_velocity + (VectorRand() * spark_velocity:Length()/math.random(15,25)) )
					
					part:SetStartSize( size )
					part:SetStartLength( size*1.5 )
					part:SetEndSize( 0 )
					part:SetEndLength( 0 )
					
					part:SetBounce( math.Rand(0.1,0.5) )
					part:SetAirResistance( 1 / size )
					part:SetCollide( true )
				end
			end
		end
		
	end
end 

function ENT:Use(activator, caller)
	return false
end

function ENT:OnRemove()
	
	if CLIENT then
		if IsValid(self.Emitter) then
			self.Emitter:Finish()
		end
	end
	
end 

local vel, len

local traceData = {}
traceData.mask = bit.bor(CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_DEBRIS, CONTENTS_MONSTER, CONTENTS_HITBOX, CONTENTS_WATER)

function ENT:PhysicsCollide(data, physobj)
	timer.Simple( 0, function() 
		if IsValid(self) and IsValid(self:GetPhysicsObject()) and data.HitEntity ~= self:GetClass() then
			local owner = self.Owner or self
			local Velocity = self:GetPhysicsObject():GetVelocity():Length()
			local Entity_Hit = data.HitEntity	
			if Entity_Hit:IsNPC() or Entity_Hit:IsPlayer() then
				Entity_Hit:TakeDamage( 15+math.Clamp(Velocity/1000,0,1000000), self, owner )
			end
			
			local Position = data.HitPos
			local Collide_Dir = data.HitNormal
			
			sound.Play( Sound("central_base_material/cbmarmor_hitnone_"..math.random(1,3)..".mp3"), Position, 75, math.random(25,50), 0.5 )
			sound.Play( Sound("central_base_material/cbm_round_deform_close_"..math.random(1,3)..".mp3"), Position, 80, math.random(180,200), 0.4 )
			
			util.ScreenShake(self:GetPos(), 3, 750, 0.25, 20*52.4934)
			
			if IsValid(owner) then
				util.BlastDamage(self, owner, data.HitPos, ((Velocity/52.4934)^0.5),  (0.01 * (Velocity/52.4934) ^ 3 ) )
			end
			
			local RandomNormal = data.HitNormal + (VectorRand()/2)
			
			local effectdata = EffectData()
			effectdata:SetOrigin( Position )
			effectdata:SetAngles( -(RandomNormal+Collide_Dir):Angle() )
			effectdata:SetScale( math.Rand(0.8,1) )
			util.Effect( "MuzzleEffect", effectdata )
			
			effectdata:SetOrigin( Position )
			effectdata:SetNormal( RandomNormal + Collide_Dir )
			effectdata:SetMagnitude( ((data.OurOldVelocity:Length() / 52.4934) * self.Mass) )
			effectdata:SetRadius( self.Mass^0.1 )
			util.Effect( "regular_material_spark", effectdata, true, true)
			
			self:Remove()
			SafeRemoveEntityDelayed(self, 10)
		end
	end)

end




