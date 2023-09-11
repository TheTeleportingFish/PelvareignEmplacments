AddCSLuaFile()

include( "includes/modules/suit_functions.lua" )

ENT.Base 			= "base_nextbot"
ENT.Spawnable		= true
ENT.AdminSpawnable		= true

function ENT:SetupDataTables()
	self:NetworkVar( "Entity", 0, "Pelvareign_Active_Weapon" )
	
end

if SERVER then 
	
	util.AddNetworkString( "pelvareign_nextbot_active_weapon" )
	
end

local Pelvareign_PersonalityTypes = {
	[1] = { 
		Type = "Aggressive", --PersonalityName
		HoldDistance = 25, --Meters
		WeaponUsageMult = 5, --Multiplier
		DissuadeRequirement = 250 --Percent
	},
	[2] = { 
		Type = "Normal", --PersonalityName
		HoldDistance = 100, --Meters
		WeaponUsageMult = 1, --Multiplier
		DissuadeRequirement = 80 --Percent
	},
	[3] = { 
		Type = "Light", --PersonalityName
		HoldDistance = 230, --Meters
		WeaponUsageMult = 0.2, --Multiplier
		DissuadeRequirement = 30 --Percent
	}

}

local Equippable_Weapons = {
	--[1] = "10_5mm_kmd",
	[1] = "13mm_tiw"
	--[3] = "apers_mdr22_cr"
}

function ENT:Initialize()

	self:SetModel( "models/player/combine_super_soldier.mdl" )
	self.LoseTargetDist	= 320000	-- How far the enemy has to be before we lose them
	self.SearchRadius 	= 35000	-- How far to search for enemies
	
	self:SetHealth( 1000000 )
	self.NetMass = 2250.5
	
	self.Threats = {}
	self.OfInterest = {}
	self.AmmunitionForWeapons = {}
	
	self.LocalTeam = {}
	
	if CLIENT then
		 language.Add( "pelvareign_nextbot", "Pelvareign" )
	elseif SERVER then
		self.CurrentState = "Active"
		self.Personality = Pelvareign_PersonalityTypes[ math.random(1,#Pelvareign_PersonalityTypes) ]
		self:SetMaxHealth( 1000000 )
		self:StartActivity( ACT_HL2MP_IDLE )
		
		
		self.loco:SetStepHeight( 30 )
		print(self.Personality.Type)
		
		--self:SetAmmo( 500, self:GetActiveWeapon():GetPrimaryAmmoType() )
	end
	
	self:SetActiveWeapon( Equippable_Weapons[ math.random(1,#Equippable_Weapons) ] )
	
	self.MovingToPosition = false
	
end

function ENT:Change_Weapon_Battery()
	local Weapon = self:GetActiveWeapon()
	if not self.Occupied and Weapon["Charge"] then
		self:EmitSound("main/interact_foley_long_1.wav", 90, math.random(115,120), 0.5 )
		self:EmitSound("physics/metal/metal_sheet_impact_bullet2.wav", 90, math.random(140,150))
		
		self.Occupied = true
		
		timer.Simple( 0.35, function() if IsValid(self) then
				local Weapon = self:GetActiveWeapon()
				if IsValid(Weapon) then
					Weapon.Charge.Current = Weapon.Charge.Max
				end
				
				self:EmitSound("main/lid_open_"..math.random(1,3)..".wav", 95, math.random(98,105), 0.9 )
				
				self.Occupied = false
				
			end
		end)
	end
	
end

function ENT:Animate()
	
	local VeloLength = self.loco:GetVelocity():Length()
	local ActiveWeapon = self:GetActiveWeapon()
	
	if math.abs(VeloLength) > 600 then
		WantedActivity = ActiveWeapon and ACT_HL2MP_RUN_SMG1 or ACT_HL2MP_RUN
		
	elseif math.abs(VeloLength) > 5 and math.abs(VeloLength) < 600 then
		WantedActivity = ActiveWeapon and ACT_HL2MP_WALK_SMG1 or ACT_HL2MP_WALK
		
	elseif math.abs(VeloLength) < 5 then
		WantedActivity = ActiveWeapon and ACT_HL2MP_IDLE_SMG1 or ACT_HL2MP_IDLE
		
	end
	
	if self:GetActivity() != WantedActivity then 
		self:StartActivity( WantedActivity )
	end
	
end

function ENT:SetActiveWeapon( weapon )
	if not self then return end
	if type(weapon) != "string" then return end
	
	if SERVER then
		local weaponset = ents.Create( weapon )
		weaponset:SetPos( self:WorldSpaceCenter() )
		weaponset:SetClip1( weaponset:GetMaxClip1() )
		weaponset:SetOwner( self )
		weaponset:SetParent( self )
		weaponset:Initialize()
		
		self:SetPelvareign_Active_Weapon(weaponset)
	else
		local ClientWeapon = weapons.Get( weapon )
		local WorldModel = ClientsideModel(ClientWeapon.WorldModel)
		WorldModel:SetOwner( self )
		WorldModel:SetParent( self )
		WorldModel:Spawn()
		
		self:SetPelvareign_Active_Weapon(WorldModel)
		
	end
	
	
	
end

function ENT:GetActiveWeapon()
	local Weapon = self:GetPelvareign_Active_Weapon()
	return Weapon
end

function ENT:Draw()
	self:DrawModel()
	self:Render_Weapon_WorldModel()
	
end

if CLIENT then
	function ENT:Render_Weapon_WorldModel()
		local ActiveWeapon = self:GetPelvareign_Active_Weapon()
		
		if not IsValid(ActiveWeapon) then return end
		
		-- Settings...
		ActiveWeapon:SetSkin(1)
		ActiveWeapon:SetNoDraw(true)
		
		if ActiveWeapon then
			local _Owner = ActiveWeapon:GetOwner()
			
			if (IsValid(_Owner)) then
				-- Specify a good position
				local offsetVec = Vector(10,0,0)
				local offsetAng = Angle(0, 0, 180)
				
				local boneid = _Owner:LookupBone("ValveBiped.Bip01_R_Hand") -- Right Hand
				if !boneid then return end
				
				local matrix = _Owner:GetBoneMatrix(boneid)
				if !matrix then return end
				
				local newPos, newAng = LocalToWorld(offsetVec, offsetAng, matrix:GetTranslation(), matrix:GetAngles())
				
				ActiveWeapon:SetPos(newPos)
				ActiveWeapon:SetAngles(newAng)
				
				ActiveWeapon:SetupBones()
			else
				ActiveWeapon:SetPos(self:GetPos())
				ActiveWeapon:SetAngles(self:GetAngles())
			end
			
			ActiveWeapon:DrawModel()
		end
		
	end
end

net.Receive( "Weapon_Change_RoundType", function( len, ply )
	local ply = ply or LocalPlayer()
	local Str = net.ReadString()
	
	ply:EmitSound("main/interact_foley_short_"..math.random(1,3)..".wav", 90, math.random(115,120), 0.8 )
	
	local ActiveWeapon = ply:GetActiveWeapon()
	local Rounds = ActiveWeapon["RoundTypes"]
	local RoundTypes = table.GetKeys(Rounds)
	local CurrentAmmoType = ActiveWeapon["AmmunitionType"]
	
	if IsValid(ActiveWeapon) then
		if Rounds and type(Rounds) == "table" then
			ActiveWeapon.AmmunitionType = Rounds[Str]
		end
	end
	
end)

function ENT:AddThreat(ent)
	local ThreatTable = self.Threats
	for key, value in pairs( ThreatTable ) do
		if value == ent then
			
			return --already threat
		end
	end
	
	if ent:GetNWBool("AHEE_EQUIPED") then 
	
		return  --A9'er
	end
	--no such threat found, time to add
	self:EmitSound( "ahee_suit/taiko_target_outer.wav", 80, 100, 1, CHAN_AUTO ) 
	table.insert( ThreatTable , ent )
end

function ENT:IsThreat(ent)
	local ThreatTable = self.Threats
	if ThreatTable == nil then return end
	
	for key, value in pairs( ThreatTable ) do
		if value == ent then
			
			return true
		end
	end
	
	--not a threat
	return false
end

function ENT:SetEnemy( ent )
	self.Enemy = ent
end
function ENT:GetEnemy()
	return self.Enemy
end

function ENT:SetAimVector( Normal )
	self.AimVector = Normal
end
function ENT:GetAimVector()
	local AimVector = self.AimVector or Vector()
	return AimVector
end
function ENT:GetShootPos()
	return self:EyePos()
end

function ENT:OnRemove()
	
	local Weapon_Remove = self:GetPelvareign_Active_Weapon()
	if not IsValid( Weapon_Remove ) then return end
	Weapon_Remove:Remove()
	
end

function ENT:Melee_Punch()
	
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
			
			if SERVER then
				local Door = ents.Create( "prop_physics" )
				if IsValid(Door) and IsValid(Object) then
					Door:SetModel( Object:GetModel() )
					Door:SetPos( Object:GetPos() )
					Door:SetAngles( Object:GetAngles() )
					Door:SetSkin( Object:GetSkin() or 0 )
					
					Object:Remove()
					Door:Spawn()
					
					local Doorphys = Door:GetPhysicsObject()
					local PhysEnv = physenv.GetPerformanceSettings()
					if IsValid(Door) and IsValid(Doorphys) then 
						Doorphys:SetVelocity( self:EyeAngles():Forward() * Doorphys:GetMass() ^2  )
					end
				end
				
			end
		end
		if SERVER then constraint.RemoveAll( Object ) end
	end
	
	if IsValid(phys) then 
		phys:ApplyForceOffset( self:GetVelocity() + (self:EyeAngles():Forward() * PushMult) , AbleToInteract.HitPos)
		timer.Simple( 0.05 , function() if IsValid(Object) and phys:GetVelocity():Length() < 5 then 
			ParticleEffect( "FragExplose", HitPoint , Angle() ) 
			sound.Play( "main/tanks_explosion_0"..math.random(1,3)..".wav", HitPoint , 100, math.random(68,92), 1 )
			Object:Remove() 
		end end)
	end
	
	if true then
	
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
		
		ClientExplosionSound( self, 300 , "main/nucleation.wav" , 175 , 0.03 )
		
		sound.Play( "main/bomb_explosion_"..math.random(1,3)..".wav", HitPoint , 130, math.random(23,25), 1 )
		sound.Play( "main/airshock.wav", HitPoint , 120, math.random(168,170), 0.3 )
		ParticleEffect( "Flashed", HitPoint , Angle() )
		ParticleEffect( "AMMOCOOKFIREBALL", HitPoint , self:EyeAngles() )
		ParticleEffect( "APFSDSSMALLEMBERS", HitPoint , self:EyeAngles() )
		
		util.ScreenShake( AbleToInteract.HitPos, (InteractFraction/0.5)*12, 2222, 0.9, (InteractFraction/0.5)*4000 )
		self:SetVelocity( -Velo/3 )
	end
	
	self:AddGestureSequence( ACT_MELEE_ATTACK2, true )
	
end

local function CBMArmorHit_Shared( Owner , Vector , Damage , PressureBit )
	local effectdata = EffectData()
	effectdata:SetOrigin( Vector )
	effectdata:SetNormal( AngleRand():Forward() )
	effectdata:SetMagnitude( Damage )
	effectdata:SetRadius( PressureBit )
	util.Effect( "centralbasematerial_spark", effectdata, true, true)
	
end

function ENT:DamageFunction( dmginfo )
	local BulletDamage = dmginfo:IsDamageType( DMG_BULLET ) or dmginfo:IsDamageType( DMG_SNIPER ) or dmginfo:IsDamageType( DMG_BUCKSHOT ) or dmginfo:IsDamageType( DMG_PLASMA ) 
	local NonsenseDamage = dmginfo:IsDamageType( DMG_RADIATION ) or dmginfo:IsDamageType( DMG_DROWN ) or dmginfo:IsDamageType( DMG_NERVEGAS ) or dmginfo:IsDamageType( DMG_BLAST ) or dmginfo:IsDamageType( DMG_BLAST_SURFACE )
	
	if true then 
		local BluntDMG = (BulletDamage and not NonsenseDamage) and 0 or 1
		local HitPoint = ( dmginfo:GetDamagePosition() )
		local HitMultitude = math.Clamp( ( (dmginfo:GetDamage()^0.95) / 100 ) , 0.01 , 5 )
		if not dmginfo:IsDamageType( DMG_BURN ) then
			CBMArmorHit_Shared( self , HitPoint , HitMultitude , BluntDMG )
		end
		
		if dmginfo:GetDamage() > (50) then
			local Weakness = math.Clamp( self:GetMaxHealth() / self:Health() , 1 , 10 )
			self:EmitSound("physics/body/body_medium_impact_soft"..math.random( 1 , 7 )..".wav", 75, math.random( 85 , 90 ) , 0.4 )
			dmginfo:ScaleDamage( math.Clamp( ((dmginfo:GetDamage()^0.95) / 1000) , 0 , 0.9 ) * Weakness )
		end
	end
	
end

function ENT:HaveEnemy()
	if not IsValid( self ) then return end
	
	if IsValid( self:GetEnemy() ) then
		if ( self:GetRangeTo(self:GetEnemy():GetPos()) > self.LoseTargetDist ) then
			self:EmitSound( "npc/combine_soldier/vo/affirmative.wav", 75, 95, 1, CHAN_AUTO ) 
			
			return self:FindEnemy()
		elseif ( self:GetEnemy():IsPlayer() and !self:GetEnemy():Alive() ) then
			self:EmitSound( "npc/combine_soldier/vo/affirmative.wav", 75, 95, 1, CHAN_AUTO ) 
			
			return self:FindEnemy()
		end	
		
		return true
	else
		
		return self:FindEnemy()
	end
	
end

function ENT:Send_Plr_Team_Transfer( Plr )
	AHEE_System_AddTo_PseudoTeam( Plr , self )
	
	net.Start("Suit_AddTo_PseudoTeam")
		net.WriteEntity( self )
	net.Send( Plr )
	
end

function ENT:FindEnemy()
	local _ents = ents.FindInSphere( self:GetPos(), self.SearchRadius )
	
	for k,v in ipairs( _ents ) do
		local Has_Health = (v:Health() and v:Health() > 1)
		if ( IsValid(v) and v!=self ) then
			if v != self:GetEnemy() and self:IsThreat( v ) then
				
				self:AddGestureSequence( ACT_SIGNAL_ADVANCE, true )
				self:EmitSound( "npc/combine_soldier/vo/affirmative2.wav", 70, 100, 1, CHAN_AUTO ) 
				self:SetEnemy(v)
				
				return true
			end
		end
	end	
	
	self:SetEnemy(nil)
	return false
end

function ENT:CheckFriendly( Entity )
	for k,v in ipairs( self.LocalTeam ) do
		if ( v!=self and Entity!=self ) then
			if v == Entity then
			
			return true
			end
		end
	end
	
	return false
end

function ENT:FindFriendly()
	local _ents = ents.FindInSphere( self:GetPos(), self.SearchRadius )
	
	for k,v in ipairs( _ents ) do
		if (v:Health() and v:Health() > 1) and v!=self then
			if not self:CheckFriendly( v ) then
				if ( v:GetClass() == self:GetClass() or v:GetNWBool("AHEE_EQUIPED") ) then
					
					
					if SERVER and v:IsPlayer() then self:Send_Plr_Team_Transfer( v ) end
					
					self:AddGestureSequence( ACT_SIGNAL_ADVANCE, true )
					self:EmitSound( "npc/combine_soldier/vo/alert1.wav", 90, 100, 1, CHAN_AUTO ) 
					
					table.insert( self.LocalTeam, v )
					return true
				end
				
			end
		end
		
	end	
	
	return false
end

function ENT:Stagger( Mult )
	if self.Staggered then return end
	self.Staggered = true
	
	local Mult = Mult and math.Clamp( Mult , 0.1 , 3 ) or 0.5
	local StaggerTime = (1 * Mult)
	
	self:EmitSound( "npc/combine_soldier/pain"..math.random(1,3)..".wav", 80, math.random(90,120), 1, CHAN_AUTO ) 
	local GestureID, GestureDur = self:LookupSequence( "ACT_HL2MP_IDLE_CROUCH" )
	self:AddGestureSequence( GestureID )
	
	timer.Simple( StaggerTime , function()
		self.Staggered = false
		return
	end)
	
end

function ENT:OnInjured( dmginfo )
	local FlinchList = { "ACT_FLINCH", "ACT_FLINCH_BACK", "ACT_FLINCH_SHOULDER_LEFT", "ACT_FLINCH_SHOULDER_RIGHT" }
	
	if ( not self.m_bApplyingDamage ) then
		self.m_bApplyingDamage = true
		
		local Inflictor = dmginfo:GetAttacker()
		if Inflictor:IsWorld() or Inflictor:Health() <= 0 then 
			Inflictor = dmginfo:GetInflictor() 
		elseif Inflictor:IsWorld() or Inflictor:Health() <= 0 then 
			Inflictor = dmginfo:GetInflictor():GetOwner()
		end
		
		if dmginfo:GetDamage() > 1000 or self:Health() < 150000 then
		
			self:DamageFunction( dmginfo )
			
			local Inflictor_From_Team = Inflictor and self.LocalTeam[table.KeyFromValue( self.LocalTeam, Inflictor )] or nil
			if not IsValid(Inflictor_From_Team) then
				self:SetEnemy( Inflictor )
			end
			
			local GestureID, GestureDur = self:LookupSequence( FlinchList[math.random(1,#FlinchList)] )
			self:AddGestureSequence( GestureID )
			self:EmitSound( "npc/combine_soldier/pain"..math.random(1,3)..".wav", 80, math.random(90,120), 1, CHAN_AUTO ) 
			self.loco:SetVelocity( self.loco:GetVelocity() * 0.9 )
		
		elseif dmginfo:GetDamage() > 5 then
			local Inflictor_From_Team = Inflictor and self.LocalTeam[table.KeyFromValue( self.LocalTeam, Inflictor )] or nil
			
			if not IsValid(Inflictor_From_Team) then
				self:SetEnemy( Inflictor )
				self:AddThreat( Inflictor )
				
				for key, Ent in pairs( self.LocalTeam ) do
					if IsValid(Ent) then
						if ( Ent:GetClass() == self:GetClass() ) then
							
							self:EmitSound( "npc/metropolice/vo/chuckle.wav", 90, 100, 1, CHAN_AUTO ) 
							
							Ent:SetEnemy( Inflictor )
							Ent:AddThreat( Inflictor )
						end
					end
				end
				
			end
			
			self:Stagger( 5000/dmginfo:GetDamage() )
			
			local GestureID, GestureDur = self:LookupSequence( FlinchList[math.random(1,#FlinchList)] )
			self:AddGestureSequence( GestureID, true )
			self:EmitSound( "npc/combine_soldier/die"..math.random(1,3)..".wav", 90, math.random(90,120), 1, CHAN_AUTO ) 
			self.loco:SetVelocity( self.loco:GetVelocity() * 0.5 )
			
		end
		
		self:TakeDamageInfo( dmginfo )
		self.m_bApplyingDamage = false
	end
	
end

function ENT:HeadLook( Position )
	local model = self:GetModel()
	if IsValid(self) then
		local headBone = self:LookupBone( "ValveBiped.Bip01_Head1" )
		local matrix = self:GetBoneMatrix(headBone)
		local headPos = matrix:GetTranslation()
		local headAng = matrix:GetAngles()
		
		local Angles = self:GetAngles()
		local AimVector = headAng:Forward()
		local PointAng = (headPos - Position):Angle()
		
		local AngleBetweenYaw = math.Clamp( Angles.yaw - PointAng.yaw , -60 , 60 )
		local AngleBetweenPitch = math.Clamp( Angles.pitch - PointAng.pitch , -45 , 80 )
		self:SetPoseParameter( "head_pitch", AngleBetweenPitch )
		self:SetPoseParameter( "head_yaw", AngleBetweenYaw )
	end
end

function ENT:CommitViolence( Ent ) -- The Answer is most likely yes, if not... Then we will soon!
	local Current_Weapon = self:GetPelvareign_Active_Weapon()
	local Pos =  Ent:WorldSpaceCenter() or Ent:GetPos()
	local Distance = self:GetPos():Distance(Pos)
	
	local CalcPos = Ent:WorldSpaceCenter() + (Ent:GetVelocity():GetNormalized() * (Ent:GetVelocity():Length() ^ 1))
	local CalcDistance = CalcPos:Distance(Pos)
	self:SetAimVector( self:GetAimVector() - ((self:GetAimVector()-(CalcPos-self:WorldSpaceCenter()):GetNormalized())*1.05) )
	
	if IsValid(Current_Weapon) then
		local Weapon = self:GetPelvareign_Active_Weapon()
		local tr = util.TraceLine( {
			start = self:EyePos(),
			endpos = self:EyePos() + self:GetAimVector() * Distance,
			filter = self
		} )
		
		local HoldType = Weapon:GetHoldType()
		self:AddGestureSequence( ACT_VM_PRIMARYATTACK, true )
		self.loco:FaceTowards( Pos )
		
		if Distance < (950 * 52.4934) then
			if Weapon:Clip1() <= 0 then 
				Weapon:Reload() 
				Weapon:SetClip1( Weapon:GetMaxClip1() )
			elseif Weapon["Charge"].Current <= 0 then
				self:Change_Weapon_Battery()
			end
			local AimVector = self:GetAimVector()
			local PointVector = (Ent:WorldSpaceCenter() - self:WorldSpaceCenter()):Angle():Forward()
		
			local AngleBetween = math.deg( math.acos( AimVector:Dot(PointVector) / (AimVector:Length() * PointVector:Length()) ) )
			if (tr.HitPos:Distance(CalcPos)/CalcDistance) > 0.1 and math.abs(AngleBetween) < 15 then
				Weapon:PrimaryAttack()
				coroutine.wait( 0.25 )
				self:SetNWEntity( "TargetSelected", Ent )
			end
		end
		
		if Distance < 200 then
			self:Melee_Punch()
		end
	end
	
end

function ENT:CommitAction()
	local Friendly_To_Go = self.LocalTeam[1]
	local Enemy = self:GetEnemy()
	local RandPosition = self:GetPos() + ( VectorRand(175,600) * VectorRand() * Vector(1,1,0) )
	local Distance = self:GetPos():Distance(RandPosition)
	
	local options = {}
	
	if IsValid(self:GetEnemy()) then
		local Pos =  Enemy:GetPos() or RandPosition
		local Distance = self:GetPos():Distance(Pos)
		if self:IsThreat( Enemy ) then
			self:CommitViolence( Enemy )
			
			local Pos_Neg = (math.random(0,1) == 0) and 1 or -1
			Position = Pos + ( VectorRand(600,4000) * Pos_Neg * Vector(1,1,0) )
			options.Run = true
			options.range = 2500
			options.dist = 150
			self:GotoPosition( Position , options )
			
			return Position
			
		end
	elseif #self.LocalTeam > 0 then
		if IsValid(Friendly_To_Go) then
		local Pos =  Friendly_To_Go:GetPos()
		local Distance = self:GetPos():Distance(Pos)
		if (Distance > 200) then
			local Pos_Neg = (math.random(0,1) == 0) and 1 or -1
			Position = Pos + ( VectorRand(80,500) * Pos_Neg * Vector(1,1,0) )
			options.Run = true
			options.range = 500
			options.dist = 10
			self:GotoPosition( Position , options )
			
			return Position
		else
			local Pos_Neg = (math.random(0,1) == 0) and 1 or -1
			Position = Pos + ( VectorRand(100,200) * Pos_Neg * Vector(1,1,0) )
			options.Run = false
			options.range = 500
			options.dist = 10
			self:GotoPosition( Position , options )
			
			return Position
		end
		end
	else
		if (Distance > 200) then
			options.Run = false
			options.range = 150
			options.dist = 10
			self:GotoPosition( RandPosition , options )
			
			
			return RandPosition
		end
	end
	
	coroutine.yield()
end

function ENT:RunBehaviour()
	while ( true ) do
		
		self:Animate()
		
		if ( self:HaveEnemy() ) then
			local Enemy = self:GetEnemy()
			local Pos =  self:CommitAction()
			if type(Pos) == "Vector" then
				local Distance = self:GetPos():Distance(Pos)
				self:HeadLook( Pos )
			end
			
		else
			local Pos = self:CommitAction()
			if type(Pos) == "Vector" then
				local Distance = self:GetPos():Distance(Pos)
				self:HeadLook( Pos+VectorRand()*50 )
			end
			
		end
		
		self:FindEnemy()
		self:FindFriendly()
		
		coroutine.yield()
	end

end	

function ENT:GotoPosition( Position, options )

	local Distance = self:GetRangeTo(Position)
	local options = options or {}
	local path = Path( "Follow" )
	
	path:SetMinLookAheadDistance( options.range or 250 )
	path:SetGoalTolerance( options.dist or 145 )
	path:Compute( self, Position )		-- Compute the path towards the enemies position
	
	if ( !path:IsValid() ) then return "failed" end
	
	if ( path:IsValid() ) then
		if options.Run then
			self.loco:SetDesiredSpeed( 3000 )
			self.loco:SetAcceleration( 500 )
			self.loco:SetDeceleration( 12 )
		else
			self.loco:SetDesiredSpeed( 600 )
			self.loco:SetAcceleration( 200 )
			self.loco:SetDeceleration( 5 )
		end
		
		if ( path:GetAge() > 0.1 ) then
			path:Compute( self, Position )
		end
		path:Update( self )
		
		if ( options.draw ) then path:Draw() end
		
		if ( self.loco:IsStuck() ) then
			self:HandleStuck()
			return "stuck"
		end
		
	end
	
	return "ok"
end

list.Set( "NPC", "pelvareign_nextbot", {
	Name = "Pelvareign A9'er Bot",
	Class = "pelvareign_nextbot",
	Category = "Pelvareign Emplacements"
})
