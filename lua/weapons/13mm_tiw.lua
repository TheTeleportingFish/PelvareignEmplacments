AddCSLuaFile()

game.AddAmmoType( {
	name = "13mm_Copper_Flare",
	dmgtype = DMG_BULLET,
	tracer = TRACER_LINE,
	plydmg = 0,
	npcdmg = 0,
	force = 12000,
	minsplash = 10,
	maxsplash = 500
} )

if CLIENT then
language.Add("13mm_copper_flare_ammo", "13mm CF Munitions")
end

SWEP.Base = "weapon_base"
SWEP.PrintName			= "13mm TIW MMG" -- This will be shown in the spawn menu, and in the weapon selection menu
SWEP.Author			= "Mark Adreon" -- These two options will be shown when you have the weapon highlighted in the weapon selection menu
SWEP.Instructions		= "Left mouse to fire a chair!"
SWEP.Spawnable	= true
SWEP.AdminOnly	= true
SWEP.Category	= "Pelvareign Armaments"
SWEP.UseHands		= true

SWEP.Charge = { Current = 751250000000 , Max = 751250000000 }

SWEP.RoundTypes = 
{
	Regular = { Type = "cw_tiwround" , Speed = 800 },
	Test = { Type = "standard_cbm_round" , Speed = 600 },
	Rigid = { Type = "cw_tiwrigidround" , Speed = 400 },
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
SWEP.Primary.Ammo		= "13mm_Copper_Flare"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo		= "none"

SWEP.ShotsPerFire = 2

SWEP.Weight			= 5
SWEP.AutoSwitchTo		= false
SWEP.AutoSwitchFrom		= false

SWEP.Aiming	= false

SWEP.Slot			= 3
SWEP.SlotPos			= 2
SWEP.DrawAmmo			= true
SWEP.DrawCrosshair		= true

SWEP.ViewModel			= "models/weapons/c_smg1.mdl"
SWEP.WorldModel			= "models/weapons/w_smg1.mdl"

list.Add( "NPCUsableWeapons", { class = "13mm_tiw", title = "13mm TIW" } )

function SWEP:Initialize()
	local owner = self:GetOwner()
	
	self.AmmunitionType = self.RoundTypes.Frag13
	
	if owner:IsPlayer() then
		self.ShotsPerFire = 5
	else
		self.ShotsPerFire = 2
	end
	
	self:SetHoldType( "smg" )
	
end

function SWEP:PrimaryAttack()
	local owner = self:GetOwner()
	local RndTable = self.AmmunitionType
	local NetMass = owner.NetMass and owner.NetMass or 60
	
	if self.Charge.Current <= 0 then
		local Sound = Sound( "ahee_suit/alert_energy_notice.mp3" )
		self:SetNextPrimaryFire( CurTime() + 0.15 )
		self:EmitSound( Sound, 80, 190, 1, CHAN_AUTO )
	return end
	
	if ( self.Weapon:Clip1() <= 0 ) then
	
		self:EmitSound( "Weapon_Pistol.Empty" )
		self:SetNextPrimaryFire( CurTime() + 0.5 )
		self:Reload()
		
	else
		
		self:SetNextPrimaryFire( CurTime() + 0.1 )	
		owner:MuzzleFlash() 
		
		self:FireProjectile( RndTable.Type , self.ShotsPerFire , RndTable.Speed )
		
		owner:SetVelocity( -owner:GetAimVector() * 1e5 / NetMass )
		
		if ( owner:IsValid() ) and SERVER then
			if (1e5 / NetMass) > 300 then
				owner:DropWeapon()
			end
		end
		
		if owner:IsPlayer() then
			local SoldierAngleKick = owner:LocalEyeAngles() + (Angle( math.random(-1,0) , math.random(-2,2) , 0 ) * 3e2 / NetMass)
			
			owner:SetViewPunchAngles( owner:GetViewPunchAngles() + (Angle( math.random(-1,0) , math.random(-1,1) , 0 ) * 1e3 / NetMass) )
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

function SWEP:SpawnRound( Rnd , Amount , Spd , Ang )
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

function SWEP:FireProjectile( Round , Amount , Speed )
	local owner = self:GetOwner()
	local Amount = Amount or 1
	if ( not owner:IsValid() ) then return end
	
	self.Charge.Current = math.Clamp( self.Charge.Current - math.random( 2.76e8 , 2.15e9 ) , 0 , self.Charge.Max )
	
	local Sound = "cbm_weaponry/standard_kable_weaponry_"..math.random(1,4)..".mp3"
	self:EmitSound( Sound, 80, math.random(200,230), 0.8, CHAN_AUTO )
	self:EmitSound( "cbm_weaponry/25mm_kessaal_brikna_relaymechanism.mp3" , 70, math.random(220,230), 0.3, CHAN_AUTO )
	
	self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	
	if ( CLIENT ) then return end
	
	if Amount > 0 then
		self:SpawnRound( Round , Amount , Speed , 0.1 )
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
	
	return 15
end

