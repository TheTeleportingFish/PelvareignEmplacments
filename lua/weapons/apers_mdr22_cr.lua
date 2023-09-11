AddCSLuaFile()

game.AddAmmoType( {
	name = "8mm_MDR_22",
	dmgtype = DMG_BULLET,
	tracer = TRACER_LINE,
	plydmg = 0,
	npcdmg = 0,
	force = 12000,
	minsplash = 10,
	maxsplash = 500
} )

if CLIENT then
language.Add("8mm_mdr_22_ammo", "8mm MDR Munitions")
end

SWEP.Base = "weapon_base"
SWEP.PrintName			= "APers MDR-22" -- This will be shown in the spawn menu, and in the weapon selection menu
SWEP.Author			= "Mark Adreon" -- These two options will be shown when you have the weapon highlighted in the weapon selection menu
SWEP.Instructions		= "Left mouse to fire a chair!"
SWEP.Spawnable	= true
SWEP.AdminOnly	= true
SWEP.Category	= "Pelvareign Armaments"
SWEP.UseHands		= true

SWEP.Charge = {Current = 130192000000 , Max = 130192000000}

SWEP.RoundTypes = 
{
	Regular = { Type = "8mm_palco_round" , Speed = 300 },
	APAFHP = { Type = "cw_tiwrigidround" , Speed = 700 },
	Frag = { Type = "cw_tiwround_frag13" , Speed = 300 },
	FragHP = { Type = "cw_tiwround_frag13" , Speed = 600 },
}

SWEP.Primary.ClipSize		= 144
SWEP.Primary.DefaultClip	= 288
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo		= "8mm_MDR_22"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo		= "none"

SWEP.ShotsPerFire = 3

SWEP.Weight			= 5
SWEP.AutoSwitchTo		= false
SWEP.AutoSwitchFrom		= false

SWEP.Aiming	= false

SWEP.Slot			= 3
SWEP.SlotPos			= 2
SWEP.DrawAmmo			= true
SWEP.DrawCrosshair		= true

SWEP.ViewModel			= "models/weapons/v_smg_p90.mdl"
SWEP.WorldModel			= "models/weapons/w_smg_p90.mdl"
SWEP.ViewModelFlip	= true

SWEP.ShootSound = Sound( "weapons/13mmtiw/13plentshotfragment.wav" )

list.Add( "NPCUsableWeapons", { class = "apers_mdr22_cr", title = "APer's MDR-22" } )

function SWEP:Initialize()
	local owner = self:GetOwner()
	
	self.AmmunitionType = self.RoundTypes.Regular
	
	if owner:IsPlayer() then
		self.ShotsPerFire = 3
	else
		self.ShotsPerFire = 3
	end
	
	
	
end

function SWEP:PrimaryAttack()
	local owner = self:GetOwner()
	local RndTable = self.AmmunitionType
	local NetMass = owner.NetMass and owner.NetMass or 60
	
	if self.Charge.Current <= 0 then
		local Sound = Sound( "main/epdd_system_failuretoexinguish_"..math.random(2,4)..".wav" )
		self:SetNextPrimaryFire( CurTime() + 0.20 )
		self:EmitSound( Sound, 75, 180, 1, CHAN_AUTO )
	return end
	
	if ( self.Weapon:Clip1() <= 0 ) then
	
		self:EmitSound( "Weapon_Pistol.Empty" )
		self:SetNextPrimaryFire( CurTime() + 0.5 )
		self:Reload()
		
	else
		
		self:SetNextPrimaryFire( CurTime() + 0.25 )	
		owner:MuzzleFlash() 
		
		FireProjectile( self , RndTable.Type , self.ShotsPerFire , RndTable.Speed )
		
		owner:SetVelocity( -owner:GetAimVector() * 1e5 / NetMass )
		
		if ( owner:IsValid() ) and SERVER then
			if (1e5 / NetMass) > 300 then
				owner:DropWeapon()
			end
		end
		
		if owner:IsPlayer() then
			local SoldierAngleKick = owner:LocalEyeAngles() + (Angle( math.random(-3,0) , math.random(-1,1) , 0 ) * 1e2 / NetMass)
			
			owner:SetViewPunchAngles( owner:GetViewPunchAngles() + (Angle( math.random(-2,0) , 0 , 0 ) * 6e2 / NetMass) )
			owner:SetEyeAngles( SoldierAngleKick )
		end
		
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

function SpawnRound( self , Rnd , Amount , Spd , Ang )
	local owner = self:GetOwner()
	if ( owner:IsPlayer() ) then
		owner:LagCompensation( true )
	end
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
	if ( owner:IsLagCompensated() ) then
		owner:LagCompensation( false )
	end
end

function FireProjectile( self , Round , Amount , Speed )
	local owner = self:GetOwner()
	local Amount = Amount or 1
	if ( not owner:IsValid() ) then return end
	
	self.Charge.Current = math.Clamp( self.Charge.Current - math.random( 9.12e+6 , 1.99e+7 ) , 0 , self.Charge.Max )
	
	local Sound = Sound( "high_caliber_cbm_weaponry/medial_high_caliber_fire_"..math.random(1,4)..".mp3" )
	self:EmitSound( Sound, 75, 120, 1, CHAN_AUTO )
	
	self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	
	if Amount > 0 then
		if ( CLIENT ) then return end
		SpawnRound( self , Round , Amount , Speed , 0.5 )
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

