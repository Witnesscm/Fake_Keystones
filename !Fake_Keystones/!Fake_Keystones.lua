local addonName = "Fake_Keystones"

C_AddOns.EnableAddOn(addonName)
C_AddOns.LoadAddOn(addonName)

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    C_AddOns.EnableAddOn(addonName)
end)