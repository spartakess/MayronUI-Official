local _, namespace = ...;
local tk = namespace.components.Toolkit; ---@type Toolkit

tk.Constants = {
    ASSETS_FOLDER = "Interface\\addons\\MUI_Core\\Assets";
    CLICK = 856;
    DUMMY_FUNC = function() end;
    DUMMY_FRAME = _G.CreateFrame("Frame");
    LOCALIZED_CLASS_NAMES = {};
    LOCALIZED_CLASS_FEMALE_NAMES = {};
    SOLID_TEXTURE = "Interface\\addons\\MUI_Core\\Assets\\Textures\\Widgets\\Solid";

    FONT = function()
        return tk.Constants.LSM:Fetch("font", namespace.components.Database.global.core.font);
    end;

    LSM = _G.LibStub("LibSharedMedia-3.0");

    BACKDROP = {
        edgeFile = "interface\\addons\\MUI_Core\\Assets\\Borders\\Solid",
        edgeSize = 1,
    };

    BACKDROP_WITH_BACKGROUND = {
      bgFile = "interface\\addons\\MUI_Core\\Assets\\Textures\\Widgets\\Solid",
      edgeFile = "interface\\addons\\MUI_Core\\Assets\\Borders\\Solid",
      edgeSize = 1,
  };

    POINTS = {
        LEFT = "LEFT";
        CENTER = "CENTER";
        RIGHT = "RIGHT";
        TOP = "TOP";
        BOTTOM = "BOTTOM";
        TOPLEFT = "TOPLEFT";
        TOPRIGHT = "TOPRIGHT";
        BOTTOMLEFT = "BOTTOMLEFT";
        BOTTOMRIGHT = "BOTTOMRIGHT";
    };

    ORDERED_POINTS = {
        -- Index table ordered by strata level
        "LEFT";
        "CENTER";
        "RIGHT";
        "TOP";
        "BOTTOM";
        "TOPLEFT";
        "TOPRIGHT";
        "BOTTOMLEFT";
        "BOTTOMRIGHT";
    };

    ORDERED_FRAME_STRATAS = {
        -- Index table ordered by strata level
        "BACKGROUND";
        "LOW";
        "MEDIUM";
        "HIGH";
        "DIALOG";
        "FULLSCREEN";
        "FULLSCREEN_DIALOG";
        "TOOLTIP";
    };

    FRAME_STRATAS = {
        -- hash-table (key/value pair) version:
        BACKGROUND          = "BACKGROUND";
        LOW                 = "LOW";
        MEDIUM              = "MEDIUM";
        HIGH                = "HIGH";
        DIALOG              = "DIALOG";
        FULLSCREEN          = "FULLSCREEN";
        FULLSCREEN_DIALOG   = "FULLSCREEN_DIALOG";
        TOOLTIP             = "TOOLTIP";
    };

    -- Blizzard global colors are tables containing r, g, b, keys and functions such as:
    -- GetRGB(), GetRGBA(), WrapTextInColorCode(), GenerateHexColor(), and more...
    COLORS = {
        ARTIFACT_GOLD   = _G.ARTIFACT_BAR_COLOR;
        BATTLE_NET_BLUE = _G.BATTLENET_FONT_COLOR;
        BLACK           = _G.BLACK_FONT_COLOR;
        DIM_GREEN       = _G.DIM_GREEN_FONT_COLOR;
        DIM_RED         = _G.DIM_RED_FONT_COLOR;
        DULL_RED        = _G.DIM_RED_FONT_COLOR;
        GOLD            = _G.NORMAL_FONT_COLOR;
        GRAY            = _G.DISABLED_FONT_COLOR;
        GREEN           = _G.GREEN_FONT_COLOR;
        LIGHT_YELLOW    = _G.LIGHTYELLOW_FONT_COLOR;
        ORANGE          = _G.ORANGE_FONT_COLOR;
        PARTY_CHAT_BLUE = _G.LIGHTBLUE_FONT_COLOR;
        RED             = _G.RED_FONT_COLOR;
        TRANSMOG_VIOLET = _G.TRANSMOGRIFY_FONT_COLOR;
        WHITE           = _G.HIGHLIGHT_FONT_COLOR;
        YELLOW          = _G.YELLOW_FONT_COLOR;
    };
};

if (tk:IsRetail()) then
  tk.Constants.FOOD_DRINK_AURAS = {
    ["43180"] = true, -- food
    ["43182"] = true, -- drink
  };
else
  tk.Constants.FOOD_DRINK_AURAS = {
    -- classic drinks
    ["24355"] = true,
    ["1137"] = true,
    ["1135"] = true,
    ["1133"] = true,
    ["432"] = true,
    ["431"] = true,
    ["430"] = true,

    -- classic foods
    ["1131"] = true,
    ["1127"] = true,
    ["5006"] = true,
    ["24800"] = true,
    ["18233"] = true,
    ["434"] = true,
    ["5004"] = true,
    ["22731"] = true,
    ["435"] = true,
    ["5007"] = true,
    ["10256"] = true,
    ["18230"] = true,
    ["25660"] = true,
    ["10257"] = true,
    ["18234"] = true,
    ["5005"] = true,
    ["7737"] = true,
    ["18229"] = true,
  };
end