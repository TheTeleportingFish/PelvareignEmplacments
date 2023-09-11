AddCSLuaFile()

game.AddAmmoType( {
	name = "10_5mm_KMD",
	dmgtype = DMG_BULLET,
	tracer = TRACER_LINE,
	plydmg = 0,
	npcdmg = 0,
	force = 12000,
	minsplash = 10,
	maxsplash = 500
} )

if CLIENT then
language.Add("10_5mm_kmd_ammo", "10.5mm Keedirak Munitions")
end

SWEP.Base = "weapon_base"
SWEP.PrintName			= "10.5mm Keedirak MD" -- This will be shown in the spawn menu, and in the weapon selection menu
SWEP.Author			= "Mark Adreon" -- These two options will be shown when you have the weapon highlighted in the weapon selection menu
SWEP.Instructions		= "Left mouse to fire a chair!"
SWEP.Spawnable	= true
SWEP.AdminOnly	= true
SWEP.Category	= "Pelvareign Armaments"
SWEP.UseHands		= false

SWEP.Charge = {Current = 600000 , Max = 600000}

SWEP.RoundTypes = 
{
	Regular = { Type = "cw_tiwbouncer_fragments" , Speed = 700 },
	APAFHP = { Type = "cw_tiwrigidround" , Speed = 700 },
	Frag = { Type = "cw_tiwround_frag13" , Speed = 300 },
	FragHP = { Type = "cw_tiwround_frag13" , Speed = 600 },
}

SWEP.Primary.ClipSize		= 20
SWEP.Primary.DefaultClip	= 90
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo		= "10_5mm_KMD"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo		= "none"

SWEP.ShotsPerFire = 1
SWEP.m_WeaponDeploySpeed = 1

SWEP.Weight	= 5
SWEP.ViewModelFOV	= 95
SWEP.AutoSwitchTo		= false
SWEP.AutoSwitchFrom		= false

SWEP.Aiming	= false

SWEP.Slot			= 2
SWEP.SlotPos			= 2
SWEP.DrawAmmo			= true
SWEP.DrawCrosshair		= true

SWEP.ViewModel			= "models/10_5mm_kmd.mdl"
SWEP.WorldModel			= "models/weapons/w_smg_p90.mdl"
SWEP.ViewModelFlip	= false

SWEP.ShootSound = Sound( "weapons/13mmtiw/13plentshotfragment.wav" )

list.Add( "NPCUsableWeapons", { class = "10_5mm_kmd", title = "10.5mm KMD" } )

function SWEP:Initialize()
	local owner = self:GetOwner()
	
	self.AmmunitionType = self.RoundTypes.Regular
	
	if owner:IsPlayer() then
		self.ShotsPerFire = 1
	else
		self.ShotsPerFire = 1
	end
	
	self:SendWeaponAnim( ACT_VM_IDLE )
	
end

function SWEP:PrimaryAttack()
	local owner = self:GetOwner()
	local RndTable = self.AmmunitionType
	local NetMass = owner.NetMass and owner.NetMass or 60
	
	if self.Charge.Current <= 0 then
		local Sound = Sound( "main/epdd_system_failuretoexinguish_"..math.random(2,4)..".wav" )
		self:SetNextPrimaryFire( CurTime() + 0.25 )
		self:EmitSound( Sound, 90, 120, 1, CHAN_AUTO )
	return end
	
	if ( self.Weapon:Clip1() <= 0 ) then
	
		self:EmitSound( "Weapon_Pistol.Empty" )
		self:SetNextPrimaryFire( CurTime() + 0.5 )
		self:Reload()
		
	else
		
		self:SetNextPrimaryFire( CurTime() + 0.05 )	
		owner:MuzzleFlash() 
		
		self:FireProjectile( self , RndTable.Type , self.ShotsPerFire , RndTable.Speed )
		
		owner:SetVelocity( -owner:GetAimVector() * 3e5 / NetMass )
		
		if ( owner:IsValid() ) and SERVER then
			if (3e5 / NetMass) > 300 then
				owner:DropWeapon()
			end
		end
		
		if owner:IsPlayer() then
			local SoldierAngleKick = owner:LocalEyeAngles() + (Angle( math.random(-1,0) , math.random(-2,2) , 0 ) * 3e3 / NetMass)
			
			owner:SetViewPunchAngles( owner:GetViewPunchAngles() + (Angle( math.random(-1,0) , math.random(-1,1) , 0 ) * 3e3 / NetMass) )
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
	local Owner = self:GetOwner()
	
	return true
end

function SWEP:CalcViewModelView(ViewModel, OldEyePos, OldEyeAng, EyePos, EyeAng)
	local Plr = LocalPlayer()
	local VectorED = Vector( 0 , 0 , 0 )
	
	local BoneID = ViewModel:LookupBone( "ValveBiped.Bip01_Head1" ) or 0
	local Bonematrix = ViewModel:GetBoneMatrix( BoneID )
	local pos = Bonematrix:GetTranslation()
	local ang = Bonematrix:GetAngles()
	
	local Angled = (Angle() - ang:Forward():Angle()) / 10
	
	if self.Aiming then
		VectorED = EyeAng:Right() * -5
	else
		VectorED = Vector( 0 , 0 , 0 )
	end
	
	return (EyePos + VectorED), EyeAng
	
end

function SWEP:DoAnimation( Type )
	local owner = self:GetOwner()
	
end

function SWEP:SpawnRound( self , Rnd , Amount , Spd , Ang )
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

function SWEP:FireProjectile( self , Round , Amount , Speed )
	local owner = self:GetOwner()
	local Amount = Amount or 1
	if ( not owner:IsValid() ) then return end
	
	local Energy = math.Rand( 212 , 3130 )
	self.Charge.Current = math.Clamp( self.Charge.Current - Energy , 0 , self.Charge.Max )
	
	local Sound = Sound( "cbm_weaponry/standard_mantli_weaponry_"..math.random(1,4)..".mp3" )
	self:EmitSound( Sound, 90, math.random(120,150), 1, CHAN_AUTO )
	
	self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	
	if ( CLIENT ) then return end
	
	if Amount > 0 then
		self:SpawnRound( self , Round , Amount , Speed , 0.5 )
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

