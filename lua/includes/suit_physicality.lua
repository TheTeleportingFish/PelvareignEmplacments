	
	include( "includes/suit_base.lua" )
	
	include( "includes/ahee_suit_movement.lua" )
	include( "includes/modules/suit_armor.lua" )
	include( "includes/modules/suit_functions.lua" )
	include( "includes/modules/pelvareign_medical.lua" )
	
	local cablemat = Material( "cable/physbeam" )
	local elecmat = Material( "effects/beam_generic01" )
	local redmat = Material( "cable/redlaser" )
	
	local FilterTones = {}
	local CordinateTones = {}
	local tcd = {}
	
	if not game.SinglePlayer() then
		
		properties.Add( "removeaheesuit", {
			MenuLabel = "#Remove AHEE Suit", -- Name to display on the context menu
			Order = 1000, -- The order to display this property relative to other properties
			MenuIcon = "icon16/fire.png", -- The icon to display next to the property
			
			Filter = function( self, ent, ply ) -- A function that determines whether an entity is valid for this property
				if ( !IsValid( ent ) ) then return false end
				if ( !ent:IsPlayer() ) then return false end
				if ( !ply:IsSuperAdmin() ) then return false end
				
				return ent:GetNWBool( "AHEE_EQUIPED" )
			end,
			
			Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )
			
				self:MsgStart()
					net.WriteEntity( ent )
				self:MsgEnd()
				
			end,
			
			Receive = function( self, length, ply ) -- The action to perform upon using the property ( Serverside )
				local ent = net.ReadEntity()
				
				--	if ( !properties.CanBeTargeted( ent, ply ) ) then return end
				if ( !self:Filter( ent, ply ) ) then return end
				
				
				net.Start( "CLIENT_UNDO_SUIT" )
					net.WriteEntity( ent )
				net.Send( ent )
				
				ent:SetNWBool("AHEE_EQUIPED",false)
				ent:SetNWEntity( "TargetSelected" , nil )
				
				print("AHEE_SUIT_THINK"..ent:SteamID())
				
				hook.Remove( "OnDamagedByExplosion" , ent )
				hook.Remove( "EntityTakeDamage" , ent )
				hook.Remove( "HUDPaint" , ent )
				hook.Remove( "Think" , ent )
				hook.Remove( "PlayerFootstep", ent )
				hook.Remove( "DoPlayerDeath", ent )
				hook.Remove( "PlayerDeath", ent )
				
			end 
			
		} )
	
	end
	
	if SERVER then
		
		util.AddNetworkString( "Shield_Toggle" )
		util.AddNetworkString( "DragShield_Toggle" )
		
		
		util.AddNetworkString( "BodyPart_DoDamage_Client" )
		util.AddNetworkString( "HoldingItem" )
		util.AddNetworkString( "Pelvareign_Physical_Interaction" )
		util.AddNetworkString( "Pelvareign_Interactive_Spawn" )
		util.AddNetworkString( "Pelvareign_Interactive_Collect" )
		
		util.AddNetworkString( "souns_lowsh" )
		util.AddNetworkString( "souns_highsh" )
		
		util.AddNetworkString( "RadiationExposure" )
		util.AddNetworkString( "MalPlhasealSuit_Squeeze" )
		util.AddNetworkString( "RadeonicGrapple_Server" )
		util.AddNetworkString( "Targeting_Ping_Server" )
		util.AddNetworkString( "Targeting_Mains_Change_Ping_Server" )
		util.AddNetworkString( "Target_To_Team_Transfer_Server" )
		
		util.AddNetworkString( "AHEE_SERVER_VALUES" )
		
		util.AddNetworkString( "GettingTargeted" )
		util.AddNetworkString( "GettingTargeted_Server" )
		
		util.AddNetworkString( "Recieve_Suit" )
		util.AddNetworkString( "Recieve_Suit_Server" )
		
		util.AddNetworkString( "Scan_Target" )
		util.AddNetworkString( "IsTarget_Rooted" )
		util.AddNetworkString( "IsTarget_Rooted_Confirm" )
		util.AddNetworkString( "GetClient_AngleToTarget" )
		util.AddNetworkString( "GetClient_AngleToTarget_Recieve" )
		
		util.AddNetworkString( "ShieldStats_Affected_Client" )
		util.AddNetworkString( "Client_Sound_ShockWave" )
		util.AddNetworkString( "CLIENT_UNDO_SUIT" )
		util.AddNetworkString( "AHEE_Targeting_Report" )
		
		util.AddNetworkString( "AHEE_Menu_Client" )
		util.AddNetworkString( "AHEE_Change_Suit_Equipment" )
		
		util.AddNetworkString( "NetDiscovery_Mapping_Request" )
		util.AddNetworkString( "NetDiscovery_Mapping_Receive" )
		
		--------------------------------------------------
		
		util.AddNetworkString( "Pelvareign_Punch" )
		util.AddNetworkString( "Change_Radeonic_Tack" )
		util.AddNetworkString( "Change_Weapon_Battery" )
		util.AddNetworkString( "Change_Weapon_Round" )
		
	end
	
	function PrintEntityName( ent )
		if SERVER then
			return ent:GetName() or nil
		end
	end
	
	function ArrayRemoveInvalid( Array )
		for i, v in pairs(Array) do
			if not v:IsValid() then 
				table.remove(i,Array)
			end
		end
	end
	
	function MalPlhasealSqueeze( Radiation , ply )
		local Plr = ply or LocalPlayer()
		if Plr.MalPlhasealSqueeze then return end
		Radiation = Radiation or false
		
		Plr.MalPlhasealSqueeze = true
		EmitSound( "ahee_suit/malplhaseal_squeeze_suit.mp3" , Vector() , -2 , CHAN_AUTO , 1 , 75 , 0 , 100 )
		if Radiation then
			EmitSound( "ahee_suit/malplhaseal_radiationrate.mp3" , Vector() , -2 , CHAN_AUTO , 1 , 75 , 0 , 100 )
			Plr.SevereRadiation = true
		end
		
		timer.Simple( 1 , function()
			if IsValid(Plr) then
				Plr.MalPlhasealSqueeze = false
				Plr.SevereRadiation = false
			end
		end)
	end
	
	function RadiationEstimate( RadiationAmt , ply )
		local ply = ply or LocalPlayer()
		local RadiationAmt = RadiationAmt or 0
		if ply.ReceivingRadiation then return end
		ply.ReceivingRadiation = true
		
		ply.ReceivedRadiation = RadiationAmt
		timer.Simple( 0.5 , function()
			if IsValid(ply) then
				ply.ReceivedRadiation = 0
				ply.ReceivingRadiation = false
			end
		end )
	end
	
	function CheckShieldingDown( ply )
		if ply.ShieldingList == nil then return end
		local ShieldsDown = 0
		for Shield, Value in pairs(ply.ShieldingList) do
			local TurnedOut = Value[2]
			ShieldsDown = ShieldsDown + (TurnedOut and 1 or 0)
		end
		
		return (ShieldsDown == #ply.ShieldingList)
	end
	
	function CheckShieldingStability( ply )
		if ply.ShieldingList == nil then return end
		
		if ply.Fraise_Stability < 10 then
			return false
		else
			return true
		end
		
	end
	
	function ClientExplosionSound( self, Meters , String , Pitch , Volume )
		
		if SERVER then
		
		local Pitch = Pitch and math.Clamp(Pitch,0,255) or 100
		local Volume = Volume and math.Clamp(Volume,0,1) or 1
		
		local traceData = {}
		traceData.mask = bit.bor(CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_DEBRIS, CONTENTS_MONSTER, CONTENTS_HITBOX, CONTENTS_WATER)
		
		local SoundDistanceMax = Meters * 52.4934
			for k, v in pairs(ents.FindInSphere(self:WorldSpaceCenter(),SoundDistanceMax)) do
				if (IsValid(v) and v:IsPlayer()) then
					local Dist = v:WorldSpaceCenter():Distance(self:WorldSpaceCenter())/SoundDistanceMax
					
					obj = v
					
					local positedplayer = v:WorldSpaceCenter()
					
					direction = ( positedplayer - self:WorldSpaceCenter() )
					
					traceData.filter = {Bouncer,self}
					traceData.start = self:WorldSpaceCenter() 
					traceData.endpos = traceData.start + direction * SoundDistanceMax
					
					local trace = util.TraceLine(traceData)
					
					local ent = trace.Entity
					local fract = trace.Fraction
					
					local isplayer = ent:IsPlayer()
					local isnpc = ent:IsNPC()
					local equal = ent == v
					
					local SpatialWaveFormat = 343 + math.random(-10,150)
					
					if not equal then 
						SpatialWaveFormat = SpatialWaveFormat / ( math.random( 110 , 150 ) / 100 )
						Dist = (Dist ^ math.random( 0.45 , 0.75 ) )
					end
					
					local ContinationWave = ( Dist * SoundDistanceMax ) / ( SpatialWaveFormat * 52.4934 )
					
					net.Start("Client_Sound_ShockWave")
						net.WriteString(String)
						net.WriteFloat(ContinationWave)
						net.WriteFloat(Dist^2)
						net.WriteFloat(Volume)
						net.WriteInt(Pitch,9)
					net.Send(v)
					
					timer.Simple( ContinationWave , function() 
						Dist = 1 - Dist
						v:SetViewPunchAngles(Angle((math.random(-100,100)/50)*((Dist)^2), (math.random(-100,100)/50)*((Dist)^2), (math.random(-100,100)/50)*((Dist)^2)))
					end)
				end
			end
		
		end
		
	end
	
	function ChangeShieldingSetting(self,Shield,Setting,Value,Toggle)
		if not self.ShieldingList then return end
		local Toggle = Toggle or false
		local ShieldToEdit = self.ShieldingList[Shield]
		self.ShieldingList[2] = Toggle
		if ShieldToEdit != nil then
			ShieldToEdit[Setting] = Value
		end
	end
	
	function SerralAnnihilation( ply , link )
		if CLIENT then return end
		local Linked = link or nil 
		local Yield = ( math.random( 2 , 3 ) * 52.4934 )
		local PlyMin , PlyMax = ply:GetHull()
		PlyMax = (PlyMax * 3) + ply:GetPos()
		PlyMin = (PlyMin * 3) + ply:GetPos()
		
		if IsValid(Linked) then 
			sound.Play( Sound("tunneling_physics/bakronic_distresipution_"..math.random(1,3)..".mp3"), ply:WorldSpaceCenter() , 130, math.random(70,110), 1 ) 
			for i=1, math.random(3,7) do
				local DetonationWaveRadius = (math.random(3,6) * 52.4934)
				local Position = Linked:WorldSpaceCenter()+VectorRand()*DetonationWaveRadius
				timer.Simple( math.random(0,350) / 1000 , function()
					sound.Play( Sound("tunneling_physics/caplier_faucation.wav"), Position , 140, math.random(70,130), 1 )
					ParticleEffect( "Flashed", Position , Angle(0,0,0) )
					ParticleEffect( "Shockwave", Position , Angle(0,0,0))
				end)
			end
			
			if IsValid(Linked) then  
				if Linked:IsPlayer() then
					Linked:Kill() 
				end
				Linked:Remove()
			end
		end
		
		for Ident, Entity in pairs( ents.FindInSphere( ply:WorldSpaceCenter() , Yield ) ) do
			local InPosition = Entity:GetPos():WithinAABox( PlyMin, PlyMax ) or Entity:WorldSpaceCenter():WithinAABox( PlyMin, PlyMax )
			if InPosition and Entity != ply and Entity:GetParent() != ply then
				local DetonationWaveRadius = (math.random(3,6) * 52.4934)
				local FractionalCharge = math.random( 1.24936e+4 , 9.17772+4 )
				local Distance = Entity:GetPos():Distance(ply:GetPos())
				local DMGInfor = DamageInfo()
				
				ply:SetVelocity( ((ply:GetPos() - Entity:GetPos()):GetNormalized() * FractionalCharge) * (Distance/Yield) )
				
				if IsValid(Entity) then  
					if Entity:IsPlayer() then
						Entity:Kill()
					end
					Entity:Remove()
				end
				sound.Play( Sound("tunneling_physics/bakronic_distresipution_"..math.random(1,3)..".mp3"), ply:WorldSpaceCenter() , 130, math.random(70,110), 1 ) 
				
				DMGInfor:SetDamage( FractionalCharge )
				DMGInfor:SetDamageType( DMG_RADIATION )
				
				for k, Obj in pairs( ents.FindInSphere( ply:WorldSpaceCenter() , DetonationWaveRadius ) ) do
					if ( Obj ~= ply ) then
						local Dist = ( 1 - ( Obj:WorldSpaceCenter():Distance( ply:WorldSpaceCenter() ) / DetonationWaveRadius ) )
						if ( IsValid(Obj) and IsValid(ply) and IsValid(DMGInfor) ) then
							Obj:SetVelocity( ( ( Obj:WorldSpaceCenter() - ply:WorldSpaceCenter() ):GetNormalized() * Dist ) * math.random(100,900) )
							Obj:TakeDamageInfo( DMGInfor )
						end
					end
				end
				
			end
		end
		
		
	end
	
	function ChangeShielding( self , Energy , OutShield , Attacker )
		local OutShield = OutShield or false
		local EnergyGottenRidOf = Energy
		local Attacker = Attacker or nil
		
		if not self.ShieldingList then return end
		
		if CheckShieldingDown(self) and CheckShieldingStability(self) then
			self.MainCapacitorMJ = (self.MainCapacitorMJ - Energy)
		end
		
		self.Fraise_Stability = self.Fraise_Stability
		
		for Shield, Value in pairs(self.ShieldingList) do
			
			local Num = Value[1]
			local TurnedOut = Value[2]
			local Power = Value[3]
			local MaxPower = Value[4]
			if TurnedOut == false then
				if OutShield == true then
					self.ShieldingList[Shield][3] = 0
					SerralAnnihilation( self , Attacker )
					break
				end
				self.ShieldingList[Shield][3] = math.Clamp(Power - EnergyGottenRidOf, 0 , MaxPower)
				EnergyGottenRidOf = math.Clamp(EnergyGottenRidOf - Power, 0 , EnergyGottenRidOf)
				if self.ShieldingList[Shield][3] == 0 then SerralAnnihilation( self , Attacker ) end
				if EnergyGottenRidOf > 0 then break end
			end
		end
		
	end
	
	local function ragdollPlayer( v )
		if v:InVehicle() then
			local vehicle = v:GetParent()
			v:ExitVehicle()
		end
		
		self.getSpawnInfo( v ) -- Collect information so we can respawn them in the same state.
		
		local ragdoll = ents.Create( "prop_ragdoll" )
		ragdoll.ragdolledPly = v
		
		ragdoll:SetPos( v:GetPos() )
		local velocity = v:GetVelocity()
		ragdoll:SetAngles( v:GetAngles() )
		ragdoll:SetModel( v:GetModel() )
		ragdoll:Spawn()
		ragdoll:Activate()
		v:SetParent( ragdoll ) -- So their player ent will match up (position-wise) with where their ragdoll is.
		-- Set velocity for each peice of the ragdoll
		local j = 1
		while true do -- Break inside
			local phys_obj = ragdoll:GetPhysicsObjectNum( j )
			if phys_obj then
				phys_obj:SetVelocity( velocity )
				j = j + 1
			else
				break
			end
		end
		
		v:Spectate( OBS_MODE_CHASE )
		v:SpectateEntity( ragdoll )
		v:StripWeapons() -- Otherwise they can still use the weapons.
		
		ragdoll:DisallowDeleting( true, function( old, new )
			if v:IsValid() then v.ragdoll = new end
		end )
		v:DisallowSpawning( true )
		
		v.ragdoll = ragdoll
		ulx.setExclusive( v, "ragdolled" )
	end

	local function unragdollPlayer( v )
		v:DisallowSpawning( false )
		v:SetParent()
		
		v:UnSpectate() -- Need this for DarkRP for some reason, works fine without it in sbox
		
		local ragdoll = v.ragdoll
		v.ragdoll = nil -- Gotta do this before spawn or our hook catches it
		
		if not ragdoll:IsValid() then -- Something must have removed it, just spawn
			ULib.spawn( v, true )
			
		else
			local pos = ragdoll:GetPos()
			pos.z = pos.z + 10 -- So they don't end up in the ground
			
			ULib.spawn( v, true )
			v:SetPos( pos )
			v:SetVelocity( ragdoll:GetVelocity() )
			local yaw = ragdoll:GetAngles().yaw
			v:SetAngles( Angle( 0, yaw, 0 ) )
			ragdoll:DisallowDeleting( false )
			ragdoll:Remove()
		end
		
		ulx.clearExclusive( v )
	end
	
	local function OverrideHook(n, f, c)
		local h = hook.GetTable()[n]
		if h then
			for k,v in pairs(h) do
				local o = v
				v = function(...)
					local args = {...}
					local callback = f(...)
					if callback then 
						if callback == true then
							return
						else
							args = {f(...)}
						end
					end
					return o(unpack(args))
				end
				hook.Add(n, k, v)
			end
		end
	end
	
	-- Helper function for ULib.spawn()
local function doWeapons( player, t )
	if not player:IsValid() then return end -- Drat, missed 'em.

	if t.curweapon then
		player:SelectWeapon( t.curweapon )
	end
end

function FindClosestToPos( TargetArray , Ply )
	local Ply = Ply or LocalPlayer()
	local Result = nil
	local Distance = math.huge 
	
	for k , Target in pairs( TargetArray ) do 
		if IsValid(Target) and Target != Ply then
			if Target:GetPos():DistToSqr(Ply:GetPos()) < Distance then 
				Result = Target 
				Distance = Target:GetPos():DistToSqr(Ply:GetPos()) 
			end
		end
	end
	return Result
end

	-- function SWEP:CheckPosVelocity()
		-- if not self then return end
		-- timer.Simple(0.001, function() 
			-- if not IsValid(self) then return end
			-- local Velocity = self.Owner:GetPos()
			
			-- Vectored = Velocity
		-- end)
		-- return Vectored
	-- end

	-- function SWEP:CheckGForce()
		-- if not self then return end
		-- local Velocity = 0
		-- timer.Simple(0.001, function() 
			-- if not IsValid(self) then return end
			-- timer.Simple(0.001, function() 
				-- if not IsValid(self) then return end
				-- local Velocity = self.Owner:GetPos()
				
				-- DiffVectored = Velocity
			-- end)
			-- -- local Velocity = math.Round(((self.Owner:GetVelocity():Length()*0.75)*2.54)/100,2)
			-- local Velocity = math.Round(((self.Owner:GetPos():Distance(DiffVectored)*0.75)*2.54)/100,2) 
			
			-- Veloed = Velocity
		-- end)
		-- return Veloed
	-- end
	
	function Shared_Startup(plr)
		
		print( "yes" , plr:GetNWBool("AHEE_EQUIPED") , plr )
		
		if not IsValid( plr ) then return end
		local self = plr
		
		PrecacheParticleSystem( "DirtFireballHit" )
		
		self.ExhaustLoop = CreateSound( self,"ahee_suit/ahee_exhaust_loop.mp3")
		self.FanLoop = CreateSound( self,"ahee_suit/ahee_fan_loop.mp3")
		self.ServoLoop = CreateSound( self,"ahee_suit/ahee_servo_loop.mp3")
		
		self.TychronicLightNoise = CreateSound( self,"ahee_suit/tychronicinverter.mp3")
		self.PullingGForce = CreateSound( self,"ahee_suit/gforce_pull.mp3")
		self.GForceBreathing = CreateSound( self,"ahee_suit/heavybreathe.mp3")
		self.GForceTackle = CreateSound( self,"ahee_suit/suit_gforcetackle.wav")
		
		self.MalPlhasealSqueeze = false
		self.SevereRadiation = false
		self.ExtremeGForceCalibration = false
		
		self.IndexedDeltaMains = 0
		self.InducedDeltaMains = 0
		self.DeltaMains = 0
		
		self.InducedGForce = 0
		self.DeltaVelocity = 0
		self.IndexedVelocity = 0
		
		self.NetMass = 2258.6
		self.ConsciousVision = 0
		self.MaxPullDist = (52.4934 * 50)				--Meters
		self.GrapplePull = 0.8								--Number
		self.WADSuppression = 1							--Number
		self.RadiationTargetingPrevention =	100 		--Percent
		self.TychronicLight = 0							--Watts
		self.TychronicInverterThrottle = 0
		self.InteractionType = "Grab"
		
		self.IsIgnited = false
		self.ReceivedRadiation = 0
		self.ReceivingRadiation = false
		
		self.selfswepHolstered = true
		self.RadeonHookHitPos = nil
		
		self.MainCapacitorMJ = 47960000.0
		self.MainCapacitorMJLimit = 47960000.0 
		
		self.ReactorToAdaptiveMains = 0
		self.ReactorToAdaptiveEnergy = 0
		
		self.ShieldingSetting = true
		self.ShieldingBufferEnergy = 1000000.0 
		self.ShieldingBufferEnergyLimit = 1000000.0 
		self.ShieldingBufferEnergyLocked = false
		
		self.DragShieldingSetting = true
		self.DragShieldingBuffer = 100.0 
		self.DragShielding = 1000000.0
		self.DragShieldingLimit = 1000000.0
		
		self.FireCapacitorEnergy = 8200000.0 
		self.FireCapacitorEnergyLimit = 8200000.0 
		self.FireCapacitorEnergyLocked = false
		
		self.InternalInterest_Pos = self:WorldSpaceCenter()
		
		self.A9_Team_List = {}
		
		self.Targeting_Mains = {
			Interest_Focus = self:WorldSpaceCenter(),
			Focus_Points = {self:WorldSpaceCenter(),self:WorldSpaceCenter(),self:WorldSpaceCenter()},
			Focus_PointsAmount = 3,
			Focus_PowerDensity = 60, --Watts/Meter^3
			Focus_Efficiency = 20, --%
			Focus_Type = "Pulse",
			Target_PowerMains = false
		}
		
		self.System_Tacks = {
			Radeonic_Tack = { 
				System_Internal_Switch = false,
				System_Power = 0, --Joules / MicroJoule
				System_Purity = 0, --Percent by MicroJoule
				System_Dissociation = 0, --Percent of Effective Burn
				System_Error = 0, --Percent
				System_Density = 0, --Meter / Second / KiloJoule
				System_Operation_Count = 0, --600000 Nominal
			},
			Bakronic_Tack = false,
			Tychronic_Tack = false,
			Nephronic_Tack = false,
		}
		
		self.JammerStats = 
		{
			Radeonic_RecieverFrequency = 0.5,
			Radeonic_RecieverAmplitude = 72,
			Radeonic_RecieverOrder = 13,
			Radeonic_RecieverType = "Bakronic"
		}
		
		self.RadeonicGrapplePack = 
		{
			RangeOrder = 50, --Meters
			PullAxis = 0, --Degrees / Meters / Second
			EnergyYield = 10, --Meters / Second / Joule / Watt
			BufferEnergy = 500000, --MegaJoules
			MaxBufferEnergy = 500000, --MegaJoules
			Charge = 500, --WattResistance
			Frequency = 20000, --Hertz
			BufferLoad = 0, --Watts
			Stability = 100.00, --%
			Hooking = false
		}
		
		self.CadronicInventory = 
		{
			Energy = 50000, --GigaJoules
			MaxEnergy = 50000, --GigaJoules
			Volume = 0, --Liters
			MaxVolume = 6000, --Liters
			Items = {}
		}
		
		self.ArmoredSuiting = 
		{
			ArmorParts = { --Name , ElasticityMod , MatPoints , MaxTemp , EnergyDen , Hitgroup
				Head = 		SetUp_Armoring( "Helmet"		, 200		, 75		, 872000000		, 950		, HITGROUP_HEAD ),
				PeltaCore = 	SetUp_Armoring( "PeltaCore"	, 200		, 32		, 128000000		, 175		, HITGROUP_HEAD ),
				
				Chest = 		SetUp_Armoring( "Chest"		, 800		, 760		, 93000000		, 85		, HITGROUP_CHEST ),
				Abdomen = 	SetUp_Armoring( "Abdomen"	, 800		, 760		, 93000000		, 85		, HITGROUP_STOMACH ),
				
				R_Arm = 		SetUp_Armoring( "Right Arm"	, 300		, 320		, 19875000		, 185		, HITGROUP_RIGHTARM ),
				L_Arm = 		SetUp_Armoring( "Left Arm"	, 300		, 320		, 19875000		, 185		, HITGROUP_LEFTARM ),
				
				R_Leg = 		SetUp_Armoring( "Right Leg"	, 700		, 120		, 99955000		, 885		, HITGROUP_RIGHTLEG ),
				L_Leg = 		SetUp_Armoring( "Left Leg"	, 700		, 120		, 99955000		, 885		, HITGROUP_LEFTLEG )
			}
		}
		
		self.MedicalStats = 
		{
			CurHealth = self:Health(),
			Bleeding = false,
			Internal_Bleeding = false,
			HeartAttack = false,
			Tension = 50.0, -- Percent
			
			PhysiologicalExhaustion = 1.0, -- Percent
			PhysiologicalExertion = 0.0, -- Percent
			BloodToxicity = 0.0, -- Percent
			
			PhysiologicalMobility = 100.0, -- Percent
			Blood = 5200.0, -- MilliLiters
			HeartRate = 800, -- BPM
			Hydration = 100.0, -- Percent
			BloodPressure = { 400 , 390 }, -- Systolic / Diastolic
			HistoAdrenalineRate = 0.0, -- Percent
			Consciousness = 100.0, -- Percent
			Mobility = 100.0, -- Percent
			
			DamagablePartitions = {},
			
			BodyParts = { --Name , Soft , Circ , Bone , BloodlossMult , MobilityPercentage , Hitgroup
				Head = 		SetUp_BodyPart( "Head"			, 200		, 5		, 350		, 3		, 30		, HITGROUP_HEAD ),
				
				Chest = 		SetUp_BodyPart( "Chest"		, 1200	, 380		, 900		, 0.7		, 10		, HITGROUP_CHEST ),
				Abdomen = 	SetUp_BodyPart( "Abdomen"	, 900		, 360		, 15		, 1.1		, 0		, HITGROUP_STOMACH ),
				
				R_Arm = 		SetUp_BodyPart( "Right Arm"	, 300		, 120		, 330		, 0.9		, 5		, HITGROUP_RIGHTARM ),
				L_Arm = 		SetUp_BodyPart( "Left Arm"	, 300		, 120		, 330		, 0.9		, 5		, HITGROUP_LEFTARM ),
				
				R_Leg = 		SetUp_BodyPart( "Right Leg"	, 700		, 200		, 400		, 2		, 25		, HITGROUP_RIGHTLEG ),
				L_Leg = 		SetUp_BodyPart( "Left Leg"		, 700		, 200		, 400		, 2		, 25		, HITGROUP_LEFTLEG )
			},
			
			Organs = {}
			
		}
		
		for Key, Value in pairs( self.MedicalStats.BodyParts ) do
			self.MedicalStats.DamagablePartitions[Key] = { Small = {} , Medium = {} , Large = {} , Low = {} , Severe = {} }
		end
		
		self.ShieldingList = {}
		self.ShieldingActiveShot = true
		self.Fraise_Malformation_Percentage = 0.0 --percentage of fraise area
		self.Fraise_Stability = 0.0 --percentage of fraise area
		self.Fraise_Stable = false
		self.Fraise_Frequency = 20000000.0 --Hertz
		
		for i=1, 7 do
			local Layer = { 
				["Shield"..i] = {  -- Index, TurnedOffBool, Power, MaxPower, Name, PowerReleaseMult
					i , 
					false , 
					i*80000.0 , 
					i*80000.0 , 
					"Shield Layer "..( 8 - i ), 
					math.Round( ( (i^2) / 49 ) , 3 ),
					TurnOff = false
				} 
			}
			table.Add( self.ShieldingList, Layer )
		end
		
		if CLIENT then
			LocalInteractables = LocalInteractables or {}
			
			self.TycronicVision = false
			self.Tycronic_NephronicVision = false
			
			TargetedRadiationExposure = 0
			TotalEnergyUsage = 0
			
			self.CordinateAlarm = CreateSound( self,"ahee_suit/alramm_system/CordinateTones/CordinateAlarm.wav")
			self.CordinateAlarm_CalcOn = CreateSound( self,"ahee_suit/alramm_system/CordinateTones/CordinateAlarm_CalcOn.wav")
			self.CordinateAlarm_JackingDesignation = CreateSound( self,"ahee_suit/alramm_system/CordinateTones/CordinateAlarm_JackingDesignation.wav")
			self.CordinateAlarm_Scrambled = CreateSound( self,"ahee_suit/alramm_system/CordinateTones/CordinateAlarm_Scrambled.wav")
			
			self.LockedFilter = CreateSound( self,"ahee_suit/alramm_system/FilterTones/LockedFilter.wav")
			self.CloseFilter = CreateSound( self,"ahee_suit/alramm_system/FilterTones/CloseFilter.wav")
			self.VeryCloseFilter = CreateSound( self,"ahee_suit/alramm_system/FilterTones/VeryCloseFilter.wav")
			self.CautionFilter = CreateSound( self,"ahee_suit/alramm_system/FilterTones/CautionFilter.wav")
			self.DangerFilter = CreateSound( self,"ahee_suit/alramm_system/FilterTones/DangerFilter.wav")
			
		end
		
		if SERVER then
			self:SetBloodColor( -1 )
			
		end
		
		self.AHEEMENU_ISOPEN = false
		
		self.AHEE_System = { 
			AHEE_CALC = false ,
			AHEE_CALC_USAGE = 600 , -- Watts
			AHEE_CALC_RANGE = 50 -- Meters
		}
		
		self.AHEE_Core = { 
			AHEE_MANUAL = false ,
			
			AHEE_CORE_LOADALLOWANCE = 100.0 , -- Percent
			AHEE_CORE_PRESSUREFLOW = 1200000000000 , --Meter^8
			AHEE_CORE_DENSITY = 50000 , -- Watt / Radeonic / Bakronic / Second
			
			AHEE_CORE_YIELDTYPE = "Geometrical Close" , -- Type of Yield, Yield should averagely be ' Type 3 Liminality State ' 
			AHEE_CORE_SPEED = 3200000 , -- RPM
			AHEE_CORE_FLOW = 0 , -- Meter^3 / Watt / Meter / Second
			AHEE_CORE_RPMYIELD = 25 , -- Watt / RPM
			
			AHEE_CORE_ABLATION = 100.0 , -- Percent
			AHEE_CORE_STRUCTURE_ABLATION = 0.0 , -- Percent
			
			AHEE_CORE_INJECTION_RATE = 60 , -- Meter^3 / Second
			
			AHEE_CORE_TEMPERATURE = 5000000 , -- Kelvin
			AHEE_CORE_STRUCTURE_HEALTH = 100.0 -- Percent
		}
		
		self.AHEE_Cooling = { 
			AHEE_MANUAL = false ,
			
			AHEE_FAN = true ,
			AHEE_FAN_SPEED = 0 , -- RPM
			
			AHEE_COOLING_USAGE = 9200000 , -- Watts
			AHEE_COOLING_PRESSURE = 0 , -- Pascals
			AHEE_COOLING_FLOW = 0 , --Meter^2
			AHEE_COOLING_DENSITY = 0 -- Watts / Meter^2 * Kelvin
		}
		
		self.PelvareignInteractables = {}
		self.Occupied = { State = false , Type = "" }
		
		self.MainCapacitorOutOfEnergy = false
		self.MainCapacitorBreak = false
		
		hook.Add( "PlayerFootstep", self, function( attachment, ply, pos, foot, sound, volume, rf )
			if (attachment:IsPlayer() and IsValid(ply) and ply:GetNWBool("AHEE_EQUIPED")) then
				local FootIntensity = math.Clamp( ((self:GetVelocity():Length()/52.4934) / 20 ) + 0.25 , 0.25, 1 )
				local FootIntensityPitch = math.Clamp( ((self:GetVelocity():Length()/52.4934) / 20 ) + 0.75 , 0.75, 1 )
				
				if self != ply then return end
				
				local Exhaustion = math.Clamp( (math.abs(self.MedicalStats.Tension - 50) * 2) / 100 , 0 , 1 ) ^ 2
				
				self.MedicalStats.PhysiologicalExertion = self.MedicalStats.PhysiologicalExertion + (math.Clamp( ( self:GetVelocity():Length()/52.4934 ) , 0 , 150 ) * 0.1 )
				
				self:SetRunSpeed( 300 + ((self.MedicalStats.PhysiologicalMobility/100) * 1000 * (1-Exhaustion)) )
				self:SetWalkSpeed( 30 + ((self.MedicalStats.PhysiologicalMobility/100) * 200) )
				
				
				local EnergySuppression = ( self:GetVelocity():Length() / 52.4934 ) ^ self.WADSuppression
				
				if self.WADSuppression == 1 then
					self:EmitSound( "ahee_suit/a9er_footstep_"..math.random(1,3)..".mp3", 90, FootIntensityPitch * math.random(100,120), FootIntensity )
					util.ScreenShake(pos, 9, 9000, 0.1, (3*52.4934) * FootIntensity )
					util.ScreenShake(pos, 5, 100, 0.2, (5*52.4934) * FootIntensity )
					
				elseif self.WADSuppression == 2 then
					self:EmitSound( "ahee_suit/wavelength_absorption_device_footstep_"..math.random(1,5)..".mp3", 70, FootIntensityPitch * math.random(55,60), FootIntensity )
					util.ScreenShake(pos, 4, 750, 0.3, (1*52.4934) * FootIntensity )
					util.ScreenShake(pos, 2, 1, 0.5, (3*52.4934) * FootIntensity )
					
					self.MainCapacitorMJ = math.Clamp( (self.MainCapacitorMJ - EnergySuppression) , 0 , self.MainCapacitorMJ )
					
				elseif self.WADSuppression == 3 then
					self:EmitSound( "ahee_suit/wavelength_absorption_device_footstep_"..math.random(1,5).."_triple.mp3", 50, math.random(38,40), FootIntensity )
					util.ScreenShake(pos, 1, 5, 0.5, (0.1*52.4934) * FootIntensity )
					
					self.MainCapacitorMJ = math.Clamp( (self.MainCapacitorMJ - EnergySuppression) , 0 , self.MainCapacitorMJ )
					
				elseif self.WADSuppression == 4 then
					self:EmitSound( "ahee_suit/wavelength_absorption_device_footstep_"..math.random(1,5).."_triple.mp3", 30, math.random(20,23), FootIntensity / 3 )
					
					self.MainCapacitorMJ = math.Clamp( (self.MainCapacitorMJ - (EnergySuppression * 2)) , 0 , self.MainCapacitorMJ )
					
				end
				
				return true -- Don't allow default footsteps, or other addon footsteps
			end
		end )
		
		hook.Add( "EntityEmitSound", self, function( attachment, t )
			if attachment:GetNWBool("AHEE_EQUIPED") and attachment:IsPlayer() and IsValid(attachment) then
				
				return SuitAudio( attachment , t )
			end
		end )
		
		self.Orig_Model = self:GetModel()
		--self:SetModel( "models/player/a9er_mas_unit.mdl" )
		
		Body_PhysioMobilityCalc( self )
		self:SetNWBool("AHEE_EQUIPED",true)
		
	end
	
	function AHEE_ATTACHED( plr )
		
		local self = plr
		if not IsValid(self) then return end
		if not plr:GetNWBool("AHEE_EQUIPED") then
			return
		end
		
		if SERVER then
			self:Give( "weapon_fists" ) 
			self:Give( "none" )
			
			--OverrideHook("OnRemove", function(ent)
				--if not self.ShieldingSetting and CheckShieldingDown(self) then return true end
			--end)
			
			--OverrideHook("CreateRagdoll", function(ent)
				--if not self.ShieldingSetting and CheckShieldingDown(self) then return true end
			--end)
			
			--OverrideHook("KillSilent", function(ent)
				--if not self.ShieldingSetting and CheckShieldingDown(self) then return true end
			--end)
			
			--OverrideHook("EntityRemoved", function(ent)
				--if not self.ShieldingSetting and CheckShieldingDown(self) then return true end
			--end)
		end
		
		--self.spawn( plr, false )
		
		local GlobalTargetedNpc = self:GetNWEntity( "TargetSelected" )
		local Owner = self
		
		local tr = { collisiongroup = COLLISION_GROUP_WORLD }
		function util.IsInWorld( pos )
			tr.start = pos
			tr.endpos = pos
			tr.mins = Vector( -16, -16, 0 )
			tr.maxs = Vector( 16, 16, 71 )
			return util.TraceHull( tr ).Hit
		end
		
		function self.getSpawnInfo( player )
			local result = {}

			local t = {}
			player.SpawnInfo = t
			t.health = player:Health()
			t.armor = player:Armor()
			if player:GetActiveWeapon():IsValid() then
				t.curweapon = player:GetActiveWeapon():GetClass()
			end

			local weapons = player:GetWeapons()
			local data = {}
			for _, weapon in ipairs( weapons ) do
				printname = weapon:GetClass()
				data[ printname ] = {}
				data[ printname ].clip1 = weapon:Clip1()
				data[ printname ].clip2 = weapon:Clip2()
				data[ printname ].ammo1 = player:GetAmmoCount( weapon:GetPrimaryAmmoType() )
				data[ printname ].ammo2 = player:GetAmmoCount( weapon:GetSecondaryAmmoType() )
			end
			t.data = data
		end

		--[[
			Function: spawn

			Enhanced spawn player. Can spawn player and return health/armor to status before the spawn. (Only IF ULib.getSpawnInfo was used previously.)
			Clears previously set values that were stored from ULib.getSpawnInfo.

			Parameters:

				ply - The player to grab information for.
				bool - If true, spawn will set player information to values stored using ULib.SpawnInfo

			Returns:

				Spawns player. Sets health/armor to stored defaults if ULib.getSpawnInfo was used previously. Clears SpawnInfo table afterwards.
		]]
		function self.spawn( player, bool )
			player:Spawn()

			if bool and player.SpawnInfo then
				local t = player.SpawnInfo
				player:SetHealth( t.health )
				player:SetArmor( t.armor )
				timer.Simple( 0.1, function() doWeapons( player, t ) end )
				player.SpawnInfo = nil
			end
		end
		
		local function TraceOrCone( TraceEnt , ConeEnt )
			local TraceIsValid, ConeIsValid = IsValid(TraceEnt), IsValid(ConeEnt)
			
			if (not TraceIsValid and ConeIsValid) then
				Ent = ConeEnt
			elseif (TraceIsValid and not ConeIsValid) then
				Ent = TraceEnt
			elseif (TraceIsValid and ConeIsValid) then
				Ent = TraceEnt
			end
			
			return Ent
		end
		
		function self:CheckNumberOfShieldingDamaged()
			local ShieldsDamaged = 0
			local ShieldList = self.ShieldingList
			for Shield, Value in pairs(self.ShieldingList) do
				local Current = Value[3]
				local Max = Value[4]
				ShieldsDamaged = ShieldsDamaged + ((Current<Max) and 1 or 0)
			end
			
			return ShieldsDamaged, #ShieldList
		end
		
		function self:CheckNumberOfShieldingDown()
			local ShieldsDown = 0
			local ShieldList = self.ShieldingList
			for Shield, Value in pairs(self.ShieldingList) do
				local TurnedOut = Value[2]
				ShieldsDown = ShieldsDown + (TurnedOut and 1 or 0)
			end
			
			return ShieldsDown, #ShieldList
		end
		
		local OwnerCenter = self:WorldSpaceCenter()
		self:SetViewPunchAngles( self:GetViewPunchAngles() + Angle( math.Clamp( self:GetForward():Dot(self:GetVelocity()/52.4934)/20 , -5 , 5 ) + math.Clamp(self:GetUp():Dot(self:GetVelocity()/52.4934)/20,-5,5) , math.Clamp(self:GetRight():Dot(self:GetVelocity()/52.4934)/20,-2,2) , math.Clamp(self:GetRight():Dot(self:GetVelocity()/52.4934)/20,-5,5) )/math.pi )
		
		--self.IndexedVelocity = math.Round(((self:GetPos():Distance(self:CheckPosVelocity())*0.75)*2.54)/100,2) or self.IndexedVelocity
		--self.DeltaVelocity = self:CheckGForce() or self.DeltaVelocity
		
		local PlayerBounds_Min, PlayerBounds_Max = self:GetHitBoxBounds(0,0)
		PlayerBounds_Min = PlayerBounds_Min or Vector()
		PlayerBounds_Max = PlayerBounds_Max or Vector()
		
		local RealGunPos = self:WorldSpaceCenter() + (PlayerBounds_Max * Vector(0,0,4))
		
		timer.Simple(0.01, function() 
			if not IsValid(self) then return end
			self.DeltaVelocity = math.Round( ( self:GetVelocity():Length() / 52.4934 ) , 2 ) or self.DeltaVelocity
			self.DeltaMains = self.MainCapacitorMJ or self.DeltaMains
		end)
		
		self.IndexedVelocity = math.Round((self:GetVelocity():Length()/52.4934),2)
		self.IndexedDeltaMains = self.MainCapacitorMJ
		
		if (not self.NetMass) then self.NetMass = 2258.6 return end
		if (not self.IndexedVelocity) then print("no Velocity") return end
		if (not self.DeltaVelocity or not self.DeltaMains) then print("no Delta") return end
		self.InducedGForce = math.Round(( (math.abs(self.IndexedVelocity - self.DeltaVelocity)^2) / 0.005) * 0.101971621 , 2)
		self.InducedDeltaMains = math.Round( self.IndexedDeltaMains - self.DeltaMains , 3)
		
		if (self.InducedGForce > 1000) and SERVER then
			if not self.DragShieldingSetting or self.DragShielding < (self.DragShieldingLimit * 0.1) then
				BodyPart_DoDamage( self , 0 , self.InducedGForce / 1000 )
				net.Start( "BodyPart_DoDamage_Client" )
				net.WriteString( "0" )
				net.WriteFloat( self.InducedGForce / 1000 )
				net.Send( self )
			end
		end
		
		DragBufferRetry = DragBufferRetry or 0
		
		local ForceInduced = ((self.InducedGForce / 0.101971621) + self.IndexedVelocity) * self.NetMass
		local CompensatingYield = (8.98755e+9) / (self.DragShielding + 1)  -- Coulomb Constant 8.9875517923(14)×10^9 kg⋅m3⋅s−2⋅C−2
		local RestrictedForces = math.abs( (ForceInduced) / (CompensatingYield+1) ) or 0
		local EnergyDensity = (CompensatingYield-RestrictedForces) / CompensatingYield
		
		if not self.MainCapacitorMJ then print("no Energy") return end
		
		local DragShieldingAmount = math.Clamp( (self.DragShieldingLimit-self.DragShielding) , 0 , self.DragShieldingLimit * 0.005 ) * (self.DragShieldingBuffer/100) 
		
		if self.DragShieldingSetting then
			self.DragShielding = math.Clamp( self.DragShielding - ((RestrictedForces / CompensatingYield) * (1-(self.DragShieldingBuffer/ 100)) ) , 0 , self.DragShieldingLimit )
			self.DragShieldingBuffer = math.Round( math.Clamp( self.DragShieldingBuffer + EnergyDensity , 0 , 100) , 1 )
			
			self.MainCapacitorMJ = math.Clamp(self.MainCapacitorMJ - (DragShieldingAmount),0,self.MainCapacitorMJ)
			self.DragShielding = math.Clamp(self.DragShielding + DragShieldingAmount,0,self.DragShieldingLimit)
			
			if ( self.DragShieldingBuffer < 25 ) then
				if (not DragBufferRetry or (CurTime() > DragBufferRetry)) then 
					local Ratio = 1-(self.DragShieldingBuffer/100)
					self:EmitSound( "tunneling_physics/dragantiform_reanihilation.mp3", 130, math.random(90,110), 1 ) 
					sound.Play( Sound("high_energy_systems/tacklecatics_endshock.mp3"), self:WorldSpaceCenter() , 90, math.random(140,200), 1 ) 
					DragBufferRetry = CurTime() + 1.5 - (1.25*Ratio)
					
					self:EmitSound("ahee_suit/suit_system_calc.mp3", 80, math.random(100,105),0.9)
					if SERVER then
						local HitPoint = ( self:WorldSpaceCenter() + (self:GetVelocity():GetNormalized() * (self:GetVelocity():Length() ^ 0.5)) + VectorRand() * 45 )
						DragShieldHit_Shared( self , HitPoint , 6)
						util.ScreenShake( HitPoint , 5 , 0.01 , 0.5 , 800 )
					end
					
				end
			end
			
		end
		
		
		local FireRecharge = math.Clamp( (self.FireCapacitorEnergyLimit-self.FireCapacitorEnergy) , 0 , (self.FireCapacitorEnergyLimit*0.001) )
		
		self.FireCapacitorEnergy = math.Clamp( self.FireCapacitorEnergy + FireRecharge , 0 , self.FireCapacitorEnergyLimit )
		self.MainCapacitorMJ = math.Clamp( self.MainCapacitorMJ - FireRecharge , 0 , self.MainCapacitorMJ )
		
		FireExtinguishRetry = FireExtinguishRetry or 0
		
		if (self.FireCapacitorEnergy <= (self.FireCapacitorEnergyLimit * 0.01)) then
			self.FireCapacitorEnergyLocked = true
		elseif (self.FireCapacitorEnergy > (self.FireCapacitorEnergyLimit * 0.15)) then
			self.FireCapacitorEnergyLocked = false
		end
		
		if self:IsOnFire() or self.IsIgnited then
			if self.FireCapacitorEnergyLocked then
				if (not FireExtinguishRetry or (CurTime() > FireExtinguishRetry)) then 
					local Ratio = self.FireCapacitorEnergy/(self.FireCapacitorEnergyLimit*0.15)
					sound.Play( Sound("ahee_suit/epdd_system/epdd_system_failuretoexinguish_"..math.random(1,4)..".mp3"), OwnerCenter , 80, math.random(98,102), 0.5 ) 
					sound.Play( Sound("tunneling_physics/radeonic_distresipution_wave_"..math.random(1,7)..".mp3"), OwnerCenter , 130, math.random(98,102), 1 ) 
					FireExtinguishRetry = CurTime() + 0.5 - (0.4*Ratio)
				end
			else
				ParticleEffect( "SmokeShockFar", OwnerCenter + (VectorRand() * math.random(50,200)) , self:EyeAngles() )
				
				self.IsIgnited = false
				
				if SERVER then
					self:Extinguish()
					util.ScreenShake(self:WorldSpaceCenter(),5,0.1,0.01,580)
					sound.Play( Sound("ahee_suit/epdd_system/epdd_system_extinguish_"..math.random(1,7)..".mp3"), OwnerCenter , 80, math.random(98,102), 1 ) 
					self.FireCapacitorEnergy = math.Clamp( self.FireCapacitorEnergy - math.random(150000,320000) , 0 , self.FireCapacitorEnergyLimit )
				end
				
			end
		end
		
		if SERVER then
			net.Start( "AHEE_SERVER_VALUES" )
				net.WriteEntity( self )
				net.WriteFloat( self.MainCapacitorMJ )
				net.WriteFloat( self.ShieldingBufferEnergy )
				
				net.WriteFloat( self.DragShielding )
				net.WriteFloat( self.DragShieldingBuffer )
				
				net.WriteFloat( self.FireCapacitorEnergy )
				
				net.WriteBool( self.MainCapacitorBreak )
				net.WriteBool( self.ShieldingBufferEnergyLocked )
				
				for Shield, Value in pairs(self.ShieldingList) do
					-- Index, TurnedOffBool, Power, MaxPower, Name, PowerReleaseMult
					
					net.WriteInt( Value[1] , 32 )
					net.WriteBool( Value[2] )
					net.WriteFloat( Value[3] )
					net.WriteFloat( Value[4] )
					net.WriteString( Value[5] )
					net.WriteFloat( Value[6] )
					
				end
				
			net.Send( self )
		end
		
		if self:IsFlagSet( FL_FROZEN ) and not CheckShieldingDown( self ) and CheckShieldingStability(self) then
			self:RemoveFlags( FL_FROZEN )
			ChangeShielding(self,0,true)
		end
		
		if not self.ShieldingList then return end
		
		local FraiseStability_RndNumber = math.Round(self.Fraise_Stability,1)
		
		if self.ShieldingSetting then
			Stability_Change = 100.0
			StabilityDelta = math.Round(Stability_Change - FraiseStability_RndNumber,1)
			
		else
			Stability_Change = 0.0
			StabilityDelta = math.Round(Stability_Change - FraiseStability_RndNumber,1)
			
		end
		
		if StabilityDelta != 0 then
			local ChargePitch = self.Fraise_Stability / 100
			self.Fraise_Stability = math.Clamp( self.Fraise_Stability + (StabilityDelta*0.01) , 0 , 100.0 )
		end
		
		if FraiseStability_RndNumber < 10 and self.Fraise_Stable then
			FraiseShield_ExplosiveDestabilization( self )
			self.Fraise_Stable = false
			
			if self.FS_StabilityNoise then self.FS_StabilityNoise:Stop() end
			
		elseif FraiseStability_RndNumber > 10 and not self.Fraise_Stable then
			local VolumeAmt = 1 - math.Clamp( (FraiseStability_RndNumber-10) / 15 , 0 , 1 )
			FraiseShield_ExplosiveDestabilization( self )
			self.Fraise_Stable = true
			
			if self.FS_StabilityNoise then self.FS_StabilityNoise:Stop() end
			
		elseif FraiseStability_RndNumber < 90 and self.Fraise_Stable then
			local VolumeAmt = 1 - math.Clamp( (FraiseStability_RndNumber-10) / 80 , 0 , 1 )
			self.FS_StabilityNoise = CreateSound( self,"ahee_suit/fraise/fraise_instabilty_impure.mp3")
			self.FS_StabilityNoise:PlayEx( VolumeAmt, 100 )
			
		end
		
		if CheckShieldingStability(self) then
			for Shield, Value in pairs(self.ShieldingList) do
				local TurnedOut = Value[2]
				local Energy = math.Round( Value[3] , 3 )
				if Energy <= 1 and not TurnedOut then
					self.ShieldingList[Shield][2] = true
					self.ShieldingList[Shield][3] = 0
					
					ClientExplosionSound( self, 300 , "tunneling_physics/caplier_faucation.wav" )
					self:EmitSound("ahee_suit/fraise/fraiseformationshield_failure_"..math.random(1,3)..".mp3", 120, math.random(98,105), 1 )
					
					if SERVER then
					local SoundDistanceMax = 3200 * 52.4934
					for k, v in pairs(ents.FindInSphere(self:WorldSpaceCenter(),SoundDistanceMax)) do
						if IsValid(v) and v:IsPlayer() and v != self then
							local Dist = v:WorldSpaceCenter():Distance(self:WorldSpaceCenter())/SoundDistanceMax
							local Meter_Dist = Dist * SoundDistanceMax
							local Blip_String = ""
							
							local SpatialWaveFormat = (343*35) + math.random(-10,150)
							local ContinationWave = ( Meter_Dist ) / ( SpatialWaveFormat * 52.4934 )
							
							Blip_String = (Meter_Dist < 180) and "ahee_suit/fraise/radeonic_range_close_blip_high_"..math.random(1,3)..".mp3" or "ahee_suit/fraise/radeonic_range_far_blip_high.mp3"
							
							net.Start("Radeonic_Range_Blip")
								net.WriteFloat(ContinationWave)
								net.WriteString(Blip_String)
								net.WriteFloat(Dist)
							net.Send(v)
							
						end
					end end
					
					local DetonationWaveRadius = (math.random(3,6) * 52.4934)
					
					if SERVER then
					
						for i=1 , 15 do
							AttackerDirectionized = VectorRand() * (( 52.4934 ) * ( math.random(40,110) / 100 ))
							local Low, High = self:WorldSpaceAABB()
							local vPos = Vector( math.Rand( Low.x, High.x ), math.Rand( Low.y, High.y ), math.Rand( Low.z, High.z ) )
							
							local effectdata = EffectData()
							effectdata:SetOrigin( vPos )
							effectdata:SetStart( AttackerDirectionized )
							effectdata:SetNormal( AngleRand():Forward() )
							effectdata:SetMagnitude( math.random(10,200)/10 )
							util.Effect( "centralbasematerial_spark", effectdata, true, true)
							
						end
					
					local d = DamageInfo()
					d:SetDamage( math.random(38000,45000) )
					d:SetDamageType( DMG_RADIATION )
					
					for k, v in pairs(ents.FindInSphere( self:WorldSpaceCenter() ,DetonationWaveRadius)) do
						if ( v ~= self ) then
							local Dist = ( 1 - (v:GetPos():Distance(self:WorldSpaceCenter())/DetonationWaveRadius) )
							if IsValid(v) and IsValid(self) and IsValid(d) then
								v:SetVelocity( ((v:GetPos() - self:WorldSpaceCenter()):GetNormalized() * Dist) * math.random(100,900) )
								v:TakeDamageInfo( d )
							end
						end
					end
					
					end
				end
			end
		end
		
		MedicalFunction_Tick( self )
		Core_Calc( self )
		
		if (self:KeyPressed(IN_USE)) and not self:KeyDown(IN_JUMP) then
			if SERVER then
				
				net.Start("GetClient_AngleToTarget")
				net.Send( self )
				
				net.Receive( "GetClient_AngleToTarget_Recieve", function( len, ply )
					local Angle_Client = net.ReadAngle()
					local sp = self:EyePos()
					local Dir = (Angle_Client + self:GetViewPunchAngles()):Forward()
					
					local traceData = {}
					local EntitiesArray = {}
					
					traceData.start = sp
					traceData.endpos = ( traceData.start + Dir * ( 25000 * 52.4934 ) )
					traceData.filter = self
					traceData.ignoreworld = true
					local trace = util.TraceLine(traceData)
					
					local EntityScanned = nil
					local EntitiesArray = ents.FindAlongRay( sp , sp + (Dir * ( 25000 * 52.4934 )) , -Vector(5,5,5) * 52.4934 , Vector(5,5,5) * 52.4934 )
					local ClosestConeEnt = FindClosestToPos( EntitiesArray , self )
					
					if table.IsEmpty( EntitiesArray ) then 
						EntityScanned = trace.Entity
						
					else
						for k, v in ipairs(EntitiesArray) do
							if v != self then
								
								if (trace.Entity or v == ClosestConeEnt) then 
									EntityScanned = TraceOrCone( trace.Entity , v )
								end 
							end
						end
						
					end
					
					net.Start("IsTarget_Rooted")
						net.WriteEntity( EntityScanned )
					net.Send( self )
					
					net.Receive( "IsTarget_Rooted_Confirm", function( len, ply )
						Ent = net.ReadEntity()
						if Ent:IsWorld() then Ent = nil end
						
						if Ent then
							net.Start( "AHEE_Targeting_Report" )
							net.WriteEntity( EntityScanned )
							net.Send( ply )
							ply:SetNWEntity( "TargetSelected", EntityScanned )
						else
							net.Start( "AHEE_Targeting_Report" )
							net.WriteEntity( nil )
							net.Send( ply )
							ply:SetNWEntity( "TargetSelected", nil )
						end
						
					end)
					
				end)
				
			end
		end
		
		pelvareign_movement( self )
		
			if self.MainCapacitorBreak then
				if (self.MainCapacitorMJ > (self.MainCapacitorMJLimit*0.1)) then 
					self.MainCapacitorBreak = self.MainCapacitorOutOfEnergy 
				else
					self.MainCapacitorBreak = self.MainCapacitorBreak
				end
			else
				self.MainCapacitorBreak = self.MainCapacitorOutOfEnergy
			end
			
			self.RSF_ShieldRecharge = CreateSound( self,"ahee_suit/radeonicstructurizationflow_shieldrecharge.mp3")
			
			if (self.ShieldingBufferEnergy < self.ShieldingBufferEnergyLimit) and SERVER then
				local MaxPowerAllowed = math.Clamp( ((self.ReactorToAdaptiveEnergy*7) + 100) , 0 , self.ShieldingBufferEnergyLimit-self.ShieldingBufferEnergy )
				if (not self.ShieldingBufferEnergyLocked and self.ShieldingBufferEnergy <= 0) then
					self.ShieldingBufferEnergyLocked = true
				else
					if self.ShieldingBufferEnergy > (self.ShieldingBufferEnergyLimit * 0.95) then
						self.ShieldingBufferEnergyLocked = false
					end
				end
				self.ShieldingBufferEnergy = math.Clamp( self.ShieldingBufferEnergy + MaxPowerAllowed, 0 , self.ShieldingBufferEnergyLimit )
				self.MainCapacitorMJ = math.Clamp( self.MainCapacitorMJ - MaxPowerAllowed, 0 , self.MainCapacitorMJLimit )
			end
			
			SBEL_Noise = SBEL_Noise or 0
			SBELWarning_Noise = SBELWarning_Noise or 0
			FireWarning_Noise = FireWarning_Noise or 0
			
			if ( self.ShieldingBufferEnergy < (self.ShieldingBufferEnergyLimit * 0.45) ) or self.ShieldingBufferEnergyLocked then
				if (not SBELWarning_Noise or (CurTime() > SBELWarning_Noise)) and CLIENT then
					local FailurePitch = (not self.ShieldingBufferEnergyLocked) and ((self.ShieldingBufferEnergy/(self.ShieldingBufferEnergyLimit * 0.45)) * 0.2) or 0
					self:EmitSound("ahee_suit/low_buffer_warning.wav", 120, 100, 0.125 ) 
					SBELWarning_Noise = CurTime() + (FailurePitch+0.2)
				end
			end
			
			if (self.FireCapacitorEnergy < (self.FireCapacitorEnergyLimit * 0.5)) then
				if (not FireWarning_Noise or (CurTime() > FireWarning_Noise)) and CLIENT then
					self:EmitSound("ahee_suit/fire_warning.wav", 120, 100, 1 ) 
					FireWarning_Noise = CurTime() + (0.6)
				end
			end
			
			if (( self.MainCapacitorBreak == false or (self.MainCapacitorMJ <= 0)) and not self.ShieldingBufferEnergyLocked) then
				local NumberOfCompromise, NumberOf = self:CheckNumberOfShieldingDamaged()
				if NumberOfCompromise > 0 then
					
					for Shield, Value in pairs(self.ShieldingList) do
						local Num = Value[1]
						local TurnedOut = Value[2]
						local Power = Value[3]
						local MaxPower = Value[4] 
						local TurnedOff = Value.TurnedOff 
						if Power < MaxPower and not TurnedOff then
							local ChargeFrequency = Power/MaxPower
							local MaxPowerAllowed = (self.ReactorToAdaptiveEnergy) + ((self.ShieldingBufferEnergyLimit*0.001) * NumberOfCompromise)
							
							if not self.RSF_ShieldRecharge:IsPlaying() then
								self.RSF_ShieldRecharge:PlayEx( 1, 50+(ChargeFrequency*200) )
							end
							
							self.ShieldingList[Shield][3] = math.Clamp(Power + MaxPowerAllowed, 0 , MaxPower)
							self.ShieldingBufferEnergy = math.Clamp( self.ShieldingBufferEnergy - MaxPowerAllowed, 0 , self.ShieldingBufferEnergyLimit )
							
							if (TurnedOut and Power > (MaxPower*0.5)) then
								self.ShieldingList[Shield][2] = false
								if CLIENT then Warn_Setup( "SEVERE: "..self.ShieldingList[Shield][5].." Failure!", true ) end
								sound.Play( Sound("ahee_suit/fraise/fraiseformationshield_setup_"..math.random(1,5)..".mp3"), self:WorldSpaceCenter() , 110, math.random(98,102), 1 ) 
								sound.Play( Sound("tunneling_physics/radeonic_distresipution_wave_"..math.random(1,7)..".mp3"), self:WorldSpaceCenter() , 120, math.random(98,102), 1 ) 
								
								local DetonationWaveRadius = (math.random(3,6) * 52.4934)
								
								if SERVER then
									for i=1 , 8 do
										AttackerDirectionized = VectorRand() * (( 52.4934 ) * ( math.random(30,100) / 100 ))
										local Low, High = self:WorldSpaceAABB()
										local vPos = Vector( math.Rand( Low.x, High.x ), math.Rand( Low.y, High.y ), math.Rand( Low.z, High.z ) )
										
										local effectdata = EffectData()
										effectdata:SetStart( vPos )
										effectdata:SetOrigin( AttackerDirectionized )
										effectdata:SetNormal( AngleRand():Forward() )
										effectdata:SetMagnitude( math.random(10,200)/10 )
										util.Effect( "tunneling_fraise_arc", effectdata, true, true)
									end
									
									local d = DamageInfo()
									d:SetDamage( math.random(6000,15000) )
									d:SetDamageType( DMG_RADIATION )
									
									for k, v in pairs(ents.FindInSphere( self:WorldSpaceCenter() ,DetonationWaveRadius)) do
										if ( v ~= self ) then
											local Dist = ( 1 - (v:GetPos():Distance(self:WorldSpaceCenter())/DetonationWaveRadius) )
											if (IsValid(v) and IsValid(self) and IsValid(d)) then
											v:SetVelocity( ((v:GetPos() - self:WorldSpaceCenter()):GetNormalized() * Dist) * math.random(100,900) )
											v:TakeDamageInfo( d )
											end
										end
									end
									
								end
								
							end
							
							break
						end
						
					end
				
				else
					self.RSF_ShieldRecharge:Stop()
				end
			
			else
				if self.MainCapacitorBreak or self.ShieldingBufferEnergyLocked then
					if (not SBEL_Noise or (CurTime() > SBEL_Noise)) and SERVER then
						local FailurePitch = (self.ShieldingBufferEnergy/self.ShieldingBufferEnergyLimit) * 0.5
						self:EmitSound("ahee_suit/fraise/fraiseformationshield_nostart.mp3", 90, math.random(98,105)*(FailurePitch+0.5), 1 ) 
						SBEL_Noise = CurTime() + (math.random(5,12)/10)
					end
				end
				self.RSF_ShieldRecharge:Stop()
			end
			
		if (IsValid(GlobalTargetedNpc) and not GlobalTargetedNpc:IsWorld()) and not self.MainCapacitorMJLocked then
			
			DistanceToTarget = self:WorldSpaceCenter():Distance(GlobalTargetedNpc:WorldSpaceCenter()) / 52.4934
			
			if DistanceToTarget then
				local RadiationPreventation = (self.RadiationTargetingPrevention/100)
				local UsedEnergy = (DistanceToTarget^(DistanceToTarget/1000))
				local TotalAntiEnergy = UsedEnergy - ( UsedEnergy * RadiationPreventation )
				TotalEnergyUsage = ((UsedEnergy^3) * RadiationPreventation)
				
				TargetedRadiationExposure = TotalAntiEnergy or 0
				self.MainCapacitorMJ = math.Clamp( self.MainCapacitorMJ - (TotalEnergyUsage / 1000000) , 0 , self.MainCapacitorMJ )
				
				if not GlobalTargetedNpc:IsPlayer() then
					if TotalAntiEnergy > 1000000 then
						for i=1, 25 do
							ParticleEffect( "HugeFire", GlobalTargetedNpc:WorldSpaceCenter() + (VectorRand() * math.random(50,500)) , VectorRand():Angle() )
						end
						if SERVER then
							GlobalTargetedNpc:Remove()
						end
						GlobalTargetedNpc:EmitSound("high_energy_systems/plasma_anticharge_coniccrossover_"..math.random(1,8)..".mp3", 130, math.random(90,130),1)
					elseif TotalAntiEnergy > 50000 then
						ParticleEffect( "SUPEREMBERHIT", GlobalTargetedNpc:WorldSpaceCenter() , VectorRand():Angle() )
						GlobalTargetedNpc:EmitSound("main/incendiarysizzle.mp3", 100, math.random(90,130),1)
					end
				end
				
				if SERVER then 
					local d = DamageInfo()
					d:SetDamage( TotalAntiEnergy )
					d:SetAttacker( game.GetWorld() )
					d:SetInflictor( game.GetWorld() )
					if GlobalTargetedNpc:IsPlayer() then
						d:SetDamageType( DMG_RADIATION )
					else
						d:SetDamageType( DMG_GENERIC )
					end
					GlobalTargetedNpc:TakeDamageInfo( d )
					GlobalTargetedNpc:EmitSound("main/incendiarysizzle.mp3", 90, math.random(90,130),math.Clamp((TotalAntiEnergy/10),0,1))
					GlobalTargetedNpc:EmitSound("ahee_suit/gforce_pull.mp3", 80, math.random(90,130),math.Clamp((TotalAntiEnergy/50),0,1))
					self:EmitSound("tunneling_physics/radeonic_distresipution_wave_3.mp3", 110, math.random(90,100),math.Clamp((TotalAntiEnergy/1),0,1))
					
					if TotalAntiEnergy > 50 then
						GlobalTargetedNpc:Ignite(1)
					end
					
				end
				
			end
			
		else
			
			if self.MainCapacitorMJLocked then
				self:SetNWEntity( "TargetSelected", nil )
			end
			
		end
		
		self.TychronicInverterThrottle = math.Clamp( self.TychronicInverterThrottle + ((self.TychronicLight - self.TychronicInverterThrottle) * 0.01) , 0 , 2500 )
		
		if SERVER then
			
			if self.TychronicLight > 0 and not self.MainCapacitorMJLocked then
				local JoulesOfAssociatedRelease = ((self.TychronicLight^2) / 100000)
				local ThrottleAmount = (self.TychronicInverterThrottle / 2500)
				self.MainCapacitorMJ = ( self.MainCapacitorMJ - JoulesOfAssociatedRelease ) 
				
				self.TychronicLightNoise = CreateSound( self,"ahee_suit/tychronicinverter.mp3")
				self.TychronicLightNoise:SetSoundLevel( 65 )
				self.TychronicLightNoise:PlayEx( ThrottleAmount, (ThrottleAmount * 70) + 10 )
				
				local SizeDifferenceMin, SizeDifferenceMax = self:GetCollisionBounds()
				local SizeAbsoluteMin, SizeAbsoluteMax = math.abs(SizeDifferenceMin:Length()), math.abs(SizeDifferenceMax:Length())
				local SizeAbsoluteAppropriate = (SizeAbsoluteMin + SizeAbsoluteMax) / 3
				
				local Radius = ((52.4934) * (self.TychronicLight / 500)) + SizeAbsoluteAppropriate
				
				for k, v in pairs(ents.FindInSphere( self:WorldSpaceCenter() ,Radius)) do
					local IsWorth = ( v:IsPlayer() or v:IsPlayer() or v:IsNextBot() or IsValid(v:GetPhysicsObject()) )
					if IsValid(v) and IsWorth and v != self and v:GetOwner() != self and not v:GetNWBool("AHEE_EQUIPED") then
						local Dist = ( 1 - ( (v:WorldSpaceCenter():Distance(self:WorldSpaceCenter()) - SizeAbsoluteAppropriate) / Radius ) ) ^ 6
						if Dist > 0 and Dist <= 1.5 then
							local Received = ( (self.TychronicLight^2) * Dist ) / 1000000
							local daginfo = DamageInfo()
							daginfo:SetAttacker( self )
							daginfo:SetInflictor( self )
							daginfo:SetDamageType( DMG_RADIATION ) 
							daginfo:SetDamagePosition( self:WorldSpaceCenter() )
							daginfo:SetDamage( Received )
							
							v:TakeDamageInfo( daginfo )
							
							if Received > 5 then
								v:Ignite(5)
								local effectdata = EffectData()
								effectdata:SetOrigin( v:WorldSpaceCenter() )
								effectdata:SetNormal( self:GetVelocity():GetNormalized() )
								effectdata:SetMagnitude( 2 )
								effectdata:SetScale( 3 )
								effectdata:SetRadius( 3 )
								util.Effect( "regular_material_spark", effectdata )
							end
							
						end
					end
				end
				
			else
				local ThrottleAmount = (self.TychronicInverterThrottle / 2500)
				self.TychronicLightNoise:PlayEx( ThrottleAmount, (ThrottleAmount * 70) + 10 )
				self.TychronicLightNoise:Stop()
				
			end
			
			AHEE_LookFor_Striker( self )
			
		end
		
		if self:KeyReleased(IN_MOVERIGHT) then
			AboutToMove = true
			timer.Simple( 0.05, function()
				AboutToMove = false
			end)
		elseif self:KeyReleased(IN_MOVELEFT) then
			AboutToMove = true
			timer.Simple( 0.05, function()
				AboutToMove = false
			end)
		elseif self:KeyReleased(IN_FORWARD) then
			AboutToMove = true
			timer.Simple( 0.05, function()
				AboutToMove = false
			end)
		elseif self:KeyReleased(IN_BACK) then
			AboutToMove = true
			timer.Simple( 0.05, function()
				AboutToMove = false
			end)
		end
		
		if (AboutToMove or false) and (TouchingGround or self:IsOnGround()) then
			local OwnerAngles = Angle(0,self:GetAngles().y,0)
			local GForceViaMove = math.Round( (37300*(math.random(19,26)/10) ) * 0.101971621 , 2)
			if self:KeyPressed(IN_MOVELEFT) then
				
				AboutToMove = false
				if self.WADSuppression < 2 then
					self:EmitSound("main/bouncehit.wav", 120, math.random(60,70),0.5)
					util.ScreenShake( self:GetPos(), 3, 2000, 0.1, (5*52.4934) )
				end
				if self.WADSuppression < 4 then
					self:EmitSound("ahee_suit/a9er_footstep_3.mp3", 80, math.random(95,110), 0.9 )
					for i = 1 , 3 do ParticleEffect( "GroundCloudLarge", self:GetPos() , Angle() + (AngleRand() * 0.8) ) end
				end
				self:SetPos( self:GetPos() + (OwnerAngles:Right() * (-1 * 52.4934)) )
				self.InducedGForce = self.InducedGForce + GForceViaMove
				
			elseif self:KeyPressed(IN_MOVERIGHT) then
				
				AboutToMove = false
				if self.WADSuppression < 2 then
					self:EmitSound("main/bouncehit.wav", 120, math.random(60,70),0.5)
					util.ScreenShake( self:GetPos(), 3, 2000, 0.1, (5*52.4934) )
				end
				if self.WADSuppression < 4 then
					self:EmitSound("ahee_suit/a9er_footstep_3.mp3", 80, math.random(95,110), 0.9 )
					for i = 1 , 3 do ParticleEffect( "GroundCloudLarge", self:GetPos() , Angle() + (AngleRand() * 0.8) ) end
				end
				self:SetPos( self:GetPos() + (OwnerAngles:Right() * (1 * 52.4934)) )
				self.InducedGForce = self.InducedGForce + GForceViaMove
			
			elseif self:KeyPressed(IN_FORWARD) then
				
				AboutToMove = false
				if self.WADSuppression < 2 then
					self:EmitSound("main/bouncehit.wav", 120, math.random(60,70),0.5)
					util.ScreenShake( self:GetPos(), 3, 2000, 0.1, (5*52.4934) )
				end
				if self.WADSuppression < 4 then
					self:EmitSound("ahee_suit/a9er_footstep_3.mp3", 80, math.random(95,110), 0.9 )
					for i = 1 , 3 do ParticleEffect( "GroundCloudLarge", self:GetPos() , Angle() + (AngleRand() * 0.8) ) end
				end
				self:SetPos( self:GetPos() + (OwnerAngles:Forward() * (1 * 52.4934)) )
				self.InducedGForce = self.InducedGForce + GForceViaMove
				
			elseif self:KeyPressed(IN_BACK) then
				
				AboutToMove = false
				if self.WADSuppression < 2 then
					self:EmitSound("main/bouncehit.wav", 120, math.random(75,70),0.5)
					util.ScreenShake( self:GetPos(), 3, 2000, 0.1, (5*52.4934) )
				end
				if self.WADSuppression < 4 then
					self:EmitSound("ahee_suit/a9er_footstep_3.mp3", 80, math.random(60,110), 0.9 )
					for i = 1 , 3 do ParticleEffect( "GroundCloudLarge", self:GetPos() , Angle() + (AngleRand() * 0.8) ) end
				end
				self:SetPos( self:GetPos() + (OwnerAngles:Forward() * (-2 * 52.4934)) )
				self.InducedGForce = self.InducedGForce + GForceViaMove
				
			end
		end
		
		RadeonicGrapple_Handling( self )
		
		if self.Targeting_Mains then
			local Target_Mains = self.Targeting_Mains
			
			local Position_Delta_Collective = Vector()
			
			if Target_Mains.Target_PowerMains then
				local Energy_Util = (Target_Mains.Interest_Focus:Distance( self:WorldSpaceCenter() )/52.4934) ^ 1.1
				local Track_Distance = 5
				local Track_Size = 52.4934 * Track_Distance
				
				if (not Target_Mains.Focus_Points_Velocities) then Target_Mains.Focus_Points_Velocities = {} end
				
				for Key, Point in pairs(Target_Mains.Focus_Points) do
					local Velocity_Key = Target_Mains.Focus_Points_Velocities[Key]
					
					Target_Mains.Focus_Points[Key] = (Point and Point.x==Point.x) and Target_Mains.Focus_Points[Key] or Vector()
					Target_Mains.Focus_Points_Velocities[Key] = (Velocity_Key and Velocity_Key.x==Velocity_Key.x) and Target_Mains.Focus_Points_Velocities[Key] or Vector()
					
					local Angle_Rotate = (SysTime()*math.pi/#Target_Mains.Focus_Points) + (((math.pi*2) / #Target_Mains.Focus_Points) * Key-1)
					local Pos_Goto = self.InternalInterest_Pos + Vector( math.sin(Angle_Rotate)*Track_Size/2 , math.cos(Angle_Rotate)*Track_Size/2 , 0 )
					local Focus_Delta = (Target_Mains.Focus_Points[Key]-Pos_Goto)
					local Focus_Delta_Distance = Target_Mains.Focus_Points[Key]:Distance(Pos_Goto)
					local Delta_Total = Focus_Delta + (VectorRand() * (math.random(1,math.random(3,7)) * (Focus_Delta_Distance^0.85)))
					
					Target_Mains.Focus_Points_Velocities[Key] = (Target_Mains.Focus_Points_Velocities[Key] * 0.8) - (Delta_Total*0.015)
					Target_Mains.Focus_Points[Key] = Target_Mains.Focus_Points[Key] + Target_Mains.Focus_Points_Velocities[Key]
					
					Position_Delta_Collective = Target_Mains.Focus_Points[Key] + Position_Delta_Collective
					
				end
				
				local Position_Delta = Target_Mains.Interest_Focus - (Position_Delta_Collective/#Target_Mains.Focus_Points)
				self.Targeting_Mains.Interest_Focus = Target_Mains.Interest_Focus - (Position_Delta*0.15)
				
				if SERVER then
					for k, v in pairs(ents.FindInSphere( Target_Mains.Interest_Focus , Track_Size )) do
						if ( v ~= self ) then
							local Dist = ( 1.05 - math.Clamp(v:GetPos():Distance(Target_Mains.Interest_Focus)/Track_Size,0,1) )
							local Velo = ((v:GetPos() - Target_Mains.Interest_Focus):GetNormalized() * Dist) * math.random(1,19)
							local PhysObj = v:GetPhysicsObject()
							
							local d = DamageInfo()
							
							if IsValid(v) and IsValid(self) then
								if IsValid( PhysObj ) then PhysObj:AddVelocity( Velo ) else v:SetVelocity( Velo ) end
								
								d:SetDamage( math.random(38000,45000) )
								d:SetDamageType( DMG_RADIATION )
								d:SetAttacker( self )
								d:SetInflictor( self )
								v:TakeDamageInfo( d )
								
								d:SetDamage( math.random(500,8000)*Dist )
								d:SetDamageType( DMG_GENERIC )
								d:SetAttacker( self )
								d:SetInflictor( self )
								v:TakeDamageInfo( d )
								
							end
						end
					end
				end
				
				self.MainCapacitorMJ = math.Clamp( (self.MainCapacitorMJ - Energy_Util) , 0 , self.MainCapacitorMJ )
				
			end
			
		end
		
		AHEE_System_GoThrough_PseudoTeam( self )
		
		if IsValid(self.HeldItem) then
			local Tick = 1/(1/FrameTime())
			self.HeldItemStrPrep = self.HeldItemStrPrep or 0
			if self:KeyDown( IN_ATTACK ) then
				self.HeldItemStrPrep = math.Clamp(self.HeldItemStrPrep+( Tick / ((self.HeldItemStrPrep*5)+1) ),0,1)
				self.MainCapacitorMJ = math.Clamp(self.MainCapacitorMJ-((self.HeldItemStrPrep/1)*1000),0,self.MainCapacitorMJ)
				util.ScreenShake( self:WorldSpaceCenter(), (self.HeldItemStrPrep/1), 3000, 0.1, ((self.HeldItemStrPrep/1)*100) )
			end
			self.MedicalStats.PhysiologicalExertion = self.MedicalStats.PhysiologicalExertion + self.HeldItemStrPrep
		else
			self.HeldItemStrPrep = 0
		end
		
		if IsValid(self:GetActiveWeapon()) and self:GetActiveWeapon():GetClass() == "weapon_fists" then
			if self:KeyDown( IN_ATTACK ) or self:KeyDown( IN_ATTACK2 ) then
				self:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_VM_PRIMARYATTACK, true)
				Pelvareign_Punch( self )
			end
		end
		
		if SERVER then
			local InteractTrace = {}
			InteractTrace.start = self:EyePos()
			InteractTrace.endpos = InteractTrace.start + self:EyeAngles():Forward() * ( 2 * 52.4934 )
			InteractTrace.filter = self
			InteractTrace.ignoreworld = true
			
			local AbleToInteract = util.TraceLine(InteractTrace)
			local PullPos = InteractTrace.start + self:EyeAngles():Forward() * ( 1 * 52.4934 )
			
			local function SharedItemUpdate( Ent )
				self.HeldItem = Ent
				net.Start( "HoldingItem" )
				net.WriteEntity( Ent ) 
				net.Send( self )
			end
			
			if IsValid(AbleToInteract.Entity) and (not IsValid(self:GetActiveWeapon()) or self:GetActiveWeapon():GetClass() == "none") then 
			
				if not self.PelvareignInteractables["Punch"] then
					net.Start( "Pelvareign_Interactive_Spawn" )
						net.WriteString( "Punch" ) -- SentText
						net.WriteString( "Punch as hard as you can!" ) -- SentSubText
						net.WriteString( "hud/interaction_hud/fist_icon.png" ) -- SentTexture
						net.WriteString( "Pelvareign_Punch" ) -- SentInteractionName
					net.Send( self )
					self.PelvareignInteractables["Punch"] = true
				end
				
				if not IsValid(self.HeldItem) then
				
				local Object = AbleToInteract.Entity
				local NameObject = Object:GetClass() or "unknown"
				local IntelligentEntity = (Object:IsNPC() or Object:IsPlayer())
				
				local ObjectPosition = Object:WorldSpaceCenter() or Object:GetPos()
				local ObjectAngle = Object:GetAngles()
				local ObjectMin, ObjectMax = Object:GetModelBounds()
				
				local PushSpeed = (Object:WorldSpaceCenter()-AbleToInteract.HitPos):GetNormalized()
				local PushMult = (1-AbleToInteract.Fraction) * (self.NetMass * 1000)
				
				local phys = Object:GetPhysicsObjectNum(AbleToInteract.PhysicsBone)
				local pushvec = PushSpeed * PushMult
				
				local PullDir = (PullPos-AbleToInteract.HitPos)
				
				if self:KeyDown( IN_ATTACK ) and not self:KeyDown( IN_ATTACK2 ) then
					Object:EmitSound("physics/metal/weapon_impact_soft"..math.random( 1 , 3 )..".wav", 90, math.random( 90 , 110 ) , 0.2 )
					
					if (1-AbleToInteract.Fraction) > 0.5 then
						self:EmitSound("physics/body/body_medium_impact_hard"..math.random( 1 , 5 )..".wav", 90, math.random( 85 , 90 ) , (1-AbleToInteract.Fraction) )
						util.ScreenShake( AbleToInteract.HitPos, ((1-AbleToInteract.Fraction)/0.5)*4, 2222, 0.1, ((1-AbleToInteract.Fraction)/0.5)*500 )
						Object:Fire("Unlock")
						Object:Fire("EnableMotion")
						
						if (1-AbleToInteract.Fraction) > 0.75 then
							BlowOpenDoor( self, Object )
						end
						
						local d = DamageInfo()
						d:SetDamage( PushMult )
						d:SetAttacker( self )
						d:SetDamageForce( PushMult * PushSpeed )
						d:SetDamageType( DMG_CLUB ) 
						
						Object:TakeDamageInfo( d )
						
					else
						self:EmitSound("physics/body/body_medium_impact_soft"..math.random( 1 , 7 )..".wav", 75, math.random( 85 , 90 ) , 0.2 )
					end
					
					if Object:IsConstraint() or Object:IsConstrained() then 
						if (1-AbleToInteract.Fraction) > 0.5 then
							constraint.RemoveAll( Object )
							Object:Fire("EnableMotion")
							Object:EmitSound("physics/metal/metal_sheet_impact_bullet"..math.random( 1 , 2 )..".wav", 100, math.random( 90 , 110 ) , 0.6 )
						end
					end
					
					if IsValid(phys) then 
						phys:ApplyForceOffset(pushvec + self:GetVelocity(), AbleToInteract.HitPos)
						local PushVelo = -phys:GetVelocity():GetNormalized() * math.Clamp(phys:GetVelocity():Length()/2,0,520)
						self:SetVelocity( PushVelo / math.Clamp((self.NetMass*20)/phys:GetMass(),0.8,20) )
					else
						Object:SetVelocity( PushSpeed * 50 )
						local NormalSpeed = -Object:GetVelocity():GetNormalized()
						self:SetVelocity( NormalSpeed )
					end
					
					if IntelligentEntity then
						if not Object:GetNWBool("AHEE_EQUIPED") then
							Object:DropWeapon( nil, PushSpeed * 20 , nil )
							if Object:IsPlayer() then Object:ViewPunch( Angle( math.random( -10 , -5 ) * (1-AbleToInteract.Fraction), 0 , 0 ) ) end
						end
					end
					
					if IsValid(self.HeldItem) then self.HeldItem = nil self.HeldItemVec = nil end
					
				elseif self:KeyPressed( IN_ATTACK2 ) then
					self:EmitSound("physics/plastic/plastic_box_impact_soft"..math.random( 1 , 4 )..".wav", 75, math.random( 90 , 95 ) , 0.25 )
					
					if IsValid(self.HeldItem) then 
						SharedItemUpdate( nil )
						self.HeldItemVec = nil
					else
						timer.Simple( 0 , function()
							if IsValid(Object) then
								SharedItemUpdate( Object )
								self.HeldItemVec = Object:WorldToLocal( AbleToInteract.HitPos )
							end
						end)
					end
					
					if Object:IsConstraint() or Object:IsConstrained() then 
						if (1-AbleToInteract.Fraction) < 0.5 then
							constraint.RemoveAll( Object )
							Object:Fire("EnableMotion")
							Object:EmitSound("physics/metal/metal_sheet_impact_bullet"..math.random( 1 , 2 )..".wav", 100, math.random( 90 , 110 ) , 0.6 )
						end
					end
					
					if not phys then
						Object:SetVelocity( (Object:WorldSpaceCenter()-self:WorldSpaceCenter()):GetNormalized() * -250 )
						local NormalSpeed = -Object:GetVelocity():GetNormalized()
						self:SetVelocity( NormalSpeed )
					end
				end
				
				end
				
				
			else
				
				if self.PelvareignInteractables["Punch"] then
					net.Start( "Pelvareign_Interactive_Collect" )
						net.WriteString( "Punch" ) -- SentText
					net.Send( self )
					self.PelvareignInteractables["Punch"] = nil
				end
				
			end
			
			if IsValid(self.HeldItem) then
				local Item = self.HeldItem
				local ObjectPosition = Item:WorldSpaceCenter()
				local phys = Item:GetPhysicsObject()
				local LocalizedPos = PullPos
				local PushMult = (self.NetMass * 1000)*self.HeldItemStrPrep
				
				if self:KeyDown( IN_ATTACK ) then
					if self:KeyPressed( IN_ATTACK2 ) then
						self.HeldItemVec = nil
						SharedItemUpdate( nil )
						self:EmitSound("physics/plastic/plastic_box_impact_hard"..math.random( 1 , 4 )..".wav", 75, math.random( 90 , 95 ) , 0.3 )
					end
					LocalizedPos = PullPos - (self:EyeAngles():Up() * 20)
				elseif self:KeyReleased( IN_ATTACK ) then
					if self.HeldItemStrPrep > 0.9 and self.DragShieldingSetting then 
						local Velo = (self:EyeAngles():Forward() * self.NetMass)
						sound.Play( Sound("ahee_suit/fraise/fraiseformationshield_failure_"..math.random(1,3)..".mp3"), self:WorldSpaceCenter() , 110, math.random(60,70), 1 ) 
						self:SetVelocity( -Velo )
					elseif self.HeldItemStrPrep > 0.9 and not self.DragShieldingSetting then
						local Velo = (self:EyeAngles():Forward() * self.NetMass)
						self:EmitSound("pelvareign_body/trauma_hit_"..math.random( 1 , 3 )..".mp3", 80, math.random( 90 , 95 ) , 1 )
						self:EmitSound( "pelvareign_body/speech/exhaust_trauma_"..math.random(3,6)..".mp3", 100, math.random(92,95), 0.9 ) 
						self:ViewPunch( Angle( math.random(-10,5), 0, math.random(-10,10) ) )
						sound.Play( Sound("main/roundhit_softmatter_"..math.random(1,9)..".mp3"), self:WorldSpaceCenter() , 110, math.random(60,70), 0.3 ) 
						ParticleEffect( "Shockwave", Item:WorldSpaceCenter() , Angle() )
						ParticleEffect( "SmokeShockFar", Item:WorldSpaceCenter() , Angle() )
						
						local dmg_random = math.Clamp( (self.HeldItemStrPrep - 0.9) * 100 , 0 , 200 )
						
						BodyPart_DoDamage( self , 4 , dmg_random )
						net.Start( "BodyPart_DoDamage_Client" )
						net.WriteString( tostring(4) )
						net.WriteFloat( dmg_random )
						net.Send( self )
						
						BodyPart_DoDamage( self , 5 , dmg_random )
						net.Start( "BodyPart_DoDamage_Client" )
						net.WriteString( tostring(5) )
						net.WriteFloat( dmg_random )
						net.Send( self )
						
						self:SetVelocity( -Velo/3 )
					else
						local Velo = (self:EyeAngles():Forward() * self.NetMass)
						self:SetVelocity( -Velo/3 )
					end
					Item:EmitSound("physics/metal/weapon_impact_soft"..math.random( 1 , 3 )..".wav", 90, math.random( 55 , 70 ) , 0.9 )
					self:EmitSound("main/interact_foley_short_"..math.random( 1 , 3 )..".wav", 85, math.random( 60 , 75 ) , 0.2 )
					self:EmitSound("main/interact_foley_short_"..math.random( 1 , 3 )..".wav", 75, math.random( 185 , 190 ) , 0.3 )
					if IsValid(phys) then phys:ApplyForceCenter( self:EyeAngles():Forward() * PushMult ) end
					self.HeldItemVec = nil
					SharedItemUpdate( nil )
				end
				
				if IsValid(self.HeldItem) and IsValid(phys) then --Make sure we didn't drop or throw
					local LocalDirPos = (ObjectPosition + self.HeldItemVec)
					LocalDirPos:Rotate( Item:GetAngles() )
					
					local mins = Item:OBBMins()
					local maxs = Item:OBBMaxs()
					local startpos = Item:WorldSpaceCenter()
					
					local tr = util.TraceHull( {
						start = startpos,
						endpos = startpos + (phys:GetVelocity():GetNormalized() * phys:GetVelocity():Length()^0.5) - (self:GetVelocity():GetNormalized() * self:GetVelocity():Length()^0.5),
						maxs = maxs/2,
						mins = -maxs/2,
						filter = {Item,phys}
					} )
					
					local PullDir = (LocalizedPos-ObjectPosition)
					if ObjectPosition:Distance(LocalizedPos) < ( 1 * 52.4934 ) and not self:KeyPressed( IN_ATTACK2 ) and (phys:GetMass()) < (self.NetMass * 2) then
						local Distanced = ObjectPosition:Distance(LocalizedPos)
						local Force = (( PullDir * math.Clamp((self.NetMass*20)/phys:GetMass(),0,5) ) * phys:GetMass()) + ((self:GetVelocity()/2) * phys:GetMass())
						local Velo = phys:GetVelocity()
						local Angle = self:EyeAngles():Forward() * phys:GetMass() * 160
						local FinishedForce = (Force - (Velo * phys:GetMass()) / 2)
						if tr.Entity != self then
							self:SetVelocity( -Velo / math.Clamp((self.NetMass*20)/phys:GetMass(),1.5,8) )
							phys:ApplyForceCenter( FinishedForce * 2 )
							
							phys:ApplyForceOffset( Angle , ObjectPosition + Item:GetForward() )
							phys:ApplyForceOffset( -Angle , ObjectPosition - Item:GetForward() )
							
							phys:AddAngleVelocity( -phys:GetAngleVelocity() / 12 )
						end
					else
						self.HeldItemVec = nil
						SharedItemUpdate( nil )
						self:EmitSound("physics/plastic/plastic_box_impact_hard"..math.random( 1 , 4 )..".wav", 75, math.random( 90 , 95 ) , 0.3 )
					end
				end
			end
			
		end
		
		if SERVER then
			
			if not self.MainCapacitorBreak then
				if not self.PelvareignInteractables["Change_Radeonic_Tack"] then
					net.Start( "Pelvareign_Interactive_Spawn" )
						net.WriteString( "Change Radeonic Tack" ) -- SentText
						net.WriteString( "Toggle Radeonic Tack System!" ) -- SentSubText
						net.WriteString( "hud/systems_hud/signal_processor_icon.png" ) -- SentTexture
						net.WriteString( "Change_Radeonic_Tack" ) -- SentInteractionName
					net.Send( self )
					self.PelvareignInteractables["Change_Radeonic_Tack"] = true
				end
			else
				if self.PelvareignInteractables["Change_Radeonic_Tack"] then
					net.Start( "Pelvareign_Interactive_Collect" )
						net.WriteString( "Change Radeonic Tack" ) -- SentText
					net.Send( self )
					self.PelvareignInteractables["Change_Radeonic_Tack"] = nil
				end
			end
			
			local ActiveWeapon = self:GetActiveWeapon()
			if IsValid(ActiveWeapon) then
				local Charge = ActiveWeapon["Charge"]
				local Rounds = ActiveWeapon["RoundTypes"]
				local CurrentAmmoType = ActiveWeapon["AmmunitionType"]
				
				if Charge and type(Charge) == "table" then
					if Charge.Current < Charge.Max then
						
						if not self.PelvareignInteractables["Change_Weapon_Battery"] then
							net.Start( "Pelvareign_Interactive_Spawn" )
								net.WriteString( "Change Battery" ) -- SentText
								net.WriteString( "Change Battery System, Requires a Battery in your inventory!" ) -- SentSubText
								net.WriteString( "hud/interaction_hud/weapon_regenerate.png" ) -- SentTexture
								net.WriteString( "Change_Weapon_Battery" ) -- SentInteractionName
							net.Send( self )
							self.PelvareignInteractables["Change_Weapon_Battery"] = true
						end
					else
						
						if self.PelvareignInteractables["Change_Weapon_Battery"] then
							net.Start( "Pelvareign_Interactive_Collect" )
								net.WriteString( "Change Battery" ) -- SentText
							net.Send( self )
							self.PelvareignInteractables["Change_Weapon_Battery"] = nil
						end
					end
				else
					
					if self.PelvareignInteractables["Change_Weapon_Battery"] then
						net.Start( "Pelvareign_Interactive_Collect" )
							net.WriteString( "Change Battery" ) -- SentText
						net.Send( self )
						self.PelvareignInteractables["Change_Weapon_Battery"] = nil
					end
				end
				
				if Rounds and type(Rounds) == "table" then
					if not self.PelvareignInteractables["Change_Weapon_Round"] then
						net.Start( "Pelvareign_Interactive_Spawn" )
							net.WriteString( "Change Round" ) -- SentText
							net.WriteString( "Change Ammunition, Requires different Rounds in your inventory!" ) -- SentSubText
							net.WriteString( "hud/interaction_hud/weapon_mechanized.png" ) -- SentTexture
							net.WriteString( "Change_Weapon_Round" ) -- SentInteractionName
						net.Send( self )
						self.PelvareignInteractables["Change_Weapon_Round"] = true
					end
					
				else
					if self.PelvareignInteractables["Change_Weapon_Round"] then
						net.Start( "Pelvareign_Interactive_Collect" )
							net.WriteString( "Change Round" ) -- SentText
						net.Send( self )
						self.PelvareignInteractables["Change_Weapon_Round"] = nil
					end
					
				end
				
			end
		end
		
		if self.MedicalStats.Consciousness < 95 then
			self:SetViewPunchAngles( self:GetViewPunchAngles() + Angle(math.random(-1,1), math.random(-1,1), math.random(-10,10)) * (1 - (self.MedicalStats.Consciousness / 100)) ^ 2 )
			self:SetViewPunchVelocity( self:GetViewPunchVelocity() + Angle(math.random(-1,1), math.random(-1,1), math.random(-10,10)) * (1 - (self.MedicalStats.Consciousness / 100)) ^ 2 )
		end
		
		self:SetDSP( 1 )
		
		if IsValid(GlobalTargetedNpc) and SERVER then
			if GlobalTargetedNpc:IsNPC() then
				net.Start("Scan_Target")
					net.WriteEntity(GlobalTargetedNpc:GetEnemy())
				net.Send(self)
			end
		end
		
	end
	
	
	
	function Core_Calc( Ply )
		local CS = Ply.AHEE_Core
		local CoS = Ply.AHEE_Cooling
		
		local MaxFanSpeed = 12000000000000
		local HeatRatio = math.Clamp( (CS.AHEE_CORE_FLOW / CoS.AHEE_FAN_SPEED) - CS.AHEE_CORE_TEMPERATURE , 5 , 60 ) 
		
		local Speed_Require = (HeatRatio) / CS.AHEE_CORE_PRESSUREFLOW
		local SpeedIntegerNoise = math.Clamp( CoS.AHEE_FAN_SPEED / 3200000000 , 0 , 20000000000 )
		local FlowIntegerNoise = math.Clamp( CS.AHEE_CORE_FLOW / 600000 , 0 , 2600000000 )
		
		local DensityPower = CS.AHEE_CORE_SPEED * CS.AHEE_CORE_RPMYIELD
		
		servo_exhaust = servo_exhaust != nil and servo_exhaust or false
		if CS.AHEE_CORE_FLOW > 100000 then
			if not servo_exhaust then
				if SERVER then Ply:EmitSound("ahee_suit/ahee_servo_start.mp3", 70, 100 , 0.25 ) end
				servo_exhaust = true
			end
			Ply.ServoLoop = CreateSound( Ply , "ahee_suit/ahee_servo_loop.mp3")
			Ply.ServoLoop:SetSoundLevel( 70 )
			Ply.ServoLoop:PlayEx( 0.1, 100 + (FlowIntegerNoise * 100) )
			
		else
			if servo_exhaust then
				if SERVER then Ply:EmitSound("ahee_suit/ahee_servo_end.mp3", 70, 100 , 0.25 ) end
				servo_exhaust = false
			end
			
		end
		
		if CoS.AHEE_FAN_SPEED > 300000 then
			Ply.FanLoop = CreateSound( Ply , "ahee_suit/ahee_fan_loop.mp3")
			Ply.FanLoop:SetSoundLevel( 60 + (SpeedIntegerNoise * 10) )
			Ply.FanLoop:PlayEx( (0.5 * SpeedIntegerNoise) , math.Round(60 + (SpeedIntegerNoise * 100)) )
		end
		
		cooling_fan = cooling_fan != nil and cooling_fan or 0
		if cooling_fan < 0.5 then 
			cooling_fan = cooling_fan + engine.TickInterval()
		else
			if CoS.AHEE_FAN and CoS.AHEE_FAN_SPEED < 500000 then 
				CoS.AHEE_COOLING_USAGE = CoS.AHEE_COOLING_USAGE * 2
				if SERVER then
				if CoS.AHEE_FAN_SPEED > 3500000 then
					Ply:EmitSound("ahee_suit/ahee_fan_starter.mp3", 65, math.random( 95 , 100 ) , 0.35 )
				else
					Ply:EmitSound("ahee_suit/ahee_fan_starter_failure_"..math.random( 1 , 4 )..".mp3", 65, math.random( 90 , 100 ) , 0.2 )
				end
				end
			end
			
			cooling_fan = 0
		end
		
		Ply.ReactorToAdaptiveEnergy = math.Clamp( CS.AHEE_CORE_DENSITY , 0 , 3500 ) * (CS.AHEE_CORE_LOADALLOWANCE/100)
		Ply.ReactorToAdaptiveMains = Ply.ReactorToAdaptiveEnergy * math.ceil((1 - (Ply.MainCapacitorMJ / Ply.MainCapacitorMJLimit)))
		
		Ply.MainCapacitorMJ = math.Clamp( Ply.MainCapacitorMJ + Ply.ReactorToAdaptiveMains, 0 , Ply.MainCapacitorMJLimit )
		Ply.MainCapacitorOutOfEnergy = (Ply.MainCapacitorMJ <= 0)
		
		if CS.AHEE_CORE_SPEED <= 0 then
			CS.AHEE_CORE_YIELDTYPE = "Geometrical Close"
			CS.AHEE_CORE_INJECTION_RATE = HeatRatio
		elseif CS.AHEE_CORE_SPEED > 0 and CS.AHEE_CORE_SPEED < 860000 then
			CS.AHEE_CORE_YIELDTYPE = "Geometrical Open"
			CS.AHEE_CORE_INJECTION_RATE = HeatRatio * 2
		elseif CS.AHEE_CORE_SPEED > 860000 then
			CS.AHEE_CORE_YIELDTYPE = "Geometrical Project"
			CS.AHEE_CORE_INJECTION_RATE = HeatRatio * 50
		end
		
		if CS.AHEE_CORE_TEMPERATURE <= -320 then
			CS.AHEE_CORE_TEMPERATURE = CS.AHEE_CORE_TEMPERATURE + 100000
			Ply:EmitSound("tunneling_physics/caplier_faucation.wav", 80, math.random( 50 , 60 ) , 0.5 )
		elseif CS.AHEE_CORE_TEMPERATURE >= math.huge then
			CS.AHEE_CORE_TEMPERATURE = 0
			Ply:EmitSound("tunneling_physics/caplier_faucation.wav", 80, math.random( 150 , 160 ) , 0.5 )
		end
		
		CS.AHEE_CORE_FLOW = math.Clamp( CS.AHEE_CORE_FLOW + ((CS.AHEE_CORE_TEMPERATURE * CS.AHEE_CORE_SPEED) / CS.AHEE_CORE_PRESSUREFLOW) * CS.AHEE_CORE_INJECTION_RATE , 0 , CS.AHEE_CORE_PRESSUREFLOW * 10 )
		CS.AHEE_CORE_PRESSUREFLOW = math.Clamp( CS.AHEE_CORE_FLOW * CS.AHEE_CORE_SPEED , 0 , 1200000000000 )
		
		CS.AHEE_CORE_TEMPERATURE = math.Clamp( ((CS.AHEE_CORE_FLOW - CoS.AHEE_FAN_SPEED) * CS.AHEE_CORE_INJECTION_RATE ) , -65000 , math.huge )
		CS.AHEE_CORE_SPEED = math.Clamp( CS.AHEE_CORE_SPEED + ((CS.AHEE_CORE_FLOW + CS.AHEE_CORE_TEMPERATURE) / CS.AHEE_CORE_DENSITY) , 0 , CS.AHEE_CORE_PRESSUREFLOW * 2 )
		
		CS.AHEE_CORE_DENSITY = math.Clamp( CS.AHEE_CORE_DENSITY + ((CS.AHEE_CORE_SPEED + CS.AHEE_CORE_TEMPERATURE) / CS.AHEE_CORE_PRESSUREFLOW * CS.AHEE_CORE_RPMYIELD) - (Ply.ReactorToAdaptiveMains * 1000) , 0 , math.huge )
		CS.AHEE_CORE_RPMYIELD = 25
		
		local IncreaseSpeed = (CoS.AHEE_COOLING_USAGE * 100) - (CoS.AHEE_COOLING_PRESSURE / CS.AHEE_CORE_PRESSUREFLOW)
		local FanDelta = CoS.AHEE_FAN_SPEED - (IncreaseSpeed)
		
		CoS.AHEE_FAN_SPEED = math.Clamp( CoS.AHEE_FAN_SPEED - (FanDelta*0.01) , 0 , MaxFanSpeed ) -- Prop Mass = 5 kg
		CoS.AHEE_COOLING_PRESSURE = math.Clamp( CoS.AHEE_FAN_SPEED*CoS.AHEE_COOLING_DENSITY , 0 , CS.AHEE_CORE_PRESSUREFLOW * 10 )
		CoS.AHEE_COOLING_DENSITY = math.Clamp( CoS.AHEE_FAN_SPEED + CoS.AHEE_COOLING_PRESSURE , 0 , CS.AHEE_CORE_DENSITY * 2 )
		CoS.AHEE_COOLING_USAGE = math.Clamp( CoS.AHEE_COOLING_USAGE - 1000 , 10000000 , 100000000 )
		
		-- AHEE_MANUAL = false ,
		
		-- AHEE_CORE_LOADALLOWANCE = 100.0 , -- Percent
		-- AHEE_CORE_PRESSUREFLOW = 1200000000000 , --Meter^8
		-- AHEE_CORE_DENSITY = 50000 , -- Watt / Radeonic / Bakronic / Second
		
		-- AHEE_CORE_YIELDTYPE = "Geometrical Close" , -- Type of Yield, Yield should averagely be ' Type 3 Liminality State ' 
		-- AHEE_CORE_SPEED = 3200000 , -- RPM
		-- AHEE_CORE_FLOW = 0 , -- Meter^3 / Watt / Meter / Second
		-- AHEE_CORE_RPMYIELD = 25 , -- Watt / RPM
		
		-- AHEE_CORE_ABLATION = 100.0 , -- Percent
		-- AHEE_CORE_STRUCTURE_ABLATION = 0.0 , -- Percent
		
		-- AHEE_CORE_INJECTION_RATE = 60 , -- Meter^3 / Second
		
		-- AHEE_CORE_TEMPERATURE = 5000000 , -- Kelvin
		-- AHEE_CORE_STRUCTUREHEALTH = 100.0 -- Percent
		
		-- AHEE_COOLING_USAGE = 9200000 , -- Watts
		-- AHEE_COOLING_PRESSURE = 500000 , -- Pascals
		-- AHEE_COOLING_FLOW = 620000 , --Meter^2
		-- AHEE_COOLING_DENSITY = 50000 -- Watts / Meter^2 * Kelvin
		
	end
	
	function Body_PhysioMobilityCalc( Ply )
		local PlyMed = Ply.MedicalStats
		local BodyPartsList = PlyMed.BodyParts
		local MobilityAffected = 0
		
		for Key , Part in pairs( BodyPartsList ) do
			local PartMobilityTaken = 0
			
			PartMobilityTaken = PartMobilityTaken + ((Part.SoftPoints / Part.MaxSoftPoints) * 0.25)
			PartMobilityTaken = PartMobilityTaken + ((Part.BonePoints / Part.MaxBonePoints) * 0.75)
			PartMobilityTaken = PartMobilityTaken * Part.MobilityPercent
			
			MobilityAffected = MobilityAffected + PartMobilityTaken
			
		end
		
		PlyMed.PhysiologicalMobility = MobilityAffected
		
	end
	
	function BodyPart_DoDamage( Ply , BodyGroup , Dmg )
		
		local Medical = Ply.MedicalStats
		local BoneDmg = (( Dmg ^ 3) / 10 )
		
		if tostring(BodyGroup) == "0" then BodyGroup = math.random(1,7) end
		
		for i , Part in pairs( Medical.BodyParts ) do
			if tostring(Part.AssignedPart) == tostring(BodyGroup) then
				
				local BoneShrapnel = Part.BonesBroken and 5 or 0
				
				if Part.SoftPoints > 0 then
					Part.SoftPoints = math.Clamp( Part.SoftPoints - math.Round(Dmg*BoneShrapnel,1) , 0 , Part.SoftPoints )
					Ply:EmitSound("pelvareign_body/trauma_hit_"..math.random( 1 , 3 )..".mp3", 80, math.random( 80 , 120 ) , 1 )
				end
				
				Ply:EmitSound("physics/body/body_medium_impact_soft"..math.random( 1 , 7 )..".wav", 75, math.random( 85 , 90 ) , 0.4 )
				
				if Part.BonePoints > 0 and not Part.BonesBroken then
					Part.BonePoints = math.Clamp( Part.BonePoints - math.Round(BoneDmg,1) , 0 , Part.BonePoints )
					if Part.BonePoints == 0 then
						if CLIENT then
							Hint_Setup( Part.Name .. " was Broken..." , true )
							EmitSound( "ahee_suit/suit_medical_warn_short.mp3" , Vector() , -2 , CHAN_AUTO , 1 , 110 , 0 , math.random(95,103) )
						end
						Part.BonesBroken = true
						Ply:EmitSound("pelvareign_body/excessivetrauma_hit_"..math.random( 1 , 5 )..".mp3", 90, math.random( 80 , 90 ) , 0.2 )
						for i=1, 3 do
							sound.Play( Sound("pelvareign_body/rawbonebreak.mp3"), Ply:WorldSpaceCenter() , 90, math.random(68,92), 1 )
						end
					end
				end
				
			end
		end
		
		Body_PhysioMobilityCalc( Ply )
		Ply.MedicalStats.PhysiologicalExertion = Ply.MedicalStats.PhysiologicalExertion + ( math.Clamp( Dmg , 0 , 150 ) * 0.1 )
		
	end
	
	net.Receive( "BodyPart_DoDamage_Client", function( len , ply )
		
		local Plr = ply or LocalPlayer()
		local BodyPoint = net.ReadString()
		local Damage = net.ReadFloat()
		
		BodyPart_DoDamage( Plr , BodyPoint , Damage )
		
	end)
	
	-- Bleeding = false,
	-- Internal_Bleeding = false,
	-- HeartAttack = false,
	-- Tension = 50.0, -- Percent
	
	-- Blood = 5200.0, -- Liters
	-- HeartRate = 800, -- BPM
	-- Hydration = 100.0, -- Percent
	-- BloodPressure = { 400 , 390 }, -- Systolic / Diastolic
	-- HistoAdrenalineRate = 0.0, -- Percent
	-- Consciousness = 100.0, -- Percent
































	function SuitAudio( Ply, t )
		
		t.DSP = 0
		t.Volume = t.Volume * 0.5
		
		return true
	end
	
	function BlowOpenDoor( ply, Object )
		if string.match( Object:GetClass(), "door" ) != nil then 
			if SERVER then
				local Door = ents.Create( "prop_physics" )
				if IsValid(Door) and IsValid(Object) then
					Door:SetModel( Object:GetModel() )
					Door:SetPos( Object:GetPos() )
					Door:SetAngles( Object:GetAngles() )
					Door:SetSkin( Object:GetSkin() or 0 )
					
					Object:Remove()
					Door:Spawn()
					
					Door:EmitSound("physics/metal/vehicle_impact_heavy1.wav", 90, math.random( 50 , 60 ) , 0.9 )
					
					local Doorphys = Door:GetPhysicsObject()
					local PhysEnv = physenv.GetPerformanceSettings()
					if IsValid(Door) and IsValid(Doorphys) then 
						Doorphys:SetVelocity( ply:EyeAngles():Forward() * Doorphys:GetMass() ^2  )
					end
				end
				
			end
		end
		
	end
	
	function Change_Weapon_Battery( ply )
		if not ply.Occupied.State then
			local Weapon = ply:GetActiveWeapon()
			Weapon:SendWeaponAnim( ACT_VM_DRAW )
			ply:EmitSound("main/interact_foley_long_1.wav", 90, math.random(115,120), 0.5 )
			ply:EmitSound("physics/metal/metal_sheet_impact_bullet2.wav", 90, math.random(140,150))
			
			ply.Occupied.State = true
			ply.Occupied.Type = "Change_Battery"
			
			timer.Simple( 0.35, function() if IsValid(ply) then
					local Weapon = ply:GetActiveWeapon()
					if IsValid(Weapon) then
						Weapon.Charge.Current = Weapon.Charge.Max
					end
					
					ply:EmitSound("main/lid_open_"..math.random(1,3)..".wav", 95, math.random(98,105), 0.9 )
					
					ply.Occupied.State = false
					ply.Occupied.Type = ""
					ply.MedicalStats.PhysiologicalExertion = ply.MedicalStats.PhysiologicalExertion + 1.9
					
				end
			end)
		end
		
	end
	
	function Change_Radeonic_Tack( ply )
		if not ply.Occupied.State then
			
			ply.Occupied.State = true
			ply.Occupied.Type = "Change_Radeonic_Tack"
			
			timer.Simple( 0.01, function() if IsValid(ply) then
					local PlyTack = ply.System_Tacks
					PlyTack.Radeonic_Tack.System_Internal_Switch = !PlyTack.Radeonic_Tack.System_Internal_Switch
					
					if CLIENT then 
						EmitSound( "ahee_suit/ahee_system_revital_click.mp3" , Vector() , -2 , CHAN_AUTO , 1 , 60 , 0 , 100 )
					end
					
					ply.Occupied.State = false
					ply.Occupied.Type = ""
					
				end
			end)
		end
		
	end
	
	function Change_Weapon_Round( ply )
		if not ply.Occupied.State then
			local Weapon = ply:GetActiveWeapon()
			Weapon:SendWeaponAnim( ACT_VM_RELOAD )
			ply:EmitSound("main/interact_foley_short_"..math.random(1,3)..".wav", 90, math.random(115,120), 0.8 )
			
			ply.Occupied.State = true
			ply.Occupied.Type = "Change_Ammunition"
			
			timer.Simple( 0.40, function() if IsValid(ply) then
					local Weapon = ply:GetActiveWeapon()
					
					ply:EmitSound("main/lid_open_"..math.random(1,3)..".wav", 95, math.random(180,200), 0.6 )
					
					ply.Occupied.State = false
					ply.Occupied.Type = ""
					ply.MedicalStats.PhysiologicalExertion = ply.MedicalStats.PhysiologicalExertion + 1.9
					
				end
			end)
		end
		
	end
	
	function Pelvareign_Punch( ply )
		
		local self = ply
		
		local InteractTrace = {}
		InteractTrace.start = self:EyePos()
		InteractTrace.endpos = InteractTrace.start + self:EyeAngles():Forward() * ( 2 * 52.4934 )
		InteractTrace.filter = self
		InteractTrace.ignoreworld = true
		
		local AbleToInteract = util.TraceLine(InteractTrace)
		local InteractFraction = AbleToInteract.Fraction
		local HitPoint = ( AbleToInteract.HitPos )
		local phys, d = nil, nil
		
		local Object = AbleToInteract.Entity
		local ObjWorldSpace = IsValid(Object) and Object:WorldSpaceCenter() or HitPoint
		local PushSpeed = IsValid(Object) and (Object:WorldSpaceCenter()-AbleToInteract.HitPos):GetNormalized() or AbleToInteract.Normal
		local PushMult = (InteractFraction^0.5) * (self.NetMass * 1000) * 420 -- rough surface area of fist
		local Velo = (self:EyeAngles():Forward() * self.NetMass)
		
		local DamageEnergyConsumation = (AbleToInteract.Fraction * self.NetMass) ^ 2
		
		if SERVER then 
			self:Extinguish() 
			
			d = DamageInfo()
			d:SetDamage( PushMult )
			d:SetAttacker( self )
			d:SetDamageForce( PushMult * PushSpeed )
			d:SetDamageType( DMG_CLUB )
		end
		
		if IsValid(Object) then
			phys = Object:GetPhysicsObject()
			
			if SERVER then 
				Object:TakeDamageInfo( d ) 
				Object:Fire("EnableMotion")
			end
			
			if string.match( Object:GetClass(), "door" ) != nil then 
				sound.Play( Sound("main/bomb_explosion_"..math.random(1,3)..".mp3"), HitPoint , 130, math.random(68,92), 1 )
				ParticleEffect( "FragExplose", HitPoint , Angle() )
				ParticleEffect( "SmokeShockFar", HitPoint , self:EyeAngles() )
				
				BlowOpenDoor( self, Object )
				
			end
			if SERVER then constraint.RemoveAll( Object ) end
			
		end
		
		if IsValid(phys) then 
			phys:ApplyForceOffset( self:GetVelocity() + (self:EyeAngles():Forward() * PushMult) , AbleToInteract.HitPos)
			timer.Simple( 0.05 , function() if IsValid(Object) and IsValid(phys) and phys:GetVelocity():Length() < 5 then 
				ParticleEffect( "FragExplose", HitPoint , Angle() ) 
				sound.Play( "main/tanks_explosion_0"..math.random(1,3)..".mp3", HitPoint , 100, math.random(68,92), 1 )
				Object:Remove() 
			end end)
		end
		
		local FullDragBar = self.DragShielding / self.DragShieldingLimit
		if FullDragBar >= 0.1 and self.DragShieldingSetting then
			self.DragShielding = math.Clamp(self.DragShielding - (DamageEnergyConsumation/400),0,self.DragShielding)
			self:EmitSound("ahee_suit/fraise/fraiseformationshield_nostart.mp3", 110, math.random(35,50),0.9)
			sound.Play( "main/bouncehit.wav", HitPoint , 130, math.random(68,92), 1 )
			
			
			if SERVER then 
				DragShieldHit_Shared( self , HitPoint , math.Rand(0.5,2) ) 
			end
		else
			
			if CheckShieldingStability(self) and not CheckShieldingDown(self) then
				self:EmitSound("ahee_suit/fraise/fraiseformationshield_failure_"..math.random(1,3)..".mp3", 110, math.random(230,250),0.9)
				
				local Hit_Table = {}
				Hit_Table.Owner = self
				Hit_Table.Vector = HitPoint
				Hit_Table.Damage = math.Rand(1,3)
				
				ShieldHit_Shared( Hit_Table )
				if SERVER then
					ChangeShielding( self , DamageEnergyConsumation , false , Object )
				
					net.Start( "ShieldStats_Affected_Client" )
					net.WriteEntity( self )
					net.WriteFloat( DamageEnergyConsumation )
					net.WriteBool( false )
					net.Send( self )
				end
			end
			
			if SERVER then
				local DetonationWaveRadius = (math.random(50,70) * 52.4934)
				for k, v in pairs(ents.FindInSphere( HitPoint ,DetonationWaveRadius)) do
					if IsValid(v) and ( v:IsPlayer() or v:IsNPC() or v:IsNextBot() or v:GetMoveType() == MOVETYPE_VPHYSICS ) then
						local Dist = ( 1 - ( v:GetPos():Distance(HitPoint) / DetonationWaveRadius ) )
						local vphys = v:GetPhysicsObject()
						
						local dmg = DamageInfo()
						dmg:SetDamage( (DamageEnergyConsumation / 1000) * Dist^2 )
						dmg:SetAttacker( game.GetWorld() )
						dmg:SetInflictor( self )
						dmg:SetDamageType( DMG_BLAST )
						
						v:TakeDamageInfo( dmg )
						if (v != ply) then
							v:SetVelocity( ((v:GetPos() - self:GetPos()):GetNormalized() * Dist^2) * math.random(1e1,1e6) )
							if IsValid(vphys) then vphys:ApplyForceCenter( ((v:GetPos() - HitPoint):GetNormalized() * Dist^2) * math.random(1e1,1e7) ) v:Fire("EnableMotion") end
						end
						
					end
				end
			end
			
			ClientExplosionSound( self, 300 , "high_energy_systems/nucleation.mp3" , 175 , 0.03 )
			
			sound.Play( "main/bomb_explosion_"..math.random(1,3)..".mp3", HitPoint , 130, math.random(23,25), 1 )
			sound.Play( "main/airshock.wav", HitPoint , 120, math.random(168,170), 0.3 )
			ParticleEffect( "Flashed", HitPoint , Angle() )
			ParticleEffect( "Shockwave", HitPoint , Angle() )
			ParticleEffect( "AMMOCOOKFIREBALL", HitPoint , self:EyeAngles() )
			ParticleEffect( "APFSDSSMALLEMBERS", HitPoint , self:EyeAngles() )
			
			util.ScreenShake( AbleToInteract.HitPos, (InteractFraction/0.5)*12, 2222, 0.9, (InteractFraction/0.5)*4000 )
			self:SetVelocity( -Velo/3 )
		end
		
	end
	
	net.Receive( "NetDiscovery_Mapping_Request", function( len , plr )
		local Ply = plr
		
		if NetDiscovery_Systematic then
			if NetDiscovery_Systematic.DistrictMapping then
				 local JSONString = util.TableToJSON( NetDiscovery_Systematic.DistrictMapping )
				 local CompressedStr = util.Compress( JSONString )
				 if CompressedStr != nil then
					net.Start("NetDiscovery_Mapping_Receive")
						net.WriteBool(true)
						net.WriteUInt( #CompressedStr, 16 )
						net.WriteData( CompressedStr, #CompressedStr )
						net.WriteString("Net Discovery Mapping Availed!")
					net.Send(Ply)
				 else
					net.Start("NetDiscovery_Mapping_Receive")
						net.WriteString("FAILURE! Net Discovery Data Failure!")
					net.Send(Ply)
				 end
				 
			end
		else
			net.Start("NetDiscovery_Mapping_Receive")
				net.WriteString("FAILURE! Net Discovery Unresolved!")
			net.Send(Ply)
		end
		
	end)
	
	net.Receive( "NetDiscovery_Mapping_Receive", function( len )
		local Ply = LocalPlayer()
		local SuccessBool = net.ReadBool()
		local bytes_amount = net.ReadUInt( 16 )
		local compressed_message = net.ReadData( bytes_amount ) -- Gets back our compressed message
		local message = util.Decompress( compressed_message ) -- Decompresses our message
		
		if SuccessBool then
			if not NetDiscovery_Systematic then NetDiscovery_Systematic = {} end
			local TableRecieved = util.JSONToTable( message )
			NetDiscovery_Systematic.DistrictMapping = TableRecieved
			
			DistrictMapping_Finish()
			
			local Message = net.ReadString()
			Hint_Setup( Message )
			
		else
			local FailureMessage = net.ReadString()
			Hint_Setup( FailureMessage, true )
			
		end
		
	end)
	
	
	net.Receive( "Pelvareign_Punch", function( len , ply )
		local Ply = ply and ply or LocalPlayer()
		if SERVER then
			net.Start( "Pelvareign_Punch" )
			net.Send( Ply )
		end
		Pelvareign_Punch( Ply )
	end)
	
	net.Receive( "Change_Weapon_Battery", function( len , ply )
		local Ply = ply and ply or LocalPlayer()
		if SERVER then
			net.Start( "Change_Weapon_Battery" )
			net.Send( Ply )
		end
		Change_Weapon_Battery( Ply )
	end)
	
	net.Receive( "Change_Radeonic_Tack", function( len , ply )
		local Ply = ply and ply or LocalPlayer()
		if SERVER then
			net.Start( "Change_Radeonic_Tack" )
			net.Send( Ply )
		end
		Change_Radeonic_Tack( Ply )
	end)
	
	net.Receive( "Change_Weapon_Round", function( len , ply )
		local Ply = ply and ply or LocalPlayer()
		if SERVER then
			net.Start( "Change_Weapon_Round" )
			net.Send( Ply )
		else
			Interactable_MainFrame = Menu_Interactable_Setup( true , Interaction_Regime_GunSystem )
		end
		Change_Weapon_Round( Ply )
	end)
	
	net.Receive( "Pelvareign_Physical_Interaction", function( len , plr )
		local Ply = plr or LocalPlayer()
		
	end)
	
	net.Receive( "HoldingItem", function( len , plr )
		local Ply = plr or LocalPlayer()
		local Held = net.ReadEntity()
		Ply.HeldItem = Held
	end)
	
	function FraiseShield_ExplosiveDestabilization( Plr )
		
		local Hit_Table = {}
		Hit_Table.Owner = Plr
		Hit_Table.Vector = Plr:WorldSpaceCenter() + (VectorRand() * math.random(-50,50))
		Hit_Table.Damage = 1
		Hit_Table.Amount = 20
		
		ShieldHit_Shared( Hit_Table )
		
		if Plr.Fraise_Stable then
			sound.Play( Sound("ahee_suit/fraise/fraiseformationshield_closeup_"..math.random(1,2)..".mp3"), Plr:WorldSpaceCenter() , 110, math.random(98,102), 1 )
		else
			sound.Play( Sound("ahee_suit/fraise/fraiseformationshield_setup_"..math.random(1,5)..".mp3"), Plr:WorldSpaceCenter() , 110, math.random(98,102), 1 )
			sound.Play( Sound("tunneling_physics/radeonic_distresipution_wave_"..math.random(1,7)..".mp3"), Plr:WorldSpaceCenter() , 120, math.random(98,102), 1 )
		end
		
	end
	
	net.Receive( "Shield_Toggle", function( len , plr )
		local Owner = plr or LocalPlayer()
		--FraiseShield_ExplosiveDestabilization( Owner )
	end)
	
	net.Receive( "DragShield_Toggle", function( len , plr )
		local Owner = plr or LocalPlayer()
		
		DragShieldHit_Shared( Owner , Owner:WorldSpaceCenter() + (VectorRand() * math.random(-50,50)), 2 , 8 )
		
		if Owner.DragShieldingSetting then
			sound.Play( Sound("ahee_suit/fraise/fraiseformationshield_closeup_"..math.random(1,2)..".mp3"), Owner:WorldSpaceCenter() , 110, math.random(98,102), 1 )
		else
			sound.Play( Sound("ahee_suit/fraise/fraiseformationshield_setup_"..math.random(1,5)..".mp3"), Owner:WorldSpaceCenter() , 110, math.random(98,102), 1 )
			sound.Play( Sound("tunneling_physics/radeonic_distresipution_wave_"..math.random(1,7)..".mp3"), Owner:WorldSpaceCenter() , 120, math.random(98,102), 1 )
		end
	end)
	
	function ShieldHit_Shared( ShieldHit_Table )
		
		local Owner = ShieldHit_Table.Owner
		local HitPoint = ShieldHit_Table.Vector
		local Multitude = ShieldHit_Table.Damage or 1
		local Amount = ShieldHit_Table.Amount or 1
		local hit_dmginfo = ShieldHit_Table.Dmginfo
		
		local Attacker = hit_dmginfo != nil and hit_dmginfo:GetAttacker() or nil
		local Attack_Dir = ( hit_dmginfo != nil and Attacker != nil ) and (Attacker:GetPos() - Owner:GetPos()):Angle() or AngleRand()
		
		local effectdata = EffectData()
		effectdata:SetOrigin( HitPoint + (VectorRand() * math.Rand(-0.8,0.8)) * Amount )
		effectdata:SetNormal( AngleRand():Forward() )
		effectdata:SetMagnitude( math.Rand( 5 , 70 ) * Multitude )
		effectdata:SetRadius( math.Rand( 0.1 , 0.3 ) )
		util.Effect( "regular_material_spark", effectdata)
		
		local effectdata2 = EffectData()
		effectdata2:SetOrigin( HitPoint )
		effectdata2:SetNormal( AngleRand():Forward() )
		effectdata2:SetMagnitude( Multitude )
		effectdata2:SetRadius( Amount )
		util.Effect( "tunneling_fraiseplane_annihilate", effectdata2, true, true)
		
		ParticleEffect( "fraise_jet_fragment", HitPoint, Attack_Dir )
		
		if Multitude > 0.15 then
			sound.Play( Sound("tunneling_physics/tunnelingphysics_conjuctspeak"..math.random( 1 , 5 )..".mp3"), HitPoint , 100, math.random(230,250), Multitude ) 
		end
		
		local BlastDmg = DamageInfo()
		BlastDmg:SetDamage( math.random(12,85) )
		BlastDmg:SetAttacker( Owner )
		BlastDmg:SetInflictor( Owner )
		BlastDmg:SetDamageType( DMG_RADIATION )
		util.BlastDamageInfo( BlastDmg, HitPoint, (math.Rand(1,3) * 52.4934) )
		
	end
	
	function DragShieldHit_Shared( Owner , Vector , Damage , Amount )
		
		local HitPoint = Vector
		local Multitude = Damage
		local Amount = Amount
		
		local CalcAmt = (Amount != nil and Amount) or 1
		
		local effectdata = EffectData()
		effectdata:SetOrigin( HitPoint + (VectorRand() * math.Rand(-0.8,0.8)) * CalcAmt )
		effectdata:SetNormal( AngleRand():Forward() )
		effectdata:SetMagnitude( math.Rand( 5 , 70 ) * Multitude )
		effectdata:SetRadius( math.Rand( 0.1 , 0.2 ) )
		util.Effect( "regular_material_spark", effectdata)
		
		local effectdata2 = EffectData()
		effectdata2:SetOrigin( HitPoint )
		effectdata2:SetNormal( AngleRand():Forward() )
		effectdata2:SetMagnitude( Multitude )
		effectdata2:SetRadius( CalcAmt )
		util.Effect( "tunneling_capillaryform_flash", effectdata2, true, true)
		
		if Multitude > 0.15 then
			sound.Play( Sound("tunneling_physics/tunnelingphysics_conjuctspeak"..math.random( 1 , 5 )..".mp3"), HitPoint , 100, math.random(230,250), Multitude ) 
		end
		
		local BlastDmg = DamageInfo()
		BlastDmg:SetDamage( math.random(3.1,5.9) )
		BlastDmg:SetAttacker( Owner )
		BlastDmg:SetInflictor( Owner )
		BlastDmg:SetDamageType( DMG_RADIATION )
		util.BlastDamageInfo( BlastDmg, Vector, math.random(13,32) )
		
	end
	
	function CBMArmorHit_Shared( Owner , Vector , Damage , PressureType , TunnelingInfo )
		local TunnelingInfo = TunnelingInfo or {}
		
		if not table.IsEmpty(TunnelingInfo) then
			local effectdata = EffectData()
			effectdata:SetOrigin( Vector )
			effectdata:SetNormal( AngleRand():Forward() )
			effectdata:SetMagnitude( Damage )
			effectdata:SetScale( PressureType )
			util.Effect( "centralbasematerial_spark", effectdata, true, true)
		else
			local effectdata = EffectData()
			effectdata:SetOrigin( Vector )
			effectdata:SetNormal( AngleRand():Forward() )
			effectdata:SetMagnitude( 0.25 )
			effectdata:SetScale( 1 )
			util.Effect( "centralbasematerial_spark", effectdata, true, true)
		end
		
	end
	
	net.Receive( "Client_Sound_ShockWave", function( len )
		local String = net.ReadString()
		local Time = net.ReadFloat()
		local Dist = ( 1 - net.ReadFloat() ) or 0
		local Volume = net.ReadFloat() or 1
		local Pitch = net.ReadInt( 9 ) or 100
		
		timer.Simple( Time , function() 
			EmitSound( String , Vector() , -1 , CHAN_AUTO , math.Clamp(Dist,0,1) * Volume , 100 , 0 , Pitch )
		end)
	end)
	
	net.Receive( "ShieldStats_Affected_Client", function( len )
		local self = net.ReadEntity()
		local Energy = net.ReadFloat() or 0
		local DropShield = net.ReadBool()
		
		ChangeShielding(self,Energy,DropShield)
		
	end)
	
	net.Receive( "AHEE_SERVER_VALUES", function( len )
		local self = net.ReadEntity()

		if not IsValid(self) then return end
		if self ~= LocalPlayer() then return end
		
		local Shield = net.ReadFloat()
		local BufferShield = net.ReadFloat()
		
		local DragShielding = net.ReadFloat()
		local DragShieldingBuffer = net.ReadFloat()
		
		local FireCapacitorEnergy = net.ReadFloat()
		
		local ShieldLock = net.ReadBool()
		local BufferShieldLock = net.ReadBool()
		
		if not self.ShieldingList then return end
		
		for Shield, Value in pairs(self.ShieldingList) do
			-- Index, TurnedOffBool, Power, MaxPower, Name, PowerReleaseMult
			
			Value[1] = net.ReadInt( 32 )
			Value[2] = net.ReadBool()
			Value[3] = net.ReadFloat()
			Value[4] = net.ReadFloat()
			Value[5] = net.ReadString()
			Value[6] = net.ReadFloat()
			
		end
		
		self.MainCapacitorMJ = Shield
		self.ShieldingBufferEnergy = BufferShield
		
		self.MainCapacitorMJLocked = ShieldLock
		self.ShieldingBufferEnergyLocked = BufferShieldLock
		
		self.FireCapacitorEnergy = FireCapacitorEnergy
		
		self.DragShielding = DragShielding
		self.DragShieldingBuffer = DragShieldingBuffer
		
		--print(self.MainCapacitorMJ)
		
		if self.ConsciousVision then 
			self.ConsciousVision = math.Clamp( self.ConsciousVision + (self.InducedGForce/500) - (4-math.Clamp(self.InducedGForce/500,1,3)) ,0,255)
		else
			self.ConsciousVision = 0
		end
	end )
	
	net.Receive( "Recieve_Suit", function()
		local self = LocalPlayer() or net.ReadEntity()
		
		if not IsValid(self) then return end
		
		Shared_Startup(self)
		
		--self:EmitSound( "main/citationcombative_stinger_fade_"..math.random(1,3)..".mp3", 120, 100, 0.5, CHAN_STATIC, 0, 0 )
		
		ParticleEffect( "Shockwave", self:WorldSpaceCenter() , Angle() )
		ParticleEffect( "SmokeShockFar", self:WorldSpaceCenter() , Angle() )
		
		print(self,self:GetNWBool("AHEE_EQUIPED"))
		Hint_Setup( "Suit Ready, Advance!" , nil , 8 )
		
		local FrameSizeW = ScrW() / 5
		local FrameSizeH = ScrH() / 5
		
		self.ScreenFrame = {}
		
		self.frame = vgui.Create( "DPanel", self.ScreenFrame , "LeftCam" )
		self.frame:SetSize( FrameSizeW, FrameSizeH )
		self.frame:SetPos( 0 , 0 )
		self.frame:SetAlpha( 200 )
		
		self.frame2 = vgui.Create( "DPanel", self.ScreenFrame , "RightCam" )
		self.frame2:SetSize( FrameSizeW, FrameSizeH )
		self.frame2:SetPos( ScrW() - FrameSizeW , 0 )
		self.frame2:SetAlpha( 200 )
		
		--self.frame:MakePopup()
		
		hook.Add( "SetupSkyboxFog", self, function ()
			if self.TycronicVision then
				local ThrottleAffect = (self.TychronicInverterThrottle / 2500)
				render.FogMode( 1 )
				render.FogStart( 100 )
				render.FogEnd( 200 + (ThrottleAffect * 25000) )
				render.FogMaxDensity( 1 )
				return true
			end
			return false
		end)
		
		hook.Add( "SetupWorldFog", self, function ()
			if self.TycronicVision then
				local ThrottleAffect = (self.TychronicInverterThrottle / 2500)
				render.FogMode( 1 )
				render.FogStart( 100 )
				render.FogEnd( 200 + (ThrottleAffect * 25000) )
				render.FogMaxDensity( 1 )
				return true
			end
			return false
		end)
		
		hook.Add( "PostDrawHUD", self, function ()
			AHEE_HUD_System()
		end)
		
		hook.Add( "PreDrawEffects", self, function ()
			ThreeD_HUD_System()
		end)
		
		hook.Add( "CalcView", "PelvareignSecondPerson", function( ply, pos, angles, fov )
			local View = PelvareignSecondPersonCalc( ply, pos, angles, fov )
			return View
		end )
		
	end)
	
	net.Receive( "GettingTargeted_Server", function( len , ply )
			local Entity = net.ReadEntity() or nil
			local TargetValue = nil
			if not IsValid(Entity) then 
				net.Start( "GettingTargeted" )
					net.WriteBool( false ) 
				net.Send( ply )
			return end
			
			if Entity:GetNWVarTable() then 
				for Key, Ent in pairs( Entity:GetNWVarTable() ) do
					if Key == "Targeted" then
						TargetValue = Ent
					end
				end
				
				if TargetValue == ply then
					net.Start( "GettingTargeted" )
						net.WriteBool( true ) 
					net.Send( ply )
				else
					net.Start( "GettingTargeted" )
						net.WriteBool( false ) 
					net.Send( ply )
				end
				
			end
	end)
	
	net.Receive( "AHEE_Targeting_Report", function( len )
		local PLR = LocalPlayer()
		local Target = net.ReadEntity() or nil
		PLR:SetNWEntity( "TargetSelected", Target )
	end)
	
	
	function DamageFunction( self , target , dmginfo )
	
		local DMGINCOMING = dmginfo:GetDamage() 
		local DMGPOS = dmginfo:GetDamagePosition()
		local Attacker = dmginfo:GetInflictor() or dmginfo:GetAttacker() or nil
		
		if string.match(tostring(Attacker),"entityflame") then
			self.IsIgnited = true
			if not self.FireCapacitorEnergyLocked then
				if SERVER then
					Attacker:Remove()
				end
			end
			
			return true
		end
		
		if dmginfo:IsDamageType( DMG_POISON ) then return true end
		if not IsValid(self) and tostring(Attacker) == tostring(attachment) then return true end
		
		local BulletDamage = dmginfo:IsDamageType( DMG_BULLET ) or dmginfo:IsDamageType( DMG_SNIPER ) or dmginfo:IsDamageType( DMG_BUCKSHOT ) or dmginfo:IsDamageType( DMG_PLASMA ) 
		local NonsenseDamage = dmginfo:IsDamageType( DMG_RADIATION ) or dmginfo:IsDamageType( DMG_DROWN ) or dmginfo:IsDamageType( DMG_NERVEGAS ) or dmginfo:IsDamageType( DMG_BLAST ) or dmginfo:IsDamageType( DMG_BLAST_SURFACE )
		
		local FullDragBar = self.DragShielding / self.DragShieldingLimit
		
		local DragShieldingOn = (FullDragBar >= 0.1 and self.DragShieldingSetting)
		local ShieldingOn = (CheckShieldingStability(self) and not CheckShieldingDown(self))
		
		if (not IsValid(Attacker) or Attacker == attachment ) then 
			return true 
		else
			AttackDist = Attacker:GetPos():Distance(self:GetPos())
		end
		
		if dmginfo:GetDamageType() == DMG_BURN then
			if ShieldingOn then 
				local EnergyResist = (dmginfo:GetDamage() / 1000)
				self:EmitSound("main/incendiarysizzle.mp3", 90, math.random(40,60),0.4)
				if not self.FireCapacitorEnergyLocked then
					self.FireCapacitorEnergy = math.Clamp( self.FireCapacitorEnergy - EnergyResist , 0 , self.FireCapacitorEnergy )
					self:EmitSound("tunneling_physics/tunnelingphysics_conjuctspeak"..math.random(1,5)..".mp3", 75, math.random(44,55),0.23)
					util.ScreenShake( self:WorldSpaceCenter(), 3, math.random(1,3000), 0.3, 350 )
				end
				return true
			else
				local EnergyResist = ((dmginfo:GetDamage() ^ 2)  / 1000)
				self:EmitSound("main/incendiarysizzle.mp3", 75, math.random(90,130),0.2)
				if not self.FireCapacitorEnergyLocked then
					self.FireCapacitorEnergy = math.Clamp( self.FireCapacitorEnergy - EnergyResist , 0 , self.FireCapacitorEnergy )
					self:EmitSound("tunneling_physics/radeonic_distresipution_wave_"..math.random(1,7)..".mp3", 110, math.random(32,60),0.9)
				end
				dmginfo:ScaleDamage( math.log( EnergyResist ) )
				return false
			end
		
		elseif dmginfo:GetDamageType() == DMG_RADIATION then
			local ConsistantRadiation = (dmginfo:GetDamage()  / 400)
			
			net.Start( "RadiationExposure" )
			net.WriteFloat( ConsistantRadiation )
			net.Send( self )
			
			if ShieldingOn and not CheckShieldingDown(self) then 
				self:EmitSound("main/incendiarysizzle.mp3", 90, math.random(90,130),0.1)
				if ConsistantRadiation > 5000 then
					net.Start( "MalPlhasealSuit_Squeeze" )
					net.WriteBool( true )
					net.Send( self )
				end
				return true
			elseif (not ShieldingOn or CheckShieldingDown(self)) and DragShieldingOn then
				local DamageEnergyConsumation = (dmginfo:GetDamage() * 6000) ^ 0.8
				self.DragShielding = math.Clamp(self.DragShielding - DamageEnergyConsumation,0,self.DragShieldingLimit)
				local Capability = math.Clamp( (DamageEnergyConsumation / 1200) , 0.1 , 5 )
				self:EmitSound("main/railexplode.wav", 120, math.random(120,200),Capability/5)
				
				local HitPoint = ( self:WorldSpaceCenter() + VectorRand() * 45 )
				DragShieldHit_Shared( self , HitPoint , Capability)
				
				if ConsistantRadiation > 5000 then
					net.Start( "MalPlhasealSuit_Squeeze" )
					net.WriteBool( true )
					net.Send( self )
				end
				return true
			else
				return false
			end
		end
		
		if ShieldingOn then
			
			local EnergyLevel = math.Clamp( ((dmginfo:GetDamage()^0.95) / 1000) , 0.25 , 3 )
			local TunnelingInfo = {}
			TunnelingInfo.CBMShell = dmginfo.CBMShell
			
			local HitPoint = self:WorldSpaceCenter() + ( dmginfo:GetDamagePosition() - self:WorldSpaceCenter() ):GetNormalized() * math.Clamp( dmginfo:GetDamagePosition():Distance(self:WorldSpaceCenter()) , 0 , 50 )
			
			local Hit_Table = {}
			Hit_Table.Owner = self
			Hit_Table.Vector = HitPoint
			Hit_Table.Damage = EnergyLevel
			Hit_Table.Dmginfo = dmginfo
			
			ShieldHit_Shared( Hit_Table )
			
			if EnergyLevel > 0 then
				self:EmitSound("ahee_suit/fraise/fraise_passive_plasmaticdetonation_light_"..math.random(1,4)..".mp3", 90, math.random(90,110),0.9)
			elseif EnergyLevel > 1.5 then
				self:EmitSound("ahee_suit/fraise/fraise_passive_plasmaticdetonation_moderate_"..math.random(1,3)..".mp3", 110, math.random(90,110),0.9)
			else
				self:EmitSound("ahee_suit/fraise/fraise_passive_plasmaticdetonation_heavy_"..math.random(1,3)..".mp3", 120, math.random(90,110),0.9)
			end
			
			local SoundDistanceMax = 3200 * 52.4934
			for k, v in pairs(ents.FindInSphere(self:WorldSpaceCenter(),SoundDistanceMax)) do
				if IsValid(v) and v:IsPlayer() and v != self then
					local Dist = v:WorldSpaceCenter():Distance(self:WorldSpaceCenter())/SoundDistanceMax
					local Meter_Dist = Dist * SoundDistanceMax
					local Blip_String = ""
					
					local SpatialWaveFormat = (343*5*EnergyLevel) + math.random(-10,150)
					local ContinationWave = ( Meter_Dist ) / ( SpatialWaveFormat * 52.4934 )
					
					if EnergyLevel > 0 then
						Blip_String = (Meter_Dist < 350) and "ahee_suit/fraise/radeonic_range_close_blip_low_"..math.random(1,3)..".mp3" or "ahee_suit/fraise/radeonic_range_far_blip_low_"..math.random(1,3)..".mp3"
					elseif EnergyLevel > 1.5 then
						Blip_String = (Meter_Dist < 375) and "ahee_suit/fraise/radeonic_range_close_blip_low_"..math.random(1,3)..".mp3" or "ahee_suit/fraise/radeonic_range_far_blip_moderate.mp3"
					else
						Blip_String = (Meter_Dist < 390) and "ahee_suit/fraise/radeonic_range_close_blip_high_"..math.random(1,3)..".mp3" or "ahee_suit/fraise/radeonic_range_far_blip_high.mp3"
					end
					
					net.Start("Radeonic_Range_Blip")
						net.WriteFloat(ContinationWave)
						net.WriteString(Blip_String)
						net.WriteFloat(Dist)
					net.Send(v)
					
				end
			end
			
			if Attacker:GetNWBool("AHEE_EQUIPED") and Attacker:IsPlayer() and not CheckShieldingDown(self) then 
				if AttackDist < (52.4934*3.25) then
					local DetonationWaveRadius = (math.random(20,30) * 52.4934)
					for k, v in pairs(ents.FindInSphere( self:WorldSpaceCenter() ,DetonationWaveRadius)) do
						if IsValid(v) and ( v:IsPlayer() or v:IsNPC() or v:IsNextBot() or v:GetMoveType() == MOVETYPE_VPHYSICS ) then
							local Dist = ( 1 - (v:GetPos():Distance(self:GetPos())/DetonationWaveRadius) )
							
							v:SetVelocity( ((v:GetPos() - self:GetPos()):GetNormalized() * Dist) * math.random(10000,90000) )
							v:EmitSound("main/roundhit_softmatter_"..math.random(1,9)..".mp3", 130, math.random(140,150),1)
							
						end
					end
					
					Attacker:EmitSound("high_energy_systems/plasma_anticharge_coniccrossover_"..math.random(1,3)..".mp3", 140, math.random(90,120),1)
					Attacker:EmitSound("main/tesladischarge0"..math.random(1,5)..".mp3", 120, math.random(80,90),1)
				end
				return true
			end
			
			local DamageEnergyConsumation = (dmginfo:GetDamage()  / 400)
			
			ChangeShielding( self , DamageEnergyConsumation , false , Attacker )
			
			net.Start( "ShieldStats_Affected_Client" )
			net.WriteEntity( self )
			net.WriteFloat( DamageEnergyConsumation )
			net.WriteBool( false )
			net.Send( self )
			
				local AttackerDirectionized = (IsValid(Attacker) and (Attacker:GetPos() - self:GetPos()):GetNormalized()) or self:EyeAngles():Forward()
				local randomiz = math.random(1,3)
				AttackerDirectionized = AttackerDirectionized * ((52.4934*randomiz)*math.random(90,100)/100)
				
				if IsValid(Attacker) and self.ShieldingActiveShot then
					local Low, High = self:WorldSpaceAABB()
					local vPos = Vector( math.Rand( Low.x, High.x ), math.Rand( Low.y, High.y ), math.Rand( Low.z, High.z ) )
					
					local effectdata = EffectData()
					effectdata:SetStart( vPos )
					effectdata:SetOrigin( AttackerDirectionized )
					effectdata:SetNormal( AngleRand():Forward() )
					if IsValid(Attacker) and Attacker != self and Attacker:GetPos():Distance(self:GetPos()) < (52.4934*3) then
						effectdata:SetEntity( Attacker )
					end
					effectdata:SetMagnitude( (dmginfo:GetDamage() / 400) + 5 )
					util.Effect( "tunneling_fraise_arc", effectdata, true, true)
				end
				
				if SERVER and self.ShieldingActiveShot then
					if IsValid(Attacker) and Attacker != self and Attacker:GetPos():Distance(self:GetPos()) < (52.4934*3) then
						local daginfo = DamageInfo()
						local dmg_random = math.random(50000,108000) 
						local PowerMultiplier = 1
						for Shield, Value in pairs(self.ShieldingList) do
							local TurnedOut = Value[2]
							local Power = Value[3]
							if TurnedOut == false then
								PowerMultiplier = Value[6]
								break
							end
						end
						if Attacker != attachment then
							daginfo:SetDamage( (dmg_random*PowerMultiplier) + ((DMGINCOMING/3)*PowerMultiplier) )
							daginfo:SetAttacker( self )
							daginfo:SetInflictor( self )
							daginfo:SetDamageType( DMG_BLAST ) 
							daginfo:SetDamagePosition( self:WorldSpaceCenter() )
							Attacker:Ignite(5)
							Attacker:TakeDamageInfo( daginfo )
							self:EmitSound("main/tesladischarge0"..math.random(1,5)..".mp3", 120, math.random(120,160),1)
						end
						
						local DetonationWaveRadius = (math.random(5,7) * 52.4934)
						
						for k, v in pairs(ents.FindInSphere( self:WorldSpaceCenter() ,DetonationWaveRadius)) do
							if IsValid(v) and ( v:IsPlayer() or v:IsNPC() or v:IsNextBot() or v:GetMoveType() == MOVETYPE_VPHYSICS ) then
								local Dist = ( 1 - (v:GetPos():Distance(self:GetPos())/DetonationWaveRadius) )
								
								v:SetVelocity( ((v:GetPos() - self:GetPos()):GetNormalized() * Dist) * math.random(1000,9000) )
								v:EmitSound("main/roundhit_softmatter_"..math.random(1,9)..".mp3", 130, math.random(70,80),1)
								
							end
						end
						
					end
					self:EmitSound("ahee_suit/fraise/active_protection_discharge_"..math.random(1,3)..".mp3", 110, math.random(100,110),1)
					
					if (dmginfo:GetDamage()  / 400) > 10 then
					
						for i=1,25 do
							timer.Simple( i/50, function()
								if not IsValid(self) or not IsValid(self) then return end
								self:SetViewPunchAngles(Angle(math.random(-10-i,10+i)/20, math.random(-10-i,10+i)/20, math.random(-10-i,10+i)/20)+self:GetViewPunchAngles())
							end)
						end
						
						local d = DamageInfo()
						d:SetDamage( math.random(29890,91300) )
						d:SetAttacker( self )
						d:SetInflictor( self )
						d:SetDamageType( DMG_RADIATION )
						util.BlastDamageInfo(d, self:WorldSpaceCenter(), (math.random(4,6) * 52.4934))
						
						net.Start( "MalPlhasealSuit_Squeeze" )
						net.WriteBool( true )
						net.Send( self )
						
					end
					
				end
				
				dmginfo:ScaleDamage( 0 )
			return true
		end
		
		if FullDragBar >= 0.1 and self.DragShieldingSetting then
			local DamageEnergyConsumation = dmginfo:GetDamage()
			self.DragShielding = math.Clamp(self.DragShielding - DamageEnergyConsumation,0,self.DragShieldingLimit)
			self:EmitSound("ahee_suit/fraise/fraiseformationshield_nostart.mp3", 110, math.random(230,250),0.9)
			
			local HitPoint = ( dmginfo:GetDamagePosition() )
			DragShieldHit_Shared( self , HitPoint , math.Clamp( ((dmginfo:GetDamage()^0.95) / 100) , 0.1 , 5 ))
			
			return true 
		end
		
		if true then 
			local BodyGroupHit = self:LastHitGroup()
			local BluntDMG = (BulletDamage and not NonsenseDamage) and 1 or 0
			local HitPoint = ( dmginfo:GetDamagePosition() )
			local HitMultitude = math.Clamp( ( (dmginfo:GetDamage()^0.95) / 100 ) , 0.01 , 5 )
			if not dmginfo:IsDamageType( DMG_BURN ) then
				CBMArmorHit_Shared( self , HitPoint , HitMultitude , BluntDMG )
			end
			
			self:SetViewPunchAngles( self:GetViewPunchAngles() + Angle( math.random(-1,1)*HitMultitude , math.random(-1,1)*HitMultitude , 0 ) )
			
			if dmginfo:GetDamage() > (50) then
				local Weakness = math.Clamp( self:GetMaxHealth() / self:Health() , 1 , 10 )
				
				local DMGed = (dmginfo:GetDamage() / (1000)) * Weakness
				
				BodyPart_DoDamage( self , BodyGroupHit , DMGed )
				
				net.Start( "BodyPart_DoDamage_Client" )
				net.WriteString( tostring(BodyGroupHit) )
				net.WriteFloat( DMGed )
				net.Send( self )
				
			end
			
			dmginfo:ScaleDamage( math.Clamp( ((dmginfo:GetDamage()^0.95) / 1000) , 0 , 0.9 ) )
			
			return false
		end
	
	end
	
	
	
	
	
	
	
	
	
	
	
	function Recieve_Suit_Server( plr )
		
		if not IsValid(plr) then return end
		local self = plr
		
		if plr:GetNWBool("AHEE_EQUIPED") then
			return 
		end
		
		net.Start( "Recieve_Suit" )
			net.WriteEntity( self ) 	
		net.Send( self )
		
		Shared_Startup(self)
		
		local META_ENT = FindMetaTable('Entity')
		local META_PLR = FindMetaTable('Player')
		local META_WEP = FindMetaTable('Weapon')
		local META_NPC = FindMetaTable('NPC')
		local META_BOT = FindMetaTable('NextBot')
		
		local META_KillSilent = META_PLR.KillSilent
		local META_Spawn = META_ENT.Spawn
		local META_Remove = META_ENT.Remove
		local META_Ragdoll = META_PLR.CreateRagdoll
		local META_Alive = META_PLR.Alive
		
		META_Alive = nil
		META_Ragdoll = nil
		META_Remove = nil
		META_KillSilent = nil
		
		if plr.OnRemove then
			plr.OnRemove = function() end
		end
		
		if plr.KillSilent then
			plr.KillSilent = function() end
		end
		
		if plr.CreateRagdoll then
			plr.CreateRagdoll = function() end
		end
		
		if (SERVER) then 
			self:SetMaxHealth( 1000000 )
			self:SetHealth( self:GetMaxHealth() )
			
			-- self.PlayerBody = ents.Create( "prop_ragdoll" )
			-- self.PlayerBody:SetModel( "models/Combine_Super_Soldier.mdl" )
			-- self.PlayerBody:SetPos( self:GetPos() )
			-- self.PlayerBody:SetAngles( self:GetAngles() )
			-- self.PlayerBody:Spawn()
			
			-- self.PlayerBody:SetCollisionGroup( COLLISION_GROUP_WORLD )
			
			-- -- hook.Add( "PhysicsCollide", self.PlayerBody, function( attachment, data, phys )
				-- -- if ( data.Speed > 50 ) then attachment:EmitSound( Sound( "Flashbang.Bounce" ) ) end
			-- -- end)
			
			self:StripWeapons()
			
		end
		
		hook.Add( "EntityTakeDamage", self, function( attachment, target, dmginfo )
			if self:GetNWBool("AHEE_EQUIPED") and target:IsPlayer() and IsValid(target) and target == attachment then
				
				return DamageFunction( self , target , dmginfo )
			end
		end)
		
		hook.Add( "PlayerDeathSound", self, function( attachment, ply )
			if ( attachment == ply and attachment:IsPlayer() and attachment:GetNWBool("AHEE_EQUIPED") and not attachment.MainCapacitorBreak ) then 
				return true
			end
		end )
		
		hook.Add( "GetFallDamage", self, function( attachment, ply, speed )
			if ( attachment == ply and attachment:IsPlayer() and attachment:GetNWBool("AHEE_EQUIPED") and not attachment.MainCapacitorBreak ) then 
				local Speed = ( ply:GetVelocity():Length()/52.4934 ) ^ 3
				return ( Speed )
			end
		end )
				
		hook.Add( "PlayerShouldTakeDamage", self, function( attachment, ply, attacker )
			if ( attachment == ply and attachment:IsPlayer() and attachment:GetNWBool("AHEE_EQUIPED") ) then 
				local FullDragBar = self.DragShielding / self.DragShieldingLimit
				local DragShieldingOn = (FullDragBar >= 0.1 and self.DragShieldingSetting)
				local ShieldingOn = (CheckShieldingStability(self) and not CheckShieldingDown(self))
				
				if DragShieldingOn and ShieldingOn then
					
					return false
				end
				
			end
		end )
		
		hook.Add( "CanPlayerSuicide", self, function( attachment, ply )
			if ( attachment == ply and attachment:IsPlayer() and attachment:GetNWBool("AHEE_EQUIPED") ) then 
				local FullDragBar = self.DragShielding / self.DragShieldingLimit
				local DragShieldingOn = (FullDragBar >= 0.1 and self.DragShieldingSetting)
				local ShieldingOn = (CheckShieldingStability(self) and not CheckShieldingDown(self))
				
				if DragShieldingOn and ShieldingOn then
					
					return false
				end
				
			end
		end )
		
		self.PhysicsCollideID = self:AddCallback( "PhysicsCollide", AHEE_DragCollide )
		
		hook.Add( "DoPlayerDeath", self, function( attachment, ply , attacker , dmginfo )
			
			if ( attachment == ply and attachment:IsPlayer() and attachment:GetNWBool("AHEE_EQUIPED") ) then 
				
				local GottenSelf = ply
				local GottenPos = ply:GetPos()
				local GottenAng = ply:EyeAngles()
				local GottenVelo = ply:GetVelocity() or Vector()
				local GottenHealth = ply.MedicalStats.CurHealth
				local GottenMaxHealth = 1000000
				local GottenWeapons = ply:GetWeapons()
				local ActiveWeapon = ply:GetActiveWeapon()
				local ActiveWeaponClass = IsValid(ActiveWeapon) and tostring(ActiveWeapon:GetClass()) or nil
				table.insert( GottenWeapons, ActiveWeapon )
				
				local GottenMedical = ply.MedicalStats
				
				ply.DeathTime = nil
				ply:StripWeapons()
				
				local FullDragBar = self.DragShielding / self.DragShieldingLimit
				local DragShieldingOn = (FullDragBar >= 0.1 and self.DragShieldingSetting)
				local ShieldingOn = (CheckShieldingStability(self) and not CheckShieldingDown(self))
				
				if DragShieldingOn or ShieldingOn then
					
					timer.Simple( 0 , function()
						ply.NetMass = nil
						ply.spawn( ply , true )
						ply:StripWeapons()
						ply:SetMaxHealth( GottenHealth )
						ply:SetHealth( GottenHealth )
						ply:SetParent()
						ply:SetPos( GottenPos )
						ply:SetEyeAngles( GottenAng )
						ply:SetVelocity( GottenVelo )
						ply:SetSuppressPickupNotices( true )
						
						for Key,Value in pairs(GottenWeapons) do
							if IsValid(Value) then
								ply:Give( Value:GetClass() )
							end
						end
						
						if not IsValid(ActiveWeapon) and ActiveWeaponClass != nil then
							ply:Give( ActiveWeaponClass )
							ply:SelectWeapon( ActiveWeaponClass )
						end
						
						ply:SetSuppressPickupNotices( false )
					end)
					
					ply.MedicalStats = GottenMedical
					ply = GottenSelf
					
					local Weakness = math.Clamp( ply:GetMaxHealth() / ply:Health() , 1 , 10 )
					local DMGed = dmginfo:GetDamage() * Weakness
					BodyPart_DoDamage( ply , BodyGroupHit , DMGed )
					
					net.Start( "BodyPart_DoDamage_Client" )
					net.WriteString( tostring(BodyGroupHit) )
					net.WriteFloat( DMGed )
					net.Send( ply )
					
					ChangeShielding(self,0,true,Attacker)
					
					ply:TakeDamageInfo( dmginfo )
					
					return false
					
				else
					
					PelvareignEmplacements_Base:RestartSuit( ply )
					self:RemoveCallback( "PhysicsCollide", self.PhysicsCollideID )
					self.PhysicsCollideID = nil
					
					timer.Simple( 0 , function()
						ply.NetMass = nil
						ply.spawn( ply , true )
						ply:SetParent()
						ply:SetPos( GottenPos )
						ply:SetEyeAngles( GottenAng )
						ply:SetVelocity( GottenVelo )
						ply:EmitSound("player/pl_drown1.wav", 60, math.random(90,100),0.5)
						ply:GodEnable() -- Spawn Protection
					end)
					
					timer.Simple( 2.5 , function() -- Enough with your godz
						ply:GodDisable()
						ply:EmitSound("player/pl_drown1.wav", 90, math.random(45,50),1)
						ply:ViewPunch( Angle( math.random( -10 , -5 ) , 0 , math.random( -5 , 5 ) ) )
					end)
					
					ply:PrintMessage(HUD_PRINTTALK, "AHEE Suit unequipped. You feel Weird...")
					ply:EmitSound("physics/metal/weapon_impact_soft"..math.random( 1 , 3 )..".wav", 90, math.random( 90 , 110 ) , 0.9 )
					ply:EmitSound("main/startupteleport.mp3", 90, 100,0.3)
					ply:EmitSound("main/tunnelingphysics_conjuctspeak"..math.random( 1 , 5 )..".mp3", 140, 100,1.0)
					
					return true
					
				end
				
			end
			
		end )
		
		
		
	end
	
	
net.Receive( "MalPlhasealSuit_Squeeze", function( len, ply )
	MalPlhasealSqueeze( net.ReadBool() , ply )
end)

net.Receive( "RadiationExposure", function()
	RadiationEstimate( net.ReadFloat() , ply )
end)

net.Receive( "AHEE_Menu_Client", function() AHEE_Menu_Client() end )
hook.Add("PlayerPostThink", "AHEE_SUIT_THINK", AHEE_ATTACHED )



