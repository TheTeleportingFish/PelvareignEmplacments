AddCSLuaFile()

function SetUp_Armoring( Name , ElasticityMod , MatPoints , MaxTemp , EnergyDen , Hitgroup )
		local NewArmorPiece = {}
		
		NewArmorPiece.Name = tostring(Name)
		
		NewArmorPiece.EnergyDensity = EnergyDen -- TeraJoules / Kg
		
		NewArmorPiece.Elasticity = ElasticityMod -- Kg / Liter
		NewArmorPiece.MaxElasticity = NewArmorPiece.Elasticity
		
		NewArmorPiece.MaterialPoints = MatPoints -- Kg / Liter
		NewArmorPiece.MaxMaterialPoints = NewArmorPiece.MaterialPoints
		
		NewArmorPiece.Temperature = 0 -- Celsius
		NewArmorPiece.MaxTemperature = MaxTemp
		
		NewArmorPiece.SheddingMult = 0.0 -- Percent / GigaJoule
		NewArmorPiece.ExploseMult = 0.0 -- Percent / GigaJoule / Kg
		
		NewArmorPiece.ArmorGone = false
		
		NewArmorPiece.AssignedPart = Hitgroup
		
		return NewArmorPiece
	end
