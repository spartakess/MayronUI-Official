-- luacheck: ignore MayronUI self 143 631
local tk, db, em, _, obj = MayronUI:GetCoreComponents();

-- Objects ---------------------------

local Engine = obj:Import("MayronUI.Engine");
local CombatTimer = Engine:CreateClass("CombatTimer", nil, "MayronUI.Engine.IDataTextModule");

-- CombatTimer Module ----------------

MayronUI:Hook("DataTextModule", "OnInitialize", function(self)
    self:RegisterDataModule("combatTimer", CombatTimer);
end);

function CombatTimer:__Construct(data, settings, dataTextModule)
    data.settings = settings;

    -- set public instance properties
    self.MenuContent = _G.CreateFrame("Frame");
    self.MenuLabels = obj:PopTable();
    self.TotalLabelsShown = 0;
    self.HasLeftMenu = false;
    self.HasRightMenu = false;
    self.SavedVariableName = "combatTimer";

    local font = tk.Constants.LSM:Fetch("font", db.global.core.font);

    -- create datatext button
    self.Button = dataTextModule:CreateDataTextButton();

    data.seconds = self.Button:CreateFontString(nil, "ARTWORK", "MUI_FontNormal");
    data.seconds:SetFont(font, data.settings.fontSize);

    data.minutes = self.Button:CreateFontString(nil, "ARTWORK", "MUI_FontNormal");
    data.minutes:SetFont(font, data.settings.fontSize);
    data.minutes:SetJustifyH("RIGHT");

    data.milliseconds = self.Button:CreateFontString(nil, "ARTWORK", "MUI_FontNormal");
    data.milliseconds:SetFont(font, data.settings.fontSize);
    data.milliseconds:SetJustifyH("LEFT");
    data.seconds:SetPoint("CENTER");
    data.minutes:SetPoint("RIGHT", data.seconds, "LEFT");
    data.milliseconds:SetPoint("LEFT", data.seconds, "RIGHT");
end

function CombatTimer:Click() end

function CombatTimer:IsEnabled(data)
    return data.enabled;
end

function CombatTimer:SetEnabled(data, enabled)
    data.enabled = false;

    if (not enabled) then
        em:CreateEventHandlerWithKey("PLAYER_REGEN_DISABLED", "DataText_CombatTimer_RegenDisabled", function()
            data.startTime = _G.GetTime();
            data.inCombat = true;
            data.executed = nil;
            self:Update();
        end);

        em:CreateEventHandlerWithKey("PLAYER_REGEN_ENABLED", "DataText_CombatTimer_RegenEnabled", function()
            data.inCombat = nil;
            data.minutes:SetText(data.minutes.value or "00");
            data.seconds:SetText(data.seconds.value or ":00:");
            data.milliseconds:SetText(data.milliseconds.value or "00");
        end);

        data.minutes:SetText("00");
        data.seconds:SetText(":00:");
        data.milliseconds:SetText("00");
    else
        -- Destroy
        em:DestroyEventHandlerByKey("DataText_CombatTimer_RegenDisabled");
        em:DestroyEventHandlerByKey("DataText_CombatTimer_RegenEnabled");

        data.minutes:SetText("");
        data.seconds:SetText("");
        data.milliseconds:SetText("");
    end
end

function CombatTimer:Update(data)
    if (data.executed) then
        return
    end

    data.executed = true;

    local function loop()
        if (not data.inCombat) then
            return
        end

        local s = (_G.GetTime() - data.startTime);

        data.minutes.value = tk.string.format("%02d", (s/60)%60);
        data.seconds.value = tk.string.format(":%02d:", s%60);
        data.milliseconds.value = tk.string.format("%02d", (s*100)%100);

        data.minutes:SetText(tk.string.format("%s%s|r", _G.RED_FONT_COLOR_CODE, data.minutes.value));
        data.seconds:SetText(tk.string.format("%s%s|r", _G.RED_FONT_COLOR_CODE, data.seconds.value));
        data.milliseconds:SetText(tk.string.format("%s%s|r", _G.RED_FONT_COLOR_CODE, data.milliseconds.value));

        tk.C_Timer.After(0.05, loop);
    end

    loop();
end