local SynastriaCoreLib = LibStub('SynastriaCoreLib-1.0')
local AceTimer = LibStub("AceTimer-3.0")
local alertFrame = {af0,af1,af2,af3}
local timerHandle = {th0,th1,th2,th3}

local tooltip = CreateFrame("GameTooltip", "ItemTooltipScanner", nil, "GameTooltipTemplate")
tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

local function IsGoodBinding(itemLink)
    if not itemLink then return false end
    tooltip:ClearLines()
    tooltip:SetHyperlink(itemLink)
    for i = 1, tooltip:NumLines() do
        local text = _G["ItemTooltipScannerTextLeft" .. i]:GetText()
        if text and (text:find(ITEM_BIND_ON_PICKUP) or text:find("Binds to account")) then
            return false
        end
    end
    return true
end

local function filterItem(itemLink)
	return SynastriaCoreLib.IsAttunableBySomeone(itemLink) and IsGoodBinding(itemLink) and (not(SynastriaCoreLib.IsAttuned(itemLink)))
end

local function HideFlashAlert()
    for num, frame in ipairs(alertFrame) do
        frame:Hide()
        frame:ClearAllPoints()
        frame:SetParent(nil) -- Detach from UI
		alertFrame[num] = nil -- Properly remove from table
    end
end

local function FlashAlert(num,itemLink)
	local ver = 100
	local hor = 100
	local itemName, _, itemRarity, _, _, _, _, _, _, itemIcon = GetItemInfo(itemLink)
    if not alertFrame[num] then
        alertFrame[num] = CreateFrame("Frame", nil, UIParent)
        alertFrame[num]:SetSize(200, 200)
		if num > 2 then ver = -100 end
		if num % 2 == 1 then hor = -100 end
		--print("num: " ..num.." x: "..hor.." y: "..ver.." name: "..itemName)
        alertFrame[num]:SetPoint("CENTER", UIParent, "CENTER", hor, ver)
       
	   -- Item icon texture
        alertFrame[num].itemTexture = alertFrame[num]:CreateTexture(nil, "BACKGROUND")
		alertFrame[num].itemTexture:SetSize(180, 180) -- Set an explicit size smaller than the frame
		alertFrame[num].itemTexture:SetPoint("CENTER", alertFrame[num], "CENTER", 0, 0) -- Center it
		alertFrame[num].itemTexture:SetTexture(itemIcon)
		alertFrame[num].itemTexture:SetTexCoord(0.07, 0.93, 0.07, 0.93) -- Crops the edges better
				
        -- Quest bang icon
        alertFrame[num].texture = alertFrame[num]:CreateTexture(nil, "ARTWORK")
        alertFrame[num].texture:SetAllPoints()
        alertFrame[num].texture:SetTexture("Interface/ContainerFrame/UI-Icon-QuestBang")
		
		-- Rarity border
		local rarityColors = {
        [0] = {0.62, 0.62, 0.62}, -- Poor (Gray)
        [1] = {1, 1, 1}, -- Common (White)
        [2] = {0, 1, 0}, -- Uncommon (Green)
        [3] = {0, 0.44, 0.87}, -- Rare (Blue)
        [4] = {0.64, 0.21, 0.93}, -- Epic (Purple)
        [5] = {1, 0.5, 0}, -- Legendary (Orange)
        [6] = {0.9, 0.8, 0.5}, -- Artifact (Gold)
		}
		local borderColor = rarityColors[itemRarity] or {1, 1, 1} -- Default to white if rarity is unknown
		-- Create a border texture
		alertFrame[num].border = alertFrame[num]:CreateTexture(nil, "OVERLAY")
		alertFrame[num].border:SetTexture("Interface\\Buttons\\UI-Quickslot2") -- Item border texture
		alertFrame[num].border:SetPoint("CENTER", alertFrame[num], "CENTER", 0, -4)
		alertFrame[num].border:SetSize(330, 330) -- Slightly larger than frame for visibility
		alertFrame[num].border:SetVertexColor(unpack(borderColor)) -- Apply rarity color
    end
    alertFrame[num]:Show()
	if timerHandle[num] then
        AceTimer:CancelTimer(timerHandle[num])
    end
    timerHandle[num] = AceTimer:ScheduleTimer(HideFlashAlert, 2.5)
end

local function GetClickableName(sender,GUID)
	if GUID then
        local _, class = GetPlayerInfoByGUID(GUID) -- Get class of sender
        if class and RAID_CLASS_COLORS[class] and RAID_CLASS_COLORS[class].colorStr then
            return "|c" .. RAID_CLASS_COLORS[class].colorStr.."|Hplayer:" .. sender .. "|h" .. sender .. "|h|r"
		else
			return "|Hplayer:" .. sender .. "|h" .. sender .. "|h|r"
        end
	else
		return "|Hplayer:" .. sender .. "|h" .. sender .. "|h|r"
    end
end

local function chatAlert(itemLink,sender,senderGUID)
	local clickableName = GetClickableName(sender,senderGUID)
	print("|cffffcc00[BegAlert]: "..clickableName.."|cffffcc00 linked: "..itemLink)
end

local function sendAlerts(itemLink,sender,senderGUID,index)
	--local itemName = GetItemInfo(itemLink)
	chatAlert(itemLink,sender,senderGUID)
	if not(UnitAffectingCombat("player")) then
		FlashAlert(index,itemLink)
	end
end

local frame = CreateFrame("Frame")

frame:RegisterEvent("CHAT_MSG_SAY")
frame:RegisterEvent("CHAT_MSG_CHANNEL")
frame:RegisterEvent("CHAT_MSG_YELL")
frame:RegisterEvent("CHAT_MSG_GUILD")
frame:RegisterEvent("CHAT_MSG_PARTY")
frame:RegisterEvent("CHAT_MSG_PARTY_LEADER")
frame:RegisterEvent("CHAT_MSG_RAID")
frame:RegisterEvent("CHAT_MSG_RAID_LEADER")
frame:RegisterEvent("CHAT_MSG_WHISPER")

local function OnEvent(self, event, msg, sender, _, _, _, _, _, _, _, _, _, senderGUID)
	if sender == UnitName("player") then 
		return -- Ignore own messages
    end
    if (msg:lower():find("free") or msg:lower():find("anyone")) then
		local itemLinks = {}
		local i = 1
		for itemLink in string.gmatch(msg, "|c.-|Hitem:.-|h.-|h|r") do
			if filterItem(itemLink) then
				sendAlerts(itemLink,sender,senderGUID,i)
				i = i + 1
			end
		end
    end
end

frame:SetScript("OnEvent", OnEvent)





