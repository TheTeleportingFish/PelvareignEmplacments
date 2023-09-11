AddCSLuaFile()

include( "includes/modules/ahee_suit_hud_material_module.lua" )

PelvareignEmplacements_Base = {} -- This will represent our "Class"
PelvareignEmplacements_Base.__index = PelvareignEmplacements_Base
--If a key cannot be found in a table, it will look in it's metatable's __index.
--This means any function we define for the 'PelvareignEmplacements_Base' table will be accessible by any object whose metatable is 'PelvareignEmplacements_Base'

game.AddParticles( "particles/cinder_explosives.pcf" )
game.AddParticles( "particles/muzzleflashes_test.pcf" )
game.AddParticles( "particles/muzzleflashes_test_b.pcf" )
game.AddParticles( "particles/cstm_muzzleflashes.pcf" )
game.AddParticles( "particles/customfraggrenadeexplose.pcf" )
game.AddParticles( "particles/heibullet_explosion.pcf" )
game.AddParticles( "particles/apfsdsdirthit.pcf" )
game.AddParticles( "particles/pelvareign_emplacements_effects_general.pcf" )

function Load_AHEE_Particles()
	PrecacheParticleSystem( "SABOTHIT" )
	PrecacheParticleSystem( "SABOTPEN" )
	PrecacheParticleSystem( "AMMOCOOKEXPLODE" )
	PrecacheParticleSystem( "AMMOCOOKOFF" )
	PrecacheParticleSystem( "DirtExplode" )
	PrecacheParticleSystem( "GroundExplode" )
	PrecacheParticleSystem( "FragExplose" )
	PrecacheParticleSystem( "DirtFireball" )
	PrecacheParticleSystem( "ShockWave" )
	PrecacheParticleSystem( "muzzleflash_m14_break_a" )
	PrecacheParticleSystem( "muzzle_flame" )
	PrecacheParticleSystem( "DirtFireballHit" )
	PrecacheParticleSystem( "Flashed" )
	PrecacheParticleSystem( "DirtDebrisShock" )
	PrecacheParticleSystem( "SmokeShockFar" )

	PrecacheParticleSystem( "fraise_jet" )
	PrecacheParticleSystem( "fraise_impact" )
	PrecacheParticleSystem( "fraise_heat_burn" )
	PrecacheParticleSystem( "fraise_explosion" )
	PrecacheParticleSystem( "fraise_jet_fragment" )
	PrecacheParticleSystem( "small_caliber_nuclear_fragmentation" )
	PrecacheParticleSystem( "small_caliber_nuclear_frag_premature" )
	PrecacheParticleSystem( "high_heat_burn_point" )
	PrecacheParticleSystem( "fraise_explosion_heat" )
	PrecacheParticleSystem( "small_caliber_shrapnel_premature" )
	PrecacheParticleSystem( "small_caliber_shrapnel" )
	PrecacheParticleSystem( "small_caliber_fragmentation_smoke" )
	PrecacheParticleSystem( "small_caliber_fragmentation" )
	PrecacheParticleSystem( "small_caliber_fragmentation_shrapnel" )
	PrecacheParticleSystem( "small_caliber_heat_shrapnel" )
	PrecacheParticleSystem( "object_vaporize_vapor" )
	PrecacheParticleSystem( "object_vaporize_shrapnel" )
	PrecacheParticleSystem( "object_vaporize_shrapnel_large" )
end

Load_AHEE_Particles()

if SERVER then
	util.AddNetworkString( "Client_Velocity_Prediction_Fix" )
end

net.Receive( "Client_Velocity_Prediction_Fix", function( len, ply ) --Client Prediction Stupidity
	local Float = net.ReadFloat()
	local Normal = net.ReadNormal()
	local Entity = net.ReadEntity()
	Entity.Client_Velocity = (Float * Normal)
end )

net.Receive( "CLIENT_UNDO_SUIT", function( len )
	local self = LocalPlayer() or net.ReadEntity()
	
	self:SetNWBool("AHEE_EQUIPED",false)
	self:SetNWEntity( "TargetSelected" , nil )
	
	self.ScreenFrame = nil
	self.frame:Remove()
	self.frame2:Remove()
	
	hook.Remove( "EntityEmitSound" , self )
	hook.Remove( "StartCommand" , self )
	hook.Remove( "CalcView" , "PelvareignSecondPerson" )
	hook.Remove( "OnDamagedByExplosion" , self )
	hook.Remove( "EntityTakeDamage" , self )
	hook.Remove( "PostDrawHUD" , self )
	hook.Remove( "PreDrawEffects" , self )
	hook.Remove( "SetupSkyboxFog" , self )
	hook.Remove( "SetupWorldFog" , self )
	hook.Remove( "Think" , self )
	hook.Remove( "PlayerFootstep", self )
	
	self:SetDSP( 1, true )
	self.NetMass = nil
	LocalInteractables = nil
	--self:SetModel( self.Orig_Model )
	
end )

function PelvareignEmplacements_Base:RestartSuit( ply )
	
	net.Start( "CLIENT_UNDO_SUIT" )
		net.WriteEntity( ply )
	net.Send( ply )
	
	ply:SetNWBool("AHEE_EQUIPED",false)
	ply:SetNWEntity( "TargetSelected" , nil )
	
	hook.Remove( "EntityEmitSound" , ply )
	hook.Remove( "OnDamagedByExplosion" , ply )
	hook.Remove( "EntityTakeDamage" , ply )
	hook.Remove( "Think" , ply )
	hook.Remove( "PlayerFootstep", ply )
	hook.Remove( "DoPlayerDeath", ply )
	hook.Remove( "CanPlayerSuicide", ply )
	hook.Remove( "PlayerShouldTakeDamage", ply )
	hook.Remove( "ShouldCollide", ply )
	
	ply:SetMoveType( MOVETYPE_WALK )
	
	ply.NetMass = nil
	--ply:SetModel( ply.Orig_Model )
	
end

function PE_Client_Panel( Panel )
	local PanelX, PanelY, PanelWidth, PanelHeight = Panel:GetBounds()
	local Screen_W, Screen_H = ScrW(), ScrH()
	
	if not ClientPanel_ResetButton then 
		local ClientPanel_ResetButton = vgui.Create( "DButton", Panel )
		ClientPanel_ResetButton:SetText( "" )
		ClientPanel_ResetButton:SetPos( 0, 0 )
		ClientPanel_ResetButton:SetSize( 100, 100 )
		ClientPanel_ResetButton:SetMouseInputEnabled( true )
		
		ClientPanel_ResetButton.Button_Color = Color( 0, 0, 255, 200 )
		
		ClientPanel_ResetButton.DoClick = function()
			Panel:Clear()
			EmitSound( Sound( "garrysmod/save_load1.wav" ), Vector(), -1, CHAN_AUTO, 1, 75, 0, 100 )
			print( "reset" )
		end
		ClientPanel_ResetButton.Paint = function( Self_Panel , w , h )
			ClientPanel_ResetButton.Button_Color = Self_Panel:IsHovered() and Color( 100, 150, 255, 200 ) or Color( 0, 0, 255, 200 )
			
			draw.RoundedBox( 20, 0, 0, w, h, ClientPanel_ResetButton.Button_Color )
			draw.DrawText( "Reset", "DefaultFixed", w * 0.5, h * 0.5, color_white, TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER )
			
		end
	end
	
	if not ClientPanel then 
		ClientPanel = vgui.Create( "DPanel" , Panel )
		ClientPanel:SetPos( 0, 0 ) -- Set the position of the panel
		ClientPanel:SetSize( 200, 200 ) -- Set the size of the panel
		ClientPanel:SetMouseInputEnabled( true )
		
		local binder = vgui.Create( "DBinder", ClientPanel )
		binder:SetSize( PanelWidth * 0.75, PanelHeight * 0.05 )
		binder:SetPos( PanelWidth * 0.5 , PanelWidth * 0.5 )
		
		ClientPanel.Paint = function( Self_Panel , w , h )
			if game.SinglePlayer() then
				draw.DrawText( "Pelvareign Emplacements", "TargetID", w * 0.5, h * 0.25, color_white, TEXT_ALIGN_CENTER )
			end
			draw.DrawText( "Pelvareign Emplacements", "TargetID", w * 0.5, h * 0.25, color_white, TEXT_ALIGN_CENTER )
			draw.DrawText( ">> 1. Addon Info", "TargetID", w * 0.5, h * 0.25, color_white, TEXT_ALIGN_CENTER )
			draw.DrawText( ">> 2. Clientside", "TargetID", w * 0.5, h * 0.25, color_white, TEXT_ALIGN_CENTER )
			draw.DrawText( "This button will set the menu up, if the suit is equipped.", "TargetID", w * 0.5, h * 0.25, color_white, TEXT_ALIGN_CENTER )
		end
		
		function binder:OnChange( num )
			print( input.GetKeyName( num ) )
		end
		
	end
	
	
	local TextX, TextY = 0, 0
	local TextColor = Color( 255, 0, 0, 255 )
	
	surface.SetFont( Panel:GetFont() or "default" )
	surface.SetTextColor( TextColor )
	surface.SetTextPos( TextX, TextY )
	surface.DrawText( Panel:GetText() )
	
	draw.RoundedBox( 4, PanelWidth*0.5, PanelHeight*0.1, PanelWidth*0.9, Screen_H*0.1, Color( 255, 255, 255 ) )
	
	surface.SetDrawColor( 170, 250, 190, 200 ) -- Set the drawing color
	surface.SetMaterial( selfidentify_shieldtoggle ) -- Use our cached material
	surface.DrawTexturedRect( (PanelWidth * 0.775) - 25/2 , (PanelHeight * 0.5) , 25 , 25 )
	
end

function PE_Client( Panel )
	
	function Panel:Paint( aWide, aTall )
		PE_Client_Panel ( self )
	end
	
end

hook.Add("PopulateToolMenu", "PEMenus", function () 
	spawnmenu.AddToolMenuOption("Utilities", "Emplacements", "PE_Client", "Clientside", "", "", PE_Client)
end)

--include("weapons/cw_mainsound/sh_sounds.lua")

-- convenience function which calls AddCSLuaFile and include on the specified file
function loadFile(path)
	AddCSLuaFile(path)
	include(path)
end
