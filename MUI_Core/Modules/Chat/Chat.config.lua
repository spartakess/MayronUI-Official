-- luacheck: ignore MayronUI self 143
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, db, _, _, obj, L = MayronUI:GetCoreComponents();
local _, C_ChatModule = MayronUI:ImportModule("ChatModule");
local table, string, unpack, tostring, pairs, ipairs = _G.table, _G.string, _G.unpack, _G.tostring, _G.pairs, _G.ipairs;
local tremove, PlaySound = _G.table.remove, _G.PlaySound;

local ChatFrameAnchorDropDownOptions = {
  [L["Top Left"]]       = "TOPLEFT";
  [L["Top Right"]]      = "TOPRIGHT";
  [L["Bottom Left"]]    = "BOTTOMLEFT";
  [L["Bottom Right"]]   = "BOTTOMRIGHT";
};

local iconDropdowns = {};

local iconOptionLabels = {
  L["Chat Channels"];
  L["Professions"];
  L["AddOn Shortcuts"];
  L["Copy Chat"];
  L["Emotes"];
  L["Online Status"];
  L["None"]
}

local iconOptions = {
  [iconOptionLabels[1]]   = "voiceChat";
  [iconOptionLabels[2]]   = "professions";
  [iconOptionLabels[3]]   = "shortcuts";
  [iconOptionLabels[4]]   = "copyChat";
  [iconOptionLabels[5]]   = "emotes";
  [iconOptionLabels[6]]   = "playerStatus";
  [iconOptionLabels[7]]   = "none";
};

if (tk:IsRetail()) then
  table.insert(iconOptionLabels, 2, L["Deafen"]);
  table.insert(iconOptionLabels, 3, L["Mute"]);
  iconOptions[iconOptionLabels[2]] = "deafen";
  iconOptions[iconOptionLabels[3]] = "mute";
end

-- Config Data ----------------------
local function CreateButtonConfigTable(dbPath, buttonID, chatFrame, addWidget)
  local configTable = obj:PopTable();

  if (buttonID == 1) then
    table.insert(configTable, {
      name = L["Standard Chat Buttons"],
      type = "title"
    });
  else
    table.insert(configTable, {
      name = string.format(L["Chat Buttons with Modifier Key %d"], buttonID),
      type = "title"
    });
  end

  table.insert(configTable, {
    name = L["Left Button"],
    dbPath = string.format("%s.buttons[%d][1]", dbPath, buttonID),
    enabled = chatFrame ~= nil,
    OnLoad = addWidget
  });

  table.insert(configTable, {
    name = L["Middle Button"],
    dbPath = string.format("%s.buttons[%d][2]", dbPath, buttonID),
    enabled = chatFrame ~= nil,
    OnLoad = addWidget
  });

  table.insert(configTable, {
    name = L["Right Button"],
    dbPath = string.format("%s.buttons[%d][3]", dbPath, buttonID),
    enabled = chatFrame ~= nil,
    OnLoad = addWidget
  });

  table.insert(configTable, { type = "divider" });

  if (buttonID == 1) then
    return unpack(configTable);
  end

  for _, modKey in obj:IterateArgs(L["Control"], L["Shift"], L["Alt"]) do
    local modKeyFirstChar = string.sub(modKey, 1, 1);

    table.insert(configTable, {
      name = modKey,
      height = 40,
      type = "check",
      dbPath = string.format("%s.buttons[%d].key", dbPath, buttonID),
      enabled = chatFrame ~= nil,
      OnLoad = addWidget,

      GetValue = function(_, currentValue)
        if (currentValue:find(modKeyFirstChar)) then
          return true;
        end

        return false;
      end,

      SetValue = function(valueDbPath, checked, oldValue)
        if (checked) then
          -- add it
          local newValue = (oldValue and tk.Strings:Concat(oldValue, modKeyFirstChar)) or modKeyFirstChar;
          db:SetPathValue(valueDbPath, newValue);

        elseif (oldValue and oldValue:find(modKeyFirstChar)) then
          -- remove it
          local newValue = oldValue:gsub(modKeyFirstChar, tk.Strings.Empty);
          db:SetPathValue(valueDbPath, newValue);
        end
      end
    });
  end

  return unpack(configTable);
end

local GetTextToHighlightFrameConfigTable;
do
  local function GetTextToHighlightLabel(highlighted)
    local coloredText = obj:PopTable();

    for index, text in ipairs(highlighted) do
      coloredText[index] = tk.Strings:SetTextColorByRGB(text, unpack(highlighted.color));
    end

    local label = tk.Strings:Join(" | ", coloredText); -- this pushes the table
    return tk.Strings:JoinWithSpace("Text to Highlight (case insensitive):", label);
  end

  function GetTextToHighlightFrameConfigTable(id, tbl, path, configModule)
    local fontString;
    local frameConfig = {
      type = "frame";
      OnClose = function(frame)
        local highlighted = db.profile.chat.highlighted:GetUntrackedTable();
        tremove(highlighted, id);
        db:SetPathValue("profile.chat.highlighted", highlighted);
        configModule:RemoveWidget(frame);
      end;
      children = {
        {
          type = "fontstring";
          content = GetTextToHighlightLabel(tbl);
          OnLoad = function(_, container)
            fontString = container.content;
          end;
        },
        {   type = "check";
            name = "Show in Upper Case";
            dbPath = tk.Strings:Join(".", path, "upperCase");
        };
        {   type = "color";
            useIndexes = true;
            name = "Set Color";
            dbPath = tk.Strings:Join(".", path, "color");

            OnPostSetValue = function()
              local newTbl = db:ParsePathValue(path):GetUntrackedTable();
              local newContent = GetTextToHighlightLabel(newTbl);
              fontString:SetText(newContent);
            end;
        };
        {   type = "button";
            name = "Edit Text";
            padding = 15;
        },
        {   type = "divider"; };
        {   type = "dropdown";
            name = "Play Sound";
            dbPath = tk.Strings:Join(".", path, "sound");
            tooltip = "Play a sound effect when any of the selected text appears in chat.";
            options = tk.Constants.SOUND_OPTIONS;
        },
        { type = "button";
          texture = "Interface\\COMMON\\VOICECHAT-SPEAKER";
          width = 20;
          height = 40;
          texHeight = 20;
          OnClick = function()
            local soundPath = tk.Strings:Join(".", path, "sound");
            local sound = db:ParsePathValue(soundPath);

            if (obj:IsNumber(sound)) then
              PlaySound(sound);
            end
          end
        }
      };
    };

    return frameConfig;
  end
end

---@param configModule ConfigModule
function C_ChatModule:GetConfigTable(_, configModule)
  return {
    module = "ChatModule",
    dbPath = "profile.chat",
    children = {
      { name = L["Enabled"],
        tooltip = "If checked, this module will be enabled.",
        type = "check",
        requiresReload = true, -- TODO: Maybe modules can be global? - move module enable/disable to general menu?
        appendDbPath = "enabled",
      },
      { type = "divider" };
      { name = "Text Highlighting"; -- TODO: LOCALE
        tooltip = L["MANAGE_TEXT_HIGHLIGHTING"];
        type = "submenu";
        children = {
          { type = "fontstring";
            content = L["MANAGE_TEXT_HIGHLIGHTING"]:gsub("\n", " ");
          };
          { type = "loop";
            args = db.profile.chat.highlighted:GetUntrackedTable();
            func = function(id, tbl)
              local path = "profile.chat.highlighted[" .. id .. "]";
              return GetTextToHighlightFrameConfigTable(id, tbl, path, configModule);
            end
          };
          { type = "button";
            name = "Add Highlighted Text";
            OnClick = function()
              local highlighted = db.profile.chat.highlighted:GetUntrackedTable();
              local id = #highlighted + 1;
              highlighted[id] = {
                "Enter text to highlight",
                color = { 1; 0; 0; };
                sound = false;
                upperCase = false;
              };

              db.profile.chat.highlighted = highlighted;
              local path = "profile.chat.highlighted[" .. id .. "]";
              local config = GetTextToHighlightFrameConfigTable(id, highlighted[id], path, configModule);
              configModule:RenderWidget(config);
            end;
          }
        };
      },
      { name = "Channel Name Aliases",
        tooltip = L["CHANNEL_NAME_ALIASES"];
        type = "submenu";

          -- aliases = {
          --   -- TODO: Locale
          --   ["4. LookingForGroup"] = "LFG";
          --   ["Guild"] = "G";
          --   ["Party"] = "P";
          --   ["Party Leader"] = "PL";
          --   ["5. WorldDefense"] = "WD";
          --   ["3. LocalDefense"] = "LD";
          --   ["2. Trade"] = "T";
          --   ["1. General"] = "G";
          -- };


        children = {
          { type = "fontstring";
            content = L["CHANNEL_NAME_ALIASES"]:gsub("\n", " ");
          };
          { name = "Guild";
            type = "textfield";
            dbPath = "profile.chat.aliases[Guild]";
          };
          { name = "Party";
            type = "textfield";
            dbPath = "profile.chat.aliases[Party]";
          };
          { name = "Party Leader";
            type = "textfield";
            dbPath = "profile.chat.aliases[Party Leader]";
          };
          { name = "Raid";
            type = "textfield";
            dbPath = "profile.chat.aliases[Raid]";
          };
          { name = "Raid Leader";
            type = "textfield";
            dbPath = "profile.chat.aliases[Raid Leader]";
          };

          { name = "1. General";
            type = "textfield";
            dbPath = "profile.chat.aliases[1. General]"; -- TODO: . not supported...
          };
          { name = "2. Trade";
            type = "textfield";
            dbPath = "profile.chat.aliases[2. Trade]";
          };
          { name = "3. LocalDefense";
            type = "textfield";
            dbPath = "profile.chat.aliases[3. LocalDefense]";
          };
          { name = "4. LookingForGroup";
            type = "textfield";
            dbPath = "profile.chat.aliases[4. LookingForGroup]";
          };
          { name = "5. WorldDefense";
            type = "textfield";
            dbPath = "profile.chat.aliases[5. WorldDefense]";
          };
        };
      },
      { name = L["Edit Box (Message Input Box)"],
        type = "submenu",
        children = {
          { name = L["Top"];
            type = "radio";
            groupName = "editBox_tabPositions";
            dbPath = "profile.chat.editBox.position";
            GetValue = function(_, value)
              return value == "TOP";
            end;
            SetValue = function(path)
              db:SetPathValue(path, "TOP");
            end;
          },
          { name = L["Bottom"];
            type = "radio";
            groupName = "editBox_tabPositions";
            dbPath = "profile.chat.editBox.position";
            GetValue = function(_, value)
              return value == "BOTTOM";
            end;
            SetValue = function(path)
              db:SetPathValue(path, "BOTTOM");
            end;
          },
          {   type = "divider";
          };
          { name = L["Y-Offset"],
            type = "slider",
            min = -50;
            max = 50;
            valueType = "number",
            tooltip = tk.Strings:Join(
              L["Set the vertical positioning of the edit box."],
              "\n\n", L["Default value is"], " -8.");
            dbPath = "profile.chat.editBox.yOffset";
          },
          { name = L["Set Height"];
            type = "slider";
            min = 20;
            max = 50;
            tooltip = tk.Strings:Join(L["The height of the edit box."], "\n\n", L["Default value is"], " 27.");
            dbPath = "profile.chat.editBox.height";
          },
          { type = "divider" };
          { name = L["Border"],
            type = "dropdown",
            options = tk.Constants.LSM:List("border"),
            dbPath = "profile.chat.editBox.border",
          },
          { name = L["Background Color"],
            type = "color",
            height = 64,
            hasOpacity = true;
            dbPath = "profile.chat.editBox.backdropColor"
          },
          { type = "divider",
          },
          { name = L["Border Size"],
            type = "slider",
            min = 1;
            max = 10;
            tooltip = tk.Strings:Join("\n\n", L["Set the border size."], L["Default value is"] .. " 1"),
            dbPath = "profile.chat.editBox.borderSize"
          },
          { name = L["Backdrop Inset"],
            type = "slider",
            min = 0;
            max = 10;
            tooltip = tk.Strings:Join("\n\n",
              L["Set the spacing between the background and the border."], L["Default value is"] .. " 0"),
            dbPath = "profile.chat.editBox.inset"
          },
        }
      },
      { name = L["Vertical Side Icons"],
        type = "submenu";
        children = {
          { name = L["Chat Frame with Icons"],
            type = "dropdown",
            tooltip = tk.Strings:Join("\n",
                  L["Only 1 active chat frame can show the chat icons on the sidebar (see icons listed below)."],
                  L["Select which chat frame the chat icons should be anchored to."]),
            options = ChatFrameAnchorDropDownOptions;
            dbPath = "profile.chat.iconsAnchor",
          },
          { type = "divider"
          },
          { type = "loop",
            loops = 6,
            func = function(id)
              return {
                name = tk.Strings:Concat("Icon ", id);
                type = "dropdown";
                dbPath = tk.Strings:Concat("profile.chat.icons[", id, "].type");
                options = iconOptions;
                OnLoad = function(_, container)
                  iconDropdowns[id] = container.widget;
                end;
                GetValue = function(_, value)
                  local _, label = tk.Tables:First(iconOptions, function(v) return v == value end);
                  return label;
                end;
                ---@param old Observer
                SetValue = function(path, newType, oldType)
                  local oldIcon = _G["MUI_ChatFrameIcon_"..tostring(oldType)];

                  if (obj:IsWidget(oldIcon)) then
                  -- if it exists then it will need to be hidden because it won't be used.
                    oldIcon:ClearAllPoints();
                    oldIcon:Hide();
                  end

                  if (newType ~= "none") then
                    -- Set any other icon whose type is the new type to the changed icon's old type
                    for otherId, otherValue in db.profile.chat.icons:Iterate() do
                      local otherType = otherValue.type;

                      if (newType == otherType) then
                        -- switch to old type
                        local otherPath = tk.Strings:Concat("profile.chat.icons[", otherId, "].type");
                        db:SetPathValue(otherPath, oldType, nil, true); -- prevent running update

                        local dropdown = iconDropdowns[otherId]; ---@type DropDownMenu
                        local _, label = tk.Tables:First(iconOptions, function(v) return v == oldType end);
                        dropdown:SetLabel(label);
                      end
                    end
                  end

                  db:SetPathValue(path, newType);
                end;
              };
            end
          },
        }
      },
      { name = L["Horizontal Top Buttons"],
        type = "title",
      },
      { type = "fontstring";
        height = 50;
        content = tk.Strings:JoinWithSpace(L["Allow the use of modifier keys to swap chat buttons while in combat."],
            L["This option will affect all active chat frames. To configure each individual button per chat frame, see the chat frame sub-menus below."]);
      };
      { name = L["Button Swapping in Combat"],
        type = "check",
        dbPath = "profile.chat.swapInCombat",
      },
      { name = L["Chat Frame Options"],
        type = "title",
      },
      { type = "loop",
        args = {"TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"},

        func = function(_, chatFrameName)
            local dbPath = string.format("profile.chat.chatFrames.%s", chatFrameName);
            local chatFrameLabel;
            local chatFrame = _G["MUI_ChatFrame_"..chatFrameName];
            local disabledWidgets = {};

            local addWidget = function(_, widget)
              table.insert(disabledWidgets, widget);
            end

            for key, value in pairs(ChatFrameAnchorDropDownOptions) do
              if (chatFrameName == value) then
                chatFrameLabel = key;
                break;
              end
            end

            local ConfigTable =
            {
              name = tk.Strings:JoinWithSpace(chatFrameLabel, L["Options"]),
              type = "submenu",
              module = "Chat",
              inherit = {
                  type = "dropdown",
                  options = C_ChatModule.Static.ButtonNames;
              },
              children = { -- shame I can't loop this
                {   name = L["Enable Chat Frame"],
                    type = "check",
                    dbPath = string.format("%s.enabled", dbPath),
                    OnClick = function(_, value)
                      for _, container in ipairs(disabledWidgets) do
                        local widget = container.widget or container.btn;
                        widget:SetEnabled(value);
                      end
                    end
                },
                {   name = L["Show Tab Bar"],
                    tooltip = L["This is the background bar that goes behind the tabs."];
                    type = "check",
                    dbPath = string.format("%s.tabBar.show", dbPath),
                    enabled = chatFrame ~= nil,
                    OnLoad = addWidget
                };
                {   type = "divider";
                };
                {   name = tk.Strings:JoinWithSpace(L["Tab Bar"], L["Y-Offset"]),
                    type = "slider",
                    min = -50;
                    max = 50;
                    dbPath = string.format("%s.tabBar.yOffset", dbPath),
                    enabled = chatFrame ~= nil,
                    OnLoad = addWidget
                };
                {   name = tk.Strings:JoinWithSpace(L["Window"], L["Y-Offset"]),
                    type = "slider",
                    min = -50;
                    max = 50;
                    dbPath = string.format("%s.window.yOffset", dbPath),
                    enabled = chatFrame ~= nil,
                    OnLoad = addWidget
                };
                {   name = tk.Strings:JoinWithSpace("Chat Frame", L["X-Offset"]),
                    type = "slider",
                    min = -50;
                    max = 50;
                    dbPath = string.format("%s.xOffset", dbPath),
                    enabled = chatFrame ~= nil,
                    OnLoad = addWidget
                };
                {   name = tk.Strings:JoinWithSpace("Chat Frame", L["Y-Offset"]),
                    type = "slider",
                    min = -50;
                    max = 50;
                    dbPath = string.format("%s.yOffset", dbPath),
                    enabled = chatFrame ~= nil,
                    OnLoad = addWidget
                };
              }
          };

          for i = 1, 3 do
            tk.Tables:AddAll(ConfigTable.children, CreateButtonConfigTable(dbPath, i, chatFrame, addWidget));
          end

          return ConfigTable;
        end
      },
    }
  };
end