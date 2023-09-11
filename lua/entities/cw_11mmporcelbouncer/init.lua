AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Mass = 80
ENT.Timer = CurTime() + 0.1

function ENT:Initialize()

	self:SetModel("models/Items/AR2_Grenade.mdl") 
	self:SetModelScale( 0.1, 0 )
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	local phys = self:GetPhysicsObject()

	if phys and phys:IsValid() then
		phys:Wake()
		phys:SetMass( self.Mass )
		
	end
	
	self:GetPhysicsObject():SetBuoyancyRatio(0)
	self.ArmTime = CurTime() 
	
	spd = physenv.GetPerformanceSettings()
    spd.MaxVelocity = 30000
	
    physenv.SetPerformanceSettings(spd)
	local trail = util.SpriteTrail( self, 0, Color( 255, 140, 100 ), false, 30, 0, 1.4, 120, "trails/laser" )
end

function ENT:Think()


	local BouncerPhys = self:GetPhysicsObject()
		BouncerPhys:AddVelocity(Vector(math.random(-80,80),math.random(-80,80),-40))	
	
		if CurTime() > self.Timer then
		ParticleEffect( "cstm_child_incendiary_hit6", self:GetPos() , self:GetAngles())
		sound.Play( Sound("weapons/13mmtiw/railfailure_0"..math.random(1,3)..".wav"), self:GetPos(), 100, math.random(90,120), 0.9 )
		BouncerPhys:AddVelocity( VectorRand() * 200)	
		self.Timer = CurTime()
		end
		
		
			

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
	return false
end 

local vel, len

local traceData = {}
traceData.mask = bit.bor(CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_DEBRIS, CONTENTS_MONSTER, CONTENTS_HITBOX, CONTENTS_WATER)

function ENT:PhysicsCollide(data, physobj)
timer.Simple( 0, function() 
local Velocity = self:GetPhysicsObject():GetVelocity()
	
	if data.HitEntity:IsPlayer() or data.HitEntity:IsNPC() then
		data.HitEntity:EmitSound("player/pain.wav", 130, math.random(60,90))
		sound.Play( Sound("main/roundhit_softmatter_"..math.random(1,9)..".wav"), data.HitPos, math.random(80,120), 100, 0.9 )
		local d = DamageInfo()
			d:SetDamage( 1000 )
			d:SetAttacker( game.GetWorld() )
			d:SetDamageType( DMG_DISSOLVE )
			data.HitEntity:TakeDamageInfo( d )
			data.HitEntity:Ignite(2)
			data.HitEntity:TakeDamage( 300, self.Owner, self )
	end
	
	if math.random(1,2) == 1 then
	
		util.ScreenShake(self:GetPos(), 50, 0.0001, 0.1, 1000) 
			
		local poititi = self:GetPos()
			
			if SERVER then
				sound.Play( Sound("main/caterousshrapnelbounce.wav"), poititi, 300, 100,0.8)
				sound.Play( Sound("weapons/13mmtiw/electricexplose.wav"), poititi, 400, 60, 1 )
			end
			
			local SoundDistanceMax = 10000
			for k, v in pairs(ents.FindInSphere(self:GetPos(),SoundDistanceMax)) do
				if v:IsPlayer() or v:IsNPC()  then
					if v then
					
					obj = v
					
					local Dist = ( 1 - (v:GetPos():Distance(self:GetPos())/SoundDistanceMax) )
					local SmallDist = ( 1 - (v:GetPos():Distance(self:GetPos())/SoundDistanceMax*2) )
					local Time = ( (v:GetPos():Distance(self:GetPos())/8000) )
					
						MaxIntensityDistance = 100 -- if an entity is THIS close to the grenade upon explosion, the intensity of the flashbang will be maximum
						FlashDuration = 0.1
						
						local table1 = {
						[1] = Bouncer,
						[2] = self
						}
						
						traceData.filter = table1
						
						local positedplayer = v:WorldSpaceCenter()
						
						direction = (positedplayer - (poititi + data.HitNormal:Angle():Forward()*-100)):GetNormal()
						
						traceData.start = poititi + data.HitNormal:Angle():Forward()*-100
						traceData.endpos = traceData.start + direction * SoundDistanceMax
						
						debugoverlay.Box( traceData.start, Vector(-10,-10,-10), Vector(10,10,10), 3.5, Color( 255, 255, 255 ) )
						debugoverlay.Line( traceData.start, traceData.endpos, 3.5, Color( 255, 255, 255 ), false )
						
						local trace = util.TraceLine(traceData)
						ent = trace.Entity
						fract = trace.Fraction
						--print(ent)
						--print(v)
						local isplayer = ent:IsPlayer()
						local isnpc = ent:IsNPC()
						local equal = ent == v
						--print("Is it equal - " .. tostring(equal))
						--print("Is it a player - " .. tostring(isplayer))
						--print("Is it a npc - " .. tostring(isnpc))
						

					timer.Simple( Time*0.5, function() 
						if (isplayer) then
							
							if SmallDist > 0 then 
								
									v:EmitSound( "main/caterousshrapnelbounce.wav", 75, 100, Dist, CHAN_AUTO )
									v:EmitSound( "weapons/13mmtiw/electricexplose.wav", 75, 60, Dist/2, CHAN_AUTO )
									
								if equal then
									
									for i = 1, 5 do
										timer.Simple( i*0.01, function() 
											v:SetViewPunchAngles(Angle((math.random(-5,5)/50)*(SmallDist+1)^5, (math.random(-5,5)/50)*(SmallDist+1)^5, (math.random(-5,5)/50)*(SmallDist+1)^5))
										end) 
									end

								end
							else
								v:EmitSound( "main/caterousshrapnelbounce.wav", 75, 100, Dist/2, CHAN_AUTO )
								v:EmitSound( "weapons/13mmtiw/electricexplose.wav", 75, 60, Dist/5, CHAN_AUTO )
								
								if equal then
									--v:EmitSound( "main/airshockwave.wav", 75, 90, Dist/20, CHAN_AUTO ) 
									for i = 1, 5 do
										timer.Simple( i*0.01, function() 
											v:SetViewPunchAngles(Angle(math.random(-1,1)*Dist, math.random(-1,1)*Dist, math.random(-1,1)*Dist))
										end) 
									end
								end
								
							end
							
						end
					end)
					
				end
			end
			end
			
			
			
			ParticleEffect( "SUPEREMBERHIT", self:GetPos() , Angle(math.random(0,360),math.random(0,360),math.random(0,360)) )
			--ParticleEffect( "Flashed", self:GetPos() , Angle(0,0,0) )
			--ParticleEffect( "SmokeShockFar", self:GetPos() , Angle(math.random(0,360),math.random(0,360),math.random(0,360)))
			
		end
		self:Remove()

		SafeRemoveEntityDelayed(self, 10)
		
end)

end
