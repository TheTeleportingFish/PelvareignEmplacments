AddCSLuaFile()

if not Transcription_Global_Output then Transcription_Global_Output = {} end

if SERVER then
	
	function Transcription_Global_Output.Clock( system , code )
		system = system or {}
		code = code or "13_12"
		
		
		
		
		
		
		
		
		
		return "Tychronic Set"..code
		
	end
	
end