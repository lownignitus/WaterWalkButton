-- Title: Water Walk Button
-- Author: LownIgnitus
-- Version: 1.0.0
-- Desc: Standalone button for Shaman/Death Knight water walk spells

CF = CreateFrame
SLASH_WATERWALKBUTTON1, SLASH_WATERWALKBUTTON2 = '/wwb', '/WWB'
local addon_name = "WaterWalkButton"
local wwbFrameBG = { bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background.blp", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border.blp", tile = true, tileSize = 32, edgeSize = 16, insets = {left = 3, right = 3, top = 3, bottom = 3}}
local wwbFrame, wwbPlayerClass, class, enClass, classIndex 

local wwbEvents_table = {}

wwbEvents_table.eventFrame = CF("Frame")
wwbEvents_table.eventFrame:RegisterEvent("ADDON_LOADED")
wwbEvents_table.eventFrame:SetScript("OnEvent", function(self, event, ...)
	wwbEvents_table.eventFrame[event](self, ...)
end)

function wwbEvents_table.eventFrame:ADDON_LOADED(AddOn)
	if AddOn ~= addon_name then
		return
	end

	wwbEvents_table.eventFrame:UnregisterEvent("ADDON_LOADED")

	local defaults = {
		["options"] = {
			["wwbLock"] = true,
			["wwbScale"] = 1,
			["wwbAlpha"] = 0,
			["wwbMouseOver"] = false,
			["wwbHidden"] = false,
		}
	}

	local function wwbSVCheck(src, dst)
		if type(src) ~= "table" then return {} end
		if type(dst) ~= "table" then dst = {} end
		for k, v in pairs(src) do
			if type(v) == "table" then
				dst[k] = wwbSVCheck(v,dst[k])
			elseif type(v) ~= type(dst[k]) then
				dst[k] = v
			end
		end
		return dst
	end

	wwbSettings = wwbSVCheck(defaults, wwbSettings)

	wwbMainFrame()
	wwbOptionsInit()
	wwbInitialize()
end

function wwbMainFrame()
	wwbFrame = CF("Frame", "wwbFrame", UIParent)
	wwbFrame:SetPoint("CENTER", UIParent, "CENTER")
	wwbFrame:SetFrameStrata("BACKGROUND")
	wwbFrame:SetBackdrop(wwbFrameBG)
	wwbFrame:SetSize(44, 44)

	wwbFrame:SetMovable(true)
	wwbFrame:SetClampedToScreen(true)
	wwbFrame:EnableMouse(true)
	wwbFrame:RegisterForDrag("LeftButton")
	wwbFrame:SetScript("OnDragStart", wwbFrame.StartMoving)
	wwbFrame:SetScript("OnDragStop", wwbFrame.StopMovingOrSizing)

	wwbFrame:SetScript("OnEnter", function(self) wwbMouseOverEnter() end)
	wwbFrame:SetScript("OnLeave", function(self) wwbMouseOverLeave() end)

	wwbFrame:Show()
end

function wwbOptionsInit()
	local wwbOptions = CF("Frame", nil, InterfaceOptionsFramePanelContainer);
	local panelWidth = InterfaceOptionsFramePanelContainer:GetWidth() -- ~623
	local wideWidth = panelWidth - 40
	wwbOptions:SetWidth(wideWidth)
	wwbOptions:Hide();
	wwbOptions.name = "|cff00ff00Water Walk Button|r"
	wwbOptionsBG = { edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, edgeSize = 16 }

	-- Special thanks to Ro for inspiration for the overall structure of this options panel (and the title/version/description code)
	local function createfont(fontName, r, g, b, anchorPoint, relativeto, relativePoint, cx, cy, xoff, yoff, text)
		local font = wwbOptions:CreateFontString(nil, "BACKGROUND", fontName)
		font:SetJustifyH("LEFT")
		font:SetJustifyV("TOP")
		if type(r) == "string" then -- r is text, not position
			text = r
		else
			if r then
				font:SetTextColor(r, g, b, 1)
			end
			font:SetSize(cx, cy)
			font:SetPoint(anchorPoint, relativeto, relativePoint, xoff, yoff)
		end
		font:SetText(text)
		return font
	end

	-- Special thanks to Hugh & Simca for checkbox creation 
	local function createcheckbox(text, cx, cy, anchorPoint, relativeto, relativePoint, xoff, yoff, frameName, font)
		local checkbox = CF("CheckButton", frameName, wwbOptions, "UICheckButtonTemplate")
		checkbox:SetPoint(anchorPoint, relativeto, relativePoint, xoff, yoff)
		checkbox:SetSize(cx, cy)
		local checkfont = font or "GameFontNormal"
		checkbox.text:SetFontObject(checkfont)
		checkbox.text:SetText(" " .. text)
		return checkbox
	end
	
	--GameFontNormalHuge GameFontNormalLarge 
	local title = createfont("SystemFont_OutlineThick_WTF", GetAddOnMetadata(addon_name, "Title"))
	title:SetPoint("TOPLEFT", 16, -16)
	local ver = createfont("SystemFont_Huge1", GetAddOnMetadata(addon_name, "Version"))
	ver:SetPoint("BOTTOMLEFT", title, "BOTTOMRIGHT", 4, 0)
	local date = createfont("GameFontNormalLarge", "Version Date: " .. GetAddOnMetadata(addon_name, "X-Date"))
	date:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	local author = createfont("GameFontNormal", "Author: " .. GetAddOnMetadata(addon_name, "Author"))
	author:SetPoint("TOPLEFT", date, "BOTTOMLEFT", 0, -8)
	local website = createfont("GameFontNormal", "Website: " .. GetAddOnMetadata(addon_name, "X-Website"))
	website:SetPoint("TOPLEFT", author, "BOTTOMLEFT", 0, -8)
	local contact = createfont("GameFontNormal", "Contact: " .. GetAddOnMetadata(addon_name, "X-Contact"))
	contact:SetPoint("TOPLEFT", website, "BOTTOMLEFT", 0, -8)
	local desc = createfont("GameFontHighlight", GetAddOnMetadata(addon_name, "Notes"))
	desc:SetPoint("TOPLEFT", contact, "BOTTOMLEFT", 0, -8)

	-- Misc Options Frame
	local wwbMiscFrame = CF("Frame", WWBMiscFrame, wwbOptions)
	wwbMiscFrame:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -8)
	wwbMiscFrame:SetBackdrop(wwbOptionsBG)
	wwbMiscFrame:SetSize(240, 240)

	local miscTitle = createfont("GameFontNormal", nil, nil, nil, "TOP", wwbMiscFrame, "TOP", 150, 16, 0, -8, "Miscellaneous Options")

	-- Enable Mouseover
	local wwbMouseOverOpt = createcheckbox("Enable Mouseover of WWB.", 18, 18, "TOPLEFT", miscTitle, "TOPLEFT", -40, -16, "wwbMouseOverOpt")

	wwbMouseOverOpt:SetScript("OnClick", function(self)
		if wwbMouseOverOpt:GetChecked() == true then
			wwbSettings.options.wwbMouseOver = true
			wwbFrame:SetAlpha(wwbSettings.options.wwbAlpha)
			ChatFrame1:AddMessage("Mouseover |cff00ff00enabled|r!")
		else
			wwbSettings.options.wwbMouseOver = false
			wwbFrame:SetAlpha(1)
			ChatFrame1:AddMessage("Mouseover |cffff0000disabled|r!")
		end
	end)

	-- Lock Button Position
	local wwbLockBtnOpt = createcheckbox("Lock the Water Walk Button.", 18, 18, "TOPLEFT", wwbMouseOverOpt, "BOTTOMLEFT", 0, 0, "wwbLockBtnOpt")

	wwbLockBtnOpt:SetScript("OnClick", function(self) wwbLocker() end)

	-- Hide Button Frame
	local wwbHideBtnOpt = createcheckbox("Hide the Water Walk Button.", 18, 18, "TOPLEFT", wwbLockBtnOpt, "BOTTOMLEFT", 0, 0, "wwbHideBtnOpt")

	wwbHideBtnOpt:SetScript("OnClick", function(self) wwbToggle() end)

	-- Scale Frame
	local wwbScaleFrame = CF("Frame", "WWBScaleFrame", wwbOptions)
	wwbScaleFrame:SetPoint("TOPLEFT", wwbMiscFrame, "TOPRIGHT", 8, 0)
	wwbScaleFrame:SetBackdrop(wwbOptionsBG)
	wwbScaleFrame:SetSize(150, 75)

	-- Scale Slider
	local wwbScale = CF("Slider", "WWBScale", wwbScaleFrame, "OptionsSliderTemplate")
	wwbScale:SetSize(120, 16)
	wwbScale:SetOrientation('HORIZONTAL')
	wwbScale:SetPoint("TOP", wwbScaleFrame, "TOP", 0, -25)

	_G[wwbScale:GetName() .. 'Low']:SetText('0.5') -- Sets left side of slider text [default is "Low"]
	_G[wwbScale:GetName() .. 'High']:SetText('1.5') -- Sets right side of slider text [default is "High"]
	_G[wwbScale:GetName() .. 'Text']:SetText('|cffFFCC00Scale|r') -- Sets the title text [top-center of slider]

	wwbScale:SetMinMaxValues(0.5, 1.5)
	wwbScale:SetValueStep(0.05);

	-- Scale Display Editbox
	local wwbScaleDisplay = CF("Editbox", "WWBScaleDisplay", wwbScaleFrame, "InputBoxTemplate")
	wwbScaleDisplay:SetSize(32, 16)
	wwbScaleDisplay:ClearAllPoints()
	wwbScaleDisplay:SetPoint("TOP", wwbScale, "BOTTOM", 0, -10)
	wwbScaleDisplay:SetAutoFocus(false)
	wwbScaleDisplay:SetEnabled(false)
	wwbScaleDisplay:SetText(wwbSettings.options.wwbScale)

	wwbScale:SetScript("OnValueChanged", function(self, value)
		value = floor(value/0.05)*0.05
		wwbFrame:SetScale(value)
		wwbSettings.options.wwbScale = value
		wwbScaleDisplay:SetText(wwbSettings.options.wwbScale)
	end);

	-- Alpha Frame
	local wwbAlphaFrame = CF("Frame", "WWBAlphaFrame", wwbOptions)
	wwbAlphaFrame:SetPoint("TOPLEFT", wwbScaleFrame, "TOPRIGHT", 8, 0)
	wwbAlphaFrame:SetBackdrop(wwbOptionsBG)
	wwbAlphaFrame:SetSize(150, 75)

	-- Alpha Slider
	local wwbAlpha = CF("Slider", "WWBAlpha", wwbAlphaFrame, "OptionsSliderTemplate")
	wwbAlpha:SetSize(120, 16)
	wwbAlpha:SetOrientation('HORIZONTAL')
	wwbAlpha:SetPoint("TOP", wwbAlphaFrame, "TOP", 0, -25)

	_G[wwbAlpha:GetName() .. 'Low']:SetText('0') -- Sets left side of slider text [default is "Low"]
	_G[wwbAlpha:GetName() .. 'High']:SetText('1') -- Sets right side of slider text [default is "High"]
	_G[wwbAlpha:GetName() .. 'Text']:SetText('|cffFFCC00Minimum Alpha|r') -- Sets the title text [top-center of slider]

	wwbAlpha:SetMinMaxValues(0, 1)
	wwbAlpha:SetValueStep(0.05);

	-- Alpha Display Editbox
	local wwbAlphaDisplay = CF("Editbox", "WWBScaleDisplay", wwbAlphaFrame, "InputBoxTemplate")
	wwbAlphaDisplay:SetSize(32, 16)
	wwbAlphaDisplay:ClearAllPoints()
	wwbAlphaDisplay:SetPoint("TOP", wwbAlpha, "BOTTOM", 0, -10)
	wwbAlphaDisplay:SetAutoFocus(false)
	wwbAlphaDisplay:SetEnabled(false)
	wwbAlphaDisplay:SetText(wwbSettings.options.wwbAlpha)

	wwbAlpha:SetScript("OnValueChanged", function(self, value)
		value = floor(value/0.05)*0.05
		wwbSettings.options.wwbAlpha = value
		if wwbSettings.options.wwbMouseOver == true then
			wwbFrame:SetAlpha(wwbSettings.options.wwbAlpha)
		end
		wwbAlphaDisplay:SetText(wwbSettings.options.wwbAlpha)
	end);

	wwbOptions.refresh = function()
		wwbScale:SetValue(wwbSettings.options.wwbScale);
		wwbAlpha:SetValue(wwbSettings.options.wwbAlpha);
	end

	function wwbOptions.okay()
		wwbOptions.Hide()
	end

	function wwbOptions.cancel()
		wwbOptions.Hide()
	end

	function wwbOptions.default()
		wwbReset()
	end

	InterfaceOptions_AddCategory(wwbOptions)
end

function wwbMakeButton(classIndex)
	local name,icon
	local wwbBtn = CF("Button", nil, wwbFrame, "SecureActionButtonTemplate")
	wwbBtn:SetFrameStrata("BACKGROUND")
	wwbBtn:SetPoint("CENTER", wwbFrame, "CENTER", 0, 0)
	wwbBtn:SetSize(34, 34)
	wwbBtn:EnableMouse(true)
	wwbBtn:SetHighlightTexture("Interface\\Button\\UI-Common-MouseHilight")
	wwbBtn:SetAttribute("type", "spell")
	if classIndex == 6 then
		name, _, icon, _, _, _, _ = GetSpellInfo(3714)
		wwbBtn:SetAttribute("spell", name)
		wwbBtn:SetNormalTexture(icon)
	elseif classIndex == 7 then
		name, _, icon, _, _, _, _ = GetSpellInfo(546)
		wwbBtn:SetAttribute("spell", name)
		wwbBtn:SetNormalTexture(icon)
	end
end

function wwbInitialize()
	-- 0=none, 1=Warrior, 2=Paladin, 3=Hunter, 4=Rogue, 5=Priest, 6=DK, 7=Shaman, 8=Mage, 9=Warlock, 10=Monk, 11=Druid, 12=DH
	class, enClass, classIndex = UnitClass("player")

	wwbFrame:SetScale(wwbSettings.options.wwbScale)

	if wwbSettings.options.wwbLock == true then
		wwbFrame:EnableMouse(true)
		wwbLockBtnOpt:SetChecked(false)
	else
		wwbFrame:EnableMouse(false)
		wwbLockBtnOpt:SetChecked(true)
	end

	if wwbSettings.options.wwbHidden == true then
		wwbFrame:Hide()
		wwbHideBtnOpt:SetChecked(true)
	else
		wwbFrame:Show()
		wwbHideBtnOpt:SetChecked(false)
	end

	if wwbSettings.options.wwbMouseOver == true then
		wwbMouseOverOpt:SetChecked(true)
		wwbFrame:SetAlpha(wwbSettings.options.wwbAlpha)
	else
		wwbMouseOverOpt:SetChecked(false)
		wwbMouseOverOpt:SetChecked(false)
	end

	if classIndex == 6 or classIndex == 7 then
		wwbMakeButton(classIndex)
	else
		wwbFrame:Hide()
	end
end

function wwbMouseOverEnter()
	if wwbSettings.options.wwbMouseOver == true then
		wwbFrame:SetAlpha(1)
	end
end

function wwbMouseOverLeave()
	if wwbSettings.options.wwbMouseOver == true then
		wwbFrame:SetAlpha(wwbSettings.options.wwbMouseOver)
	end
end

function wwbToggle()
	if wwbSettings.options.wwbHidden == false then
		wwbFrame:Hide()
		ChatFrame1:AddMessage("Water Walk Button |cffff0000hidden|r!")
		wwbSettings.options.wwbHidden = true
		wwbHideBtnOpt:SetChecked(true)
	else
		wwbFrame:Show()
		ChatFrame1:AddMessage("Water Walk Button |cff00ff00visible|r!")
		wwbSettings.options.wwbHidden = false
		wwbHideBtnOpt:SetChecked(false)
	end
end

function wwbLocker()
	if wwbSettings.options.wwbLock == true then
		wwbSettings.options.wwbLock = false
		wwbLockBtnOpt:SetChecked(true)
		wwbFrame:EnableMouse(false)
		ChatFrame1:AddMessage("Water Walk Button |cffff0000locked|r!")
	else
		wwbSettings.options.wwbLock = true
		wwbLockBtnOpt:SetChecked(false)
		wwbFrame:EnableMouse(true)
		ChatFrame1:AddMessage("Water Walk Button |cff00ff00unlock|r!")
	end
end

function wwbOption()
	InterfaceOptionsFrame_OpenToCategory("|cff00ff00Water Walk Button|r")
end

function wwbInfo()
	ChatFrame1:AddMessage(GetAddOnMetadata(addon_name, "Title") .. " " .. GetAddOnMetadata(addon_name, "Version") .. " on " .. GetAddOnMetadata(addon_name, "X-Date"))
	ChatFrame1:AddMessage("Author: " .. GetAddOnMetadata(addon_name, "Author"))
end

function SlashCmdList.WATERWALKBUTTON(msg, Editbox)
	if msg == "toggle" then
		wwbToggle()
	elseif msg == "lock" then
		wwbLocker()
	elseif msg == "options" then
		wwbOption()
	elseif msg == "info" then
		wwbInfo()
	else
		ChatFrame1:AddMessage("|cff71c671Water Walk Button|r")
		ChatFrame1:AddMessage("|cff71c671type /WWB followed by:|r")
		ChatFrame1:AddMessage("|cff71c671  -- toggle to toggle display of the button.|r")
		ChatFrame1:AddMessage("|cff71c671  -- lock to toggle locking the button in place.|r")
		ChatFrame1:AddMessage("|cff71c671  -- options to open to addon options.|r")
		ChatFrame1:AddMessage("|cff71c671  -- info to display current info for the addon.|r")
	end
end

PetBattleFrame:HookScript("OnShow", function() wwbFrame:Hide() end)
PetBattleFrame:HookScript("OnHide", function() if wwbSetting.options.wwbHidden == false then wwbFrame:Show() end end)