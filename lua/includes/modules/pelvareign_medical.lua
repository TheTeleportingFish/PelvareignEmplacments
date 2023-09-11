AddCSLuaFile()

function SetUp_BodyPart( Name , Soft , Circ , Bone , BloodlossMult , MobilityPercentage , Hitgroup )
		local NewBodyPart = {}
		
		NewBodyPart.Name = tostring(Name)
		
		NewBodyPart.SoftPoints = Soft
		NewBodyPart.CirculationPoints = Circ
		NewBodyPart.BonePoints = Bone
		
		NewBodyPart.MaxSoftPoints = NewBodyPart.SoftPoints
		NewBodyPart.MaxCirculationPoints = NewBodyPart.CirculationPoints
		NewBodyPart.MaxBonePoints = NewBodyPart.BonePoints
		
		NewBodyPart.BonesBroken = false
		
		NewBodyPart.BloodLossMult = BloodlossMult
		NewBodyPart.MobilityPercent = MobilityPercentage
		
		NewBodyPart.AssignedPart = Hitgroup
		
		return NewBodyPart
	end

function MedicalFunction_Tick( Ply )
		
		local PlyMed = Ply.MedicalStats
		
		local TensionAmt = PlyMed.Tension / 50
		local CurHeartBeat = PlyMed.HeartRate
		local Blood_Positive, Blood_Negative = PlyMed.BloodPressure[1], PlyMed.BloodPressure[2]
		local PhysioExhaust = PlyMed.PhysiologicalExhaustion
		local PhysioExert = PlyMed.PhysiologicalExertion
		
		local BloodToxCount = PlyMed.BloodToxicity
		local BloodIdeal = 5200
		
		local SustainedBloodChange = 0
		local CardiacCapability = (PlyMed.Mobility / 100)
		local CardioTension = ((BloodIdeal - PlyMed.Blood) / BloodIdeal) * BloodToxCount
		local TensionChange = (PlyMed.Tension - ( ((CardioTension * 50) + 50) * CardiacCapability )) - (PhysioExhaust / 5)
		
		local HeartIdeal = (((math.abs(math.sin( CurTime() / 20 )) * math.random(5,30) / 10 ) + 800) * CardiacCapability) * TensionAmt
		local Blood_Positive_Ideal = 400 * ((TensionAmt + CardioTension) ^ 2)
		local Blood_Negative_Ideal = 390 * (TensionAmt + CardioTension)
		
		local PhysiologicalExhaustion_Ideal = 1 + (99 * (1-CardiacCapability) )
		local PhysiologicalExhaustionChange = (PhysiologicalExhaustion_Ideal / 100)
		
		local SystolicChange = (((Blood_Positive_Ideal - Blood_Positive) / Blood_Positive_Ideal) * CardiacCapability )
		local DiastolicChange = (((Blood_Negative_Ideal - Blood_Negative) / Blood_Negative_Ideal) * CardiacCapability )
		
		local ToxicityChange = ((PhysioExhaust / PlyMed.HeartRate * Blood_Negative) / Blood_Negative) - ((PlyMed.HeartRate * Blood_Positive) / PhysioExert)
		
		if PlyMed.Bleeding or PlyMed.Internal_Bleeding then
			PlyMed.Blood = PlyMed.Blood + SustainedBloodChange
		end
		
		PlyMed.HeartRate = math.Clamp( PlyMed.HeartRate - (PlyMed.HeartRate - HeartIdeal) * 0.025 , 0 , 15000 )
		PlyMed.PhysiologicalExhaustion = math.Clamp( PlyMed.PhysiologicalExhaustion - PhysiologicalExhaustionChange + TensionChange + ((PhysioExert - 15) / CurHeartBeat) , 0.01 , 200 )
		PlyMed.PhysiologicalExertion = math.Clamp( PlyMed.PhysiologicalExertion + ( ((math.Clamp( ( Ply.InducedGForce / 100 ) , 0 , 50000 ) * 0.5 ) * PhysioExhaust) - ((PlyMed.PhysiologicalExertion / 250) * (TensionAmt)) ) * CardiacCapability , 0.01 , 200 )
		PlyMed.Tension = math.Clamp( PlyMed.Tension - (( TensionChange + math.Clamp( ( Ply.InducedGForce / 1000 ) , 0 , 10 ) ) * 0.25) , 0 , 100 )
		
		PlyMed.BloodPressure[1] = math.Clamp( PlyMed.BloodPressure[1] + (SystolicChange * TensionAmt) , -50 , 7000 )
		PlyMed.BloodPressure[2] = math.Clamp( PlyMed.BloodPressure[2] + (DiastolicChange * TensionAmt) , -50 , 6000 )
		
		
		
		PlyMed.Consciousness = (math.Clamp( (PlyMed.Consciousness + ( ( ((SystolicChange-DiastolicChange)+TensionAmt) - ((PhysioExhaust/200) + (PhysioExert/200)) ) * 0.5 )) , 0 , 100 ) * 0.8) + ((PlyMed.BodyParts.Head.SoftPoints / PlyMed.BodyParts.Head.MaxSoftPoints)*20)
		PlyMed.BloodToxicity = math.Clamp( PlyMed.BloodToxicity + ( ToxicityChange * 0.001 ) , 0.001 , 100 )
		PlyMed.Mobility = math.Clamp( (PlyMed.Mobility + CardiacCapability + TensionAmt ) - PlyMed.BloodToxicity , 0.1 , 100 )
		
		PlyMed.CurHealth = Ply:Health()
		
	end




