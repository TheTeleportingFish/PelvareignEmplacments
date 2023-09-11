AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.PrintName = "A.H.E.E. Computational Device"
ENT.Author = "The Pelvareign Concept"
ENT.Information = "How to delete enemy - Use."
ENT.Spawnable = true
ENT.AdminSpawnable = true 
ENT.Category = "Pelvareign Armaments"

ENT.Model = "models/entities/ahee_suit.mdl"

function ENT:ObjectProperties_Init()
	self.ObjectProperties = {} -- This is our metatable. It will represent our "Class"
	self.ObjectProperties.__index = ObjectProperties
	
	local ObjectProperties = self.ObjectProperties
	
	function ObjectProperties:SetIntegrity( num )
		ObjectProperties.Integrity = num
	end
	
	function ObjectProperties:GetIntegrity()
		return ObjectProperties.Integrity
	end
	
	function ObjectProperties:SetHeat( temp )
		ObjectProperties.Heat = temp
	end
	
	function ObjectProperties:GetHeat()
		return ObjectProperties.Heat
	end
	
	function ObjectProperties:SetMass( mass )
		ObjectProperties.Mass = mass
	end
	
	function ObjectProperties:GetMass()
		return ObjectProperties.Mass
	end
	
	function ObjectProperties:SetDensity( density )
		ObjectProperties.Density = density
	end
	
	function ObjectProperties:GetDensity()
		return ObjectProperties.Density
	end
	
	function ObjectProperties:SetArmorLevel( level )
		ObjectProperties.ArmorLevel = level
	end

	function ObjectProperties:GetArmorLevel()
		return ObjectProperties.ArmorLevel
	end
	
end

AddCSLuaFile("includes/suit_base.lua")
AddCSLuaFile("includes/suit_physicality.lua")
include( "includes/suit_physicality.lua" )

local phys, ef

function TableEntityCheckAndRemove( Table )
	if table.Count( Table ) < 1 then return end
	for Index, v in pairs(Table) do
		if not v:IsValid() then 
			table.remove(Table,Index)
		end
	end
end

if CLIENT then
	function ENT:Draw()
		
		self:DrawModel()
		
	end
end

function ENT:Initialize()
	
	self:ObjectProperties_Init()
	
	self.ObjectProperties:SetIntegrity( 100.00 ) --%
	self.ObjectProperties:SetHeat( 16.00 ) --C
	self.ObjectProperties:SetMass( 201.75 ) --Kg
	self.ObjectProperties:SetDensity( 0.0168 ) --Kg/Cm3
	self.ObjectProperties:SetArmorLevel( 91 ) --Type G-A515
	
	if CLIENT then
		
		hook.Add( "PostDrawTranslucentRenderables", self, function( bDrawingDepth, bDrawingSkybox )
			if bDrawingSkybox then return end
			
		end)
	else
	
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
		phys:SetMass( 201.75 )
		phys:SetDragCoefficient( 1e-12 )
	end
	
	spd = physenv.GetPerformanceSettings()
    spd.MaxVelocity = MaxSpeed
    physenv.SetPerformanceSettings(spd)
	
	self:GetPhysicsObject():SetBuoyancyRatio(0)
	self.Entity:SetUseType(SIMPLE_USE)
	end
	
end

local Ctx, Toggle = 0, false

function ENT:Use(activator, caller)
	
	if activator:IsPlayer() then
		if not activator:GetNWBool("AHEE_EQUIPED") then
			
			--activator:GetActiveWeapon():SendWeaponAnim( ACT_VM_DRAW )
			activator:PrintMessage(HUD_PRINTTALK, "AHEE Suit equipped. You feel different...")
			activator:EmitSound("items/ammopickup.wav", 90, 40,0.9)
			activator:EmitSound("main/startupteleport.mp3", 80, 100,0.2)
			activator:EmitSound("main/airshockwave.wav", 140, 100,0.9)
			ParticleEffect( "SmokeShockFar", activator:WorldSpaceCenter() , Angle() )
			
			self:Remove()
			
			Recieve_Suit_Server( activator )
			
		else 
			activator:PrintMessage(HUD_PRINTTALK, "You have the AHEE Suit on.")
			return
		end
	end
	
end

function ENT:FireActivation(activator,bool)
end

local vel, velLen, CT, CTd

function ENT:PhysicsCollide(data, physobj)
	vel = physobj:GetVelocity()
	velLen = vel:Length()
	
		local phyed = self:GetPhysicsObject()
		
		if velLen > 100 then
			phyed:SetVelocity( phyed:GetVelocity() + (-data.HitNormal * phyed:GetVelocity():Length()/2) )
		CT = CurTime()
		
		if not self.NextImpact then self.NextImpact = CT + 0.01 end
		if CT > self.NextImpact then
			
			if velLen < 500 then
				
				self:EmitSound("physics/metal/metal_sheet_impact_hard"..math.random(6,8)..".wav", 75, math.random(60,66))
				self:EmitSound("ambient/machines/keyboard7_clicks_enter.wav", 80, math.random(130,140))
			else
				self:EmitSound("physics/metal/metal_box_impact_hard"..math.random(1,3)..".wav", 90, math.random(60,65))
				
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

function ENT:PhysicsUpdate(phys)

	local angles = phys:GetAngles()
	local velocity = phys:GetVelocity()

	if velocity:Length() > (343 * 52.4934) then
		phys:SetAngles( self:AlignAngles( self:GetAngles():Up():Angle() , velocity:Angle() ) )
		phys:SetVelocity( velocity )
	end
	
end


hook.Add( "ServerDmgTarget", "ServerTargetHook", DamageTarget )

function ENT:Think()
	local phyed = self:GetPhysicsObject()
	
	self:NextThink( CurTime() + 0.01 )
    return true
end
