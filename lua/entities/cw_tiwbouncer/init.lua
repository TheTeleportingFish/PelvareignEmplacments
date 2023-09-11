AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.BlastDamage = 30
ENT.BlastRadius = 590.55*2
ENT.BlastDamage2 = 15000
ENT.BlastRadius2 = (590.55/2)
ENT.Mass = 80
ENT.Timer = CurTime() + 0.3

function ENT:Initialize()

	self:SetModel("models/Items/AR2_Grenade.mdl") 
	self:SetModelScale( 1, 0 )
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
	local trail = util.SpriteTrail( self, 0, Color( 255, 140, 100 ), false, 130, 0, 0.1, 120, "trails/laser" )
end

function ENT:Think()


	local BouncerPhys = self:GetPhysicsObject()
		BouncerPhys:AddVelocity(Vector(math.random(-80,80),math.random(-80,80),-40))	
	
		if CurTime() > self.Timer then
		ParticleEffect( "DirtExplodeHit", self:GetPos() , self:GetAngles())
		sound.Play( Sound("weapons/13mmtiw/railfailure_0"..math.random(1,3)..".wav"), self:GetPos(), 100, math.random(90,120), 0.9 )
		BouncerPhys:AddVelocity(self:GetForward()*math.random(10,math.random(20,math.random(30,2000))))	
		self.Timer = CurTime() + math.random(5,80)/100
		end
		
		
			

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
	
	for i = 1, math.random(1,math.random(2,5)) do
		local AngleFired = AngleRand()
		ParticleEffect( "SUPEREMBERHIT", self:GetPos() , AngleFired:Up():Angle() )
		
		if SERVER then
			
			local Bouncer = ents.Create("cw_tiwbouncer_fragments")
			Bouncer:SetPos(self:GetPos() + VectorRand()* math.random(-3,3)/10)
			Bouncer:SetAngles(AngleFired)
			Bouncer:SetOwner( self.Owner )
			Bouncer:Spawn()
			
			
			local BouncerPhys = Bouncer:GetPhysicsObject()
			BouncerPhys:SetVelocityInstantaneous((Vector(math.random(-1800,1800),math.random(-1800,1800),0)+(VectorRand() * math.random(5,500)))-((Velocity*2)+data.HitNormal * math.random(50,math.random(100,15000))))
			
			local maxx = math.random(1,20)/10
			local minn = math.random(-1,-20)/10
			BouncerPhys:AddAngleVelocity( Vector(math.random(minn,maxx),math.random(minn,maxx),math.random(minn,maxx)) )
			
		end
		
	end
	
	util.ScreenShake(self:GetPos(), 9, 0.2, 0.8, 1000) 
	
	local poititi = self:GetPos()
	sound.Play( Sound("high_energy_systems/caterousshrapnelbounce.mp3"), poititi, 100, 100,0.8)
	sound.Play( Sound("main/airshock.wav"), poititi, 400, 60, 0.9 )
	sound.Play( Sound("weapons/13mmtiw/electricexplose.wav"), poititi, 400, 60, 1 )
		
		
	local SoundDistanceMax = 20000
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
					[1] = self
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
					
					local isplayer = ent:IsPlayer()
					local isnpc = ent:IsNPC()
					local equal = ent == v
					
					if (isplayer) and equal  then
					
						local hitDistance = SoundDistanceMax * fract
						local isMaxIntensity = (hitDistance - MaxIntensityDistance) < 0
						local decay = (SoundDistanceMax - MaxIntensityDistance)/3
						local intensity = 0
						--print(hitDistance)
						
						if isMaxIntensity then
							intensity = 1
						else
							local decayDistance = hitDistance - MaxIntensityDistance
							intensity = 1 - decayDistance / decay
						end
						
						intensity = math.min((intensity + 0.25) , 1)
						
						local duration = intensity * FlashDuration
						
						end
						
						if (isplayer or isnpc) and equal  then
							if intensity != nil then
								if intensity > 0.6 then
								ent:TakeDamage( 50*(((intensity)-0.6)*10), game.GetWorld(), game.GetWorld() )
								elseif intensity > 0.9 then
								ent:TakeDamage( 15000*(((intensity)-0.9)*10), game.GetWorld(), game.GetWorld() )
								end
							end
						end
						
				timer.Simple( Time*0.5, function() 
					
					if (isplayer) then
						v:EmitSound( "high_energy_systems/caterousshrapnelbouncefar.mp3", 75, 100, Dist*6, CHAN_AUTO ) 
						v:EmitSound( "main/airshock.wav", 75, 50, Dist/17, CHAN_AUTO ) 
						v:EmitSound( "weapons/13mmtiw/electricexplose.wav", 75, math.random(70,110), Dist/6, CHAN_AUTO )
						if equal then
							v:EmitSound( "main/airshockwave.wav", 75, 90, Dist, CHAN_AUTO ) 
						end
						
						if SmallDist > 0 then 
							v:EmitSound( "high_energy_systems/caterousshrapnelbounce.mp3", 75, 100, SmallDist/15, CHAN_AUTO )
							v:EmitSound( "weapons/13mmtiw/electricexplose.wav", 75, math.random(95,105), SmallDist/2, CHAN_AUTO )
							if equal then
								v:EmitSound( "main/airshock.wav", 75, 100, SmallDist/5, CHAN_AUTO ) 
								v:EmitSound( "main/airshockwave.wav", 75, 40, SmallDist, CHAN_AUTO )
							end
						end
						
					end
					
				end)
			end
		end
	end
	
	for i = 1, 6 do
		if math.random(1,6) == 1 then
			ParticleEffect( "SUPEREMBERHIT", self:GetPos() , Angle(math.random(0,360),math.random(0,360),math.random(0,360)) )
		end
		ParticleEffect( "Flashed", self:GetPos() , Angle(0,0,0) )
	end
	
	ParticleEffect( "ShockWave", self:GetPos() , Angle(math.random(0,360),math.random(0,360),math.random(0,360)))
	ParticleEffect( "APFSDSSCREEN", self:GetPos() , Angle(0,0,0) )
	
	if math.random(1,3) == 1 then
		ParticleEffect( "SmokeShockFar", self:GetPos() , Angle(math.random(0,360),math.random(0,360),math.random(0,360)))
	end
	
	self:Remove()
	SafeRemoveEntityDelayed(self, 10)
	
end)

end
