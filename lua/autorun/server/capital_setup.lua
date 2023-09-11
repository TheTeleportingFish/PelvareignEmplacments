AddCSLuaFile()

-- convenience function which calls AddCSLuaFile and include on the specified file
function loadFile(path)
	AddCSLuaFile(path)
	include(path)
end
