AddCSLuaFile()

if not NetDiscovery_Systematic then NetDiscovery_Systematic = {} end

NetDiscovery_Systematic.DistrictMapping = {}
NetDiscovery_Systematic.DistrictArmaments = {}
NetDiscovery_Systematic.SectorArmaments = {}

NetDiscovery_Systematic.ConformancyValues = {}

NetDiscovery_Systematic.SectorTags = {}
NetDiscovery_Systematic.DistrictTags = {}
NetDiscovery_Systematic.LocalDistrictTags = {}

NetDiscovery_Systematic.LocalizedTags = {}

NetDiscovery_Systematic.CrawlTags = {}
NetDiscovery_Systematic.LocalizedInformants = {}

if SERVER then
	
	function NetDiscovery_Systematic.ConnectNetDiscoverySystem( ply , system , code )
		ply = ply or nil
		system = system or {}
		code = code or "13_12"
		
		
		
		
		
		
		
		
		
		return "Net Discovery Pinged"
		
	end
	
	function NetDiscovery_Systematic.DistrictMappingSetup()
		Mapping = Mapping or {}
		Mapping.Sectors = {}
		
		for i=1, 9 do
			local Sector = {}
			Sector.Number = math.random(1,450)
			Sector.Name = "Code " .. Sector.Number
			Sector.Targets = 0
			Sector.Rating = "Non-Eval"
			Sector.Requirement = "13-5"
			Sector.Value = i
			
			Mapping.Sectors[Sector.Name] = Sector
		end
		
		
		
		
		
		return Mapping
	end
	
	
	NetDiscovery_Systematic.DistrictMapping = NetDiscovery_Systematic.DistrictMappingSetup()
	
end
















