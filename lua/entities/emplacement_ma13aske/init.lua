AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")
include("cl_init.lua")

local phys, ef

function TableEntityCheckAndRemove( Table )
	if table.Count( Table ) < 1 then return end
	for Index, v in pairs(Table) do
		if not v:IsValid() then 
			table.remove(Table,Index)
		end
	end
end

-- net.Start("ShockwaveFunction")
-- net.WriteFloat(Dist)
-- net.Broadcast()

local traceData = {}
traceData.mask = bit.bor(CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_DEBRIS, CONTENTS_MONSTER, CONTENTS_HITBOX, CONTENTS_WATER)

function ENT:PlantEffect(entity,pos,direction)
	local Bellit={
		Attacker=entity,
		Damage=15,
		Force=2000,
		Num=1,
		Tracer=0,
		Dir=direction,
		Spread=Vector(0,0,0),
		Src=pos
	}
	entity:FireBullets(Bellit)
end

function DamageTarget( self , Target , DmgInfo , dmg_random )
	if IsValid(Target) then
		if(Target:IsNPC())then
			Target:Fire("respondtoexplodechirp","",0.5)
			Target:Fire("selfdestruct","",1)
			Target:Fire("disarm"," ",0)
			Target:Fire("explode","",0)
			Target:Fire("gunoff","",0)
			Target:Fire("settimer","0",0)
		end
		util.BlastDamage(self,self,Target:WorldSpaceCenter(),12,dmg_random/4)
		Target:Ignite(5,0)
		Target:TakeDamageInfo( DmgInfo )
	end
end

function ENT:Initialize()

	game.AddParticles( "particles/heibullet_explosion.pcf" )
	PrecacheParticleSystem( "DirtFireballHit" )
	PrecacheParticleSystem( "Flashed" )
	
	self:CustomInitialize()
end


hook.Add( "ServerDmgTarget", "ServerTargetHook", DamageTarget )