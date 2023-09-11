ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.PrintName = "T-TA-16 Grenade"
ENT.Author = "Dog"
ENT.Information = "How to delete leechers - Use."
ENT.Spawnable = true
ENT.AdminSpawnable = false 
ENT.Category = "Pelvareign Weaponry"

ENT.Model = "models/entities/standard_tta_grenade.mdl"
ENT.Healthed = 100

local STATE_ARMED = 1
local STATE_UNARMED = 0

function ENT:SetupDataTables()
	self.NextImpact = 0
	self.NextCharge = 0
	self.PinsOn = false
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
	
	spd = physenv.GetPerformanceSettings()
    spd.MaxVelocity = ((343 * 52.4934) * 50)
	
    physenv.SetPerformanceSettings(spd)

	if phys and phys:IsValid() then
		phys:Wake()
		phys:SetMass( 30 )
		phys:SetDragCoefficient( 1e-12 )
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
		self.PinsOn = true
	else
		self.PinsOn = false
	end

end)



local Ctx, Toggle = 0, false

function ENT:Use(activator, caller)
	
	if (CurTime() > Ctx) then Ctx = CurTime() + 0.5 if not activator:KeyDown( IN_WALK ) then Toggle = not Toggle end else return false end
	
	if Toggle then
		self:SetAngles( self:AlignAngles( self:GetAngles():Up():Angle() , (activator:EyeAngles():Forward()):Angle() ) )
	else
		self:SetAngles( self:AlignAngles( self:GetAngles() , game.GetWorld():GetForward():Angle() ) )
	end
	
	if not activator:KeyDown( IN_WALK ) then 
		activator:PickupObject( self ) 
		self.PlrGrabbing = activator
		return false 
	end
	
	if not self.RollersMoving and not self.RollersOn and not self.PinsMoving then
		self:FireActivation(activator,true)
		
	elseif not self.RollersMoving and self.RollersOn and not self.PinsMoving then
		self:FireActivation(activator,false)
		
	end
	
	self.PlrGrabbing = nil
	
	return true
end

function ENT:FireActivation(activator,bool)
	net.Start("CLIENT_TOGGLE")
		net.WriteEntity( self )
		net.WriteBool( bool )
		net.WriteEntity( activator )
	net.Broadcast()
	
	if bool then
		self.RollersMoving = true
		self.PinsMoving = true
		self:EmitSound("buttons/button24.wav", 80, math.random(60,65))
		timer.Simple(0.1, function()
			self.RollersOn = true
			self.RollersMoving = false
			self.PinsOn = true
			self.PinsMoving = false
			self.State = STATE_ARMED
		end)
	else
		self.RollersMoving = true
		self.PinsMoving = true
		self:EmitSound("buttons/button24.wav", 80, math.random(80,85))
		timer.Simple(0.1, function()
			self.RollersOn = false
			self.RollersMoving = false
			self.PinsOn = false
			self.PinsMoving = false
			self.State = STATE_UNARMED
		end)
	end
	
end

local vel, velLen, CT, CTd

function ENT:PhysicsCollide(data, physobj)
	vel = physobj:GetVelocity()
	velLen = vel:Length()
	
		local phyed = self:GetPhysicsObject()
		
		if velLen > 100 then
			phyed:SetVelocity( phyed:GetVelocity() + (-data.HitNormal * phyed:GetVelocity():Length()) )
		CT = CurTime()
		if CT > self.NextImpact then
			
			if velLen < 500 then
				
				self:EmitSound("physics/metal/metal_sheet_impact_hard"..math.random(6,8)..".wav", 75, math.random(160,166))
				self:EmitSound("ambient/machines/keyboard7_clicks_enter.wav", 80, math.random(80,90))
			else
				self:EmitSound("physics/metal/metal_box_impact_hard"..math.random(1,3)..".wav", 90, math.random(120,125))
				
				local effectdata = EffectData()
				effectdata:SetOrigin( data.HitPos )
				effectdata:SetAngles( Angle() )
				effectdata:SetNormal( vel:GetNormalized() )
				effectdata:SetMagnitude( 2 )
				effectdata:SetRadius( 2 )
				util.Effect( "Sparks", effectdata)
			end
			
			self.NextImpact = CT + 0.01
		end
	end
	
	if velLen > (343 * 52.4934) and data.HitEntity:IsWorld() then
		sound.Play("main/bomb_explosion_1.wav", data.HitPos, 110, math.random(170,200))
		ParticleEffect( "DirtDebrisShock", data.HitPos , Angle(0,0,0) )
		util.ScreenShake(data.HitPos,120,2,0.1,1500)
	end
	
end

local Detection_Radius = (300 * 52.4934)

function ENT:FragmentOrCreateERBM( Entity , Amount )
	local PhysObj = Entity:GetPhysicsObject()
	for i=1, Amount do
		local Round = ents.Create("esbm_fragmentation")
		local AngleFire = PhysObj:GetVelocity() + VectorRand()
		
		Round:SetPos( Entity:WorldSpaceCenter() + (Entity:GetUp() + VectorRand()) * 10 )
		Round:SetAngles( AngleFire:Angle() )
		Round:Spawn()
		
		local RoundPhys = Round:GetPhysicsObject()
		RoundPhys:SetVelocityInstantaneous( Entity:GetVelocity() + ((VectorRand() *math.random(10000,12000))/2) )
	end
end

function ENT:SendShockWave(Pos)
	local Posed = Pos or self:WorldSpaceCenter()

	local explosedist = 500 * 52.4934666667
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
	local EntInSphere = ents.FindInSphere( self:WorldSpaceCenter() , Detection_Radius )
	for key,found in pairs(EntInSphere)do
		local Phys=found:GetPhysicsObject()
		local Class=found:GetClass()
		if ( IsValid(Phys) and (type(found) == "NPC") ) and (Class ~= "esbm_fragmentation") and (Class ~= self:GetClass()) and (not found:IsPlayer()) then
			local Dist=((found:WorldSpaceCenter())-self:WorldSpaceCenter()):Length()
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
	local EntInSphere = ents.FindInSphere( self:WorldSpaceCenter() , Detection_Radius/2 )
	local FilteredEntInSphere = {}
	for key,found in pairs(EntInSphere)do
		local Phys=found:GetPhysicsObject()
		local Class=found:GetClass()
		if ( IsValid(Phys) and (type(found) == "NPC") ) and (Class ~= "esbm_fragmentation") and (Class ~= self:GetClass()) then --or found:IsPlayer()
			table.insert(FilteredEntInSphere,found)
		end
	end
	return FilteredEntInSphere
end

function ENT:PhysicsUpdate(phys)
	if not Phys then return end
	
	local angles = phys:GetAngles()
	local velocity = phys:GetVelocity()
	
	if velocity:Length() > (343 * 52.4934) then
		phys:SetAngles( self:AlignAngles( self:GetAngles():Up():Angle() , velocity:Angle() ) )
		phys:SetVelocity( velocity )
	end
	
end


hook.Add( "ServerDmgTarget", "ServerTargetHook", DamageTarget )

function ENT:Think()
	
	local SelfPhys = self:GetPhysicsObject()
	if not SelfPhys then return end
	
	if SERVER and IsValid(self.PlrGrabbing) then
		
		local aim = {}
		aim.start = self.PlrGrabbing:EyePos()
		aim.endpos = aim.start + self.PlrGrabbing:EyeAngles():Forward() * 1000000000
		aim.filter = {self,self.PlrGrabbing}
		traced = util.TraceLine(aim)
		
		if not (traced.Entity):IsWorld() and IsValid(traced.Entity) then
			if type(self.NextTick) ~= "number" or CurTime() >= self.NextTick then
				self:EmitSound("main/mechanism_borcheltick.wav", 90, 200)
				
		
		if self.PlrGrabbing:KeyDown( IN_RELOAD ) and traced.Entity ~= self.Target then
			local tr = {}
			tr.start = self.PlrGrabbing:EyePos()
			tr.endpos = tr.start + self.PlrGrabbing:EyeAngles():Forward() * 1000000000
			tr.filter = {self,self.PlrGrabbing}
			trace = util.TraceLine(tr)
			
			if not (trace.Entity):IsWorld() and IsValid(trace.Entity) then
				self:EmitSound("buttons/blip1.wav", 90, 120)
				self.Target = trace.Entity
			else
				self:EmitSound("buttons/button11.wav", 90, 220)
			end
		end
		
			self.NextTick = CurTime() + 0.1
			end
		end
		
		if self.PlrGrabbing:KeyDown( IN_ATTACK ) and not self:IsPlayerHolding() then
			local Grabbing = self.PlrGrabbing
			Grabbing:EmitSound("physics/flesh/flesh_impact_hard1.wav", 90, 250)
			Grabbing:EmitSound("main/bouncehit.wav", 120, math.random(80,90),1)
			Grabbing:EmitSound("main/antispatialknock_highsavor.wav", 120, math.random(50,55))
			
			SelfPhys:SetVelocity( Grabbing:EyeAngles():Forward() * (343 * 52.4934) * 3 )
			self:FireActivation(Grabbing,true)
			
			ParticleEffect( "Flashed", self:GetPos() , Angle(0,0,0) )
			ParticleEffect( "Shockwave", self:GetPos() , Angle(0,0,0) )
			
		end
	end
	
		if self:GetVelocity():Length() < (343 * 52.4934) or not IsValid(self) then 
			hook.Remove( "Think" , self ) 
		else
			if not IsValid(self.Emitter) and CLIENT then self.Emitter = ParticleEmitter(self:WorldSpaceCenter()) end
			hook.Add( "Think", self, function ()
				if IsValid(self) and IsValid(self.Emitter) then
					local Mach_Num = math.Clamp(math.Round(self:GetVelocity():Length() / (343 * 52.4934)),0,10)
					for i=1, Mach_Num do
						local part = self.Emitter:Add("particle/smokesprites_0003" , self:WorldSpaceCenter())
						part:SetStartSize(math.random(20,80))
						part:SetEndSize(2000)
						part:SetStartAlpha(100)
						part:SetEndAlpha(0)
						part:SetDieTime(0.25)
						part:SetRoll(math.random(0, 360))
						part:SetRollDelta(0.01)
						part:SetColor(255*(Mach_Num/2), 255*(Mach_Num/2), 255*(Mach_Num/2))
						part:SetLighting(false)
						part:SetVelocity((self:GetVelocity()*0.1)+(VectorRand() * math.random(10,100)))
						
						local effectdata = EffectData()
						effectdata:SetOrigin( self:WorldSpaceCenter() )
						effectdata:SetAngles( AngleRand() )
						effectdata:SetNormal( game.GetWorld():GetUp() )
						effectdata:SetMagnitude( 1 )
						effectdata:SetRadius( 20 )
						util.Effect( "Sparks", effectdata)
						
						ParticleEffect( "Shockwave", self:GetPos() + (VectorRand() * 52.4934) * i , Angle(0,0,0) )
					end
				end
			end)
		end
	
	
	if SERVER and not self:IsPlayerHolding() then self.PlrGrabbing = nil end
	
	if self.State == STATE_ARMED then
		if CurTime() > self.NextCharge and IsValid(self.Target) then
			local Target = self.Target
			local Phys = Target:GetPhysicsObject()
			
			local Dmg_Array = self:FindDmgTarget()
			local Dist = 1 - (Target:GetPos():Distance(self:WorldSpaceCenter()) / Detection_Radius)
			if Dist > 0 and SERVER then -- or Target:IsPlayer()
				if not IsValid(trail) and not IsValid(trail2) then
					trail = util.SpriteTrail( self, 0, Color( 255, 255, 255 ), true, 80, 0, 0.5, 30, "trails/laser" )
					trail2 = util.SpriteTrail( self, 0, Color( 50, 50, 200 ), true, 120,0, 1.2, 30, "trails/laser" )
				end
				
				SelfPhys:SetVelocity( SelfPhys:GetVelocity() + ((Target:WorldSpaceCenter() - self:WorldSpaceCenter()):GetNormalized() * (343 * 52.4934) * 2) * math.Clamp(Dist,0,1) )
				self:EmitSound("main/target_tick.wav", 120, 150*((Dist*2)+0.5))
				if Dist < 0.8 then return end
				if not Phys then return end
				local Vel = (Phys:GetVelocity()-SelfPhys:GetVelocity())
				local Spd = Vel:Length()
				local CanBeTarget = (string.match(type(Target),"Entity") ~= nil or string.match(type(Target),"NPC") ~= nil)
				local TargetVelocityHighSpeed = (Spd > (52.4934*3)) or (Dist > 0.5)
				if TargetVelocityHighSpeed and CanBeTarget then
					for _, Targeted in pairs(Dmg_Array) do
						
						local daginfo = DamageInfo()
						local dmg_random = math.random(40000,50000) 
						daginfo:SetDamage( dmg_random * (1-Dist) )
						daginfo:SetAttacker( self )
						daginfo:SetDamageType( DMG_DIRECT ) 
						daginfo:SetDamagePosition( Target:WorldSpaceCenter() )
						if IsValid(Phys) then
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
						end
						
						Target:EmitSound("main/roundhit_softmatter_"..math.random(1,9)..".wav", 80, math.random(140,150),1)
						hook.Run( "ServerDmgTarget", self , Target , daginfo , dmg_random )
					end
						
						self:SendShockWave(self:WorldSpaceCenter())
						util.ScreenShake(Target:WorldSpaceCenter(),120,2,0.1,1500)
						self:EmitSound("main/bouncehit.wav", 80, math.random(80,90),1)
						self:EmitSound("main/incendiarysizzle", 100, math.random(120,130),1)
						self:EmitSound("main/antispatialknock_highsavor.wav", 100, math.random(60,65))
						self:EmitSound("main/railexplode.wav", 120, math.random(50,55))
						ParticleEffect( "Flashed", self:GetPos() , Angle(0,0,0) )
						ParticleEffect( "DirtFireballHit", self:GetPos() , Angle(0,0,0) )
						self:FragmentOrCreateERBM( self , math.random(10,12) )
						self:Remove()
						
					
				end
				
			end
			if IsValid(trail) and IsValid(trail2) and not IsValid(Target) then
				trail:Remove()
				trail2:Remove()
			end
			self.NextCharge = CurTime() + 0.01
		end
	end
	
	self:NextThink( CurTime() + 0.01 )
    return true
end
