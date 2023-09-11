AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")




function ENT:Initialize()
	self:SetModel(self.Model) 
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	self.CanHurt = true
	local phys = self:GetPhysicsObject()

	if phys and phys:IsValid() then
		phys:Wake()
	end
	
	self.dt.ammoCharge = self.AmmoCapacity
	
	self.HP = self.HealthAmount
end

local dmg, wep, am, cl, ammo, ED, pos, mag, amountToGive, maxAmmo

function ENT:OnTakeDamage(dmginfo)
	if self.Exploded then
		return
	end
	
	self:GetPhysicsObject():AddVelocity(dmginfo:GetDamageForce() * 0.02)
	
	dmg = dmginfo:GetDamage()
	self.HP = self.HP - dmg
	
	if self.HP <= 0 then
		self.Exploded = true
		
		pos = self:GetPos()
		
		
		ParticleEffectAttach( "AMMOCOOKOFF", 4, self, 4)
		
		timer.Simple(0.1, function() self:Ignite( 6 , 200 ) self:EmitSound("CW_AMMOCOOKOFF") end)
		timer.Simple(1, function() self:Ignite( 6 , 600 ) self:EmitSound("CW_AMMOCOOKOFF") end)
		timer.Simple(1.1, function()  self:EmitSound("CW_AMMOCOOKOFF") end)
		timer.Simple(1.3, function() self:EmitSound("CW_AMMOCOOKOFF") end)
		timer.Simple(1.5, function()
		
			if SERVER then
			
			local angled
			
			if self:GetVelocity():Length() > 500 then
			angled = ((self:GetVelocity()):GetNormalized()):Angle()
			elseif (self:GetVelocity():Length() > 100) and (self:GetVelocity():Length() < 500) then
			angled = ((self:GetVelocity()*1000):GetNormalized()):Angle()
			else
			angled = Angle(-90,0,0)
			end
			
			self:Extinguish()
			self:EmitSound("CW_FragGrenade_Explode")
			self:EmitSound("CW_AMMOMETALEXPLODE")
			self:EmitSound("main/shell_explosion_1.wav", 150, math.random(75,120), 1, CHAN_STATIC )
			util.BlastDamage(self, self, pos + Vector(0, 0, 32), self.ExplodeRadius/3, self.ExplodeDamage)
			util.ScreenShake( pos, 10, 7, 2, 850 )
			
			
			ParticleEffect( "AMMOCOOKEXPLODE", self:GetPos() , angled )
			
			
			SafeRemoveEntity(self)
			
			end
			
			
			
			
		end)
		
				
	end
	
end

function ENT:Use(activator, caller)
	if self.CaliberSpecific then
		if activator:IsPlayer() and activator:Alive() then
			if not activator.AmmoGiveDelay or CurTime() > activator.AmmoGiveDelay then
				activator:GiveAmmo(self.ResupplyAmount, self.Caliber)
				
				activator.AmmoGiveDelay = CurTime() + self.ResupplyTime
				self.dt.ammoCharge = self.dt.ammoCharge - self.ResupplyAmount
			end
			
			if self.dt.ammoCharge <= 0 then
				self:Remove()
			end
		end
	else
		if activator:IsPlayer() and activator:Alive() then
			if not activator.AmmoGiveDelay or CurTime() > activator.AmmoGiveDelay then
				if self.dt.ammoCharge > 0 then
					wep = activator:GetActiveWeapon()
					
					if IsValid(wep) then
						if wep.CW20Weapon then
							ammo = activator:GetAmmoCount(wep.Primary.Ammo)
							
							if ammo < wep.Primary.ClipSize_Orig * self.ResupplyMultiplier then
								-- check the amount of ammo that should be handed to the player
								amountToGive = math.Clamp(wep.Primary.ClipSize_Orig, 0, wep.Primary.ClipSize_Orig * self.ResupplyMultiplier)
								
								-- if it's greater than 0, give it to the player
								if amountToGive > 0 then
									activator:SetAmmo(math.Clamp(ammo + amountToGive, 0, wep.Primary.ClipSize_Orig * self.ResupplyMultiplier), wep.Primary.Ammo)
									activator:EmitSound("items/ammo_pickup.wav", 60, 100)
									self.dt.ammoCharge = self.dt.ammoCharge - 1
								end
							end
						end
					end
				end
				
				activator.AmmoGiveDelay = CurTime() + self.ResupplyTime
				
				if self.dt.ammoCharge <= 0 then
					SafeRemoveEntity(self)
				end
			end
		end
	end
end