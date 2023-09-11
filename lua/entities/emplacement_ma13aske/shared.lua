ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.PrintName = "MultiAnode - 13 ; Anti Spatial Knocking Emplacement"
ENT.Author = "Dog"
ENT.Information = "How to delete leechers - Use."
ENT.Spawnable = true
ENT.AdminSpawnable = false 
ENT.Category = "Pelvareign Emplacements"

ENT.Model = "models/ma13aske.mdl"
ENT.Healthed = 100

ENT.NextImpact = 0
ENT.NextCharge = 0
ENT.NextHealthWarn = 0
ENT.RollersMoving = false
ENT.RollersOn = false
ENT.PinsMoving = false
ENT.PinsOn = false
ENT.WeldedGround = nil
ENT.Shocked = false

if (SERVER) then
	util.AddNetworkString( "ShockwaveFunction" )
	util.AddNetworkString( "ma13aske_arc_client" )
end

ENT.Charge = 0 --GJ

local STATE_ARMED = 1
local STATE_UNARMED = 0

function ENT:PoseParameterFunction( Name , Level )
	local sPose = self:GetPoseParameter( Name )
	self:SetPoseParameter(sPose, Level)
end

function ENT:OnRemove()
	hook.Remove( "PostDrawTranslucentRenderables" , self )
	--hook.Remove( "FireClientArc", "ClientArcHook" )
	return true
end 

function ENT:CustomInitialize()
	
	self:SetModel(self.Model) 
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	
	self.Shocked = false
	self.NextImpact = 0
	self.NextCharge = 0
	self.NextHealthWarn = 0
	self.RollersMoving = false
	self.RollersOn = false
	self.PinsMoving = false
	self.PinsOn = false
	self.WeldedGround = nil
	
	self.Charge = 0 --GJ
	
	self.PinnedToWorld = false
	
	phys = self:GetPhysicsObject()
	
	phys:SetDragCoefficient( 0.01 )

	if phys and phys:IsValid() then
		phys:Wake()
	end
	
	spd = physenv.GetPerformanceSettings()
    spd.MaxVelocity = MaxSpeed
	
    physenv.SetPerformanceSettings(spd)
	
	for s = 1, 8 do
		self:ManipulateBoneAngles( self:LookupBone( "Roller"..s ) , Angle(0,0,0) )
	end
	
	self:ManipulateBonePosition( self:LookupBone( "FireShield" ) , Vector(0,-9,0) )
	
	self.State = STATE_UNARMED
	
	self.ChargeNoise = CreateSound( self , "main/chargehum.wav" )
	self.ChargeNoise:SetSoundLevel( 80 )
	
	self.ElectricGrounding = CreateSound( self , "main/gforce_pull.wav" )
	self.ElectricGrounding:SetSoundLevel( 120 )
	
	self:GetPhysicsObject():SetBuoyancyRatio(0)
end

function ENT:Use(activator, caller)
	
	if not self.RollersMoving and not self.RollersOn and not self.PinsMoving then
		self:EmitSound("weapons/old/open.mp3", 100, math.random(60,66))
		for s = 1, 8 do
			for i = 1, 10 do
				timer.Simple(i/10, function()
					if self:IsValid() then
						self:ManipulateBoneAngles( self:LookupBone( "Roller"..s ) , Angle(0,0,-(i*12)) )
					end
				end)
			end
		end
		self.RollersMoving = true
		self.PinsMoving = true
		for i=1, 20 do
			timer.Simple(i/10, function()
				if self:IsValid() then
					self:EmitSound("main/mechanism_borcheltick.wav", 90, 100+i)
				end
			end)
		end
		timer.Simple(2, function()
			self.RollersOn = true
			self.RollersMoving = false
			self.PinsOn = true
			self.PinsMoving = false
			for i = 1 , 8 do
				self:ManipulateBonePosition( self:LookupBone( "Pin"..i ), Vector(0,0,-20) )
			end
			for i=1,5 do
				self:EmitSound("main/airshockwave.wav", 120, math.random(120,130))
				self:EmitSound("main/bouncehit.wav", 120, math.random(120,130))
			end
		end)
		
		for i = 1, 10 do
			timer.Simple(i/10, function()
				if self:IsValid() then
					self:ManipulateBonePosition( self:LookupBone( "FireShield" ) , Vector(0,-9+(i*0.9),0) )
				end
			end)
		end
		
	elseif not self.RollersMoving and self.RollersOn and not self.PinsMoving then
		for v = 1 , 20 do
			timer.Simple(v/10, function()
				for i = 1 , 8 do
					self:ManipulateBonePosition( self:LookupBone( "Pin"..i ), Vector(0,0,-20+v) )
				end
			end)
		end
		timer.Simple(2, function()
		self:EmitSound("weapons/old/open.mp3", 100, math.random(60,66))
		for s = 1, 8 do
			for i = 1, 10 do
				timer.Simple(i/10, function()
					if self:IsValid() then
						self:ManipulateBoneAngles( self:LookupBone( "Roller"..s ) , Angle(0,0,-120+(i*12)) )
					end
				end)
			end
		end
		self.RollersMoving = true
			timer.Simple(1, function()
				self.RollersOn = false
				self.RollersMoving = false
			end)
		end)
		
	end
	
	return true
end

local vel, len, CT, CTd

function ENT:PhysicsCollide(data, physobj)
	vel = physobj:GetVelocity()
	len = vel:Length()
	
	if len > 100 then
		CT = CurTime()
		if CT > self.NextImpact then
			self.Healthed = self.Healthed - 0.1
			self:EmitSound("physics/metal/metal_grenade_impact_hard"..math.random(1,3)..".wav", 100, math.random(60,66))
			self.NextImpact = CT + 0.05
		end
	end
	
end

function ENT:PoseAnimLerpFunction( Name , InitPoserate , FinalPoserate , Seconds )
	local delay = CurTime() + Seconds
	local LerpValue = InitPoserate
	
	hook.Add( "Think", "AnimLerpFunction", function()
		if CurTime() < delay and self:IsValid() then
			local ratio = 1 - (( delay - CurTime() ) / Seconds)
			LerpValue = Lerp(ratio,InitPoserate,FinalPoserate)
			self:ManipulateBoneAngles( self:LookupBone( Name ) , Angle(0,0,LerpValue) )
		else
			LerpValue = FinalPoserate
			hook.Remove("Think","AnimLerpFunction")
		end
		
	end)
	
end

local Detection_Radius = 100 * 52.4934

function ENT:GetPoz()
	return self:GetPos()+self:GetUp()*20
end

function ENT:FragmentOrCreateERBM( Entity , Amount )
	local PhysObj = Entity:GetPhysicsObject()
	for i=1, Amount do
		local Round = ents.Create("esbm_fragmentation")
		local AngleFire = PhysObj:GetVelocity() + (VectorRand() * PhysObj:GetVelocity():Length()/10) + VectorRand()
		
		Round:SetPos( Entity:WorldSpaceCenter() + VectorRand() * 20 )
		Round:SetAngles( AngleFire:Angle() )
		Round:Spawn()
		
		local RoundPhys = Round:GetPhysicsObject()
		RoundPhys:SetVelocityInstantaneous(Round:GetForward()*math.random(1000,12000))
	end
end

function ExistentialRemoval( self , Target )
	local vPoint = Target:WorldSpaceCenter()
	self:FragmentOrCreateERBM( Target , math.random(6,10) )
	Target:Remove()
	Target:EmitSound("ambient/energy/weld2.wav", 110, math.random(40,60),1)
	Target:EmitSound("main/railexplode.wav", 120, math.random(70,73),0.8)
	for i=1,25 do
		if IsValid(Target) then 
		ParticleEffect( "SUPEREMBERHIT", vPoint , -Target:GetVelocity():GetNormalized():Angle():Up():Angle() + AngleRand()/4 )
		end
	end
	ParticleEffect( "ShockWave", vPoint , Angle() )
	self:SendShockWave(vPoint)
	local effectdata = EffectData()
	effectdata:SetOrigin( vPoint )
	effectdata:SetAngles( AngleRand() )
	effectdata:SetNormal( VectorRand() )
	effectdata:SetMagnitude( 5 )
	effectdata:SetRadius( 50 )
	util.Effect( "Sparks", effectdata)
	for i=1,40 do
		self:PlantEffect(Target,vPoint,-Target:GetVelocity():GetNormalized():Angle() + AngleRand()/2)
	end
	
end

function ENT:SendShockWave(Pos)
	local Posed = Pos or self:GetPos()

	local explosedist = 200 * 52.4934666667
	for k, v in pairs(ents.FindInSphere(Posed,explosedist)) do
		 if v:IsPlayer() then
			local Dist = ( 1 - (v:GetPos():Distance(Posed)/explosedist)^0.5 )
			local PositionCapture = Posed
			timer.Simple( ((v:GetPos():Distance(Posed)/explosedist)^0.5 ) *0.5, function() 
				local tr = {}
				tr.start = PositionCapture
				tr.endpos = v:WorldSpaceCenter()
				tr.filter = self
					
				trace = util.TraceLine(tr)
				--debugoverlay.Line( tr.start, tr.endpos, 1, Color( 255, 255, 255 ), false )
				if trace.Entity and trace.Entity == v then
				
				for i = 1, 10 do
					timer.Simple( i*0.005, function() 
						v:SetViewPunchAngles(Angle((math.random(-8,8))*(Dist)^2, (math.random(-3,3))*(Dist)^2, (math.random(-3,3))*(Dist)^2))
					end) 
				end
				
				net.Start("ShockwaveFunction")
					net.WriteFloat(Dist)
				net.Broadcast()
				
				end
				
			end)
		 end
	end

end

function ENT:FindTarget()
	local NewTarg=nil
	local Closest=Detection_Radius
	for key,found in pairs(ents.FindInSphere(self:GetPoz(),Detection_Radius))do
		local Phys=found:GetPhysicsObject()
		local Class=found:GetClass()
		if ( (IsValid(Phys) and found ~= self) or IsValid(string.match(type(found),"NPC")) ) and Class ~= "esbm_fragmentation" and Class ~= "emplacement_ma13aske" and not found:IsPlayer() then --or found:IsPlayer()
			local Dist=((found:LocalToWorld(found:OBBCenter()))-self:GetPoz()):Length()
			if(Dist<Closest)then
				NewTarg=found
				Closest=Dist
			end
		end
	end
	return NewTarg
end

function ENT:Think()
	
	if self.State == STATE_ARMED then
	self.Charge = math.Clamp(self.Charge + 1000, 0, 100000)
	if SERVER then
		self.ChargeNoise:Play()
		self.ChargeNoise:ChangePitch(80+((self.Charge/100000)*120))
		self.ChargeNoise:ChangeVolume(1-(self.Charge/100000))
	end
		if CurTime() > self.NextCharge then
			local Target = self:FindTarget()
				if IsValid(Target) and not Target:IsFlagSet(FL_DISSOLVING) and self.Shocked == false and SERVER then -- or Target:IsPlayer()
					local Dist = 1 - (Target:GetPos():Distance(self:GetPos()) / Detection_Radius)
					if Dist < 0.6 then return end
					local Phys = Target:GetPhysicsObject()
					local Vel = (Phys:GetVelocity()-self:GetPhysicsObject():GetVelocity())
					local Spd = Vel:Length()
					local CanBeTarget = (string.match(type(Target),"Entity") ~= nil or string.match(type(Target),"NPC") ~= nil)
					local TargetVelocityHighSpeed = Spd > (52.4934*1)
					local TargetVelocityLowSpeed = Spd > (52.4934*0.25) 
					if not Phys then return end
					if not SERVER then return end
					if TargetVelocityLowSpeed and not TargetVelocityHighSpeed and CanBeTarget then
						self:EmitSound("main/mechanism_borcheltick.wav", 90, 200)
						self:EmitSound("main/target_tick.wav", 90, 100*((Spd/52.4934)*4))
					elseif self.Charge > 10000 and TargetVelocityHighSpeed and CanBeTarget then
						local AttackerDirectionized = (Target:GetPos() - self:GetPos()):GetNormalized()
						local TargetDirect = Vector()
						TargetDirect = AttackerDirectionized * ((52.4934*3)*math.random(10,100)/100)
						if SERVER then
							net.Start("ma13aske_arc_client")
								net.WriteEntity(self)
								net.WriteVector(TargetDirect) 
								net.WriteEntity(Target)
								net.WriteFloat(Dist*30)
							net.Broadcast()
						end
						
						local daginfo = DamageInfo()
						local dmg_random = math.random(2000000,3000000000) 
						daginfo:SetDamage( dmg_random * (1-Dist) )
						daginfo:SetAttacker( self )
						daginfo:SetDamageType( DMG_DIRECT ) 
						daginfo:SetDamagePosition( Target:WorldSpaceCenter() )
						daginfo:SetDamageForce( (game.GetWorld():GetUp()+VectorRand()) * Phys:GetMass() * math.random(50,1000) )
						
						if dmg_random > Phys:GetMass() then 
							local vPoint = Target:WorldSpaceCenter()
							Target:AddFlags( FL_DISSOLVING ) 
							Target:SetColor( Color(0,0,0) )
							Target:SetShouldServerRagdoll( true )
							hook.Add( "CreateEntityRagdoll", "ErasureOfCorpse", function( entity, ragdoll )
								if tostring(entity) == tostring(Target) then
									local Physed = ragdoll:GetPhysicsObject()
									Physed:SetVelocity( VectorRand() * Physed:GetMass() * 2000 )
									timer.Simple(1, function() 
										if IsValid(ragdoll) then 
											ExistentialRemoval( self , ragdoll )
										end
									end)
								end
								timer.Simple(1, function() 
									hook.Remove( "CreateEntityRagdoll" , "ErasureOfCorpse" )
								end)
							end)
							
							for v=1,10 do
								timer.Simple(v/math.random(2,7), function()
									if IsValid(Target) then 
										if math.random(1,10) > 9 then
											self:FragmentOrCreateERBM( Target , 1 )
										end
										local Physed = Target:GetPhysicsObject()
										Target:EmitSound("ambient/energy/weld2.wav", 120, math.random(90,120),1)
										Target:EmitSound("main/tesladischarge0"..math.random(1,5)..".wav", 90, math.random(240,250))
										local effectdata = EffectData()
										effectdata:SetOrigin( Target:WorldSpaceCenter() )
										effectdata:SetAngles( Angle() )
										effectdata:SetNormal( game.GetWorld():GetUp() )
										effectdata:SetMagnitude( 5 )
										effectdata:SetRadius( 2 )
										util.Effect( "Sparks", effectdata)
										
										local tr = {}
										tr.start = Target:WorldSpaceCenter() 
										tr.endpos = tr.start + (VectorRand() * (math.random(6,12)*52.4934))
										tr.filter = Target
										local trace = util.TraceLine(tr)
										local TracePlusNormal = trace.HitPos + (trace.HitNormal * 2)
										
										net.Start("ma13aske_arc_client")
											net.WriteEntity(Target)
											net.WriteVector(TracePlusNormal - self:WorldSpaceCenter()) 
											net.WriteEntity(nil)
											net.WriteFloat(math.random(1,10))
										net.Broadcast()
										
										local effectdata2 = EffectData()
										effectdata2:SetOrigin( TracePlusNormal )
										effectdata2:SetAngles( Angle() )
										effectdata2:SetNormal( game.GetWorld():GetUp() )
										effectdata2:SetMagnitude( 2 )
										effectdata2:SetRadius( 5 )
										util.Effect( "Sparks", effectdata2)
										
										Physed:SetVelocity( Physed:GetVelocity() + ((TracePlusNormal-Target:WorldSpaceCenter()):GetNormalized() * (math.random(16,24)*52.4934)) )
										ParticleEffect( "Flashed", TracePlusNormal , AngleRand() )
										
									end
								end)
							end
							
							timer.Simple(math.random(2,2.5), function() 
								if IsValid(Target) then 
									ExistentialRemoval( self , Target )
									hook.Remove( "CreateEntityRagdoll" , "ErasureOfCorpse" )
								end
							end)
							
							Phys:SetVelocity(Phys:GetVelocity()*3)
							local effectdata = EffectData()
							effectdata:SetOrigin( vPoint )
							effectdata:SetAngles( AngleRand() )
							effectdata:SetNormal( game.GetWorld():GetUp() )
							effectdata:SetMagnitude( 5 )
							effectdata:SetRadius( 5 )
							ParticleEffect( "SUPEREMBERHIT", vPoint , AngleRand() )
							util.Effect( "Sparks", effectdata)
						end
						
						self:SendShockWave()
						
						util.ScreenShake(Target:WorldSpaceCenter(),120,2,0.1,1500)
						
						Target:EmitSound("main/roundhit_softmatter_"..math.random(1,9)..".wav", 80, math.random(140,150),1)
						Target:EmitSound("main/bouncehit.wav", 80, math.random(80,90),1)
						Target:EmitSound("main/incendiarysizzle", 100, math.random(120,130),1)
						
						self.Shocked = true
						hook.Run( "ServerDmgTarget", self , Target , daginfo , dmg_random )
						
						self.Charge = self.Charge - (49999 * (1-Dist)) + 1
						
						self:EmitSound("main/antispatialknock_highsavor.wav", 100, math.random(190,200))
						self:EmitSound("main/tesladischarge0"..math.random(1,5)..".wav", 90, math.random(240,250))
						
					end
				end
			self.NextCharge = CurTime() + 0.1
			self.Shocked = false
		end
	end
	
	if self:GetManipulateBonePosition( self:LookupBone( "Pin1" ) ) == Vector(0,0,-20) and not self.PinnedToWorld then
		local tr = {}
		tr.start = self:WorldSpaceCenter()
		tr.endpos = tr.start - self:GetUp() * 50
		tr.filter = self
		local trace = util.TraceLine(tr)
		
		self.PinnedToWorld = true
		self.State = STATE_ARMED
		if SERVER and (trace.HitWorld or IsValid(trace.Entity)) then 
			if trace.HitWorld then
				self.WeldedGround = constraint.Weld( self, game.GetWorld(), 0, 0, 0, false, false ) 
			elseif trace.Entity then
				self.WeldedGround = constraint.Weld( self, trace.Entity, 0, 0, 0, false, false ) 
			end
		end
	elseif self:GetManipulateBonePosition( self:LookupBone( "Pin1" ) ) == Vector(0,0,0) and self.PinnedToWorld then
		self.PinnedToWorld = false
		self.State = STATE_UNARMED
		if SERVER and self.WeldedGround then 
			self.WeldedGround:Remove()
		end
	end
		
	
		
	self:NextThink( CurTime() + 0.01 )
    return true
end
