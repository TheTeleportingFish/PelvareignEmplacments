AddCSLuaFile()

local Suit_Mains_List = {}
local WeaponChecks = {
"PrintName",
"RoundTypes",
"Primary",
"Secondary",
"ViewModel",
"WorldModel",
"Charge"
	}

function MainMenu_Modules_New( Name, Image, Module_Function )
	local Module_Item = {}
	local Module_Methods = {}
	Module_Methods.__index = Module_Methods
	
	Module_Item.Identification = Name
	Module_Item.Image = Image
	
	function Module_Methods:Fire_Function()
		Module_Function( MainFrame )
	end
	
	setmetatable( Module_Item, Module_Methods )
	
	table.insert( System_Mains_Tabs , Module_Item )
	return Module_Item
end

function System_Table_List_Add( System_Table , Name , Tree_Pos , Accept_Table , Type )
	local List_Additive = {}
	List_Additive.Name = Name
	List_Additive.Tree_Pos = Tree_Pos
	List_Additive.Accept_Table = Accept_Table
	List_Additive.Type = Type or "Button"
	if not Name or not Tree_Pos then return end
	
	table.insert( System_Table , List_Additive )
	return List_Additive
end

function MainMenu_Modules_Load()
	local Plr = LocalPlayer()
	
	System_Mains_Tabs = {}
	
	Suit_Mains_List = {}
	
	MainMenu_Modules_New( "Suit Mains", other_icon, Menu_Module_Suit_Mains )
	MainMenu_Modules_New( "Detection", other_icon, Menu_Module_Suit_Mains )
	MainMenu_Modules_New( "Armor", other_icon, Menu_Module_Suit_Mains )
	MainMenu_Modules_New( "Vital", other_icon, Menu_Module_Suit_Mains )
	MainMenu_Modules_New( "Core Function", other_icon, Menu_Module_Suit_Mains )
	
	System_Table_List_Add( Suit_Mains_List , "Grapple Pack" , Plr.RadeonicGrapplePack , {
		Charge=1,
		Frequency=1,
		EnergyYield=1,
		RangeOrder=1,
		PullAxis=1
	} , "Button" )
	
end

function Menu_RemovePanel( Frame )
	local self = LocalPlayer()
	if IsValid(MainFrame) then
		MainFrame.TabSelected = nil 
	end
	Frame:Remove()
	EmitSound( "ahee_suit/hud_systemmenuantiblip.wav", Vector(), -1, CHAN_STATIC, 1, 75, 0, 100 )
end

function Menu_Module_Suit_Mains()
	local self = LocalPlayer()
	if not MainFrame or MainFrame["Menu_Tab_Suit_Mains"] then 
		EmitSound( "ahee_suit/ahee_system_map_short.mp3", Vector(), -1, CHAN_STATIC, 1, 75, 0, 100 )
		return 
	end
	
	local Scroll,ListVelocity,UpAmount
	local FrameSizeW = ScrW() / 2.25
	local FrameSizeH = ScrH() / 2.25
	
	local FrameMargin = FrameSizeW / 200
	
	local RandomStart = math.random(0,1) == 1 and -1 or 2
	local StartPos = FrameSizeW * RandomStart
	
	local FrameWidthPosCurrent = StartPos
	
	local TabArray = {}
	
	local Frame = vgui.Create( "DPanel", nil , "Module Suit Mains Menu" )
	Frame:SetSize( FrameSizeW, FrameSizeH )
	Frame:SetPos( StartPos, ScrH()/2 )
	Frame:MakePopup()
	Frame:SetKeyboardInputEnabled( false )
	
	Frame.ItemSelected = nil
	
	MainFrame["Menu_Tab_Suit_Mains"] = Frame
	
	if not MainFrame["Menu_Tab_Suit_Mains"] or not Frame then Frame:Remove() MainFrame["Menu_Tab_Suit_Mains"]  = nil return end
	EmitSound( "ahee_suit/hud_systemmenublip.wav", Vector(), -1, CHAN_STATIC, 1, 75, 0, 100 )
	
	local CloseButtonSizeX, CloseButtonSizeY = FrameSizeW/6, FrameSizeH/12
	local CloseButtonPositionX, CloseButtonPositionY = (FrameSizeW/2) - (CloseButtonSizeX/2), (FrameSizeH) - (CloseButtonSizeY) - FrameMargin
	
	local GridSizes = FrameSizeW*(2/3)
	local GridHeight = FrameSizeH*0.05
	local Margin = 10
	
	local function ButtonListToPanelSide( Table , Accept_Table )
		local GridTable = gridpanel:GetItems()
		
		for Num, Value in pairs( gridpanel:GetItems() ) do
			gridpanel:RemoveItem(Value)
		end
		
		if not Table or not Accept_Table then return end
		
		for Key, Value in pairs( Table ) do
			surface.SetFont("DermaDefaultBold")
			if Accept_Table[Key] != nil then
			
			local but = vgui.Create( "DButton", gridpanel )
			but:SetText( "" )
			but.GridName = tostring(Key)
			but.ButtonCol = Color(0,0,0,200)
			
			but:SetSize( PanelSizeX, PanelSizeY*0.05 )
			
			gridpanel:AddItem( but )
			
			but.Paint = function( ButtonSelf, w, h )
				local TextMargin = FrameMargin/2
				
				if ButtonSelf:IsHovered() then
					local TimeCol = math.abs( math.sin(CurTime()*3) )
					ButtonSelf.ButtonCol = Color( 10*((1-TimeCol)*14) , 200*TimeCol , 255*TimeCol , 150 )
					if input.IsMouseDown( MOUSE_LEFT ) then
						ButtonSelf.ButtonCol = Color(255,255,255,200)
						if not ButtonSelf.Down then
							ButtonSelf.Down = true
							EmitSound( "ahee_suit/fire_warning.wav", Vector(), -1, CHAN_STATIC, 0.25, 75, 0, 230 )
						end
					else
						if ButtonSelf.Down then
							ButtonSelf.Down = false
						end
					end
				else
					ButtonSelf.ButtonCol = Color(0,0,0,200)
					if ButtonSelf.Down then
						ButtonSelf.Down = false
					end
				end
				
				draw.RoundedBox( FrameMargin, 0, 0, w, h, Color(255,255,255,100) )
				draw.RoundedBox( FrameMargin, FrameMargin/2, FrameMargin/2, w-FrameMargin, h-FrameMargin, ButtonSelf.ButtonCol )
				
				local FrameTextX, FrameTextY = surface.GetTextSize( but.GridName )
				local TextPositionX, TextPositionY = (w*0.025) , (h/2) 
				draw.RoundedBox( FrameMargin, TextPositionX - (TextMargin/2) , TextPositionY - (TextMargin/2) - (FrameTextY/2), FrameTextX + TextMargin , FrameTextY + TextMargin , Color(255,200,150,100) )
				draw.SimpleText( ButtonSelf.GridName, "DermaDefaultBold", TextPositionX, TextPositionY , Color(0,0,0,240), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
				
				if type(Value) != "table" then
					local FrameTextX, FrameTextY = surface.GetTextSize( tostring(Value) )
					local TextPositionX, TextPositionY = (w*0.6) , (h/2) 
					draw.RoundedBox( FrameMargin, TextPositionX - (TextMargin/2) - (FrameTextX/2) , TextPositionY - (TextMargin/2) - (FrameTextY/2), FrameTextX + TextMargin , FrameTextY + TextMargin , Color(255,200,150,100) )
					draw.SimpleText( tostring(Value), "DermaDefault", TextPositionX, TextPositionY , Color(0,0,0,240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				end
			end
			
			end
		end
		
	end
	
	local function CreateButtonAddToList( Index , Tag , Table , Accept_Table )
		local GridTable = gridpanel:GetItems()
		local but = vgui.Create( "DButton" )
		but:SetText( "" )
		but:SetSize( GridSizes, GridHeight )
		but.GridName = tostring(Index)
		but.ButtonCol = Color(0,0,0,200)
		but.Down = false
		
		grid:AddItem( but )
		
		but.Paint = function( ButtonSelf, w, h )
			local TextMargin = FrameMargin/2
			
			if ButtonSelf:IsHovered() then
				local TimeCol = math.abs( math.sin(CurTime()*3) )
				ButtonSelf.ButtonCol = Color( 10*((1-TimeCol)*14) , 200*TimeCol , 255*TimeCol , 150 )
				if input.IsMouseDown( MOUSE_LEFT ) then
					ButtonSelf.ButtonCol = Color(255,255,255,200)
					if not ButtonSelf.Down then
						ButtonSelf.Down = true
						EmitSound( "ahee_suit/fire_warning.wav", Vector(), -1, CHAN_STATIC, 0.25, 60, 0, 230 )
						
						if Frame.GridSelected != but.GridName then
							Frame.GridSelected = but.GridName
						end
						
					end
				else
					if ButtonSelf.Down then
						ButtonSelf.Down = false
					end
				end
			else
				ButtonSelf.ButtonCol = Color(0,0,0,200)
				if ButtonSelf.Down then
					ButtonSelf.Down = false
				end
			end
			
			but.DoClick = function()
				EmitSound( "ahee_suit/fire_warning.wav", Vector(), -1, CHAN_STATIC, 0.25, 60, 0, 50 )
				Set_Grid_System()
				ButtonListToPanelSide( Table , Accept_Table )
			end
			
			if Frame.GridSelected == but then
				ButtonSelf.ButtonCol = Color(255,255,255,200)
			end
			
			draw.RoundedBox( FrameMargin, 0, 0, w, h, Color(255,255,255,100) )
			draw.RoundedBox( FrameMargin, FrameMargin/2, FrameMargin/2, w-FrameMargin, h-FrameMargin, ButtonSelf.ButtonCol )
			
			surface.SetFont("DermaDefaultBold")
			local FrameTextX, FrameTextY = surface.GetTextSize( ButtonSelf.GridName )
			local TextPositionX, TextPositionY = (w*0.25) - (FrameTextX/2), (h/2) - (TextMargin/2)
			draw.RoundedBox( FrameMargin, TextPositionX - (TextMargin/2) , TextPositionY - (TextMargin/2) - (FrameTextY/2), FrameTextX + TextMargin , FrameTextY + TextMargin , Color(255,200,150,100) )
			draw.SimpleText( ButtonSelf.GridName, "DermaDefaultBold", TextPositionX + (FrameTextX/2) , TextPositionY , Color(0,0,0,240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			
			surface.SetFont("Default")
			local FrameTextX, FrameTextY = surface.GetTextSize( tostring( Tag ) )
			local TextPositionX, TextPositionY = (w*0.75) - (FrameTextX/2), (h/2) - (TextMargin/2)
			draw.RoundedBox( FrameMargin, TextPositionX - (TextMargin/2) , TextPositionY - (TextMargin/2) - (FrameTextY/2), FrameTextX + TextMargin , FrameTextY + TextMargin , Color(255,255,255,100) )
			draw.SimpleText( tostring( Tag ), "Default", TextPositionX + (FrameTextX/2) , TextPositionY , Color(0,0,0,240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			
		end
	end
	
	function Set_Grid_System()
		if grid or gridpanel or FrameArray then
			grid:Remove()
			gridpanel:Remove()
			FrameArray:Remove()
		end
		
		grid = vgui.Create( "DGrid", Frame )
		grid:SetPos( FrameMargin, CloseButtonSizeY*1.5 )
		grid:SetCols( 1 )
		grid:SetColWide( GridSizes )
		grid:SetRowHeight( GridHeight )
		
		FrameArray = vgui.Create( "DPanel", Frame , "Menu Array" )
		FrameArray:SetSize( (FrameSizeW*(1/3))-Margin , FrameSizeH-Margin )
		FrameArray:SetPos( (FrameSizeW*(2/3))+(Margin/2) , (Margin/2) )
		
		PanelSizeX, PanelSizeY = FrameArray:GetSize()
		
		gridpanel = vgui.Create( "DGrid", FrameArray )
		gridpanel:SetPos( 0 , (PanelSizeY*0.1)+(FrameMargin) )
		gridpanel:SetCols( 1 )
		gridpanel:SetColWide( PanelSizeX )
		gridpanel:SetRowHeight( PanelSizeY*0.05 )
		
		for Number, Tag in pairs( Suit_Mains_List ) do
			if Tag then
				local Added_Name = Tag.Name
				local Added_Tree = Tag.Tree_Pos
				local Added_Type = Tag.Type
				local Added_Accept_Table = Tag.Accept_Table
				
				CreateButtonAddToList( Added_Name, "MultiSelect", Added_Tree , Added_Accept_Table )
				
			end
		end
		
		FrameArray.Paint = function( Main, w, h )
			surface.SetFont("DermaDefaultBold")
			
			local FrameText = Frame.GridSelected or "Suit Mains"
			local FrameTextX, FrameTextY = surface.GetTextSize( FrameText )
			local TextMargin = FrameMargin*2
			local TextPositionX, TextPositionY = (w/2), (TextMargin)
			
			draw.RoundedBox( FrameMargin, 0, 0, w, h, Color(250,250,250,200) )
			draw.RoundedBox( FrameMargin, FrameMargin/2, FrameMargin/2, w-FrameMargin, h-FrameMargin, Color(0,0,0,100) )
			
			draw.RoundedBox( FrameMargin/10, TextPositionX - (FrameTextX/2) - (TextMargin/2) , TextPositionY - (TextMargin/2) , FrameTextX + TextMargin , FrameTextY + TextMargin , Color(20,20,20,200) )
			draw.SimpleText( FrameText, "DermaDefaultBold", (w/2) , TextPositionY + (FrameTextY/2) , color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			
		end
		
	end
	
	Set_Grid_System()
	
	Frame.Paint = function( Main, w, h )
		if not (FrameWidthPosCurrent) then return end
		if not MainFrame["Menu_Tab_Suit_Mains"] then Menu_RemovePanel( Frame ) return end
		
		local FrameWidthPosDesired = (ScrW()/2) - (FrameSizeW/2)
		local Desired = math.Round( (FrameWidthPosDesired - FrameWidthPosCurrent) * 0.5 , 1 )
		
		if Desired ~= 0 then
			FrameWidthPosCurrent = math.Clamp( FrameWidthPosCurrent + Desired , -FrameSizeW , FrameSizeW*2 )
			Frame:SetPos( FrameWidthPosCurrent , (ScrH()/2) - (FrameSizeH/2) )
		end
		
		surface.SetFont("SystemWarningFont")
		
		draw.RoundedBox( FrameMargin, 0, 0, w, h, Color(0,0,0,200) )
		draw.RoundedBox( FrameMargin, FrameMargin/2, FrameMargin/2, w-FrameMargin, h-FrameMargin, Color(0,0,0,100) )
		
		local FrameText = Frame.GridSelected or "Suit Mains"
		local FrameTextX, FrameTextY = surface.GetTextSize( FrameText )
		local TextMargin = FrameMargin*2
		local TextPositionX, TextPositionY = (FrameSizeW*(1/3)), (CloseButtonSizeY/2) - (TextMargin/2)
		
		draw.RoundedBox( FrameMargin/10, TextPositionX - (FrameTextX/2) - (TextMargin/2) , TextPositionY - (TextMargin/2) , FrameTextX + TextMargin , FrameTextY + TextMargin , Color(20,20,20,200) )
		draw.SimpleText( FrameText, "SystemWarningFont", TextPositionX , TextPositionY + (FrameTextY/2) , color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		
		if grid then
			local GridItems = grid and #grid:GetItems() or 0
			local ListHeight = (#grid:GetItems() * GridHeight) - (FrameSizeH - CloseButtonSizeY*3)
			local Scrolled = input.GetAnalogValue( ANALOG_MOUSE_WHEEL ) or 0
			Scroll = Scroll and (Scroll - ((Scroll - Scrolled) * 0.25)) or 0
			ListVelocity = ListVelocity and (ListVelocity * 0.25) + ((Scroll - Scrolled) * RealFrameTime()) or 0
			UpAmount = UpAmount and math.Clamp( UpAmount + ListVelocity , 0 , 1 ) or 0
			
			grid:SetPos( FrameMargin, (CloseButtonSizeY+FrameMargin) - (ListHeight*UpAmount) )
			
		end
		
	end
	
	Hint_Setup( "Mains Menu Setup" )
	
	if not MainFrame["Menu_Tab_Suit_Mains"] or not Frame then Menu_RemovePanel( Frame ) MainFrame["Menu_Tab_Suit_Mains"] = nil return end
	
end


function Menu_Mapping_Setup()
	local self = LocalPlayer()
	if not MainFrame then return end
	
	local FrameSizeW = ScrW() / 2
	local FrameSizeH = ScrW() / 2
	
	local FrameMargin = FrameSizeW / 100
	
	local RandomStart = math.random(0,1) == 1 and -1 or 2
	local StartPos = FrameSizeW * RandomStart
	
	local FrameWidthPosCurrent = StartPos
	
	local TabArray = {}
	
	local Frame = vgui.Create( "DPanel", nil , "Mapping Menu" )
	Frame:SetSize( FrameSizeW, FrameSizeH )
	Frame:SetPos( StartPos, ScrH()/2 )
	Frame:MakePopup()
	Frame:SetKeyboardInputEnabled( false )
	
	Frame.GridSelected = nil
	MainFrame["Mapping_Sys"] = Frame
	
	if not MainFrame["Mapping_Sys"] or not Frame then Frame:Remove() return end
	EmitSound( "ahee_suit/hud_systemmenublip.wav", Vector(), -1, CHAN_STATIC, 1, 75, 0, 100 )
	
	local CloseButtonSizeX, CloseButtonSizeY = FrameSizeW/6, FrameSizeH/12
	local CloseButtonPositionX, CloseButtonPositionY = (FrameSizeW/2) - (CloseButtonSizeX/2), (FrameSizeH) - (CloseButtonSizeY) - FrameMargin
	
	local GridSizes = FrameSizeH/3.5
	local Grid = vgui.Create( "DGrid", Frame )
	Grid:SetPos( (FrameSizeW/2)-((GridSizes*3)/2), CloseButtonSizeY*1 )
	Grid:SetCols( 3 )
	Grid:SetColWide( GridSizes )
	Grid:SetRowHeight( GridSizes )
	
	Frame.Paint = function( Main, w, h )
		if not (FrameWidthPosCurrent) then return end
		if not MainFrame["Mapping_Sys"] then Menu_RemovePanel( Frame ) return end
		
		local FrameWidthPosDesired = (ScrW()/2) - (FrameSizeW/2)
		local Desired = math.Round( (FrameWidthPosDesired - FrameWidthPosCurrent) * 0.5 , 1 )
		
		if Desired ~= 0 then
			FrameWidthPosCurrent = math.Clamp( FrameWidthPosCurrent + Desired , -FrameSizeW , FrameSizeW*2 )
			Frame:SetPos( FrameWidthPosCurrent , (ScrH()/2) - (FrameSizeH/2) )
		end
		
		surface.SetFont("SystemWarningFont")
		
		local FrameText = Frame.GridSelected and Frame.GridSelected.Info.Name.." ; District Map" or "District Map"
		local FrameTextX, FrameTextY = surface.GetTextSize( FrameText )
		
		draw.RoundedBox( FrameMargin, 0, 0, w, h, Color(0,0,0,200) )
		draw.RoundedBox( FrameMargin, FrameMargin/2, FrameMargin/2, w-FrameMargin, h-FrameMargin, Color(0,0,0,100) )
		
		local TextMargin = FrameMargin*2
		local TextPositionX, TextPositionY = (FrameSizeW/2) - (FrameTextX/2), (CloseButtonSizeY/2) - (TextMargin/2)
		
		draw.RoundedBox( FrameMargin/10, TextPositionX - (TextMargin/2) , TextPositionY - (TextMargin/2) , FrameTextX + TextMargin , FrameTextY + TextMargin , Color(20,20,20,200) )
		draw.SimpleText( FrameText, "SystemWarningFont", (FrameSizeW/2) , TextPositionY + (FrameTextY/2) , color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		
	end
	
	function DistrictMapping_Finish()
		
		if NetDiscovery_Systematic and NetDiscovery_Systematic.DistrictMapping then
		local Mapping = NetDiscovery_Systematic.DistrictMapping
		
		FrameMargin = FrameMargin / 2
		for Number, Sector in pairs( Mapping.Sectors ) do
			if Sector == nil then return end
			local DeterminedToggles = { [1] = "Rating", [2] = "Requirement", [3] = "Value", [4] = "Targets" }
			local Type = 1
			
			local but = vgui.Create( "DButton" )
			but:SetText( "" )
			but:SetSize( GridSizes, GridSizes )
			but.GridName = "Sector " .. Sector.Name
			but.ButtonCol = Color(0,0,0,200)
			but.Info = Sector
			but.Down = false
			but.RightDown = false
			
			Grid:AddItem( but )
			
			but.DoClick = function()
				if Frame.GridSelected != but then
					Frame.GridSelected = but
				else
					Frame.GridSelected = nil
				end
			end
			
			but.DoRightClick = function()
				
			end
			
			but.Paint = function( ButtonSelf, w, h )
				if ButtonSelf:IsHovered() then
					ButtonSelf.ButtonCol = Color(10,200,255,100)
					if input.IsMouseDown( MOUSE_LEFT ) then
						ButtonSelf.ButtonCol = Color(255,200,130,150)
						if not ButtonSelf.Down then
							ButtonSelf.Down = true
							EmitSound( "ahee_suit/fire_warning.wav", Vector(), -1, CHAN_STATIC, 0.25, 75, 0, 230 )
						end
					elseif input.IsMouseDown( MOUSE_RIGHT ) then
						ButtonSelf.ButtonCol = Color(255,0,0,150)
						if not ButtonSelf.RightDown then
							ButtonSelf.RightDown = true
							EmitSound( "ahee_suit/suit_malfease_warn.mp3", Vector(), -1, CHAN_STATIC, 0.1, 75, 0, 200 )
							Type = Type + 1
						end
					else
						if ButtonSelf.Down then
							ButtonSelf.Down = false
						end
						if ButtonSelf.RightDown then
							ButtonSelf.RightDown = false
						end
					end
				else
					ButtonSelf.ButtonCol = Color(0,0,0,200)
					if ButtonSelf.Down then
						ButtonSelf.Down = false
					end
					if ButtonSelf.RightDown then
						ButtonSelf.RightDown = false
					end
				end
				
				if Type > 4 then
					Type = 1
				end
				
				ButtonSelf:SetSize( Grid:GetWide()/3, Grid:GetTall()/3 )
				
				draw.RoundedBox( FrameMargin, 0, 0, w, h, Color(255,90,0,100) )
				draw.RoundedBox( FrameMargin, FrameMargin/2, FrameMargin/2, w-FrameMargin, h-FrameMargin, ButtonSelf.ButtonCol )
				
				surface.SetFont("DermaDefaultBold")
				local FrameTextX, FrameTextY = surface.GetTextSize( ButtonSelf.GridName )
				local TextMargin = FrameMargin*2
				local TextPositionX, TextPositionY = (w/2) - (FrameTextX/2), (h/2) - (TextMargin/2)
				draw.RoundedBox( FrameMargin, TextPositionX - (TextMargin/2) , TextPositionY - (TextMargin/2) , FrameTextX + TextMargin , FrameTextY + TextMargin , Color(255,255,255,50) )
				draw.SimpleText( ButtonSelf.GridName, "DermaDefaultBold", TextPositionX + (FrameTextX/2) , TextPositionY + (FrameTextY/2) , Color(0,0,0,200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				
				surface.SetFont("DermaDefault")
				local Text = tostring(DeterminedToggles[Type]) .. ": " .. Sector[DeterminedToggles[Type]]
				local FrameTextX, FrameTextY = surface.GetTextSize( Text )
				local TextMargin = FrameMargin*3
				local TextPositionX, TextPositionY = (w/2) - (FrameTextX/2), (h/2) + (TextMargin/2)
				draw.RoundedBox( FrameMargin, TextPositionX - (TextMargin/2) , TextPositionY - (TextMargin/2) + (FrameTextY*2) , FrameTextX + TextMargin , FrameTextY + TextMargin , Color(255,255,255,50) )
				draw.SimpleText( Text, "DermaDefault", TextPositionX + (FrameTextX/2) , TextPositionY + (FrameTextY/2) + (FrameTextY*2) , Color(0,0,0,200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				
				draw.SimpleText( Type, "GModNotify", TextPositionX - (FrameTextY*2) , TextPositionY + (FrameTextY/2) + (FrameTextY*2) , Color(0,0,0,140), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			end
			
		end
			
			local MappedTargetPanel = vgui.Create( "DPanel", Frame , "Mapping Target Menu" )
			MappedTargetPanel:SetSize( GridSizes*3, GridSizes*3 )
			MappedTargetPanel:SetPos( (FrameSizeW/2)-((GridSizes*3)/2), CloseButtonSizeY*1.5 )
			MappedTargetPanel:SetMouseInputEnabled( false )
			
			MappedTargetPanel.Paint = function( Main, w, h )
				if Frame.GridSelected then
					Selected = Frame.GridSelected
					SelX, SelY = (Selected:GetX()-Grid:GetWide()/2), (-Selected:GetY()+Grid:GetTall()/2)
					Grid:SetPos( -SelX , SelY )
					SectorArea = 1000/3
					Grid:SetColWide( GridSizes*3 )
					Grid:SetRowHeight( GridSizes*3 )
					
				else
					SelX, SelY = 0, 0
					Grid:SetPos( ((FrameSizeW/2) - ((GridSizes*3)/2)) , (CloseButtonSizeY*1) )
					SectorArea = 1000
					Grid:SetColWide( GridSizes )
					Grid:SetRowHeight( GridSizes )
					
				end
				
				if EntAliveArray then
					local Array = EntArray
					table.Add( Array, {LocalPlayer()} )
					for Key, Entity in pairs( Array ) do
						local Position = Entity:GetPos()
						local Angle = Entity:GetAngles()
						local PosInSectorX = ( (-Position.x / 52.4934) / SectorArea ) * w - SelX
						local PosInSectorY = ( (Position.y / 52.4934) / SectorArea ) * h - SelY
						local SizeX,SizeY = 16, 16
						
						surface.SetDrawColor( 255, 255, 255, 150 )
						
						if Entity == LocalPlayer() then
							surface.SetDrawColor( 255, math.abs(math.sin( CurTime()*3 ))*150, math.abs(math.sin( CurTime()*3 ))*50, 255 ) 
							SizeX = SizeX * 1.5
							SizeY = SizeY * 1.5
						elseif Entity.Rooted then
							surface.SetDrawColor( 255, 200, 50, 175 ) 
							SizeX = SizeX * 1.5
							SizeY = SizeY * 1.5
						end
						
						if Entity.Targeted then
							local SizeChange = (math.abs(math.sin( CurTime()*2 )) * 2)
							ChangedSizeX = SizeX * (2 + SizeChange)
							ChangedSizeY = SizeY * (2 + SizeChange)
							
							surface.SetDrawColor( 255, math.abs(math.sin( CurTime()*5 ))*255, 60, 35 )
							surface.SetMaterial( vitalsymbol_lineofsight_in ) -- Use our cached material
							surface.DrawTexturedRectRotated( ((w/2)+PosInSectorX) , ((h/2)+PosInSectorY) , ChangedSizeX, ChangedSizeY , CurTime()*160 ) -- Actually draw the rectangle
							
							surface.SetDrawColor( 0, 0, 0, 255 )
							surface.SetMaterial( main_pointerbeam ) -- Use our cached material
							surface.DrawTexturedRectRotated( ((w/2)+PosInSectorX), ((h/2)+PosInSectorY), SizeX, SizeY, Angle.yaw+90 )
							
						else
							surface.SetMaterial( main_pointerbeam ) -- Use our cached material
							surface.DrawTexturedRectRotated( (w/2)+PosInSectorX, (h/2)+PosInSectorY, SizeX, SizeY, Angle.yaw+90 ) -- Actually draw the rectangle
						end
						
					end
				end
			end
			
		end
		
	end
	
	Hint_Setup( "~ Mapping Menu Setup ~" )
	
	net.Start("NetDiscovery_Mapping_Request")
	net.SendToServer()
	
	if not MainFrame["Mapping_Sys"] or not Frame then Menu_RemovePanel( Frame ) return end
	
end

function Menu_WeaponStats_Setup( Panel )
	local self = LocalPlayer()
	if not MainFrame or MainFrame["Weapon_Stats"] then 
		EmitSound( "ahee_suit/ahee_system_map_short.mp3", Vector(), -1, CHAN_STATIC, 1, 75, 0, 100 )
		return 
	end
	
	local Weapon = self:GetActiveWeapon()
	local Scroll,ListVelocity,UpAmount
	local FrameSizeW = ScrW() / 2.25
	local FrameSizeH = ScrH() / 2.25
	
	local FrameMargin = FrameSizeW / 200
	
	local RandomStart = math.random(0,1) == 1 and -1 or 2
	local StartPos = FrameSizeW * RandomStart
	
	local FrameWidthPosCurrent = StartPos
	
	local TabArray = {}
	
	local Frame = vgui.Create( "DPanel", nil , "Weapon Stats Menu" )
	Frame:SetSize( FrameSizeW, FrameSizeH )
	Frame:SetPos( StartPos, ScrH()/2 )
	Frame:MakePopup()
	Frame:SetKeyboardInputEnabled( false )
	
	Frame.ItemSelected = nil
	
	MainFrame["Weapon_Stats"] = Frame
	
	if not MainFrame["Weapon_Stats"] or not Frame then Frame:Remove() MainFrame["Weapon_Stats"]  = nil return end
	EmitSound( "ahee_suit/hud_systemmenublip.wav", Vector(), -1, CHAN_STATIC, 1, 75, 0, 100 )
	
	local CloseButtonSizeX, CloseButtonSizeY = FrameSizeW/6, FrameSizeH/12
	local CloseButtonPositionX, CloseButtonPositionY = (FrameSizeW/2) - (CloseButtonSizeX/2), (FrameSizeH) - (CloseButtonSizeY) - FrameMargin
	
	local GridSizes = FrameSizeW*(2/3)
	local GridHeight = FrameSizeH*0.05
	local Margin = 10
	
	local function ButtonListToPanelSide( Table )
		local GridTable = gridpanel:GetItems()
		
		for Num, Value in pairs( gridpanel:GetItems() ) do
			gridpanel:RemoveItem(Value)
		end
		
		if not Table then return end
		
		for Num, Key in pairs( Table ) do
			surface.SetFont("DermaDefaultBold")
			
			local but = vgui.Create( "DButton", gridpanel )
			but:SetText( "" )
			but.GridName = tostring(Num)
			but.ButtonCol = Color(0,0,0,200)
			
			but:SetSize( PanelSizeX, PanelSizeY*0.05 )
			
			gridpanel:AddItem( but )
			
			but.Paint = function( ButtonSelf, w, h )
				local TextMargin = FrameMargin/2
				
				if ButtonSelf:IsHovered() then
					local TimeCol = math.abs( math.sin(CurTime()*3) )
					ButtonSelf.ButtonCol = Color( 10*((1-TimeCol)*14) , 200*TimeCol , 255*TimeCol , 150 )
					if input.IsMouseDown( MOUSE_LEFT ) then
						ButtonSelf.ButtonCol = Color(255,255,255,200)
						if not ButtonSelf.Down then
							ButtonSelf.Down = true
							EmitSound( "ahee_suit/fire_warning.wav", Vector(), -1, CHAN_STATIC, 0.25, 75, 0, 230 )
						end
					else
						if ButtonSelf.Down then
							ButtonSelf.Down = false
						end
					end
				else
					ButtonSelf.ButtonCol = Color(0,0,0,200)
					if ButtonSelf.Down then
						ButtonSelf.Down = false
					end
				end
				
				draw.RoundedBox( FrameMargin, 0, 0, w, h, Color(255,255,255,100) )
				draw.RoundedBox( FrameMargin, FrameMargin/2, FrameMargin/2, w-FrameMargin, h-FrameMargin, ButtonSelf.ButtonCol )
				
				local FrameTextX, FrameTextY = surface.GetTextSize( but.GridName )
				local TextPositionX, TextPositionY = (w*0.025) , (h/2) 
				draw.RoundedBox( FrameMargin, TextPositionX - (TextMargin/2) , TextPositionY - (TextMargin/2) - (FrameTextY/2), FrameTextX + TextMargin , FrameTextY + TextMargin , Color(255,200,150,100) )
				draw.SimpleText( ButtonSelf.GridName, "DermaDefaultBold", TextPositionX, TextPositionY , Color(0,0,0,240), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
				
				if type(Key) != "table" then
				local FrameTextX, FrameTextY = surface.GetTextSize( tostring(Key) )
				local TextPositionX, TextPositionY = (w*0.6) , (h/2) 
				draw.RoundedBox( FrameMargin, TextPositionX - (TextMargin/2) - (FrameTextX/2) , TextPositionY - (TextMargin/2) - (FrameTextY/2), FrameTextX + TextMargin , FrameTextY + TextMargin , Color(255,200,150,100) )
				draw.SimpleText( tostring(Key), "DermaDefault", TextPositionX, TextPositionY , Color(0,0,0,240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				end
			end
		end
		
	end
	
	local function CreateButtonAddToList( Index, Tag , Table )
		local GridTable = gridpanel:GetItems()
		local but = vgui.Create( "DButton" )
		but:SetText( "" )
		but:SetSize( GridSizes, GridHeight )
		but.GridName = tostring(Index)
		but.ButtonCol = Color(0,0,0,200)
		but.Down = false
		
		grid:AddItem( but )
		
		but.Paint = function( ButtonSelf, w, h )
			local TextMargin = FrameMargin/2
			
			if ButtonSelf:IsHovered() then
				local TimeCol = math.abs( math.sin(CurTime()*3) )
				ButtonSelf.ButtonCol = Color( 10*((1-TimeCol)*14) , 200*TimeCol , 255*TimeCol , 150 )
				if input.IsMouseDown( MOUSE_LEFT ) then
					ButtonSelf.ButtonCol = Color(255,255,255,200)
					if not ButtonSelf.Down then
						ButtonSelf.Down = true
						EmitSound( "ahee_suit/fire_warning.wav", Vector(), -1, CHAN_STATIC, 0.25, 60, 0, 230 )
						
						if Frame.GridSelected != but.GridName then
							Frame.GridSelected = but.GridName
						end
						
					end
				else
					if ButtonSelf.Down then
						ButtonSelf.Down = false
					end
				end
			else
				ButtonSelf.ButtonCol = Color(0,0,0,200)
				if ButtonSelf.Down then
					ButtonSelf.Down = false
				end
			end
			
			but.DoClick = function()
				EmitSound( "ahee_suit/fire_warning.wav", Vector(), -1, CHAN_STATIC, 0.25, 60, 0, 50 )
				Set_Grid_System()
				ButtonListToPanelSide( Table )
			end
			
			if Frame.GridSelected == but then
				ButtonSelf.ButtonCol = Color(255,255,255,200)
			end
			
			draw.RoundedBox( FrameMargin, 0, 0, w, h, Color(255,255,255,100) )
			draw.RoundedBox( FrameMargin, FrameMargin/2, FrameMargin/2, w-FrameMargin, h-FrameMargin, ButtonSelf.ButtonCol )
			
			surface.SetFont("DermaDefaultBold")
			local FrameTextX, FrameTextY = surface.GetTextSize( ButtonSelf.GridName )
			local TextPositionX, TextPositionY = (w*0.25) - (FrameTextX/2), (h/2) - (TextMargin/2)
			draw.RoundedBox( FrameMargin, TextPositionX - (TextMargin/2) , TextPositionY - (TextMargin/2) - (FrameTextY/2), FrameTextX + TextMargin , FrameTextY + TextMargin , Color(255,200,150,100) )
			draw.SimpleText( ButtonSelf.GridName, "DermaDefaultBold", TextPositionX + (FrameTextX/2) , TextPositionY , Color(0,0,0,240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			
			surface.SetFont("Default")
			local FrameTextX, FrameTextY = surface.GetTextSize( tostring( Tag ) )
			local TextPositionX, TextPositionY = (w*0.75) - (FrameTextX/2), (h/2) - (TextMargin/2)
			draw.RoundedBox( FrameMargin, TextPositionX - (TextMargin/2) , TextPositionY - (TextMargin/2) - (FrameTextY/2), FrameTextX + TextMargin , FrameTextY + TextMargin , Color(255,255,255,100) )
			draw.SimpleText( tostring( Tag ), "Default", TextPositionX + (FrameTextX/2) , TextPositionY , Color(0,0,0,240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			
		end
	end
	
	function Set_Grid_System()
		if grid or gridpanel or FrameArray then
			grid:Remove()
			gridpanel:Remove()
			FrameArray:Remove()
		end
		
		grid = vgui.Create( "DGrid", Frame )
		grid:SetPos( FrameMargin, CloseButtonSizeY*1.5 )
		grid:SetCols( 1 )
		grid:SetColWide( GridSizes )
		grid:SetRowHeight( GridHeight )
		
		FrameArray = vgui.Create( "DPanel", Frame , "Weapon Stats Menu Array" )
		FrameArray:SetSize( (FrameSizeW*(1/3))-Margin , FrameSizeH-Margin )
		FrameArray:SetPos( (FrameSizeW*(2/3))+(Margin/2) , (Margin/2) )
		
		PanelSizeX, PanelSizeY = FrameArray:GetSize()
		
		gridpanel = vgui.Create( "DGrid", FrameArray )
		gridpanel:SetPos( 0 , (PanelSizeY*0.1)+(FrameMargin) )
		gridpanel:SetCols( 1 )
		gridpanel:SetColWide( PanelSizeX )
		gridpanel:SetRowHeight( PanelSizeY*0.05 )
		
		for Number, Tag in pairs( WeaponChecks ) do
			if Weapon[Tag] then
				local LocalTag = Weapon[Tag]
				if type(LocalTag)== "table" then
					CreateButtonAddToList( Tag, "MultiSelect", LocalTag )
				else
					CreateButtonAddToList( Tag, LocalTag )
				end
			end
		end
		
		FrameArray.Paint = function( Main, w, h )
			surface.SetFont("DermaDefaultBold")
			
			local FrameText = Frame.GridSelected or "Weapon Statistics"
			local FrameTextX, FrameTextY = surface.GetTextSize( FrameText )
			local TextMargin = FrameMargin*2
			local TextPositionX, TextPositionY = (w/2), (TextMargin)
			
			draw.RoundedBox( FrameMargin, 0, 0, w, h, Color(250,250,250,200) )
			draw.RoundedBox( FrameMargin, FrameMargin/2, FrameMargin/2, w-FrameMargin, h-FrameMargin, Color(0,0,0,100) )
			
			draw.RoundedBox( FrameMargin/10, TextPositionX - (FrameTextX/2) - (TextMargin/2) , TextPositionY - (TextMargin/2) , FrameTextX + TextMargin , FrameTextY + TextMargin , Color(20,20,20,200) )
			draw.SimpleText( FrameText, "DermaDefaultBold", (w/2) , TextPositionY + (FrameTextY/2) , color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			
		end
		
	end
	
	Set_Grid_System()
	
	Frame.Paint = function( Main, w, h )
		if not (FrameWidthPosCurrent) then return end
		if not MainFrame["Weapon_Stats"] then Menu_RemovePanel( Frame ) return end
		
		local FrameWidthPosDesired = (ScrW()/2) - (FrameSizeW/2)
		local Desired = math.Round( (FrameWidthPosDesired - FrameWidthPosCurrent) * 0.5 , 1 )
		
		if Desired ~= 0 then
			FrameWidthPosCurrent = math.Clamp( FrameWidthPosCurrent + Desired , -FrameSizeW , FrameSizeW*2 )
			Frame:SetPos( FrameWidthPosCurrent , (ScrH()/2) - (FrameSizeH/2) )
		end
		
		surface.SetFont("SystemWarningFont")
		
		draw.RoundedBox( FrameMargin, 0, 0, w, h, Color(0,0,0,200) )
		draw.RoundedBox( FrameMargin, FrameMargin/2, FrameMargin/2, w-FrameMargin, h-FrameMargin, Color(0,0,0,100) )
		
		local FrameText = Frame.GridSelected or "Weapon Statistics"
		local FrameTextX, FrameTextY = surface.GetTextSize( FrameText )
		local TextMargin = FrameMargin*2
		local TextPositionX, TextPositionY = (FrameSizeW*(1/3)), (CloseButtonSizeY/2) - (TextMargin/2)
		
		draw.RoundedBox( FrameMargin/10, TextPositionX - (FrameTextX/2) - (TextMargin/2) , TextPositionY - (TextMargin/2) , FrameTextX + TextMargin , FrameTextY + TextMargin , Color(20,20,20,200) )
		draw.SimpleText( FrameText, "SystemWarningFont", TextPositionX , TextPositionY + (FrameTextY/2) , color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		
		if grid then
			local GridItems = grid and #grid:GetItems() or 0
			local ListHeight = (#grid:GetItems() * GridHeight) - (FrameSizeH - CloseButtonSizeY*3)
			local Scrolled = input.GetAnalogValue( ANALOG_MOUSE_WHEEL ) or 0
			Scroll = Scroll and (Scroll - ((Scroll - Scrolled) * 0.25)) or 0
			ListVelocity = ListVelocity and (ListVelocity * 0.25) + ((Scroll - Scrolled) * RealFrameTime()) or 0
			UpAmount = UpAmount and math.Clamp( UpAmount + ListVelocity , 0 , 1 ) or 0
			
			grid:SetPos( FrameMargin, (CloseButtonSizeY+FrameMargin) - (ListHeight*UpAmount) )
			
			if Weapon != self:GetActiveWeapon() or GridItems != #WeaponChecks then
				Weapon = self:GetActiveWeapon()
				Set_Grid_System()
			end
			
		end
		
	end
	
	Hint_Setup( "Weapon Stats Menu Setup" )
	
	if not MainFrame["Weapon_Stats"] or not Frame then Menu_RemovePanel( Frame ) MainFrame["Weapon_Stats"] = nil return end
	
end

function Menu_Inventory_Setup()
	local self = LocalPlayer()
	if not MainFrame then return end
	
	local Inventory = self.CadronicInventory
	local FrameSizeW = ScrW() / 2.25
	local FrameSizeH = ScrH() / 2.25
	
	local FrameMargin = FrameSizeW / 100
	
	local RandomStart = math.random(0,1) == 1 and -1 or 2
	local StartPos = FrameSizeW * RandomStart
	
	local FrameWidthPosCurrent = StartPos
	
	local TabArray = {}
	
	local Frame = vgui.Create( "DPanel", nil , "Inventory Menu" )
	Frame:SetSize( FrameSizeW, FrameSizeH )
	Frame:SetPos( StartPos, ScrH()/2 )
	Frame:MakePopup()
	Frame:SetKeyboardInputEnabled( false )
	
	Frame.ItemSelected = nil
	Frame.Score = 0
	
	MainFrame["Sys_Inventory"] = Frame
	
	if not MainFrame["Sys_Inventory"] or not Frame then Frame:Remove() return end
	self:EmitSound( "ahee_suit/hud_systemmenublip.wav", 120, 100, 1, CHAN_STATIC, 0, 0 )
	
	local CloseButtonSizeX, CloseButtonSizeY = FrameSizeW/6, FrameSizeH/12
	local CloseButtonPositionX, CloseButtonPositionY = (FrameSizeW/2) - (CloseButtonSizeX/2), (FrameSizeH) - (CloseButtonSizeY) - FrameMargin
	
	local GridSizes = FrameSizeH/4
	local GridColumns = 6
	local grid = vgui.Create( "DGrid", Frame )
	grid:SetPos( (FrameSizeW/2)-((GridSizes*GridColumns)/2), CloseButtonSizeY*1.5 )
	grid:SetCols( GridColumns )
	grid:SetColWide( GridSizes )
	grid:SetRowHeight( GridSizes )
	
	Frame.Paint = function( Main, w, h )
		if not (FrameWidthPosCurrent) then return end
		if not MainFrame["Sys_Inventory"] then Menu_RemovePanel( Frame ) return end
		
		local FrameWidthPosDesired = (ScrW()/2) - (FrameSizeW/2)
		local Desired = math.Round( (FrameWidthPosDesired - FrameWidthPosCurrent) * 0.5 , 1 )
		
		if Desired ~= 0 then
			FrameWidthPosCurrent = math.Clamp( FrameWidthPosCurrent + Desired , -FrameSizeW , FrameSizeW*2 )
			Frame:SetPos( FrameWidthPosCurrent , (ScrH()/2) - (FrameSizeH/2) )
		end
		
		surface.SetFont("SystemWarningFont")
		
		local FrameText = Frame.ItemSelected and Frame.ItemSelected.Name or "Cadronic Inventory"
		local FrameTextX, FrameTextY = surface.GetTextSize( FrameText )
		
		draw.RoundedBox( FrameMargin, 0, 0, w, h, Color(0,0,0,200) )
		draw.RoundedBox( FrameMargin, FrameMargin/2, FrameMargin/2, w-FrameMargin, h-FrameMargin, Color(0,0,0,200) )
		
		local TextMargin = FrameMargin*2
		local TextPositionX, TextPositionY = (FrameSizeW/2) - (FrameTextX/2), (CloseButtonSizeY/2) - (TextMargin/2)
		
		draw.RoundedBox( FrameMargin/10, TextPositionX - (TextMargin/2) , TextPositionY - (TextMargin/2) , FrameTextX + TextMargin , FrameTextY + TextMargin , Color(255,255,255,200) )
		draw.SimpleText( FrameText, "SystemWarningFont", (FrameSizeW/2) , TextPositionY + (FrameTextY/2) , Color(0,0,0,240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		
	end
	
	FrameMargin = FrameMargin / 2
	for i=1,17 do --ItemOrder, Item in pairs( Inventory.Items )
		local Volume = math.random()
		local but = vgui.Create( "DButton" )
		but:SetText( "" )
		but:SetSize( GridSizes, GridSizes )
		but.ButtonCol = Color(0,0,0,200)
		but.Down = false
		
		but.Name = "Item "..i
		but.Volume = "Volume "..Volume
		
		grid:AddItem( but )
		
		but.DoClick = function()
		end
		
		but.Paint = function( ButtonSelf, w, h )
			surface.SetFont("DermaDefaultBold")
			
			if ButtonSelf:IsHovered() then
				ButtonSelf.ButtonCol = Color(10,200,255,100)
				if input.IsMouseDown( MOUSE_LEFT ) then
					ButtonSelf.ButtonCol = Color(255,200,130,150)
					if not ButtonSelf.Down then
						if Frame.ItemSelected == ButtonSelf then Frame.ItemSelected = nil else Frame.ItemSelected = ButtonSelf end
						ButtonSelf.Down = true
						self:EmitSound( "ahee_suit/fire_warning.wav", 90, 230, 0.25, CHAN_STATIC, 0, 0 )
					end
				else
					if ButtonSelf.Down then
						ButtonSelf.Down = false
					end
				end
			else
				if Frame.ItemSelected == ButtonSelf then 
					ButtonSelf.ButtonCol = Color(255,200,130,150)
				else 
					ButtonSelf.ButtonCol = Color(0,0,0,200)
				end
				
				if ButtonSelf.Down then
					ButtonSelf.Down = false
				end
			end
			
			draw.RoundedBox( FrameMargin, 0, 0, w, h, Color(255,90,90,100) )
			draw.RoundedBox( FrameMargin, FrameMargin/2, FrameMargin/2, w-FrameMargin, h-FrameMargin, ButtonSelf.ButtonCol )
			
			local Width, Height = (w*0.5), (h*0.5)
			local Glow = 255+(math.sin((CurTime()+i)/3)*600)
			
			surface.SetDrawColor( Glow , Glow , Glow , 200 )
			
			surface.SetMaterial( other_icon )
			surface.DrawTexturedRectRotated( (w/2), (h/2), Width, Height, math.sin((CurTime()+i)/3)*30 )
			
			local String1 = ButtonSelf.Name
			local FrameTextX, FrameTextY = surface.GetTextSize( String1 )
			local TextMargin = FrameMargin*2
			local TextPositionX, TextPositionY = (w/2) - (FrameTextX/2), (h*0.25) - (TextMargin/2)
			draw.RoundedBox( FrameMargin/10, TextPositionX - (TextMargin/2) , TextPositionY - (TextMargin/2) , FrameTextX + TextMargin , FrameTextY + TextMargin , Color(255,255,255,200) )
			draw.SimpleText( String1, "DermaDefault", TextPositionX + (FrameTextX/2) , TextPositionY + (FrameTextY/2) , Color(0,0,0,240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			
			local String2 = "Volume : 50"
			FrameTextX, FrameTextY = surface.GetTextSize( String2 )
			TextPositionX, TextPositionY = (w/2) - (FrameTextX/2), (h*0.75) - (TextMargin/2)
			draw.RoundedBox( FrameMargin/10, TextPositionX - (TextMargin/2) , TextPositionY - (TextMargin/2) , FrameTextX + TextMargin , FrameTextY + TextMargin , Color(255,255,255,200) )
			draw.SimpleText( String2, "DermaDefault", TextPositionX + (FrameTextX/2) , TextPositionY + (FrameTextY/2) , Color(0,0,0,240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end
		
	end
	
	local MaxParticles = 20
	local CadronicCore = vgui.Create( "DPanel", Frame , "Cadronic Core Menu" )
	CadronicCore:SetSize( (FrameSizeW), (FrameSizeH) )
	CadronicCore:SetPos( 0, 0 )
	CadronicCore:SetMouseInputEnabled( false )
	
	CadronicCore.NiceParticles = {}
	
	CadronicCore.Paint = function( Main, w, h )
		local Particles = Main.NiceParticles
		MouseXMove = MouseXMove and ( MouseXMove - (MouseXMove - gui.MouseX()) * 0.5 ) or gui.MouseX()
		MouseYMove = MouseYMove and ( MouseYMove - (MouseYMove - gui.MouseY()) * 0.5 ) or gui.MouseY()
		local DeltaX = math.Round( MouseXMove-gui.MouseX() , 4 )
		local DeltaY = math.Round( MouseYMove-gui.MouseY() , 4 )
		
		grid:SetPos( (FrameSizeW/2) - ((GridSizes*GridColumns)/2) - DeltaX, (CloseButtonSizeY*1.5) - DeltaY )
		
		if (math.abs(DeltaX) + math.abs(DeltaY)) > 12 then
			if not DeltaLock then
				DeltaLock = true
				self:EmitSound( "ahee_suit/hud_systemmenuaccept.wav", 60, 250, 0.1, CHAN_STATIC, 0, 0 )
			end
		else
			if DeltaLock then
				DeltaLock = false
				self:EmitSound( "ahee_suit/hud_systemmenuaccept.wav", 60, 50, 0.1, CHAN_STATIC, 0, 0 )
			end
		end
		
		for i=1, #Particles do
			if Particles[i] then
				local Part = Particles[i]
				local CircleSize = Part.Size + math.abs(math.sin( CurTime() )) * Part.Size
				local ColSub = (math.sin( CurTime() ) * 20) * Part.Size
				Part.X = (Part.X + Part.XVel) + math.random(-1,1)*RealFrameTime()
				Part.Y = (Part.Y + Part.YVel) - math.random(-1,1)*RealFrameTime()
				Part.XVel = Part.XVel - ((DeltaX+math.random(-1,1))*RealFrameTime())
				Part.YVel = Part.YVel - ((DeltaY+math.random(-1,1))*RealFrameTime())
				if Frame.ItemSelected then
					local SelectedFrameX, SelectedFrameY = (Frame.ItemSelected):GetPos()
					local GridOffsetX, GridOffsetY = (grid):GetPos()
					
					local OffsetPosX, OffsetPosY = (SelectedFrameX+GridOffsetX), (SelectedFrameY+GridOffsetY)
					
					Part.XVel = (Part.XVel*0.95) - ( Part.X-(OffsetPosX+(GridSizes/2)) )*RealFrameTime()
					Part.YVel = (Part.YVel*0.95) - ( Part.Y-(OffsetPosY+(GridSizes/2)) )*RealFrameTime()
				end
				
				draw.RoundedBox( CircleSize/2, Part.X-(CircleSize/2), Part.Y-(CircleSize/2), CircleSize, CircleSize, Color( 255 , 255 - ColSub/2 , 255 - ColSub , 100 ) )
				if not DeltaLock then 
					surface.SetDrawColor( 255 , 255 , 255 , 150 )
					surface.SetMaterial( other_icon )
					surface.DrawTexturedRectRotated( Part.X, Part.Y, CircleSize*1.5, CircleSize*1.5, (math.sin( CurTime() ) * 45) )
				else 
					surface.SetDrawColor( 255 , 210 , 90 , 160 )
					surface.SetMaterial( question_icon )
					surface.DrawTexturedRectRotated( Part.X, Part.Y, CircleSize*1, CircleSize*1, (math.sin( CurTime() ) * 120) )
				end
				
				local OffX = (Part.X > (w*0.99) or Part.X < (w*0.01))
				local OffY = (Part.Y > (h*0.99) or Part.Y < (h*0.01))
				
				if OffX or OffY then 
					table.remove( Particles , i )
					local ExploseSize = GridSizes*math.random(0.5,0.8)
					self:EmitSound( "ahee_suit/suit_malfease_warn.mp3", 60, math.random(120,130), 0.1, CHAN_STATIC, 0, 0 )
					surface.SetDrawColor( math.random(0,255) , 255 , 30 , 170 )
					surface.SetMaterial( cycle_icon )
					surface.DrawTexturedRect( math.Clamp(Part.X,0,w-ExploseSize), math.Clamp(Part.Y,0,h-ExploseSize), ExploseSize, ExploseSize )
					
					Frame.Score = Frame.Score + 1
				end
			end
		end
		
		if (#Particles < MaxParticles) and math.random(1,55) == 1 then
			self:EmitSound( "ahee_suit/suit_malfease_warn.mp3", 60, math.random(240,250), 0.1, CHAN_STATIC, 0, 0 )
			for i=1, math.random(1,3) do
				local Particle = { 
					X=(FrameSizeW*math.random(10,90)/100) ,
					Y=(FrameSizeH*math.random(10,90)/100) ,
					XVel=(math.random(-5,5)/100) ,
					YVel=(math.random(-5,5)/100) ,
					Size=(math.random(11,16))
				}
				table.insert( Particles , Particle )
				
				local ExploseSize = GridSizes*math.random(1.2,2)
				surface.SetDrawColor( 255 , 255 , math.random(0,255) , 90 )
				surface.SetMaterial( explosive_icon )
				surface.DrawTexturedRectRotated( math.Clamp(Particle.X,0,w-ExploseSize), math.Clamp(Particle.Y,0,h-ExploseSize), ExploseSize, ExploseSize, math.random(-360,360) )
			end
		end
		
		if Particles then
			local ParticleRatio = (#Particles/MaxParticles)
			local Script1 = ""
			
			if ParticleRatio <= 0.60 then 
				Script1 = "MORE PARTICLES!" 
			elseif Frame.ItemSelected then 
				Script1 = Frame.ItemSelected.Name.."... Don't grab it! It's a Trick!"
			else
				Script1 = "Hello there!"
			end
			
			surface.SetFont("DermaDefaultBold")
			local Script1FrameTextX, Script1FrameTextY = surface.GetTextSize( Script1 )
			draw.SimpleText( Script1, "DermaDefaultBold", w - 10, 10, Color( 255 , 255 , 255 , (ParticleRatio*500) + 25 ) , TEXT_ALIGN_RIGHT )
			
			local Script2 = "Amount of Particles - "..#Particles.."/"..MaxParticles
			surface.SetFont("GModNotify")
			local Script2FrameTextX, Script2FrameTextY = surface.GetTextSize( Script2 )
			draw.SimpleText( Script2, "GModNotify", w - 10, Script1FrameTextY + 10, Color( 255 , (ParticleRatio*255) , (ParticleRatio*255) , (ParticleRatio*200) + 50 ) , TEXT_ALIGN_RIGHT )
			
			local CogSize = Script2FrameTextY*1.25
			surface.SetDrawColor( 255 , (ParticleRatio*255) , (ParticleRatio*255) , (ParticleRatio*200) + 50 )
			surface.SetMaterial( machine_icon )
			surface.DrawTexturedRectRotated( w-(Script2FrameTextX+CogSize), CogSize+Script1FrameTextY/2, CogSize, CogSize, (math.sin( CurTime() * 20 ) *30) * (1-ParticleRatio) )
			
			local Script3 = "Particles Annihilated ~ "..Frame.Score
			surface.SetFont("DermaLarge")
			local Script3FrameTextX, Script3FrameTextY = surface.GetTextSize( Script3 )
			draw.SimpleText( Script3, "DermaLarge", w - 16, h - 8, Color( 255 , 255 , 255 , 120 ) , TEXT_ALIGN_RIGHT , TEXT_ALIGN_BOTTOM )
			
		end
		
	end
	
	Hint_Setup( "Inventory Menu Setup" )
	
	if not MainFrame["Mapping_Sys"] or not Frame then Menu_RemovePanel( Frame ) return end
	
end

function Interaction_Regime_GunSystem( Frame )
	local self = LocalPlayer()
	
	local ActiveWeapon = self:GetActiveWeapon()
	local Charge = ActiveWeapon["Charge"]
	local Rounds = ActiveWeapon["RoundTypes"]
	local RoundTypes = table.GetKeys(Rounds)
	local CurrentAmmoType = ActiveWeapon["AmmunitionType"]
	
	local FrameSizeW, FrameSizeH = Frame:GetSize()
	local FrameMargin = FrameSizeW / 100
	
	local GridSizes = FrameSizeW/6
	local GridColumns = 6
	local grid = vgui.Create( "DGrid", Frame )
	local Grid_XDistance, Grid_YDistance = (FrameSizeW*0.5)-((GridSizes*GridColumns)/2), FrameSizeH*0.25
	grid:SetPos( Grid_XDistance, Grid_YDistance )
	grid:SetCols( GridColumns )
	grid:SetColWide( GridSizes )
	grid:SetRowHeight( GridSizes )
	
	grid.ItemSelected = nil
	
	local function Create_GunSystem_Button( Name , Num )
		local button = vgui.Create( "DButton" )
		button:SetText( "" )
		button:SetSize( GridSizes, GridSizes )
		
		button.Name = Name or "Unknown"
		button.Speed = Rounds[Name].Speed or "Unknown"
		
		button.DoClick = function()
			net.Start( "Weapon_Change_RoundType" )
				net.WriteString( tostring(Name) )
			net.SendToServer()
			
			EmitSound( "ahee_suit/alert_energy_notice.mp3", Vector(), -1, CHAN_STATIC, 0.25, 60, 0, 230 )
			
			Frame:Remove()
			EmitSound( "ahee_suit/hud_systemmenuantiblip.wav", Vector(), -1, CHAN_STATIC, 1, 75, 0, 100 )
		end
		
		button.Paint = function( ButtonSelf, w, h )
			surface.SetFont("DefaultSmall")
			
			if ButtonSelf:IsHovered() then
				ButtonSelf.ButtonCol = Color(10,200,255,100)
				if input.IsMouseDown( MOUSE_LEFT ) then
					ButtonSelf.ButtonCol = Color(255,200,130,150)
					if not ButtonSelf.Down then
						if Frame.ItemSelected == ButtonSelf then Frame.ItemSelected = nil else Frame.ItemSelected = ButtonSelf end
						ButtonSelf.Down = true
						EmitSound( "ahee_suit/fire_warning.wav", Vector(), -1, CHAN_STATIC, 0.25, 60, 0, 230 )
					end
				else
					if ButtonSelf.Down then
						ButtonSelf.Down = false
					end
				end
			else
				if Frame.ItemSelected == ButtonSelf then 
					ButtonSelf.ButtonCol = Color(255,200,130,150)
				else 
					ButtonSelf.ButtonCol = Color(0,0,0,200)
				end
				
				if ButtonSelf.Down then
					ButtonSelf.Down = false
				end
			end
			
			draw.RoundedBox( FrameMargin, 0, 0, w, h, Color(255,90,90,100) )
			draw.RoundedBox( FrameMargin, FrameMargin/2, FrameMargin/2, w-FrameMargin, h-FrameMargin, ButtonSelf.ButtonCol )
			
			local Width, Height = (w*1.1), (h*1.1)
			local Glow = 200+(math.sin((CurTime()+Num)/3)*55)
			
			surface.SetDrawColor( Glow , Glow , 255 , 200 )
			
			surface.SetMaterial( generalized_ballistic )
			surface.DrawTexturedRectRotated( (w/2), (h/2), Width, Height, math.sin((CurTime()+Num)/3)*5 )
			
			local String1 = ButtonSelf.Name
			local FrameTextX, FrameTextY = surface.GetTextSize( String1 )
			local TextMargin = FrameMargin
			local TextPositionX, TextPositionY = (w/2) - (FrameTextX/2), (h*0.1) - (TextMargin/2)
			draw.RoundedBox( FrameMargin/10, TextPositionX - (TextMargin/2) , TextPositionY - (TextMargin/2) , FrameTextX + TextMargin , FrameTextY + TextMargin , Color(255,255,255,100) )
			draw.SimpleText( String1, "DefaultSmall", TextPositionX + (FrameTextX/2) , TextPositionY + (FrameTextY/2) , Color(0,0,0,240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			
			local String2 = "M/s : "..button.Speed
			FrameTextX, FrameTextY = surface.GetTextSize( String2 )
			TextPositionX, TextPositionY = (w/2) - (FrameTextX/2), (h*0.9) - (TextMargin/2)
			draw.RoundedBox( FrameMargin/10, TextPositionX - (TextMargin/2) , TextPositionY - (TextMargin/2) , FrameTextX + TextMargin , FrameTextY + TextMargin , Color(255,255,255,100) )
			draw.SimpleText( String2, "DefaultSmall", TextPositionX + (FrameTextX/2) , TextPositionY + (FrameTextY/2) , Color(0,0,0,240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end
		return button
	end
	
	for i = 1, #RoundTypes do
		local button = Create_GunSystem_Button( RoundTypes[i] , i )
		grid:AddItem( button )
	end
	
	local Scroll,UpAmount,ListVelocity = 0, 0, 0
	
	grid.Paint = function( Main, w, h )
		
		local ListHeight = ((#grid:GetItems()/GridColumns) * GridSizes) - (FrameSizeH - Grid_YDistance*2)
		local Scrolled = input.GetAnalogValue( ANALOG_MOUSE_WHEEL )
		Scroll = Scroll and (Scroll - ((Scroll - Scrolled) * 0.5)) or 0
		ListVelocity = ListVelocity and (ListVelocity * 0.1) + ((Scroll - Scrolled) * RealFrameTime()) or 0
		UpAmount = UpAmount and math.Clamp( UpAmount + ListVelocity , 0 , 1 ) or 0
		
		grid:SetPos( Grid_XDistance, Grid_YDistance - (ListHeight*UpAmount) )
		
	end
	
end

function Menu_Interactable_Setup( IsPlayerDependant , Interaction_Regime )
	local self = LocalPlayer()
	local IsPlayerDependant = IsPlayerDependant or false
	local Interaction_Regime = Interaction_Regime or nil
	
	EmitSound( "ahee_suit/hud_systemmenublip.wav", Vector(), -1, CHAN_STATIC, 1, 60, 0, 230 )
	
	local FrameSizeW = ScrW() / 3
	local FrameSizeH = ScrH() / 3
	
	local FrameMargin = FrameSizeW / 100
	
	local RandomStart = math.random(0,1) == 1 and -1 or 2
	local StartPos = FrameSizeW * RandomStart
	
	local FrameWidthPosCurrent = StartPos
	
	local Frame = vgui.Create( "DPanel", nil , "Interactable Menu" )
	Frame:SetSize( FrameSizeW, FrameSizeH )
	Frame:SetPos( StartPos, ScrH()/2 )
	Frame:MakePopup()
	Frame:SetKeyboardInputEnabled( false )
	
	Frame.ItemSelected = nil
	Frame.Score = 0
	
	if Interaction_Regime and isfunction(Interaction_Regime) then Interaction_Regime( Frame ) end
	
	Frame.Paint = function( Main, w, h )
		if not (FrameWidthPosCurrent) then return end
		
		local FrameWidthPosDesired = (ScrW()/2) - (FrameSizeW/2)
		local Desired = math.Round( (FrameWidthPosDesired - FrameWidthPosCurrent) * 0.5 , 1 )
		
		if Desired ~= 0 then
			FrameWidthPosCurrent = math.Clamp( FrameWidthPosCurrent + Desired , -FrameSizeW , FrameSizeW*2 )
			Frame:SetPos( FrameWidthPosCurrent , (ScrH()/2) - (FrameSizeH/2) )
		end
		
		surface.SetFont("SystemWarningFont")
		
		local FrameText = Frame.ItemSelected and Frame.ItemSelected.Name or "Interaction"
		local FrameTextX, FrameTextY = surface.GetTextSize( FrameText )
		
		local TitleSizeX, TitleSizeY = FrameSizeW/6, FrameSizeH/12
		local TitlePositionX, TitlePositionY = (FrameSizeW/2) - (TitleSizeX/2), (FrameSizeH) - (TitleSizeY) - FrameMargin
		
		local TextMargin = FrameMargin*2
		local TextPositionX, TextPositionY = (FrameSizeW/2) - (FrameTextX/2), (TitleSizeY/2) - (TextMargin/2)
		
		draw.RoundedBox( FrameMargin, 0, 0, w, h, Color(0,0,0,200) )
		draw.RoundedBox( FrameMargin, FrameMargin/2, FrameMargin/2, w-FrameMargin, h-FrameMargin, Color(0,0,0,200) )
		
		draw.RoundedBox( FrameMargin/10, TextPositionX - (TextMargin/2) , TextPositionY - (TextMargin/2) , FrameTextX + TextMargin , FrameTextY + TextMargin , Color(255,255,255,200) )
		draw.SimpleText( FrameText, "SystemWarningFont", (FrameSizeW/2) , TextPositionY + (FrameTextY/2) , Color(0,0,0,240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		
		if not IsValid(AbleToInteract.Entity) and not IsPlayerDependant then
			Frame:Remove()
			EmitSound( "ahee_suit/hud_systemmenuantiblip.wav", Vector(), -1, CHAN_STATIC, 1, 60, 0, 230 )
		end
		
	end
	
	return Frame
end

function Menu_Lock_Site_Setup( IsPlayerDependant , Interaction_Regime )
	local self = LocalPlayer()
	local IsPlayerDependant = IsPlayerDependant or false
	local Interaction_Regime = Interaction_Regime or nil
	
	EmitSound( "ahee_suit/hud_systemmenublip.wav", Vector(), -1, CHAN_STATIC, 1, 60, 0, 230 )
	
	local FrameSizeW = ScrW() / 3
	local FrameSizeH = ScrH() / 3
	
	local FrameMargin = FrameSizeW / 100
	
	local RandomStart = math.random(0,1) == 1 and -1 or 2
	local StartPos = FrameSizeW * RandomStart
	
	local FrameWidthPosCurrent = StartPos
	
	local Frame = vgui.Create( "DPanel", nil , "Lock Site Menu" )
	Frame:SetSize( FrameSizeW, FrameSizeH )
	Frame:SetPos( StartPos, ScrH()/2 )
	Frame:MakePopup()
	Frame:SetKeyboardInputEnabled( false )
	
	Frame.ItemSelected = nil
	Frame.Score = 0
	
	if Interaction_Regime and isfunction(Interaction_Regime) then Interaction_Regime( Frame ) end
	
	function Frame:Menu_Lock_Site_Remove()
		Frame:Remove()
		EmitSound( "ahee_suit/hud_systemmenuantiblip.wav", Vector(), -1, CHAN_STATIC, 1, 60, 0, 230 )
	end
	
	
	
	local TeamTransfer_Button = vgui.Create( "DButton", Frame )
	TeamTransfer_Button:SetText( "" )
	TeamTransfer_Button:SetSize( FrameSizeW*0.2, FrameSizeH*0.1 )
	TeamTransfer_Button:SetPos( FrameSizeH*0.025, FrameSizeH*0.025 )
	
	TeamTransfer_Button.Hover_Percent = 0
	TeamTransfer_Button.ButtonCol = Color(200,200,200,100)
	TeamTransfer_Button.Down = false
	
	TeamTransfer_Button.DoClick = function()
		EmitSound( "ahee_suit/ahee_system_manage_liss.mp3", Vector(), -1, CHAN_STATIC, 0.35, 90, 0, 100 )
		
		net.Start("Target_To_Team_Transfer_Server")
		net.SendToServer()
		
		Target_To_Team_Transfer( self )
	end
	
	TeamTransfer_Button.Paint = function( ButtonSelf, w, h )
		surface.SetFont("Default")
		local Mouse_Input_Left = input.IsMouseDown( MOUSE_LEFT )
		local Button_Percent = (ButtonSelf.Hover_Percent/100)
		
		if ButtonSelf:IsHovered() then
			ButtonSelf.Hover_Percent = math.Clamp( ButtonSelf.Hover_Percent + (RealFrameTime() * 150) , 0 , 100 )
			if Mouse_Input_Left then
				if not ButtonSelf.Down then
					EmitSound( "ahee_suit/fire_warning.wav", Vector(), -1, CHAN_STATIC, 0.25, 60, 0, 230 )
					ButtonSelf.Down = true
				end
				ButtonSelf.ButtonCol = Color(255,200,130,150)
			else
				ButtonSelf.Down = false
				ButtonSelf.ButtonCol = Color(10,200,255,100)
			end
			
		else
			ButtonSelf.Down = false
			ButtonSelf.ButtonCol = Color(200,200,200,100)
			ButtonSelf.Hover_Percent = math.Clamp( ButtonSelf.Hover_Percent - (RealFrameTime() * 300) , 0 , 100 )
			
		end
		
		draw.RoundedBox( FrameMargin, 0, 0, w, h, Color(255,255,255,50) )
		draw.RoundedBox( FrameMargin, FrameMargin/2, FrameMargin/2, w-FrameMargin, h-FrameMargin, ButtonSelf.ButtonCol )
		
		draw.RoundedBox( FrameMargin, FrameMargin/2, FrameMargin/2, (w-FrameMargin)*Button_Percent, h-FrameMargin, Color(255*Button_Percent,55*Button_Percent,55*Button_Percent,80) )
		
		local String1 = "TARGET -> TEAM"
		local FrameTextX, FrameTextY = surface.GetTextSize( String1 )
		local TextMargin = FrameMargin
		local TextPositionX, TextPositionY = (w*0.5), (h*0.5)
		draw.SimpleText( String1, "Default", TextPositionX , TextPositionY , Color(255,255,255,240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end
	
	
	
	local AlertTeam_Button = vgui.Create( "DButton", Frame )
	local ATB_Size_W, ATB_Size_H = FrameSizeW*0.3, FrameSizeH*0.15
	AlertTeam_Button:SetText( "" )
	AlertTeam_Button:SetSize( ATB_Size_W , ATB_Size_H )
	AlertTeam_Button:SetPos( (FrameSizeW*0.5)-(ATB_Size_W/2), (FrameSizeH*0.5)-(ATB_Size_H/2) )
	
	AlertTeam_Button.Hover_Percent = 0
	AlertTeam_Button.ButtonCol = Color(200,200,200,100)
	AlertTeam_Button.Down = false
	
	AlertTeam_Button.DoClick = function()
		EmitSound( "ahee_suit/ahee_system_lace_activate.mp3", Vector(), -1, CHAN_STATIC, 0.35, 90, 0, 100 )
		
		net.Start("Suit_Alert_PseudoTeam",true)
		net.SendToServer()
	end
	
	AlertTeam_Button.Paint = function( ButtonSelf, w, h )
		surface.SetFont("Trebuchet24")
		local Mouse_Input_Left = input.IsMouseDown( MOUSE_LEFT )
		local Button_Percent = (ButtonSelf.Hover_Percent/100)
		
		if ButtonSelf:IsHovered() then
			ButtonSelf.Hover_Percent = math.Clamp( ButtonSelf.Hover_Percent + (RealFrameTime() * 150) , 0 , 100 )
			if Mouse_Input_Left then
				if not ButtonSelf.Down then
					EmitSound( "ahee_suit/fire_warning.wav", Vector(), -1, CHAN_STATIC, 0.25, 60, 0, 230 )
					ButtonSelf.Down = true
				end
				ButtonSelf.ButtonCol = Color(255,200,130,150)
			else
				ButtonSelf.Down = false
				ButtonSelf.ButtonCol = Color(10,200,255,100)
			end
			
		else
			ButtonSelf.Down = false
			ButtonSelf.ButtonCol = Color(200,200,200,100)
			ButtonSelf.Hover_Percent = math.Clamp( ButtonSelf.Hover_Percent - (RealFrameTime() * 300) , 0 , 100 )
			
		end
		
		draw.RoundedBox( FrameMargin, 0, 0, w, h, Color(255,255,255,50) )
		draw.RoundedBox( FrameMargin, FrameMargin/2, FrameMargin/2, w-FrameMargin, h-FrameMargin, ButtonSelf.ButtonCol )
		
		draw.RoundedBox( FrameMargin, FrameMargin/2, FrameMargin/2, (w-FrameMargin)*Button_Percent, h-FrameMargin, Color(255*Button_Percent,55*Button_Percent,55*Button_Percent,80) )
		
		local String1 = "TEAM ALERT LISS"
		local FrameTextX, FrameTextY = surface.GetTextSize( String1 )
		local TextMargin = FrameMargin
		local TextPositionX, TextPositionY = (w*0.5), (h*0.5)
		draw.SimpleText( String1, "Trebuchet24", TextPositionX , TextPositionY , Color(255,255,255,240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end
	
	
	
	Frame.Paint = function( Main, w, h )
		if not (FrameWidthPosCurrent) then return end
		
		local FrameWidthPosDesired = (ScrW()/2) - (FrameSizeW/2)
		local Desired = math.Round( (FrameWidthPosDesired - FrameWidthPosCurrent) * 0.5 , 1 )
		
		if Desired ~= 0 then
			FrameWidthPosCurrent = math.Clamp( FrameWidthPosCurrent + Desired , -FrameSizeW , FrameSizeW*2 )
			Frame:SetPos( FrameWidthPosCurrent , (ScrH()/2) - (FrameSizeH/2) )
		end
		
		surface.SetFont("SystemWarningFont")
		
		local FrameText = Frame.ItemSelected and Frame.ItemSelected.Name or "Lock Site"
		local FrameTextX, FrameTextY = surface.GetTextSize( FrameText )
		
		local TitleSizeX, TitleSizeY = FrameSizeW/6, FrameSizeH/12
		local TitlePositionX, TitlePositionY = (FrameSizeW/2) - (TitleSizeX/2), (FrameSizeH) - (TitleSizeY) - FrameMargin
		
		local TextMargin = FrameMargin*2
		local TextPositionX, TextPositionY = (FrameSizeW/2) - (FrameTextX/2), (TitleSizeY/2) - (TextMargin/2)
		
		draw.RoundedBox( FrameMargin, 0, 0, w, h, Color(0,0,0,200) )
		draw.RoundedBox( FrameMargin, FrameMargin/2, FrameMargin/2, w-FrameMargin, h-FrameMargin, Color(0,0,0,200) )
		
		draw.RoundedBox( FrameMargin/10, TextPositionX - (TextMargin/2) , TextPositionY - (TextMargin/2) , FrameTextX + TextMargin , FrameTextY + TextMargin , Color(255,255,255,200) )
		draw.SimpleText( FrameText, "SystemWarningFont", (FrameSizeW/2) , TextPositionY + (FrameTextY/2) , Color(0,0,0,240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		
	end
	
	return Frame
end

function AHEE_HUD_PseudoTeam()
	local self = LocalPlayer()
	local A9_TeamList = self.A9_Team_List
	
	local A9_TeamList_Local_Num = #A9_TeamList
	
	EmitSound( "ahee_suit/hud_systemmenublip.wav", Vector(), -1, CHAN_STATIC, 1, 60, 0, 230 )
	
	local SymBackingX = (ScrW() * 0)
	local SymBackingY = (ScrH() * 0.45)
	
	local FrameSizeW = (ScrW() * 0.175)
	local FrameSizeH = (ScrH() * 0.2)
	
	local FrameMargin = FrameSizeW / 100
	local StartPos = FrameSizeW * -0.9
	
	local FrameWidthPosCurrent = StartPos
	
	local Frame = vgui.Create( "DPanel", nil , "HUD PseudoTeam Menu" )
	Frame:SetSize( FrameSizeW, FrameSizeH )
	Frame:SetPos( StartPos, ScrH()/2 )
	
	Frame:MakePopup()
	Frame:SetMouseInputEnabled( self.AHEEMENU_ISOPEN )
	Frame:SetKeyboardInputEnabled( false )
	
	Frame.ItemSelected = nil
	
	local GridPanel = vgui.Create( "DPanel" , Frame )
	local Grid_XDistance, Grid_YDistance = (FrameSizeW*0.05), (FrameSizeH*0.1)
	GridPanel:SetPos( Grid_XDistance, Grid_YDistance ) -- Set the position of the panel
	GridPanel:SetSize( FrameSizeW*0.9, FrameSizeH*0.8 ) -- Set the size of the panel
	GridPanel:SetMouseInputEnabled( true )
	
	GridPanel.Paint = function( Main, w, h )
		draw.RoundedBox( FrameMargin, 0, 0, w, h, Color(0,0,0,100) )
	end
	
	local grid = vgui.Create( "DGrid", GridPanel )
	local GridSizes = FrameSizeW*0.9
	grid:SetPos( 0, 0 )
	grid:SetCols( 1 )
	grid:SetColWide( GridSizes )
	grid:SetRowHeight( GridSizes*0.2 )
	grid:SetMouseInputEnabled( self.AHEEMENU_ISOPEN )
	grid:SetKeyboardInputEnabled( false )
	
	local function Create_PseudoTeam_Button( Num )
		local Unit = A9_TeamList[Num]
		local button = vgui.Create( "DButton", Frame )
		button:SetText( "" )
		button:SetSize( GridSizes, GridSizes*0.2 )
		
		local ButtonSize_W, ButtonSize_H = button:GetSize()
		
		if Unit:IsPlayer() then
			local Unit_Name = string.Left( Unit:GetName(), 10 ) 
			local Extra_String = ((string.len(Unit:GetName())-string.len(Unit_Name)) > 0) and "..." or ""
			button.Name = tostring( "U" .. Num .. " ; " .. Unit_Name .. Extra_String .." ; Adreon 9 Unit"  )
		else
			button.Name = tostring( "U" .. Num .. " ; Adreon 9 Unit"  )
		end
		
		button.DoClick = function()
			EmitSound( "ahee_suit/ahee_system_revital_click.mp3", Vector(), -1, CHAN_STATIC, 0.25, 60, 0, 230 )
		end
		
		local Frame_Image = vgui.Create( "DPanel" , button )
		local Frame_Image_X, Frame_Image_Y = ButtonSize_W*0.125, ButtonSize_H*0.5
		local Frame_Image_W, Frame_Image_H = ButtonSize_W*0.2, ButtonSize_H*0.8
		Frame_Image:SetPos( Frame_Image_X - (Frame_Image_W/2), Frame_Image_Y - (Frame_Image_H/2) ) -- Set the position of the panel
		Frame_Image:SetSize( Frame_Image_W, Frame_Image_H ) -- Set the size of the panel
		
		Frame_Image.Paint = function( Main, w, h )
			local Unit_IsPlayer = Unit:IsPlayer()
			local Unit_FrameColor = Unit_IsPlayer and Color(50 , 200 , 255 , 200) or Color(255 , 255 , 255 , 100)
			draw.RoundedBox( FrameMargin, 0, 0, w, h, Unit_FrameColor )
			surface.SetDrawColor( 255 , 255 , 255 , 240 )
			surface.SetMaterial( icon_identity_random_3 )
			surface.DrawTexturedRectRotated( w*0.5, h*1.5, w*3, h*3, math.sin((SysTime()+Num)*2)*3 )
		end
		
		local Frame_Title = vgui.Create( "DPanel" , button )
		local Frame_Title_X, Frame_Title_Y = ButtonSize_W*0.6125, ButtonSize_H*0.1
		local Frame_Title_W, Frame_Title_H = ButtonSize_W*0.75, ButtonSize_H*0.4
		Frame_Title:SetPos( Frame_Title_X - (Frame_Title_W/2), Frame_Title_Y ) -- Set the position of the panel
		Frame_Title:SetSize( Frame_Title_W , Frame_Title_H ) -- Set the size of the panel
		
		Frame_Title.Paint = function( Main, w, h )
			if not IsValid(Unit) then return end
			surface.SetFont("DefaultSmall")
			local String1 = button.Name
			local FrameTextX, FrameTextY = surface.GetTextSize( String1 )
			local TextMargin = FrameMargin
			draw.RoundedBox( FrameMargin, 0 , 0 , w , h , Color(255,255,255,100) )
			draw.SimpleText( String1, "DefaultSmall", w/2 , 0 , Color(0,0,0,240), TEXT_ALIGN_CENTER, TEXT_ALIGN_LEFT )
			
			local Main_Cap_W, Main_Cap_H = w*0.9, h*0.3
			local Main_Cap_X, Main_Cap_Y = w*0.05,  h*0.6
			draw.RoundedBox( FrameMargin, Main_Cap_X, Main_Cap_Y, Main_Cap_W, Main_Cap_H, Color( (math.abs(math.sin(SysTime()*3.14))*100) , 0 , 0 , 200 ) )
			
			if Unit.MainCapacitorMJ then
				local Main_Cap_Bar = math.Clamp(Unit.MainCapacitorMJ/Unit.MainCapacitorMJLimit,0,1)
				draw.RoundedBox( FrameMargin, Main_Cap_X, Main_Cap_Y, Main_Cap_W*Main_Cap_Bar, Main_Cap_H, Color(200,255,255,200) )
			end
			
		end
		
		button.Paint = function( ButtonSelf, w, h )
			if not IsValid(Unit) then return end
			if ButtonSelf:IsHovered() then
				ButtonSelf.ButtonCol = Color(10,200,255,100)
				if input.IsMouseDown( MOUSE_LEFT ) then
					ButtonSelf.ButtonCol = Color(255,200,130,150)
					if not ButtonSelf.Down then
						if Frame.ItemSelected == ButtonSelf then Frame.ItemSelected = nil else Frame.ItemSelected = ButtonSelf end
						ButtonSelf.Down = true
						EmitSound( "ahee_suit/fire_warning.wav", Vector(), -1, CHAN_STATIC, 0.25, 60, 0, 230 )
					end
				else
					if ButtonSelf.Down then
						ButtonSelf.Down = false
					end
				end
			else
				if Frame.ItemSelected == ButtonSelf then 
					ButtonSelf.ButtonCol = Color(255,200,130,150)
				else 
					ButtonSelf.ButtonCol = Color(30,140,60,100)
				end
				
				if ButtonSelf.Down then
					ButtonSelf.Down = false
				end
			end
			
			draw.RoundedBox( FrameMargin, FrameMargin/2, FrameMargin/2, w-FrameMargin, h-FrameMargin, ButtonSelf.ButtonCol )
			
			--Health
			local Health_W, Health_H = w*0.75, h*0.05
			local Health_X, Health_Y = w*0.2325,  h*0.55
			local Health_Bar = math.Clamp(Unit:Health()/Unit:GetMaxHealth(),0,1)
			draw.RoundedBox( FrameMargin, Health_X, Health_Y, Health_W, Health_H, Color(110,0,0,200) )
			draw.RoundedBox( FrameMargin, Health_X, Health_Y, Health_W*Health_Bar, Health_H, Color(200,120,0,180) )
			
			--Shield_Buffer
			local Shield_W, Shield_H = w*0.75, h*0.05
			local Shield_X, Shield_Y = w*0.2325,  h*0.65
			draw.RoundedBox( FrameMargin, Shield_X, Shield_Y, Shield_W, Shield_H, Color(0,0,100,200) )
			
			if Unit.ShieldingBufferEnergy then
				local Shield_Bar = math.Clamp(Unit.ShieldingBufferEnergy/Unit.ShieldingBufferEnergyLimit,0,1)
				draw.RoundedBox( FrameMargin, Shield_X, Shield_Y, Shield_W*Shield_Bar, Shield_H, Color(0,50,255,100) )
			end
			
			--Shield_List
			local ShieldList_W, ShieldList_H = w*0.75, h*0.05
			local ShieldList_X, ShieldList_Y = w*0.2325,  h*0.65
			
			for i=1, 7 do
				local Local_Bar_Margin = (ShieldList_W/7)/3
				local Local_Bar_Size = (ShieldList_W/7) - Local_Bar_Margin
				local Local_X_Pos = ShieldList_X + (Local_Bar_Size+Local_Bar_Margin)*(i-1)
				draw.RoundedBox( FrameMargin, Local_X_Pos+(Local_Bar_Margin/2), ShieldList_Y, Local_Bar_Size, ShieldList_H, Color( (math.abs(math.sin((SysTime()+i)*7/2))*200) , 0 , 0 , 40 ) )
			end
			
			if Unit.ShieldingList then
				local Local_Bar_Margin = (ShieldList_W/#Unit.ShieldingList)/3
				local Local_Bar_Size = (ShieldList_W/#Unit.ShieldingList) - Local_Bar_Margin
				
				for Key, Value in pairs(Unit.ShieldingList) do
					
					local Local_X_Pos = ShieldList_X + (Local_Bar_Size+Local_Bar_Margin)*(Value[1]-1)
					local ShieldList_Bar = math.Clamp(Value[3]/Value[4],0,1)
					draw.RoundedBox( FrameMargin/5, Local_X_Pos+(Local_Bar_Margin/2), ShieldList_Y, Local_Bar_Size, ShieldList_H, Color(255,255,255,40) )
					
				end
				
			end
			
			--Shield_Stability
			local Shield_Stability_W, Shield_Stability_H = w*0.75, h*0.05
			local Shield_Stability_X, Shield_Stability_Y = w*0.2325,  h*0.75
			draw.RoundedBox( FrameMargin, Shield_Stability_X, Shield_Stability_Y, Shield_Stability_W, Shield_Stability_H, Color(0,0,0,200) )
			
			if Unit.Fraise_Stability then
				local Shield_Stability_Bar = math.Clamp(Unit.Fraise_Stability/100,0,1)
				draw.RoundedBox( FrameMargin, Shield_Stability_X, Shield_Stability_Y, Shield_Stability_W*Shield_Stability_Bar, Shield_Stability_H, Color(150,200,255,100) )
			end
			
			
		end
		
		return button
	end
	
	for Index, Value in ipairs(A9_TeamList) do
		local button = Create_PseudoTeam_Button( Index )
		grid:AddItem( button )
	end
	
	EmitSound( "ahee_suit/ahee_system_map_long.mp3", Vector(), -1, CHAN_STATIC, 0.5, 60, 0, 200 )
	
	local Scroll,UpAmount,ListVelocity = 0, 0, 0
	
	grid.Paint = function( Main, w, h ) 
		if self.AHEEMENU_ISOPEN then
			local ListHeight = (#grid:GetItems() * GridSizes*0.2) - (FrameSizeH - Grid_YDistance*2)
			local Scrolled = input.GetAnalogValue( ANALOG_MOUSE_WHEEL )
			Scroll = Scroll and (Scroll - ((Scroll - Scrolled) * 1)) or 0
			ListVelocity = ListVelocity and (ListVelocity * 0.1) + ((Scroll - Scrolled) * RealFrameTime()) or 0
			UpAmount = UpAmount and math.Clamp( UpAmount + ListVelocity , 0 , 1 ) or 0
			
			grid:SetPos( 0, 0 - (ListHeight*UpAmount) )
		end
	end
	
	Frame.Paint = function( Main, w, h )
		if not (FrameWidthPosCurrent) then return end
		if not self:GetNWBool("AHEE_EQUIPED") then Frame:Remove() return end
		
		local FrameWidthPosDesired = SymBackingX
		local Desired = math.Round( (FrameWidthPosDesired - FrameWidthPosCurrent) * 0.5 , 1 )
		
		if Desired ~= 0 then
			FrameWidthPosCurrent = math.Clamp( FrameWidthPosCurrent + Desired , -FrameSizeW , FrameSizeW*2 )
			Frame:SetPos( FrameWidthPosCurrent , SymBackingY )
		end
		
		surface.SetFont("Default")
		
		local FrameText = "Local Team"
		local FrameTextX, FrameTextY = surface.GetTextSize( FrameText )
		
		local TitleSizeX, TitleSizeY = FrameSizeW/6, FrameSizeH/12
		local TitlePositionX, TitlePositionY = (FrameSizeW/2) - (TitleSizeX/2), (FrameSizeH) - (TitleSizeY) - FrameMargin
		
		local TextMargin = FrameMargin*2
		local TextPositionX, TextPositionY = (FrameSizeW/2) - (FrameTextX/2), (TitleSizeY/2) - (TextMargin/2)
		
		draw.RoundedBox( FrameMargin, 0, 0, w, h, Color(0,0,0,100) )
		draw.RoundedBox( FrameMargin, FrameMargin/2, FrameMargin/2, w-FrameMargin, h-FrameMargin, Color(0,0,0,100) )
		
		draw.RoundedBox( FrameMargin/10, TextPositionX - (TextMargin/2) , TextPositionY - (TextMargin/2) , FrameTextX + TextMargin , FrameTextY + TextMargin , Color(255,255,255,200) )
		draw.SimpleText( FrameText, "Default", (FrameSizeW/2) , TextPositionY + (FrameTextY/2) , Color(0,0,0,240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		
		if #A9_TeamList != A9_TeamList_Local_Num then
			A9_TeamList_Local_Num = #A9_TeamList
			Frame:Remove()
			
			EmitSound( "ahee_suit/ahee_system_map_long.mp3", Vector(), -1, CHAN_STATIC, 0.75, 60, 0, 200 )
		end
		
	end
	
	return Frame
end

