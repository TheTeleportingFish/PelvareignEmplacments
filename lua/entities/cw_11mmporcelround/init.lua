AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.BlastDamage = 30
ENT.BlastRadius = 590.55
ENT.BlastDamage2 = 15000
ENT.BlastRadius2 = (590.55/3)
ENT.Mass = 120

function ENT:CreateBouncer(position)
	
	local SoundDistanceMax = 20000

	for i = 1, math.random(1,math.random(11,32)) do
		if SERVER then
			Bouncer = ents.Create("cw_11mmporcelbouncer")
		end
		AngleFire = (((math.random(860,960)/1000)*self.Owner:EyeAngles():Forward())+ ((math.random(100,300)/1000)*self.Owner:EyeAngles():Up()) + ((math.random(-500,500)/5000)*self.Owner:EyeAngles():Right())):Angle()
		ParticleEffect( "Flashed", position , AngleFire )
			
		if SERVER then
			Bouncer:SetPos(position+self.Owner:EyeAngles():Up()*25)
			Bouncer:SetAngles(AngleFire)
			Bouncer:SetOwner( self.Owner )
			Bouncer:Spawn()
			
			local BouncerPhys = Bouncer:GetPhysicsObject()
			BouncerPhys:SetVelocityInstantaneous(Bouncer:GetForward()*math.random(1000,10000))
			
			local maxx = math.random(1,20)/10
			local minn = math.random(-1,-20)/10
			BouncerPhys:AddAngleVelocity( Vector(math.random(minn,maxx),math.random(minn,maxx),math.random(minn,maxx)) )
			
		end
	end
	
	timer.Simple( 0.1, function() 
			sound.Play( Sound("main/cbmbounce1.wav"), position, 110, math.random(80,110),0.6)		
	end)
	
	for k, v in pairs(ents.FindInSphere(position,SoundDistanceMax)) do
		if v:IsPlayer() then
			if v then
				local Dist = ( 1 - (v:GetPos():Distance(position)/SoundDistanceMax) )
				
				timer.Simple( 0.2, function() 
					if CLIENT then
						v:EmitSound( "main/cbmbounce1far.wav", 75, 100, Dist, CHAN_AUTO ) 			
					end
				end)
				
			end
		end
	end
	
	if SERVER then
		util.ScreenShake( position, 9, 600, 0.5, 500 )
	end

end

function ENT:Initialize()

	self:SetModel("models/Items/AR2_Grenade.mdl") 
	self:SetModelScale( 0.275, 0 )
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE)
	self:SetMoveCollide( MOVECOLLIDE_DEFAULT )

	local phys = self:GetPhysicsObject()
	
	if (self:GetTargeted() != nil ) and (self:GetTargeted():IsNPC() or self:GetTargeted():IsPlayer())then
	self.CurrentDist = phys:GetPos():Distance(self:GetTargeted():WorldSpaceCenter())
	self.Lowest = self.CurrentDist
	end
	
	
	self:SetLagCompensated( true )
	if phys and phys:IsValid() then
		phys:Wake()
		phys:SetMass( self.Mass )
		
	end
	
	self:EmitSound( Sound("EMRP") )
	self:GetPhysicsObject():SetBuoyancyRatio(0)


	spd = physenv.GetPerformanceSettings()
    spd.MaxVelocity = 80000
	
    physenv.SetPerformanceSettings(spd)
	local trail = util.SpriteTrail( self, 0, Color( 255, 120, 120 ), true, 20, 0, 0.2, 0.8, "trails/laser" )
	
end

function ENT:Think()
	local RoundPhys = self:GetPhysicsObject()
	local Targeted = self:GetTargeted()
	--print(Targeted)
	if (Targeted != nil) and (Targeted:IsNPC() or Targeted:IsPlayer()) then
		if self.CurrentDist <= self.Lowest then
			if self:GetPhysicsObject() != nil then
				local SteerForce = 2000
				local AutoDistance = self.Owner:WorldSpaceCenter():Distance(self:GetTargeted():WorldSpaceCenter())
				local TriggerDistance = AutoDistance - 200
				local MaxTurnDistance = 500
				local MagnitudeVelocity = Vector( math.abs(self:GetTargeted():GetVelocity().x) ^ 0.5 , math.abs(self:GetTargeted():GetVelocity().y) ^ 0.5 , math.abs(self:GetTargeted():GetVelocity().z) ^ 0.5 )
				local MoveVector = ( RoundPhys:GetPos() - ( self:GetTargeted():WorldSpaceCenter() + ( MagnitudeVelocity * self:GetTargeted():GetVelocity():GetNormalized() ) )):GetNormalized() * -SteerForce
				local MoveVectorNormalized = MoveVector - (self:GetForward() * SteerForce/1.05)
				local TurnCalc = 1 - math.Clamp( (self.CurrentDist-MaxTurnDistance)/(TriggerDistance) , 0 , 1 )
				if self.CurrentDist < TriggerDistance then
					RoundPhys:AddVelocity( MoveVectorNormalized * TurnCalc )	
				end
				--print(TurnCalc)
			end
			self.Lowest = self.CurrentDist
			self.CurrentDist = RoundPhys:GetPos():Distance(self:GetTargeted():WorldSpaceCenter())
		else
		--print("fucked")
		end
		--print(self.Lowest)
		--print(self.CurrentDist)
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

function ENT:OnRemove()
	self:StopSound("EMRP")
	return false
end 

local vel, len

local traceData = {}
traceData.mask = bit.bor(CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_DEBRIS, CONTENTS_MONSTER, CONTENTS_HITBOX, CONTENTS_WATER)

function ENT:PhysicsCollide(data, physobj)
timer.Simple( 0, function() 
	local Velocity = self:GetPhysicsObject():GetVelocity()
	local position = self:GetPos()
	
	ParticleEffect( "GroundCloudLarge", position , data.HitNormal:Angle():Up():Angle() )
	ParticleEffect( "GroundCloud", position , data.HitNormal:Angle():Up():Angle() )
	sound.Play( Sound("CW_HEI_Explose"), position )
	
	if data.HitEntity == self.Owner then
	return false
	end
	
	--print(data.HitEntity)
	
	if ( data.HitEntity:IsNPC() or data.HitEntity:IsPlayer() or string.match(tostring(data.HitEntity),"npc*") or string.match(tostring(data.HitEntity),"phys*") ) and data.HitEntity:IsValid() then

	--ParticleEffect( "GroundCloudLarge", position , (self.Owner:GetPos() - position):Angle() )

	local EntityToSlam = data.HitEntity
	local ExplodeRadius = 20
	local ExplodeDamage = 1000
	
	if string.match(tostring(EntityToSlam),"phys*")  then 
		for k, v in pairs(ents.FindInSphere(data.HitPos,200)) do
			if string.match(tostring(v),"npc*") then
				if v:IsNPC() and v:IsValid() then
					EntityToSlam = v
					--print(EntityToSlam)
				end
			end
		end
	end
	
	if SERVER then
		if EntityToSlam:IsValid() then
	
	if string.match(tostring(EntityToSlam),"npc_turret_floor") and EntityToSlam:IsNPC() then
	--print("dmg turret")
	EntityToSlam:Fire("SelfDestruct")
	elseif string.match(tostring(EntityToSlam),"npc_helicopter") and EntityToSlam:IsNPC() then
	--print("dmg heli")
	EntityToSlam:Fire("Break")
	end

			local d = DamageInfo()
			d:SetDamage( 1000 )
			d:SetAttacker( game.GetWorld() )
			d:SetDamageType( DMG_DISSOLVE )
			EntityToSlam:TakeDamageInfo( d )
			--EntityToSlam:Ignite(20)
			EntityToSlam:TakeDamage( 10000, game.GetWorld(), game.GetWorld() )

			
			for i = 1, 5 do
			ParticleEffect( "Flashed", self:GetPos() , Angle(0,0,0) )
			ParticleEffect( "HEISPARKDEBRIS", self:GetPos() , self:GetAngles():Forward():Angle() + ((VectorRand()):Angle()/5) )
			end
			--util.BlastDamage(game.GetWorld(), game.GetWorld(), EntityToSlam:GetPos(), ExplodeRadius, ExplodeDamage)
			end
		end
	
	EntityToSlam:EmitSound("player/pain.wav", 130, math.random(60,90))
	
	sound.Play( Sound("main/roundhit_softmatter_"..math.random(1,9)..".wav"), position, math.random(80,120), 100, 0.9 )
	
		local poititi = self:GetPos()
		
		for i=1, 100 do
			util.ScreenShake(self:GetPos(), 50, 0.0001, 0.1, 1000) 
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
							
								v:EmitSound( "main/roundhit_softmatter_"..math.random(1,9)..".wav", 30, 100, SmallDist, CHAN_AUTO ) 
								
								if equal then
									v:EmitSound( "main/roundhit_softmatter_"..math.random(1,9)..".wav", 30, 100, SmallDist, CHAN_AUTO ) 
									for i = 1, 5 do
										timer.Simple( i*0.01, function() 
											v:SetViewPunchAngles(Angle((math.random(-5,5)/50)*(SmallDist+1)^5, (math.random(-5,5)/50)*(SmallDist+1)^5, (math.random(-5,5)/50)*(SmallDist+1)^5))
										end) 
									end

								end
							else
								--v:EmitSound( "main/rigidpeircefar.wav", 75, math.random(70,80), Dist, CHAN_AUTO )
								--v:EmitSound( "main/airshock.wav", 30, 50, Dist/120, CHAN_AUTO ) 
								
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
			
	else
	
		if math.random(1,1) == 1 then
			self:CreateBouncer(position)
		end
	
	end

		self:Remove()

		SafeRemoveEntityDelayed(self, 10)
		
end)

end
