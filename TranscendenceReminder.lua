local _, playerClass = UnitClass("player")
if playerClass ~= "MONK" then return end

local warned = false
local readyCheckActive = false

local function HasTranscendence()
    return AuraUtil.FindAuraByName("Transcendence", "player")
end

-- =====================================================
-- Banner Frame
-- =====================================================

local banner = CreateFrame("Button", "TranscendenceReminderBanner", UIParent, "SecureActionButtonTemplate, BackdropTemplate")
banner:SetSize(500, 70)
banner:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
banner:SetFrameStrata("HIGH")
banner:SetAttribute("type", "spell")
banner:SetAttribute("spell", "Transcendence")
banner:RegisterForClicks("AnyUp", "AnyDown")
banner:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
})
banner:SetBackdropColor(0.15, 0.4, 0.15, 0.9)
banner:SetBackdropBorderColor(0, 1, 0.5, 1)
banner:Hide()

local text = banner:CreateFontString(nil, "OVERLAY")
text:SetFont("Fonts\\FRIZQT__.TTF", 28, "OUTLINE")
text:SetPoint("CENTER", banner, "CENTER", 0, 0)
text:SetText("Place Transcendence!")
text:SetTextColor(0.3, 1, 0.6)

local icon1 = banner:CreateTexture(nil, "OVERLAY")
icon1:SetSize(48, 48)
icon1:SetPoint("RIGHT", text, "LEFT", -12, 0)
icon1:SetTexture("Interface\\Icons\\Monk_Ability_Transcendence")

local icon2 = banner:CreateTexture(nil, "OVERLAY")
icon2:SetSize(48, 48)
icon2:SetPoint("LEFT", text, "RIGHT", 12, 0)
icon2:SetTexture("Interface\\Icons\\Monk_Ability_Transcendence")

-- =====================================================
-- Animations (pulse + glow like Soulstone Reminder)
-- =====================================================

local pulseAG = banner:CreateAnimationGroup()
pulseAG:SetLooping("REPEAT")
do
    local up = pulseAG:CreateAnimation("Scale")
    up:SetScale(1.015, 1.015)
    up:SetDuration(0.8)
    up:SetOrder(1)

    local down = pulseAG:CreateAnimation("Scale")
    down:SetScale(0.985, 0.985)
    down:SetDuration(0.8)
    down:SetOrder(2)
end

local glowAG = banner:CreateAnimationGroup()
glowAG:SetLooping("REPEAT")
do
    local a1 = glowAG:CreateAnimation("Alpha")
    a1:SetFromAlpha(1)
    a1:SetToAlpha(0.6)
    a1:SetDuration(0.6)
    a1:SetOrder(1)

    local a2 = glowAG:CreateAnimation("Alpha")
    a2:SetFromAlpha(0.6)
    a2:SetToAlpha(1)
    a2:SetDuration(0.6)
    a2:SetOrder(2)
end

-- =====================================================
-- Show / Hide
-- =====================================================

local function ShowBanner()
    banner:Show()
    pulseAG:Play()
    glowAG:Play()
    PlaySound(8959)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff88[TranscendenceReminder]|r Place Transcendence!")
end

local function HideBanner()
    banner:Hide()
    if pulseAG:IsPlaying() then pulseAG:Stop() end
    if glowAG:IsPlaying() then glowAG:Stop() end
    banner:SetScale(1)
    banner:SetAlpha(1)
end

local function UpdateVisibility()
    if not readyCheckActive then
        HideBanner()
        return
    end
    if HasTranscendence() then
        readyCheckActive = false
        HideBanner()
        return
    end
    if not warned then
        warned = true
        ShowBanner()
    end
end

-- =====================================================
-- Events
-- =====================================================

local frame = CreateFrame("Frame")
frame:RegisterEvent("READY_CHECK")
frame:RegisterEvent("READY_CHECK_FINISHED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("UNIT_AURA")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "READY_CHECK" then
        if IsInRaid() then
            readyCheckActive = true
            warned = false
            UpdateVisibility()
        end
    elseif event == "READY_CHECK_FINISHED" then
        readyCheckActive = false
        HideBanner()
    elseif event == "PLAYER_REGEN_ENABLED" then
        warned = false
    elseif event == "UNIT_AURA" then
        local unit = ...
        if unit == "player" and readyCheckActive then
            UpdateVisibility()
        end
    end
end)
