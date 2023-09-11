AddCSLuaFile()

local Ctx = 0
local phys, ef, vel, velLen, CT, CTd
local Detection_Radius = (300 * 52.4934)

local cablemat = Material( "cable/physbeam" )
local elecmat = Material( "cable/blue_elec" )
local redmat = Material( "cable/redlaser" )

game.AddParticles( "particles/heibullet_explosion.pcf" )
PrecacheParticleSystem( "DirtFireballHit" )
PrecacheParticleSystem( "Flashed" )
PrecacheParticleSystem( "DirtDebrisShock" )

local STATE_ARMED = 1
local STATE_UNARMED = 0

ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.PrintName = "T-TA-13 Grenade"
ENT.Author = "Dog"
ENT.Information = "How to delete leechers - Use."
ENT.Spawnable = true
ENT.AdminSpawnable = false 
ENT.Category = "Pelvareign Weaponry"

ENT.Model = "models/entities/standard_tta_grenade.mdl"
ENT.Healthed = 100

function ENT:SetupDataTables()
	self.NextImpact = 0
	self.NextCharge = 0
	self.PinsOn = false
	self.Tracing = nil
	self.Shocked = false
	self.AttachedToGround = false
	self.State =  STATE_UNARMED
end

if (SERVER) then
	util.AddNetworkString( "ShockwaveFunction" )
	util.AddNetworkString( "CLIENT_TOGGLE" )
	
	ENT.PlrGrabbing = nil
end

local traceData = {}
traceData.mask = bit.bor(CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_DEBRIS, CONTENTS_MONSTER, CONTENTS_HITBOX, CONTENTS_WATER)

function TableEntityCheckAndRemove( Table )
	if table.Count( Table ) < 1 then return end
	for Index, v in pairs(Table) do
		if not v:IsValid() then 
			table.remove(Table,Index)
		end
	end
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

function Mod_AeroDrag(ent, forward, mult)
	if SERVER then
		if (constraint.HasConstraints(ent)) then return end
		if (ent:IsPlayerHolding()) then return end
		local Phys = ent:GetPhysicsObject()
		local Vel = Phys:GetVelocity()
		local Spd = Vel:Length()
		local Stabilization = ent:GetRight():Dot(Vel) / Spd
		if (Spd < 300) then return end
		mult = mult or 1
		local Pos, Mass = Phys:LocalToWorld(Phys:GetMassCenter()), Phys:GetMass()
		Phys:ApplyForceOffset((Vel * Mass / 6 * mult) / math.abs(1 + Stabilization), (Pos + forward))
		Phys:ApplyForceOffset((-Vel * Mass / 6 * mult) / math.abs(1 + Stabilization), (Pos - forward))
		Phys:AddAngleVelocity( -Phys:GetAngleVelocity() / math.Clamp(ent:GetRight():Dot(Vel)^0.5,2,12) )
	end
end

function ENT:FragmentOrCreateERBM( Entity , Amount )
	local PhysObj = Entity:GetPhysicsObject()
	local CurrentDist = Entity:WorldSpaceCenter():Distance(Entity.Target:WorldSpaceCenter())
	local DirectionToTarget = (Entity.Target:WorldSpaceCenter() - Entity:WorldSpaceCenter()):GetNormalized()
	
	for i=1, Amount do
		local Round = ents.Create("caterous_fragmentation")
		local AngleFire = ( DirectionToTarget + ( ( VectorRand() / 4 ) / (CurrentDist / 52.4934) ) ):Angle()
		
		Round:SetPos( Entity:WorldSpaceCenter() + (VectorRand() * 10) )
		Round:SetAngles( AngleFire )
		Round:Spawn()
		
		local RoundPhys = Round:GetPhysicsObject()
		RoundPhys:SetVelocityInstantaneous( AngleFire:Forward() * math.random(23000,32000)  )
	end
	
	local EMBERDIR = ( PhysObj:GetVelocity():GetNormalized() + VectorRand() )
	
	for i = 1, 34 do
		ParticleEffect( "ShockWave", Entity:WorldSpaceCenter() + (VectorRand() * math.random(10,500)) , Angle(0,0,0))
		ParticleEffect( "HugeFire", Entity:WorldSpaceCenter() + ( EMBERDIR * math.random(10,150) ) + (VectorRand() * math.random(100,1000)) , EMBERDIR:Angle():Up():Angle() )
	end
	
	for v = 1, 33 do
		ParticleEffect( "SUPEREMBERHIT", Entity:WorldSpaceCenter() + ( EMBERDIR * math.random(10,1500) ) + (VectorRand() * math.random(1,50)) , EMBERDIR:Angle():Up():Angle() )
		util.ScreenShake( Entity:WorldSpaceCenter() , 999, 9999, 1.3, 7000 ) 
	end
	
	local d = DamageInfo()
	
	d:SetDamage( 398.12 * (40 ^ 2) )
	d:SetAttacker( self )
	d:SetInflictor( self )
	d:SetDamageType( DMG_RADIATION )
	util.BlastDamageInfo(d, Entity:WorldSpaceCenter(), 43 * 52.4934)
	
	for k, v in pairs( ents.FindInSphere( Entity:WorldSpaceCenter() , 32 * 52.4934 ) ) do
		if IsValid(v) then
			ParticleEffect( "SUPEREMBERHIT", v:WorldSpaceCenter() , EMBERDIR:Angle():Up():Angle() )
			
			local Dist = Entity:WorldSpaceCenter():Distance(v:WorldSpaceCenter())
			
			if string.match(tostring(v),"npc_turret_floor") and v:IsNPC() then
				EntityToSlam:Fire("SelfDestruct")
			elseif string.match(tostring(v),"npc_helicopter") and v:IsNPC() then
				EntityToSlam:Fire("Break")
			end
			
			d:SetDamage( 8.01 * (Dist ^ 3) )
			d:SetAttacker( self )
			d:SetInflictor( self )
			d:SetDamageType( DMG_BLAST )
			v:TakeDamageInfo( d )
			
			d:SetDamage( 23 * (Dist ^ 2) )
			d:SetAttacker( self )
			d:SetInflictor( self )
			d:SetDamageType( DMG_GENERIC )
			v:TakeDamageInfo( d )
			
			if v == Entity.Target then
				d:SetDamage( 398.12 * (Dist ^ 2) )
				d:SetAttacker( self )
				d:SetInflictor( self )
				d:SetDamageType( DMG_GENERIC )
				v:TakeDamageInfo( d )
			end
			
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
		if ( IsValid(Phys) and (type(found) == "NPC") ) and (Class ~= self:GetClass()) and (not found:IsPlayer()) then
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
		if ( IsValid(Phys) and (type(found) == "NPC") ) and (Class ~= self:GetClass()) then --or found:IsPlayer()
			table.insert(FilteredEntInSphere,found)
		end
	end
	return FilteredEntInSphere
end

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

if SERVER then
	util.AddNetworkString( "Client_Shockwave_TTA_13" )
end

net.Receive( "Client_Shockwave_TTA_13", function( len )
	local Ply = LocalPlayer()
	local ContinationWave = net.ReadFloat()
	local Dist = ( 1 - net.ReadFloat() ) or 0
	local Visible = net.ReadBool() or false
	if ContinationWave == nil then return end
	
	timer.Simple( ContinationWave , function() 
		if Dist < 0.50 or not Visible then
			EmitSound( "main/tacklecatics_endshock.mp3", Vector() , -1 , CHAN_AUTO , math.Clamp(Dist^2,0,1) , 75 , 0 , math.random(190,195) )
			EmitSound( "main/airshockwave.wav", Vector() , -1 , CHAN_AUTO , math.Clamp(Dist,0,1) , 90 , 0 , math.random(20,30) )
			EmitSound( "high_caliber_cbm_weaponry/83mm_sebboul_distant_"..math.random(1,3)..".mp3", Vector() , -1 , CHAN_AUTO , math.Clamp(Dist,0,1) , 90 , 0 , math.random(45,55) )
			
		else
			EmitSound( "main/tacklecatics_beginshock.mp3", Vector() , -1 , CHAN_AUTO , math.Clamp(Dist^2,0,1) , 90 , 0 , math.random(190,200) )
			EmitSound( "main/plasma_anticharge_coniccrossover_"..math.random(1,8)..".mp3", Vector() , -1 , CHAN_AUTO , math.Clamp(Dist^2,0,1) , 90 , 0 , math.random(90,120) )
			EmitSound( "ambient/explosions/explode_4.wav", Vector() , -1 , CHAN_AUTO , math.Clamp(Dist^2,0,1) , 90 , 0 , math.random(140,180) )
			
		end
	end)
end)

function ENT:SinuousExplosion( Original_Pos , Meters )
	local traceData = {}
	traceData.mask = bit.bor(CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_DEBRIS, CONTENTS_MONSTER, CONTENTS_HITBOX, CONTENTS_WATER)
	
	local SoundDistanceMax = Meters * 52.4934
		for k, v in pairs(ents.FindInSphere(Original_Pos,SoundDistanceMax)) do
			if IsValid(v) and v:IsPlayer() then
				local Dist = v:WorldSpaceCenter():Distance(Original_Pos)/SoundDistanceMax
				
				obj = v
				
				local positedplayer = v:WorldSpaceCenter()
				
				direction = ( positedplayer - Original_Pos )
				
				traceData.filter = {Bouncer,self}
				traceData.start = Original_Pos 
				traceData.endpos = traceData.start + direction * SoundDistanceMax
				
				local trace = util.TraceLine(traceData)
				
				local ent = trace.Entity
				local fract = trace.Fraction
				
				local isplayer = ent:IsPlayer()
				local isnpc = ent:IsNPC()
				local equal = ent == v
				
				local SpatialWaveFormat = 343 + math.random(-10,150)
				
				if not equal then 
					SpatialWaveFormat = SpatialWaveFormat / ( math.Rand( 1.10 , 1.50 ) )
					Dist = (Dist ^ math.random( 0.75 , 0.9 ) )
				end
				
				local ContinationWave = ( Dist * Meters ) / ( SpatialWaveFormat )
				
				net.Start("Client_Shockwave_TTA_13")
					net.WriteFloat(ContinationWave)
					net.WriteFloat(Dist)
					net.WriteBool(equal)
				net.Send(v)
				
			end
		end
end

function ENT:FireActivation(activator,bool)
	net.Start("CLIENT_TOGGLE")
		net.WriteEntity( self )
		net.WriteBool( bool )
		net.WriteEntity( activator )
	net.Broadcast()
	
	if IsValid(self) then
	if bool then
		self.RollersMoving = true
		self.PinsMoving = true
		timer.Simple(0.1, function()
			self.RollersOn = true
			self.RollersMoving = false
			self.PinsOn = true
			self.PinsMoving = false
			self.State = STATE_ARMED
			
			self:EmitSound("physics/metal/metal_sheet_impact_bullet2.wav", 90, math.random(225,230))
			self:ManipulateBonePosition( self:LookupBone( "Button" ) , ( Vector(0,0,-1) / 4 ) )
		end)
	else
		self.RollersMoving = true
		self.PinsMoving = true
		timer.Simple(0.1, function()
			self.RollersOn = false
			self.RollersMoving = false
			self.PinsOn = false
			self.PinsMoving = false
			self.State = STATE_UNARMED
			
			self:EmitSound("physics/metal/metal_sheet_impact_bullet2.wav", 90, math.random(240,250))
			self:EmitSound("main/target_tick.wav", 90, math.random(50,60))
			self:ManipulateBonePosition( self:LookupBone( "Button" ) , self.ButtonPos )
		end)
	end
	end
	
end

function ENT:Use(activator, caller)
	
	if (CurTime() > Ctx) then 
		Ctx = CurTime() + 0.5
		if not activator:KeyDown( IN_WALK ) then 
			self.Toggle = not self.Toggle 
		end 
	else
		return false 
	end
	
	if self.Toggle then
		self:SetAngles( self:AlignAngles( self:GetAngles():Up():Angle() , (activator:EyeAngles():Forward()):Angle() ) )
		activator:EmitSound("main/interact_foley_short_"..math.random(1,3)..".wav", 75, math.random(95,110), 0.4 )
		self:EmitSound("physics/metal/metal_sheet_impact_hard"..math.random(6,8)..".wav", 80, math.random(240,250))
	else
		self:SetAngles( self:AlignAngles( self:GetAngles() , game.GetWorld():GetForward():Angle() ) )
		activator:EmitSound("main/interact_foley_short_"..math.random(1,3)..".wav", 75, math.random(130,140), 0.4 )
		self:EmitSound("physics/metal/metal_sheet_impact_hard"..math.random(6,8)..".wav", 80, math.random(240,250))
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

function ENT:Initialize()
	
	self:CustomInitialize()
	
	if CLIENT then
		self:SetModel(self.Model) 
		
		hook.Add( "PostDrawTranslucentRenderables", self, function( bDrawingDepth, bDrawingSkybox )
		
			if bDrawingSkybox then return end
			
			local Angle = EyeAngles()
			local Pos = self:WorldSpaceCenter() + self:GetUp()*5
				
			Angle:RotateAroundAxis( Angle:Up(), -90 )
			Angle:RotateAroundAxis( Angle:Forward(), 90 )
				
			cam.Start3D2D( Pos , Angle, 1 )
			
			if self.PinsOn then
				
				if math.abs(math.sin(CurTime()*20)) > 0.5 then
					local pos,material = Vector(), Material( "sprites/light_ignorez" )
					render.SetMaterial( material )
					render.DrawSprite( pos, 20, 20, Color( 255, 255*math.abs(math.sin(CurTime())), 0 ) )
					render.DrawSprite( pos, 6, 6, Color( 255, 255, 255 ) )
				end
				
			end
			
			cam.End3D2D()
			
		end)
		
	end
	
end

function ENT:Draw()
	cam.Start3D()
	
	local DistFromEntToMeters = ( LocalPlayer():WorldSpaceCenter():Distance(self:WorldSpaceCenter()) / 52.4934 )
	
	if DistFromEntToMeters < 20 and DistFromEntToMeters > 1.5 then
	
		local Pos = LocalPlayer():GetEyeTrace().HitPos
		local LookDist = ( self:WorldSpaceCenter():Distance(Pos) / 52.4934 )
		if LookDist < 2 then
			render.SetColorMaterial()
			for i=1,10 do
				render.DrawSphere( self:WorldSpaceCenter(), ((math.cos( CurTime() * 2 ) * 0.25) + 1) * ((i * 52.4934)/15) , 20, 20, Color( 255, 255-(i^2.5), 255-(i^2.5), 20 ) )
			end
			
			local Angle = Angle( 0, EyeAngles().y, 0 )
			local Pos = self:WorldSpaceCenter() + Vector( 0, 0, (math.cos( CurTime() * 2 ) * (0.125 * 52.4934)) + (0.85 * 52.4934) )
			
			Angle:RotateAroundAxis( Angle:Up(), -90 )
			Angle:RotateAroundAxis( Angle:Forward(), 90 - (30 * math.cos( CurTime() * 4 )) )
			
			cam.Start3D2D( Pos , Angle, 0.25 )
				local text = "1 - 25 Meter Kill Zone"
				surface.SetFont( "Default" )
				local tW, tH = surface.GetTextSize( text )

				local pad = 10

				surface.SetDrawColor( 0, 0, 0, 200 )
				surface.DrawRect( -tW / 2 - pad, -pad, tW + pad * 2, tH + pad * 2 )
				surface.SetDrawColor( 0, 150, 255, 50 )
				pad = pad - 2
				surface.DrawRect( -tW / 2 - pad, -pad, tW + pad * 2, tH + pad * 2 )

				draw.SimpleText( text, "Default", -tW / 2, 0, Color( 200, 150, 255, 200 ) )
				draw.SimpleText( text, "Default", -tW / 2, -2, Color( 255, 255, 255, 255 ) )
			cam.End3D2D()
			
		end
	
	end
	
	cam.End3D()
	self:DrawModel()
	
end

function ENT:PhysicsUpdate(phys)

	local angles = phys:GetAngles()
	local velocity = phys:GetVelocity()
	
	if self:GetBodygroup( 1 ) == 0 then
	
		Mod_AeroDrag( self , self:GetUp() , 0.01 )
		phys:AddAngleVelocity( (-self:GetUp() * (self:GetUp():Dot(velocity)/50)) )
	
	else
	
		Mod_AeroDrag( self , self:GetUp() , 0.1 )
		phys:AddAngleVelocity( (-self:GetUp() * (self:GetUp():Dot(velocity)/100)) )
	
	end
	
	local VelocityInMeters = (velocity:Length()/52.4934)
	
	if self.WindCrackle then
		self.WindCrackle:Play()
		self.WindCrackle:ChangePitch( math.Clamp( VelocityInMeters / 2 , 50 , 240 ) )
		self.WindCrackle:ChangeVolume( math.Clamp( VelocityInMeters / 200 , 0 , 1 ) )
	end
	
	CompressionWave = CurTime()
	if self.NextCompressionTick == nil or CompressionWave > self.NextCompressionTick then
		if velocity:Length() > (100 * 52.4934) then
			if IsValid(self.compressiontrail) then
				self.compressiontrail:Remove()
			end
			self.compressiontrail = util.SpriteTrail( self, 0, Color( 255, 255, 255, math.Clamp( (VelocityInMeters / 100) * 10 , 0 , 255 ) ), true, 0, math.Clamp( VelocityInMeters * 2 , 0 , 1000 ), 0.05, 10, "effects/beam_generic01" )
		else
			if IsValid(self.compressiontrail) then
				self.compressiontrail:Remove()
			end
		end
		self.NextCompressionTick = CompressionWave + 0.25
	end
	
	if velocity:Length() > (343 * 52.4934) then
		phys:SetAngles( self:AlignAngles( self:GetAngles():Up():Angle() , velocity:Angle() ) )
		phys:SetVelocity( velocity )
	end
	
end

function ENT:PhysicsCollide(data, physobj)
	vel = physobj:GetVelocity()
	velLen = vel:Length()
	
		local phyed = self:GetPhysicsObject()
		
		if velLen > (1 * 52.4934) then
			phyed:SetVelocity( phyed:GetVelocity() + ( -data.HitNormal * phyed:GetVelocity():Length() / 1.25 ) )
		CT = CurTime()
		if CT > self.NextImpact then
			
			if velLen < (25 * 52.4934) then
				
				self:EmitSound("physics/metal/metal_sheet_impact_hard"..math.random(6,8)..".wav", 70, math.random(180,200))
			else
				self:EmitSound("physics/metal/metal_box_impact_hard"..math.random(1,3)..".wav", 85, math.random(180,200))
				
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
	
	if velLen > (50 * 52.4934) and data.HitEntity:IsWorld() then
		sound.Play("main/ground_hit_explosive_"..math.random(1,3)..".mp3", data.HitPos, 140, math.random(100,140) , 1 )
		sound.Play("main/fragexplose"..math.random(1,3)..".wav", data.HitPos, 90, math.random(100,140) , 0.6 )
		ParticleEffect( "DirtDebrisShock", data.HitPos , Angle(0,0,0) )
		util.ScreenShake(data.HitPos,120,2,0.5,3500)
	end
	
end

hook.Add( "ServerDmgTarget", "ServerTargetHook", DamageTarget )

function ENT:Think()
	
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
		
		if self.PlrGrabbing:KeyDown( IN_ATTACK2 ) then
			
			local WasPlayer = self.PlrGrabbing
			
			WasPlayer:EmitSound("main/interact_foley_short_"..math.random(1,3)..".wav", 80, math.random(95,110), 0.25 )
			
			if self:GetBodygroup( 1 ) == 0 then
				self:EmitSound("main/grenade_cap_click.wav", 80, math.random(90,100), 0.8 )
			end
			
			timer.Simple( 0.25 , function() if IsValid(self) and IsValid(WasPlayer) then
			
				if self:GetBodygroup( 1 ) == 0 then
				------------------------------------------------------
				
				local Cap = ents.Create("prop_physics")
				
				local CapBonePos, CapBoneAngle = self:GetBonePosition( self:LookupBone( "Cap" ) )
				
				Cap:SetPos( CapBonePos )
				Cap:SetAngles( Cap:AlignAngles( Cap:GetAngles():Up():Angle() , (self:GetUp()):Angle() ) )
				Cap:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
				Cap:SetOwner( self.Owner )
				Cap:SetModel( "models/entities/standard_tta_grenade_cap.mdl" )
				Cap:Spawn()
					
				local MetersPerSecond = (math.random( 20 , 46 )/10) * 52.4934
				local CapPhys = Cap:GetPhysicsObject()
				
				local AnyVector = VectorRand() * ( Cap:GetForward() + Cap:GetRight() )
				
				CapPhys:SetVelocityInstantaneous( CapPhys:GetVelocity() + (AnyVector*MetersPerSecond/10) + (Cap:GetUp()*MetersPerSecond) )
				CapPhys:SetAngleVelocityInstantaneous( ( AnyVector * math.random( 20 , 90 ) ) * math.pi )
				
				timer.Simple( 5 , function() if IsValid(Cap) then Cap:Remove() end end )
				
				WasPlayer:PickupObject( self ) 
				self.PlrGrabbing = WasPlayer
				
				self:SetBodygroup( 1, 1 )
				self:EmitSound("main/lid_open_"..math.random(1,3)..".wav", 90, math.random(98,105), 0.7 )
				
				------------------------------------------------------
				
				end
			
			end end )
			
		end
		
		if self.PlrGrabbing:KeyDown( IN_ATTACK )  then
			
			local Grabbing = self.PlrGrabbing
			Grabbing:EmitSound("physics/flesh/flesh_impact_hard1.wav", 90 , 45 , 1 )
			Grabbing:EmitSound("main/interact_foley_long_1.wav", 80, math.random(115,120), 0.5 )
			
			Grabbing:SetVelocity( Grabbing:EyeAngles():Forward() * -(1 * 52.4934) )
			self:GetPhysicsObject():SetVelocity( Grabbing:GetVelocity() + Grabbing:EyeAngles():Forward() * (10 * 52.4934) )
			
			if self:GetManipulateBonePosition( self:LookupBone( "Button" ) ) == self.ButtonPos then
				self:EmitSound("physics/metal/metal_sheet_impact_bullet2.wav", 90, math.random(240,250))
				self:ManipulateBonePosition( self:LookupBone( "Button" ) , ( Vector(0,0,-1) / 4 ) )
			end
			
			if self.PlrGrabbing:KeyDown( IN_WALK ) then
				
				if self:GetBodygroup( 1 ) ~= 1 then Grabbing:EmitSound("main/interact_foley_short_"..math.random(1,3)..".wav", 90, math.random(60,70), 0.5 ) return end
				
				timer.Simple( 0.1 , function() 
					if IsValid(self) and IsValid(Grabbing) then 
					-----------------------------------------
					if self:GetBodygroup( 2 ) == 0 then
						
						local Clip = ents.Create("prop_physics")
						
						local ClipBonePos, ClipBoneAngle = self:GetBonePosition( self:LookupBone( "Clip" ) )
				
						Clip:SetPos( ClipBonePos )
						Clip:SetAngles( Clip:AlignAngles( Clip:GetAngles():Up():Angle() , (self:GetUp()):Angle() ) )
						Clip:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
						Clip:SetOwner( self.Owner )
						Clip:SetModel( "models/entities/standard_tta_grenade_clip.mdl" )
						Clip:Spawn()
						
						local MetersPerSecond = 3.4 * 52.4934
						local ClipPhys = Clip:GetPhysicsObject()
						ClipPhys:SetVelocityInstantaneous( ClipPhys:GetVelocity() + ( (self:GetUp()*MetersPerSecond) + (self:GetForward()*-MetersPerSecond*2) ) )
						ClipPhys:SetAngleVelocityInstantaneous( ( self:GetRight() * math.random( 360 , 720 ) ) * math.pi )
						
						timer.Simple( 5 , function() if IsValid(Clip) then Clip:Remove() end end )
						
						Clip:EmitSound("main/grenade_clip_break_"..math.random(1,3)..".mp3", 80, math.random(100,102), 1 )
						
						self:SetBodygroup( 2, 1 )
						
					end
					-----------------------------------------
					end
				end)
				
				timer.Simple( 0.25 , function() 
					if IsValid(self) and IsValid(Grabbing) then 
					
					Grabbing:EmitSound("main/interact_foley_short_"..math.random(1,3)..".wav", 90, math.random(80,90), 0.9 ) 
					
					Grabbing:EmitSound("main/bouncehit.wav", 120 , math.random(80,120) , 1 )
					
					self:GetPhysicsObject():SetVelocity( Grabbing:EyeAngles():Forward() * (343 * 52.4934) * 3 )
					self:FireActivation(Grabbing,true)
					
					ParticleEffect( "Shockwave", self:GetPos() , Angle(0,0,0) )
					
					self:SetOwner( Grabbing )
					
					end
				end )
				
			end
			
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
	
	local phyed = self:GetPhysicsObject()
	
	if self.State == STATE_ARMED then
		local Owner = self:GetOwner()
		
		if not Owner:GetNWBool("AHEE_EQUIPED") then
			Owner:SetNWEntity( "TargetSelected" , nil )
		end
		
		self.Target = IsValid(Owner:GetNWEntity( "TargetSelected" )) and Owner:GetNWEntity( "TargetSelected" ) or self.Target
		if CurTime() > self.NextCharge and IsValid(self.Target) then
			local Target = self.Target
			local Dmg_Array = self:FindDmgTarget()
			local Dist = 1 - (Target:WorldSpaceCenter():Distance(self:WorldSpaceCenter()) / Detection_Radius)
			if Dist > 0 and SERVER then -- or Target:IsPlayer()
				if not IsValid(self.trail) and not IsValid(self.trail2) then
					self.trail = util.SpriteTrail( self, 0, Color( 255, 255, 255 ), true, 10, 0, 0.1, 10, "effects/beam_generic01" )
					self.trail2 = util.SpriteTrail( self, 0, Color( 50, 50, 200 ), true, 50,0, 0.15, 10, "effects/beam_generic01" )
				end
				
				if phyed != nil then
					local CurrentDist = phyed:GetPos():Distance(Target:WorldSpaceCenter())
					local SteerForce = 3850 + math.random(-135,125)
					local AutoDistance = self:WorldSpaceCenter():Distance(Target:WorldSpaceCenter())
					local TriggerDistance = AutoDistance - 100
					local MaxTurnDistance = 150 + math.random(-135,135)
					local MagnitudeVelocity = Vector( math.abs(Target:GetVelocity().x) ^ 0.5 , math.abs(Target:GetVelocity().y) ^ 0.5 , math.abs(Target:GetVelocity().z) ^ 0.5 )
					local MoveVector = ( phyed:GetPos() - (Target:WorldSpaceCenter() + ( MagnitudeVelocity * Target:GetVelocity():GetNormalized() ) )):GetNormalized() * -SteerForce
					local MoveVectorNormalized = MoveVector - (self:GetForward() * SteerForce/1.05)
					local TurnCalc = 1 - math.Clamp( (CurrentDist-MaxTurnDistance)/(TriggerDistance) , 0 , 1 )
					
					phyed:AddVelocity( (MoveVectorNormalized * TurnCalc) - (physenv.GetGravity():GetNormalized() * (physenv.GetGravity():Length() ^ 0.5)) )	
					
				end
				phyed:SetVelocity( phyed:GetVelocity() + ((Target:WorldSpaceCenter() - self:WorldSpaceCenter()):GetNormalized() * (343 * 52.4934) * 2) * math.Clamp(Dist,0,1) )
				self:EmitSound("main/target_tick.wav", 120, 150*((Dist*2)+0.5))
				if Dist < 0.8 then return end
				local Phys = Target:GetPhysicsObject() or Target
				local TargetVelo = IsValid(Phys) and Phys:GetVelocity() or Vector()
				local Vel = ( TargetVelo - phyed:GetVelocity() )
				local Spd = Vel:Length()
				local CanBeTarget = IsValid(Target)
				local TargetVelocityHighSpeed = (Dist > 0.5) or (Spd > (52.4934*3))
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
						
						Target:EmitSound("main/roundhit_softmatter_"..math.random(1,9)..".mp3", 80, math.random(140,150),1)
						hook.Run( "ServerDmgTarget", self , Target , daginfo , dmg_random )
					end
					
					self:SinuousExplosion(self:WorldSpaceCenter(),300)
					util.ScreenShake(Target:WorldSpaceCenter(),120,2,0.1,1500)
					self:EmitSound("main/bouncehit.wav", 80, math.random(80,90),1)
					self:EmitSound("main/incendiarysizzle.mp3", 100, math.random(120,130),1)
					self:EmitSound("main/antispatialknock_highsavor.mp3", 100, math.random(60,65))
					self:EmitSound("main/railexplode.wav", 120, math.random(50,55))
					ParticleEffect( "Flashed", self:GetPos() , Angle(0,0,0) )
					ParticleEffect( "DirtFireballHit", self:GetPos() , Angle(0,0,0) )
					
					self:FragmentOrCreateERBM( self , math.random(5,8) )
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

function ENT:CustomInitialize()
	
	if SERVER then
	self:SetModel(self.Model) 
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	
	self.WindCrackle = CreateSound( self, "main/wind_breaking.mp3")
	self.WindCrackle:SetSoundLevel( 90 )
	
	self.Toggle = true
	self.ButtonPos = self:GetManipulateBonePosition( self:LookupBone( "Button" ) )
	
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


















function ENT:OnRemove()
	hook.Remove( "PostDrawTranslucentRenderables", self )
	
	if self.WindCrackle ~= nil then
		self.WindCrackle:Stop()
	end
	
	return true
end 

function ENT:SpawnFunction( ply, tr, ClassName )
	if ( !tr.Hit ) then return end
	
	local SpawnPos = tr.HitPos + tr.HitNormal * 10
	local SpawnAng = ply:EyeAngles()
	SpawnAng.p = 0
	SpawnAng.y = SpawnAng.y + 180
	
	local ent = ents.Create( ClassName )
	ent:SetPos( SpawnPos )
	ent:SetAngles( SpawnAng )
	ent:Spawn()
	ent:Activate()
	
	return ent
	
end



