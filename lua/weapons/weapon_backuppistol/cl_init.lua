include("shared.lua")
local mat = Material("models/weapons/backuppistol/bpistol_sheet")
local illumtint = mat:GetVector("$selfillumtint")
local colvec = Vector(1,1,1)
SWEP.Slot = 1
SWEP.SlotPos = 0
SWEP.PrintName = "Backup Pistol"
SWEP.Category = "Scavenger Deathmatch"
killicon.Add("weapon_backuppistol","hud/weapons/weapon_backuppistol",color_white)

local selecttex = surface.GetTextureID("hud/weapons/weapon_backuppistol")
function SWEP:DrawWeaponSelection(x,y,w,h,a)
	surface.SetTexture(selecttex)
	local size = math.min(w,h)
	surface.SetDrawColor(255,255,255,a)
	surface.DrawTexturedRect(x+(w-size)/2,y+(h-size)/2,size,size)
end

function SWEP:PreDrawViewModel(vm,wep,pl)
	if wep:GetClass() != "weapon_backuppistol" then
		return
	end
	local ctime = CurTime()
	local glowamt = wep:GetGlowAmount()
	colvec.x = glowamt
	colvec.y = glowamt
	colvec.z = glowamt
	mat:SetVector("$selfillumtint",colvec)
end

function SWEP:PostDrawViewModel(vm,wep,pl)
	if wep:GetClass() != "weapon_backuppistol" then
		return
	end
	mat:SetVector("$selfillumtint",illumtint)
end

function SWEP:GetGlowAmount()
	return math.Clamp((self.dt.Charges/self.MaxCharge+math.Clamp(self.LastFired+1-CurTime(),0,1)+0.3)*1.3,0.3,1.7)
end

function SWEP:DrawWorldModel()
	local glowamt = self:GetGlowAmount()
	colvec.x = glowamt
	colvec.y = glowamt
	colvec.z = glowamt
	mat:SetVector("$selfillumtint",colvec)
	self:DrawModel()
	mat:SetVector("$selfillumtint",illumtint)
end

local PANEL = {}
PANEL.Weapon = NULL

function PANEL:Init()
	self.AmmoLabel = vgui.Create("DLabel",self)
	self.AmmoLabel:SetFont("Scav_HUDNumber5")
	self.Initialized = true
end

function PANEL:SetWeapon(wep)
	self.Weapon = wep
end

function PANEL:AutoSetup()
	self:SetSize(128,64)
	self:SetPos(ScrW()-self:GetWide()-32,ScrH()-self:GetTall()-16)
end

function PANEL:Think()
	if !IsValid(LocalPlayer():GetActiveWeapon()) || (LocalPlayer():GetActiveWeapon() != self.Weapon) then
		self:SetVisible(false)
	else
		self.AmmoLabel:SetText(self.Weapon:GetAmmo())
		self:InvalidateLayout()
	end
end

function PANEL:InvalidateLayout()
	if !self.Initialized then
		return
	end
	self.AmmoLabel:SizeToContents()
	self.AmmoLabel:SetPos((self:GetWide()-self.AmmoLabel:GetWide())/2,(self:GetTall()-self.AmmoLabel:GetTall())/2)
end

vgui.Register("scav_HUDBPistol",PANEL,"DPanel")

SWEP.HUD = vgui.Create("scav_HUDBPistol")
SWEP.HUD:AutoSetup()
SWEP.HUD:SetVisible(false)
SWEP.HUD:SetSkin("sg_menu")