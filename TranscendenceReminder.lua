local _, playerClass = UnitClass("player")
if playerClass ~= "MONK" then return end

local warned = false

local function HasTranscendence()
    return AuraUtil.FindAuraByName("Transcendence", "player")
end

local function Warn()
    if warned then return end
    if HasTranscendence() then return end
    warned = true
    UIErrorsFrame:AddMessage("Place Transcendence!", 1, 0.2, 0.2, nil, 3)
    PlaySound(8959)
    DEFAULT_CHAT_FRAME:AddMessage("|cffff3333[TranscendenceReminder]|r Place Transcendence!")
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("READY_CHECK")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:SetScript("OnEvent", function(self, event)
    if event == "READY_CHECK" then
        if IsInRaid() then Warn() end
    elseif event == "PLAYER_REGEN_ENABLED" then
        warned = false
    end
end)
