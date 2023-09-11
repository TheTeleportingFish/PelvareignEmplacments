AddCSLuaFile()

SWEP.Base = "weapon_base"
SWEP.PrintName			= "8mm Brdakladii" -- This will be shown in the spawn menu, and in the weapon selection menu
SWEP.Author			= "Mark Adreon" -- These two options will be shown when you have the weapon highlighted in the weapon selection menu
SWEP.Instructions		= "Left mouse to fire a chair!"
SWEP.Spawnable	= true
SWEP.AdminOnly	= true
SWEP.Category	= "Pelvareign Armaments"
SWEP.UseHands		= true

SWEP.Charge = 751250000000

SWEP.RoundTypes = 
{
	Regular = { Type = "cw_tiwround" , Speed = 800 },
	Rigid = { Type = "cw_tiwrigidround" , Speed = 1000 },
	Frag13 = { Type = "cw_tiwround_frag13" , Speed = 450 },
	Frag13HP = { Type = "cw_tiwround_frag13" , Speed = 400 },
	CoreaDosic = { Type = "cw_tiwround_coreadosic" , Speed = 600 },
	CL1 = { Type = "cw_tiwround_suppressant" , Speed = 200 },
	CL2 = { Type = "cw_tiwround_heavysuppressant" , Speed = 300 },
	CL3 = { Type = "cw_tiwround_extremesuppressant" , Speed = 400 }
}

SWEP.Primary.ClipSize		= 1046
SWEP.Primary.DefaultClip	= 1046
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo		= "13mm Copper Flare"

SWEP.ShotsPerFire = 1

SWEP.Weight			= 5
SWEP.AutoSwitchTo		= false
SWEP.AutoSwitchFrom		= false

SWEP.Aiming	= false

SWEP.Slot			= 3
SWEP.SlotPos			= 2
SWEP.DrawAmmo			= true
SWEP.DrawCrosshair		= true

SWEP.ViewModel			= "models/weapons/c_357.mdl"
SWEP.WorldModel			= "models/weapons/w_357.mdl"

SWEP.ShootSound = Sound( "weapons/13mmtiw/13plentshotfragment.wav" )

function SWEP:Initialize()
	local owner = self:GetOwner()
	
	self.AmmunitionType = self.RoundTypes.Regular
	
	if owner:IsPlayer() then
		self.ShotsPerFire = 5
	else
		self.ShotsPerFire = 1
	end
	
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetHoldType( "smg" )
	
	if ( SERVER ) then self:PhysicsInit( SOLID_VPHYSICS ) end
	
	self:PhysWake()
	
	local Physics = self:GetPhysicsObject()
	if IsValid(Physics) then Physics:SetMass( 60 ) end
	
end

function SWEP:PrimaryAttack()
	local owner = self:GetOwner()
	local RndTable = self.AmmunitionType
	
	if ( self.Weapon:Clip1() <= 0 ) then
	
		self:EmitSound( "Weapon_Pistol.Empty" )
		self:SetNextPrimaryFire( CurTime() + 0.5 )
		self:Reload()
		
	else
		
		owner:SetVelocity( -owner:GetAimVector() * 50 )
		
		self:SetNextPrimaryFire( CurTime() + 0.05 )	
		owner:MuzzleFlash() 
		
		self:FireProjectile( RndTable.Type , self.ShotsPerFire , RndTable.Speed )
		
	end
	
end

function SWEP:SecondaryAttack()
	
	self:SetNextSecondaryFire( CurTime() + 0.25 )	
	
	if self.Aiming then
		self.Aiming = false
	else
		self.Aiming = true
	end
	
end

function SWEP:Think()
	
	if self.Aiming then
		self:SetLocalPos( Vector( 0 , 0 , 0 ) )
	else
		self:SetLocalPos( Vector( 0 , 10 , 0 ) )
	end
	
	return true
end

function SWEP:DoAnimation( Type )
	local owner = self:GetOwner()
	
end

function SWEP:SpawnRound( Rnd , Amount , Spd , Ang )
	for i = 1 , math.Clamp( Amount , 0 , 200 ) do
		local owner = self:GetOwner()
		local Round = ents.Create( Rnd )
		if ( not Round:IsValid() ) then return end
		
		local aimvec = owner:GetAimVector()
		local pos = aimvec * 16 -- This creates a new vector object
		pos:Add( owner:GetShootPos() ) -- This translates the local aimvector to world coordinates
		
		Round:SetNWEntity( "Targeted" , owner:GetNWEntity( "TargetSelected" ) )
		
		Round:SetPos( pos )
		Round:SetAngles( aimvec:Angle() )
		Round:SetOwner( owner )
		Round:Spawn()
		
		local RoundPhys = Round:GetPhysicsObject()
		if ( not RoundPhys:IsValid() ) then Round:Remove() return end
		
		local MetersPerSecond = Spd * 52.4934
		local SpreadAng = Ang
		local RoundAng = Round:GetAngles()
		RoundAng:Add( AngleRand( -SpreadAng , SpreadAng ) )
		
		local VelocityVector = RoundAng:Forward() * MetersPerSecond
		RoundPhys:SetVelocityInstantaneous( VelocityVector )
		
		self:SetClip1( math.Clamp( self:Clip1() - 1 , 0 , self:GetMaxClip1() ) )
	end
end

function SWEP:FireProjectile( Round , Amount , Speed )
	local owner = self:GetOwner()
	local Amount = Amount or 1
	
	if ( not owner:IsValid() ) then return end
	
	self:EmitSound( self.ShootSound )
	self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	
	if ( CLIENT ) then return end
	
	if Amount > 0 then
		self:SpawnRound( Round , Amount , Speed , 1 )
	end
	
end

function SWEP:CanBePickedUpByNPCs()
	
	return true
end


function SWEP:ShouldDropOnDie()
	
	return false
end

function SWEP:GetNPCRestTimes()
	
	return 0.2, 0.8
end

function SWEP:GetNPCBurstSettings()
	
	return 1, 30, 0.0
end

function SWEP:GetNPCBulletSpread( proficiency )
	
	return 2
end

