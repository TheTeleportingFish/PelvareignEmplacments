local string = string
local table = table
local error = error
local Material = Material
local baseclass = baseclass

module("invitem")

--Create a list of all inventory items.
local invitems = invitems or {}
local allitems = allitems or {}

--Create our root baseclass, with all items are based off somewhere down the line.
invitems.item_baseitem = {}
invitems.item_baseitem.Icon = Material("vgui/items/baseweapon.png")
invitems.item_baseitem.Name = "Base Item"
invitems.item_baseitem.Width = 1
invitems.item_baseitem.Height = 1
invitems.item_baseitem.Weight = 1
invitems.item_baseitem.Owner = NULL
invitems.item_baseitem.BaseClass = {}
invitems.item_baseitem.UniqueID = -1 --We set this when we create the object.
function invitems.item_baseitem:Init()

end
function invitems.item_baseitem:Remove()
	allitems[self.id] = nil
	self:OnRemove()
end
function invitems.item_baseitem:OnRemove()
	--This is the function we can override per-class.
end
-- These two functions are for the Grid-Based Inventory Tutorial, which this system is compatable with.
function invitems.item_baseitem:GetSize()
	return self.Width, self.Height
end
function invitems.item_baseitem:GetIcon()
	return self.Icon
end
--baseclass.Set is a GMod function. See lua/includes/modules/baseclass.lua
baseclass.Set("item_baseitem", invitems.item_baseitem)


--Saves a class to our internal list of items, and defines our class's baseclass.
function Register(classtbl, name)

	name = string.lower(name)
	
	baseclass.Set( name, classtbl )
	
	classtbl.BaseClass = baseclass.Get(classtbl.Base)
	
	invitems[ name ] = classtbl
	
end

--Our constructor, which takes an argument to determine the class.
function Create(class)
	--Prevent non-existant classes from being created.
	if not invitems[class] then error("Tried to create new inventory item from non-existant class: "..class) end
	
	local newItem = table.Copy(invitems[class])
	
	--Add our new object to the list of all items currently in the game.
	local id = table.insert(allitems, newItem)
	--Give it a unique ID.
	newItem.UniqueID = id
	
	--Call our Init function when we create the new item.
	newItem:Init()
	
	return newItem
end

--Returns a table of all classes.
function GetClasses()
	return invitems
end

--Returns the class table of a given class from our saved list.
function GetClassTable(classname)
	return invitems[classname]
end

--Returns a COPY of the class table, so we don't modify the original.
function GetClassTableCopy(classname)
	return table.Copy(invitems[classname])
end

--Returns a list of all current items objects.
function GetAll()
	return allitems
end