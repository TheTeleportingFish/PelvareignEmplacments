AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
include("cl_init.lua")

ENT.Model = "models/ma13aske.mdl"

ENT.Healthed = 100

local MaxSpeed = 300 * 52.4934666667

local phys, ef

if (SERVER) then
	util.AddNetworkString( "DeathNotification" )
	util.AddNetworkString( "ShockwaveFunction" )
end

function TableEntityCheckAndRemove( Table )
	if table.Count( Table ) < 1 then return end
	for Index, v in pairs(Table) do
		if not v:IsValid() then 
			table.remove(Table,Index)
		end
	end
end

function ENT:Initialize()
	self:SetModel(self.Model) 
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	self.NextImpact = 0
	self.NextHealthWarn = 0
	phys = self:GetPhysicsObject()
	
	phys:SetDragCoefficient( 0.01 )

	if phys and phys:IsValid() then
		phys:Wake()
	end
	
	spd = physenv.GetPerformanceSettings()
    spd.MaxVelocity = MaxSpeed
	
	self.TheFuck = CreateSound( self , "npc/strider/striderx_alert2.wav" )
	self.TheFuck:SetSoundLevel( 80 )
	
	self.Cancer = CreateSound( self , "npc/turret_floor/retract.wav" )
	self.Cancer:SetSoundLevel( 140 )
	
    physenv.SetPerformanceSettings(spd)
	
	self:GetPhysicsObject():SetBuoyancyRatio(0)
end

function ENT:FuckingDie()

	if math.random(1,3) == 1 then
		for i = 1 , math.random(1,6) do
			if SERVER then
			OhMyGodPain = ents.Create("emplacement_thefuckingstupid")

			OhMyGodPain:SetPos(self:GetPos() + VectorRand()*math.random(1,10))
			OhMyGodPain:SetAngles(self:GetAngles())
			OhMyGodPain:SetOwner( self )
			OhMyGodPain:Spawn()
				
			for i = 1 , 100 do
			ParticleEffect( "Flashed", OhMyGodPain:GetPos() + VectorRand()*math.random(250,1000), Angle(0,0,0) )
			end
				
			local RoundPhys = OhMyGodPain:GetPhysicsObject()
			RoundPhys:SetVelocityInstantaneous(VectorRand()*math.random(160,2000))

			end
		end
	end

	for i=1, 80 do
	util.ScreenShake( self:GetPos(), 12, 0.1, 0.5, 2000 )
	end
	sound.Play( Sound("CW_FragGrenade_Explode"), self:GetPos() )
	self:EmitSound("CW_FragGrenade_Explode_Back")
	ParticleEffect( "FragExplose", self:GetPos() , Angle(0,0,0) )
	ParticleEffect( "Flashed", self:GetPos() , Angle(0,0,0) )
	ParticleEffect( "Shockwave", self:GetPos() , Angle(0,0,0) )
	
	if SERVER then
		rf = RecipientFilter()
		rf:AddAllPlayers()
	end
	
	net.Start("DeathNotification")
	net.Broadcast()
	
	local explosedist = 800 * 52.4934666667
	
	for k, v in pairs(ents.FindInSphere(self:GetPos(),explosedist)) do
		 if v:IsPlayer() then
			local Dist = ( 1 - (v:GetPos():Distance(self:GetPos())/explosedist)^0.5 )
			local PositionCapture = self:GetPos()
			timer.Simple( ((v:GetPos():Distance(self:GetPos())/explosedist)^0.5 ) *1.5, function() 
				local tr = {}
				tr.start = PositionCapture
				tr.endpos = v:WorldSpaceCenter()
					
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

	self:Remove()
end

function ENT:AnimLerpFunction( InitPoserate , FinalPoserate , Seconds )
local delay = CurTime() + Seconds
local LerpValue = InitPoserate
	return hook.Add( "Think", "AnimLerpFunction", function()
		if CurTime() < delay and self:IsValid() then
			local ratio = 1 - (( delay - CurTime() ) / Seconds)
			--print(CurTime(),delay,ratio)
			LerpValue = Lerp(ratio,InitPoserate,FinalPoserate)
		else
			hook.Remove("Think","AnimLerpFunction")
		end
		return LerpValue
	end)
	
end

local traceData = {}
traceData.mask = bit.bor(CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_DEBRIS, CONTENTS_MONSTER, CONTENTS_HITBOX, CONTENTS_WATER)

function ENT:Use(activator, caller)
		t = t or 3
		
	self:ResetSequenceInfo()
	--self:SetPoseParameter( self:LookupPoseParameter( "bolt_level" ) , self:AnimLerpFunction(  0 , 100 , 1 ) ) 
	
	--print(self:AnimLerpFunction(  0 , 100 , 1 ))
	
	timer.Simple(t, function()
		if self:IsValid() then
			--self:FuckingDie()
			for key, obj in ipairs(player.GetAll()) do
				if obj:Alive() then
					traceData.filter = obj
					
					local direction = (self:GetPos() - obj:GetPos()):GetNormal()
					traceData.start = obj:GetPos()
					traceData.endpos = traceData.start + direction *500
					
					local trace = util.TraceLine(traceData)
					local ent = trace.Entity
				end
			end
		end
	end)
	
	return true
end

function ENT:OnRemove()
	return false
end 

local vel, len, CT, CTd

function ENT:PhysicsCollide(data, physobj)
	vel = physobj:GetVelocity()
	len = vel:Length()
	
	if len > 5000 then -- let it roll
		physobj:SetVelocity(vel * 300) -- cheap as fuck, but it works
	end	
	
	util.ScreenShake( self:GetPos(), 12, 0.1, 0.5, 200 )
	
	if string.match(data.HitEntity:GetModel(),"models/props_c17/furniturestove001a.mdl") then
		data.HitEntity:Remove()
		self:FuckingDie()
	elseif data.HitEntity:IsNPC() then 
		data.HitEntity:EmitSound("vo/npc/male01/ow0"..math.random(1,2)..".wav", 90, math.random(96,103))
		if SERVER then 
			local d = DamageInfo()
			d:SetDamage( 10 * (len/52.4934666667) )
			d:SetAttacker( self )
			d:SetDamageType( DMG_BURN )
			data.HitEntity:TakeDamageInfo( d )
		end
	end
	
	if len > 100 then
		CT = CurTime()
		if CT > self.NextImpact then
			self.Healthed = self.Healthed - 0.1
			self:EmitSound("physics/metal/metal_grenade_impact_hard3.wav", 100, math.random(30,200))
			self.NextImpact = CT + 0.01
		end
	end
end



function ENT:Think()
	physobj = self:GetPhysicsObject()
	vel = physobj:GetVelocity()
	len = vel:Length()
	local Orig_StupidDist = 50 * 52.4934666667
	local StupidDist = Orig_StupidDist
	
	if self.Healthed <= 0 then self:FuckingDie() end
	
	CTd = CurTime()
		
	if CTd > self.NextHealthWarn then
			
	self:EmitSound("ambient/alarms/klaxon1.wav", 70, self.Healthed+100)
	self.NextHealthWarn = CTd + math.abs(math.sin(self.Healthed/110))
	end
	
	if len > 25	then -- let it fly
		
		local TheStupid = math.Clamp((vel:Length()*1.25)/MaxSpeed,0.1,1)*50
		self.Cancer:Play()
		self.TheFuck:Play()
		self.TheFuck:ChangePitch(math.random(9,90))
		self.Cancer:ChangePitch(TheStupid)
		physobj:SetVelocity(vel * 0.99) -- cheap as fuck, but it works
		FindSphereArray = ents.FindInSphere(self:GetPos(),StupidDist+1)
		FindPropTargetsArray = {}
			for k, v in pairs(FindSphereArray) do
			local EnemyClosest
				if IsValid(v) and v != self and v:GetPos():Distance(self:GetPos()) < Orig_StupidDist  then
					TableEntityCheckAndRemove( FindPropTargetsArray )
					
					if v:GetClass() == "emplacement_thefuckingstupid" and table.Count( FindPropTargetsArray ) < 1 then
						EnemyClosest = v
					elseif v:GetModel() == "models/props_c17/furniturestove001a.mdl" then
						if not table.HasValue( FindPropTargetsArray, v ) then
							table.insert(FindPropTargetsArray,v)
						end
						EnemyClosest = v
					end 
					if IsValid(EnemyClosest) then
						local ExtraSpeed = 1
						local Dist = (  (EnemyClosest:GetPos():Distance(self:GetPos())/StupidDist) )
						local speed = (EnemyClosest:GetPos() - self:GetPos()):GetNormalized() * Dist
						if self:WaterLevel() >= 2 then 
						ExtraSpeed = 8
						self:EmitSound("ambient/water/drip"..math.random(1,4)..".wav", 130, math.random(60,100))
						end
						physobj:SetVelocity(vel + (ExtraSpeed*speed*math.random(5,300)))
						StupidDist = EnemyClosest:GetPos():Distance(self:GetPos()) 
					end
				end
			end
	end
	
	if vel:Length() >= (MaxSpeed * 0.9) then
		self:FuckingDie()
	end

		if self:GetPoseParameter( "bolt_level" ) == 100 then
			constraint.Weld( self, game.GetWorld(), 0, 0, 0, false, false )
		end
		
	self:NextThink( CurTime() + 0.1 )
    return true
end

















