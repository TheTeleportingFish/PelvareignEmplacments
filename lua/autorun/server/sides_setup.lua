AddCSLuaFile()

if not Pelvareign_Side then Pelvareign_Side = {} end
if not Romaz_Side then Romaz_Side = {} end
if not Benezine_Side then Benezine_Side = {} end

baseclass.Set( "Pelvareign_Side" , Pelvareign_Side )
baseclass.Set( "Romaz_Side" , Romaz_Side )
baseclass.Set( "Benezine_Side" , Benezine_Side )

Pelvareign_Side.UnitTypes = {
	[1] = { Type = "Capital Federalist Commandant", Rank = 2300, Order = 70
	},
	[2] = { Type = "Commandant Field Specialist", Rank = 2200, Order = 62
	},
	[3] = { Type = "Commanding Officer", Rank = 2000, Order = 55
	},
	[4] = { Type = "Ancil Commanding Officer", Rank = 1800, Order = 52
	},
	[5] = { Type = "Privatier Commanding Officer", Rank = 1600, Order = 49
	},
	[6] = { Type = "Tariboral Advanced ", Rank = 900, Order = 32
	},
	[7] = { Type = "Keebal Infantry", Rank = 800, Order = 30
	},
	[8] = { Type = "Kedral Infantry", Rank = 700, Order = 24
	},
	[9] = { Type = "Scebral Infantry", Rank = 200, Order = 8
	}
}

Pelvareign_Side.FieldUnits = {}
Pelvareign_Side.Ships = {}

Pelvareign_Side.UTCSystems = {}
Pelvareign_Side.UTACSystems = {}

if SERVER then
	
	function Pelvareign_Side:CreateShips()
		Crafts = {}
		
		
		
		
		
		
		
		
		
		return Crafts
		
	end
	
	function Pelvareign_Side:CreateFieldUnit( Entity )
		local Unit = {}
		
		if not (Entity:IsNextBot() or Entity:IsPlayer()) then return end
		Unit.Entity = Entity
		Unit.UnitType = self.UnitTypes[ math.random(1,#self.UnitTypes) ]
		
		
		table.insert( Pelvareign_Side.FieldUnits , Unit )
	end
	
end

