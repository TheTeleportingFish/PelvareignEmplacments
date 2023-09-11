AddCSLuaFile()

ENT.Base = "base_entity"
ENT.Type = "anim"

ENT.PrintName		= "Pelvareign Character"
ENT.Author			= ""
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""

ENT.Spawnable = true

ENT.Mins = Vector( -16, -16, -16 )
ENT.Maxs = Vector(  16,  16,  16 )

function ENT:Initialize()
	self.PhysCollide = CreatePhysCollideBox( self.Mins, self.Maxs )
	self:SetCollisionBounds( self.Mins, self.Maxs )
	
	if SERVER then
		self:PhysicsInitBox( self.Mins, self.Maxs )
		self:SetSolid( SOLID_VPHYSICS )
		self:PhysWake()
		
	end
	
	if CLIENT then
		self:SetRenderBounds( self.Mins, self.Maxs )
		language.Add( "pelvareign_character", "Pelvareign Character" )
	end
	
	self:EnableCustomCollisions( true )
	self:DrawShadow( false )
end

-- Handles collisions against traces. This includes player movement.
function ENT:TestCollision( startpos, delta, isbox, extents )
	if not IsValid( self.PhysCollide ) then
		return
	end

-- TraceBox expects the trace to begin at the center of the box, but TestCollision is bad
	local max = extents
	local min = -extents
	max.z = max.z - min.z
	min.z = 0
	
	local hit, norm, frac = self.PhysCollide:TraceBox( self:GetPos(), self:GetAngles(), startpos, startpos + delta, min, max )
	
	if not hit then
		return
	end
	
	return { 
		HitPos = hit,
		Normal  = norm,
		Fraction = frac,
	}
end

list.Set( "SpawnableEntities", "pelvareign_character", {
	Name = "Pelvareign A9'er Bot",
	Class = "pelvareign_character",
	Category = "Pelvareign Emplacements"
})


function ENT:Animate()
end


function ENT:OnRemove()
end


function ENT:PhysicsCollide( data, physobj )
end


function ENT:PhysicsUpdate( physobj )
	
	if math.random(1,10) == 1 then
		local Bouncer = ents.Create("standard_cbm_round")
		
		Bouncer:SetPos( self:GetPos() + (VectorRand() * 15) )
		Bouncer:SetAngles( self:GetAngles() )
		Bouncer:SetOwner( owner )
		Bouncer:Spawn()
		
		local BouncerPhys = Bouncer:GetPhysicsObject()
		
		if IsValid(BouncerPhys) then
			BouncerPhys:SetVelocityInstantaneous( BouncerPhys:GetAngles():Forward() * math.Rand(45,45.5) * 52.4934 )
		end
	end
	
end

function ENT:SpawnFunction( ply, tr, ClassName )

	if ( !tr.Hit ) then return end

	local SpawnPos = tr.HitPos + tr.HitNormal * 16

	local ent = ents.Create( ClassName )
	ent:SetPos( SpawnPos )
	ent:Spawn()
	ent:Activate()

	return ent

end

if ( CLIENT ) then

	function ENT:Draw( flags )

		self:DrawModel( flags )
		render.DrawWireframeBox( self:GetPos(), self:GetAngles(), self.Mins, self.Maxs, Color( 255, 0, 0 ), true )

	end

	function ENT:DrawTranslucent( flags )

		-- This is here just to make it backwards compatible.
		-- You shouldn't really be drawing your model here unless it's translucent

		self:Draw( flags )

	end

end

if ( SERVER ) then

	function ENT:OnTakeDamage( dmginfo )

	--[[
		Msg( tostring(dmginfo) .. "\n" )
		Msg( "Inflictor:\t" .. tostring(dmginfo:GetInflictor()) .. "\n" )
		Msg( "Attacker:\t" .. tostring(dmginfo:GetAttacker()) .. "\n" )
		Msg( "Damage:\t" .. tostring(dmginfo:GetDamage()) .. "\n" )
		Msg( "Base Damage:\t" .. tostring(dmginfo:GetBaseDamage()) .. "\n" )
		Msg( "Force:\t" .. tostring(dmginfo:GetDamageForce()) .. "\n" )
		Msg( "Position:\t" .. tostring(dmginfo:GetDamagePosition()) .. "\n" )
		Msg( "Reported Pos:\t" .. tostring(dmginfo:GetReportedPosition()) .. "\n" )	-- ??
	--]]

	end


	function ENT:Use( activator, caller, type, value )
	end


	function ENT:StartTouch( entity )
	end


	function ENT:EndTouch( entity )
	end


	function ENT:Touch( entity )
	end

	--[[---------------------------------------------------------
	   Name: Simulate
	   Desc: Controls/simulates the physics on the entity.
		Officially the most complicated callback in the whole mod.
		 Returns 3 variables..
		 1. A SIM_ enum
		 2. A vector representing the linear acceleration/force
		 3. A vector represending the angular acceleration/force
		If you're doing nothing you can return SIM_NOTHING
		Note that you need to call ent:StartMotionController to tell the entity
			to start calling this function..
	-----------------------------------------------------------]]
	function ENT:PhysicsSimulate( phys, deltatime )
		return SIM_NOTHING
	end

end