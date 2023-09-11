ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.PrintName = "ESBM Fragmentation Device"
ENT.Author = "Dog"
ENT.Information = "How to delete leechers - Use."
ENT.Spawnable = true
ENT.AdminSpawnable = false 
ENT.Category = "Pelvareign Emplacements"

ENT.Model = "models/props_junk/plasticbucket001a.mdl"
ENT.Healthed = 100

local STATE_ARMED = 1
local STATE_UNARMED = 0

function ENT:SetupDataTables()
	self.NextImpact = 0
	self.NextCharge = 0
	self.RollersMoving = false
	self.RollersOn = false
	self.PinsMoving = false
	self.PinsOn = false
	self.WeldedGround = nil
	self.Tracing = nil
	self.Shocked = false
	self.AttachedToGround = false
	self.State =  STATE_UNARMED
end

if SERVER then
	ENT.PlrGrabbing = nil
end

if (SERVER) then
	util.AddNetworkString( "ShockwaveFunction" )
	util.AddNetworkString( "CLIENT_TOGGLE" )
end

function ENT:OnRemove()
	hook.Remove( "PostDrawTranslucentRenderables", self )
	return true
end 

local phys, ef

function TableEntityCheckAndRemove( Table )
	if table.Count( Table ) < 1 then return end
	for Index, v in pairs(Table) do
		if not v:IsValid() then 
			table.remove(Table,Index)
		end
	end
end

-- net.Start("ShockwaveFunction")
-- net.WriteFloat(Dist)
-- net.Broadcast()

local traceData = {}
traceData.mask = bit.bor(CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_DEBRIS, CONTENTS_MONSTER, CONTENTS_HITBOX, CONTENTS_WATER)

function ENT:PlantEffect(entity,pos,direction)
	local Bellit={
		Attacker=entity,
		Damage=15,
		Force=2000,
		Num=1,
		Tracer=0,
		Dir=direction,
		Spread=Vector(0,0,0),
		Src=pos
	}
	entity:FireBullets(Bellit)
end

function DamageTarget( self , Target , DmgInfo , dmg_random )
	if IsValid(Target) then
		if(Target:IsNPC())then
			Target:Fire("sethealth","2",0)
			Target:Fire("respondtoexplodechirp","",0.5)
			Target:Fire("selfdestruct","",1)
			Target:Fire("disarm"," ",0)
			Target:Fire("explode","",0)
			Target:Fire("gunoff","",0)
			Target:Fire("settimer","0",0)
		end
		util.BlastDamage(self,self,Target:WorldSpaceCenter(),12,dmg_random/4)
		Target:Ignite(5,0)
		Target:TakeDamageInfo( DmgInfo )
	end
end

function ENT:CustomInitialize()
	game.AddParticles( "particles/heibullet_explosion.pcf" )
	PrecacheParticleSystem( "DirtFireballHit" )
	PrecacheParticleSystem( "Flashed" )
	PrecacheParticleSystem( "DirtDebrisShock" )
	
	self:SetModel(self.Model) 
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	
	phys = self:GetPhysicsObject()
	
	phys:SetDragCoefficient( 0.01 )

	if phys and phys:IsValid() then
		phys:Wake()
	end
	
	spd = physenv.GetPerformanceSettings()
    spd.MaxVelocity = MaxSpeed
	
    physenv.SetPerformanceSettings(spd)
	
	self.State = STATE_UNARMED
	
	self:GetPhysicsObject():SetBuoyancyRatio(0)
end

net.Receive( "CLIENT_TOGGLE", function()
	local self = net.ReadEntity()
	local bool = net.ReadBool()
	local activator = net.ReadEntity()
	
	if bool then
		local TimerFast = (activator:KeyDown( IN_WALK ) and 0) or 1
		self.RollersMoving = true
		self.PinsMoving = true
		self:EmitSound("buttons/button24.wav", 80, math.random(60,65))
		timer.Simple(0.25*TimerFast, function()
			self:EmitSound("physics/metal/metal_box_impact_bullet"..math.random(1,3)..".wav", 100, math.random(60,66))
			self.RollersOn = true
			self.RollersMoving = false
			self.PinsOn = true
			self.PinsMoving = false
		end)
		
	else
		self.RollersMoving = true
		self.PinsMoving = true
		self:EmitSound("buttons/button24.wav", 80, math.random(80,85))
		timer.Simple(0.25, function()
			self:EmitSound("physics/metal/metal_box_impact_bullet"..math.random(1,3)..".wav", 100, math.random(90,100))
			self.RollersOn = false
			self.RollersMoving = false
			self.PinsOn = false
			self.PinsMoving = false
		end)
		
	end

end)



local Ctx, Toggle = 0, false

function ENT:Use(activator, caller)
	
	if (CurTime() > Ctx) then Ctx = CurTime() + 0.5 if not activator:KeyDown( IN_WALK ) then Toggle = not Toggle end else return false end
	
	if Toggle then
		self:SetAngles( self:AlignAngles( self:GetAngles():Up():Angle() , (-activator:EyeAngles():Forward()):Angle() ) )
	else
		self:SetAngles( self:AlignAngles( self:GetAngles() , game.GetWorld():GetForward():Angle() ) )
	end
	
	if not activator:KeyDown( IN_WALK ) then 
		activator:PickupObject( self ) 
		self.PlrGrabbing = activator
		return false 
	end
	
	if not self.RollersMoving and not self.RollersOn and not self.PinsMoving then
		net.Start("CLIENT_TOGGLE")
			net.WriteEntity( self )
			net.WriteBool( true )
			net.WriteEntity( activator )
		net.Broadcast()
		
		self.RollersMoving = true
		self.PinsMoving = true
		self:EmitSound("buttons/button24.wav", 80, math.random(60,65))
		timer.Simple(0.25*(activator:KeyDown( IN_WALK ) and 0), function()
			self:EmitSound("physics/metal/metal_box_impact_bullet"..math.random(1,3)..".wav", 100, math.random(60,66))
			self.RollersOn = true
			self.RollersMoving = false
			self.PinsOn = true
			self.PinsMoving = false
			self.State = STATE_ARMED
		end)
		
	elseif not self.RollersMoving and self.RollersOn and not self.PinsMoving then
		net.Start("CLIENT_TOGGLE")
			net.WriteEntity( self )
			net.WriteBool( false )
			net.WriteEntity( activator )
		net.Broadcast()
		
		self.RollersMoving = true
		self.PinsMoving = true
		self:EmitSound("buttons/button24.wav", 80, math.random(80,85))
		timer.Simple(0.25, function()
			self:EmitSound("physics/metal/metal_box_impact_bullet"..math.random(1,3)..".wav", 100, math.random(90,100))
			self.RollersOn = false
			self.RollersMoving = false
			self.PinsOn = false
			self.PinsMoving = false
			self.State = STATE_UNARMED
		end)
		
	end
	
	self.PlrGrabbing = nil
	
	return true
end

local vel, velLen, CT, CTd

function ENT:PhysicsCollide(data, physobj)
	vel = physobj:GetVelocity()
	velLen = vel:Length()
	
	if velLen > 100 then
		CT = CurTime()
		if CT > self.NextImpact then
			
			if velLen < 1000 then
				self:EmitSound("physics/metal/metal_sheet_impact_hard"..math.random(6,8)..".wav", 75, math.random(60,66))
			else
				self:EmitSound("physics/metal/metal_box_impact_hard"..math.random(1,3)..".wav", 90, math.random(80,85))
				
				local effectdata = EffectData()
				effectdata:SetOrigin( data.HitPos )
				effectdata:SetAngles( Angle() )
				effectdata:SetNormal( vel:GetNormalized() )
				effectdata:SetMagnitude( 2 )
				effectdata:SetRadius( 2 )
				util.Effect( "Sparks", effectdata)
			end
			
			self.NextImpact = CT + 0.1
		end
	end
	
end

local Detection_Radius = (10 * 52.4934)

function ENT:GetPoz()
	return self:GetPos()+self:GetUp()*20
end

function ENT:FragmentOrCreateERBM( Entity , Amount )
	local PhysObj = Entity:GetPhysicsObject()
	for i=1, Amount do
		local Round = ents.Create("caterous_fragmentation")
		local AngleFire = PhysObj:GetVelocity() + VectorRand()
		
		Round:SetPos( Entity:WorldSpaceCenter() + (Entity:GetUp() + VectorRand()) * 10 )
		Round:SetAngles( AngleFire:Angle() )
		Round:Spawn()
		
		local RoundPhys = Round:GetPhysicsObject()
		RoundPhys:SetVelocityInstantaneous( (Entity:GetUp() + VectorRand()/5) *math.random(10000,12000))
	end
end

function ENT:SendShockWave(Pos)
	local Posed = Pos or self:WorldSpaceCenter()

	local explosedist = 300 * 52.4934666667
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
	local EntInSphere = ents.FindInSphere( self:GetPoz() , Detection_Radius )
	for key,found in pairs(EntInSphere)do
		local Phys=found:GetPhysicsObject()
		local Class=found:GetClass()
		if ( (IsValid(Phys) and found ~= self) or IsValid(string.match(type(found),"NPC")) ) and Class ~= "caterous_fragmentation" and Class ~= self:GetClass() and not found:IsPlayer() then --or found:IsPlayer()
			local Dist=((found:LocalToWorld(found:OBBCenter()))-self:GetPoz()):Length()
			if(Dist<Closest)then
				NewTarg=found
				Closest=Dist
			end
		end
	end
	return NewTarg
end

function ENT:FindDmgTarget()
	local NewTarg=nil
	local Closest=Detection_Radius
	local EntInSphere = ents.FindInSphere( self:GetPoz() , Detection_Radius/2 )
	local FilteredEntInSphere = {}
	for key,found in pairs(EntInSphere)do
		local Phys=found:GetPhysicsObject()
		local Class=found:GetClass()
		if ( (IsValid(Phys) and found ~= self) or IsValid(string.match(type(found),"NPC")) ) and Class ~= "caterous_fragmentation" and Class ~= self:GetClass() then --or found:IsPlayer()
			table.insert(FilteredEntInSphere,found)
		end
	end
	return FilteredEntInSphere
end

hook.Add( "ServerDmgTarget", "ServerTargetHook", DamageTarget )

ENT.TraceTouching = false

function ENT:Think()
	
	if SERVER and not self:IsPlayerHolding() then self.PlrGrabbing = nil end
	
	local ModelMinBound , ModelMaxBound = self:GetCollisionBounds()
	
	local tr = {}
	tr.start = self:WorldSpaceCenter() + (ModelMinBound.z * self:GetUp())
	tr.endpos = tr.start - self:GetUp() * 20
	tr.filter = {self}
	local trace = util.TraceLine(tr)
	
	if CLIENT then self.Tracing = trace end
	
	if trace.Hit and not self.TraceTouching then
		self.TraceTouching = true
		self:EmitSound("buttons/button16.wav", 60, 120)
	elseif not trace.Hit and self.TraceTouching then
		self.TraceTouching = false
		self:EmitSound("buttons/button16.wav", 60, 90)
	end
	
	if (self.PinnedToWorld and not self.PinsOn) then
		if CLIENT then self.AttachedToGround = false end
		self:EmitSound("ambient/machines/spinup.wav", 75, 120, 0.25)
		self.PinnedToWorld = false
		
		if SERVER and IsValid(self.WeldedGround) then 
			self:EmitSound("physics/surfaces/sand_impact_bullet1.wav", 90, 80)
			
			local effectdata = EffectData()
			effectdata:SetOrigin( trace.HitPos )
			effectdata:SetAngles( Angle() )
			effectdata:SetNormal( trace.HitNormal )
			effectdata:SetMagnitude( 1 )
			effectdata:SetRadius( 1 )
			util.Effect( "Sparks", effectdata)
			
			self.WeldedGround:Remove()
		end
	end
	
	if (not self.PinnedToWorld and self.PinsOn) then
		if CLIENT then self.AttachedToGround = true end
		self.PinnedToWorld = true
		
		if SERVER and (trace.HitWorld or IsValid(trace.Entity)) then 
			self:EmitSound("physics/metal/metal_canister_impact_hard1.wav", 90, 120)
			
			local effectdata = EffectData()
			effectdata:SetOrigin( trace.HitPos )
			effectdata:SetAngles( Angle() )
			effectdata:SetNormal( trace.HitNormal )
			effectdata:SetMagnitude( 6 )
			effectdata:SetRadius( 1 )
			util.Effect( "Sparks", effectdata)
			
			self:PlantEffect(self,self:WorldSpaceCenter(),trace.Normal)
			
			if trace.HitWorld then
				self.WeldedGround = constraint.Weld( self, game.GetWorld(), 0, 0, 0, false, false ) 
			elseif trace.Entity then
				self.WeldedGround = constraint.Weld( self, trace.Entity, 0, 0, 0, false, false ) 
			end
		end
	end
	
	if self.State == STATE_ARMED then
		if CurTime() > self.NextCharge then
			local Target = self:FindTarget()
			local Dmg_Array = self:FindDmgTarget()
			if IsValid(Target) and SERVER then -- or Target:IsPlayer()
				local Dist = 1 - (Target:GetPos():Distance(self:GetPos()) / Detection_Radius)
				local Phys = Target:GetPhysicsObject()
				if not Phys then return end
				local Vel = (Phys:GetVelocity()-self:GetPhysicsObject():GetVelocity())
				local Spd = Vel:Length()
				local CanBeTarget = (string.match(type(Target),"Entity") ~= nil or string.match(type(Target),"NPC") ~= nil)
				local TargetVelocityHighSpeed = (Spd > (52.4934*3)) or (Dist > 0.5)
				local TargetVelocityLowSpeed = (Spd > (52.4934*0.25)) or (Dist > 0.1)
				if TargetVelocityLowSpeed and not TargetVelocityHighSpeed and CanBeTarget then
						self:EmitSound("main/mechanism_borcheltick.wav", 120, 200)
						self:EmitSound("main/target_tick.wav", 100, 150*((Dist*2)+0.5))
				elseif TargetVelocityHighSpeed and CanBeTarget then
					for _, Targeted in pairs(Dmg_Array) do
						
						local daginfo = DamageInfo()
						local dmg_random = math.random(1000,5000) 
						daginfo:SetDamage( dmg_random * (1-Dist) )
						daginfo:SetAttacker( self )
						daginfo:SetDamageType( DMG_DIRECT ) 
						daginfo:SetDamagePosition( Target:WorldSpaceCenter() )
						daginfo:SetDamageForce( (game.GetWorld():GetUp()+VectorRand()) * Phys:GetMass() * math.random(50,1000) )
						
						if dmg_random > Phys:GetMass() then 
							local vPoint = Target:WorldSpaceCenter()
							
							Phys:SetVelocity(Phys:GetVelocity()*3)
							local effectdata = EffectData()
							effectdata:SetOrigin( vPoint )
							effectdata:SetAngles( AngleRand() )
							effectdata:SetNormal( game.GetWorld():GetUp() )
							effectdata:SetMagnitude( 20 )
							effectdata:SetRadius( 5 )
							util.Effect( "Sparks", effectdata)
						end
						
						Target:EmitSound("main/roundhit_softmatter_"..math.random(1,9)..".wav", 80, math.random(140,150),1)
						hook.Run( "ServerDmgTarget", self , Target , daginfo , dmg_random )
					end
						
						self:SendShockWave(self:WorldSpaceCenter())
						util.ScreenShake(Target:WorldSpaceCenter(),120,2,0.1,1500)
						self:EmitSound("main/bouncehit.wav", 80, math.random(80,90),1)
						self:EmitSound("main/incendiarysizzle", 100, math.random(120,130),1)
						self:EmitSound("main/antispatialknock_highsavor.wav", 100, math.random(60,65))
						ParticleEffect( "Flashed", self:GetPos() , Angle(0,0,0) )
						ParticleEffect( "DirtDebrisShock", self:GetPos() , Angle(0,0,0) )
						self:FragmentOrCreateERBM( self , math.random(10,14) )
						self:Remove()
						
					
				end
				self.NextCharge = CurTime() + 0.25
			end
		end
	end
	
	self:NextThink( CurTime() + 0.01 )
    return true
end
