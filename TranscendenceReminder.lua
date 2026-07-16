local _, playerClass = UnitClass("player")
if playerClass ~= "MONK" then return end

local warned = false
local readyCheckActive = false

local function HasTranscendence()
    -- 12.1: aura APIs hard-error while auras are secret (combat/encounters).
    -- Treat unreadable as "has it" so the banner never nags mid-fight.
    local ok, aura = pcall(AuraUtil.FindAuraByName, "Transcendence", "player")
    return not ok or aura
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
banner:SetAlpha(0)
banner:EnableMouse(false)

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

local glowAG = banner:CreateAnimationGroup()
glowAG:SetLooping("REPEAT")
do
    local a1 = glowAG:CreateAnimation("Alpha")
    a1:SetFromAlpha(1)
    a1:SetToAlpha(0.5)
    a1:SetDuration(0.8)
    a1:SetOrder(1)
    a1:SetSmoothing("IN_OUT")

    local a2 = glowAG:CreateAnimation("Alpha")
    a2:SetFromAlpha(0.5)
    a2:SetToAlpha(1)
    a2:SetDuration(0.8)
    a2:SetOrder(2)
end

-- =====================================================
-- Show / Hide
-- =====================================================

-- The banner is a SecureActionButton (click it to cast Transcendence), so it
-- cannot be :Show()/:Hide()'d while in combat lockdown. Instead it stays
-- permanently shown and visibility is faked with alpha, which is combat-legal
-- — so a ready check that fires mid-combat still displays the banner.
--
-- EnableMouse is ALSO protected on a secure button during combat lockdown
-- (confirmed via ADDON_ACTION_BLOCKED in the wild), so the mouse state is
-- only applied out of combat and reconciled on PLAYER_REGEN_ENABLED. Mid-
-- combat the banner is visual-only; click-to-cast re-arms when combat drops.
local bannerShown = false

local function ApplyBanner()
    if bannerShown then
        banner:SetAlpha(1)
        if not glowAG:IsPlaying() then glowAG:Play() end
    else
        if glowAG:IsPlaying() then glowAG:Stop() end
        banner:SetAlpha(0)
    end
    if not InCombatLockdown() then
        banner:EnableMouse(bannerShown)
    end
end

local function ShowBanner()
    bannerShown = true
    ApplyBanner()
    PlaySound(8959)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff88[TranscendenceReminder]|r Place Transcendence!")
end

local function HideBanner()
    bannerShown = false
    ApplyBanner()
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
frame:RegisterUnitEvent("UNIT_AURA", "player")
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
        -- Apply the mouse state that couldn't be changed during combat.
        banner:EnableMouse(bannerShown)
    elseif event == "UNIT_AURA" then
        if readyCheckActive then
            UpdateVisibility()
        end
    end
end)
