-- DaVinci Resolve Timeline Version Updater (GUI)

-- Version: v0.1.8 (2025-06-20)
local SCRIPT_VERSION = 'v0.1.8'

-- Helper: log to both console and GUI
function logMsg(msg)
    print(msg)
    if itm.TextEdit then
        itm.TextEdit:Append(msg .. '\n')
    end
end

-- Use the global Resolve object if available
local resolve = Resolve
if type(resolve) == "function" then
    resolve = resolve()
end
if not resolve then
    print('Error: Resolve scripting API not available. Please run this script from within DaVinci Resolve.')
    return
end

local fusion = resolve:Fusion()
if not fusion then
    print('Error: Could not access Fusion. Exiting.')
    return
end

local ui = fusion.UIManager
local dispatcher = bmd.UIDispatcher(ui)

-- Helper: get current date as YYYY-MM-DD
function getCurrentDate()
    local date = os.date('%Y-%m-%d')
    return date
end

-- Helper: get current date in specified format
function getCurrentDateFormatted(format)
    local dateFormatMap = {
        ['YYYY-MM-DD'] = '%Y-%m-%d',
        ['YYMMDD']     = '%y%m%d',
        ['YYYYMMDD']   = '%Y%m%d',
        ['DD-MM-YYYY'] = '%d-%m-%Y',
        ['MM-DD-YYYY'] = '%m-%d-%Y',
    }
    local formatStr = dateFormatMap[format] or '%Y-%m-%d' -- default
    return os.date(formatStr)
end

-- Helper: extract version number from name (v001, V2, version1, etc.)
function extractVersion(name)
    -- Try to find version patterns in order of specificity
    local v
    -- First try vNN or vNNN pattern (most common)
    v = name:match('[vV](%d+)')
    if v then return tonumber(v) end
    -- Then try versionNN pattern
    v = name:match('[vV]ersion(%d+)')
    if v then return tonumber(v) end
    return nil
end

-- Helper: prompt for version number
function promptForVersionNumber()
    local input, ok = ui:RequestTextInput(win, {
        Title = 'Enter Version Number',
        Text = 'Enter version number to append (e.g. 1, 2, 10):',
        Default = '1',
    })
    if ok and input and tonumber(input) then
        return tonumber(input)
    end
    return nil
end

-- Helper: insert version before date if present
function insertVersionBeforeDate(name, vstr)
    -- Find date patterns
    local date_patterns = {
        '%d%d%d%d%-%d%d%-%d%d', -- YYYY-MM-DD
        '%d%d%d%d%d%d%d%d',     -- YYYYMMDD
        '%d%d%d%d%d%d',        -- YYMMDD
        '%d%d%-%d%d%-%d%d%d%d',-- DD-MM-YYYY or MM-DD-YYYY
        '%d%d/%d%d/%d%d%d%d',  -- DD/MM/YYYY or MM/DD/YYYY
        '%d%d%d%d/%d%d/%d%d',  -- YYYY/MM/DD
    }
    for _, pat in ipairs(date_patterns) do
        local s, e = name:find(pat)
        if s then
            local before = name:sub(1, s-1):gsub('[ _%-]+$', '')
            local after = name:sub(s)
            return (before ~= '' and before .. ' ' or '') .. vstr .. ' ' .. after
        end
    end
    -- No date found, just append
    return name .. ' ' .. vstr
end

-- Helper: get formatted version string
function getVersionString(versionNum, versionFormat)
    -- Extracts prefix (like 'v', 'V', 'version') and number part (like '1', '01', '001')
    local prefix, numPart = versionFormat:match('(^%a+)(%d+)$')
    if prefix and numPart then
        -- Format with padding based on length of number part
        return string.format('%s%0' .. #numPart .. 'd', prefix, versionNum)
    else
        -- Fallback for simple formats like 'v1' or if pattern fails
        local p = versionFormat:match('^%a+') or 'v'
        return p .. tostring(versionNum)
    end
end

-- Helper: increment version in name, or add if missing
function incrementVersion(name, appendV1, versionFormat, userVersionNum)
    local v = extractVersion(name)
    if v then
        local newv = v + 1
        local vstr = getVersionString(newv, versionFormat)
        -- Remove old version, then insert new version before date if present
        -- The order of gsub is important to avoid 'version' becoming 'ersion'
        local name_wo_version = name:gsub('[vV]ersion%d+', ''):gsub('[vV]%d+', ''):gsub('^%s*', ''):gsub('%s*$', '')
        return insertVersionBeforeDate(name_wo_version, vstr)
    else
        if appendV1 then
            local versionNum = tonumber(userVersionNum) or 1
            local vstr = getVersionString(versionNum, versionFormat)
            return insertVersionBeforeDate(name, vstr)
        else
            return name
        end
    end
end

-- Helper: remove date from name (various formats)
function removeDate(name)
    local n = name
    -- The patterns are now flexible to handle different separators (-, _, /, space).
    local separator = "[%s%-_/]"
    local date_patterns = {
        "%d%d%d%d"..separator.."%d%d"..separator.."%d%d", -- YYYY-sep-MM-sep-DD
        "%d%d"..separator.."%d%d"..separator.."%d%d%d%d", -- DD-sep-MM-sep-YYYY or MM-sep-DD-sep-YYYY
        "%d%d%d%d%d%d%d%d",     -- YYYYMMDD
        "%d%d%d%d%d%d",        -- YYMMDD
    }
    for _, pat in ipairs(date_patterns) do
        n = n:gsub(pat, '')
    end
    -- Clean up any leftover separators
    n = n:gsub('%s+', ' ')
    n = n:gsub('[ _%-]+$', ''):gsub('^[ _%-]+', '')
    return n
end

-- Helper: add current date to name, always after version if present
function addCurrentDate(name, dateFormat)
    -- Remove any existing date
    local n = removeDate(name)
    -- Find version pattern
    local versionPattern = '([vV]%d+)' -- e.g. v3
    local versionPos, versionEnd = n:find(versionPattern)
    if versionPos then
        -- Insert date after version
        local before = n:sub(1, versionEnd)
        local after = n:sub(versionEnd + 1)
        return before .. ' ' .. getCurrentDateFormatted(dateFormat) .. after
    else
        -- No version, just append date
        return n .. ' ' .. getCurrentDateFormatted(dateFormat)
    end
end

-- Helper: recursively find the folder containing a timeline by name
function findTimelineFolder(rootFolder, timelineName)
    local clips = rootFolder:GetClipList()
    for _, clip in ipairs(clips) do
        if clip:GetName() == timelineName then
            return rootFolder
        end
    end
    local subfolders = rootFolder:GetSubFolderList()
    for _, sub in ipairs(subfolders) do
        local found = findTimelineFolder(sub, timelineName)
        if found then return found end
    end
    return nil
end

-- Helper: recursively find the parent of a folder by unique id
function findParentFolder(rootFolder, targetFolder)
    local subfolders = rootFolder:GetSubFolderList()
    for _, sub in ipairs(subfolders) do
        if sub:GetUniqueId() == targetFolder:GetUniqueId() then
            return rootFolder
        end
        local found = findParentFolder(sub, targetFolder)
        if found then return found end
    end
    return nil
end

-- Helper: create custom-named folder in parent folder
function createCustomFolderInParent(mediaPool, currentFolder, folderName)
    local rootFolder = mediaPool:GetRootFolder()
    local parentFolder = findParentFolder(rootFolder, currentFolder)
    if not parentFolder then
        logMsg('Could not find parent folder for ' .. currentFolder:GetName())
        return nil
    end
    local subfolders = parentFolder:GetSubFolderList()
    for _, f in ipairs(subfolders) do
        if f:GetName() == folderName then
            logMsg('Using existing folder: ' .. folderName)
            return f
        end
    end
    local newFolder = mediaPool:AddSubFolder(parentFolder, folderName)
    if newFolder then
        logMsg('Created new folder: ' .. folderName .. ' in parent ' .. parentFolder:GetName())
    else
        logMsg('Failed to create folder: ' .. folderName)
    end
    return newFolder
end

-- Helper: format name with space replacement
function formatNameSpaces(name, mode)
    local formatters = {
        underscore = function(n) return n:gsub('[%s%-_]+', '_') end,
        minus = function(n) return n:gsub('[%s%-_]+', '-') end,
        space = function(n) return n:gsub('[_%-]+', ' '):gsub('%s+', ' '):gsub('^%s*', ''):gsub('%s*$', '') end,
    }
    if formatters[mode] then
        return formatters[mode](name)
    end
    return name
end

-- Main processing function (updated)
function processTimelines(patterns)
    local startTime = os.time()
    if itm.TextEdit then
        itm.TextEdit:SetText('')
    end
    logMsg('Timeline versioning started. (Script ' .. SCRIPT_VERSION .. ')')
    logMsg('Settings:')
    logMsg('- Version +1: ' .. (patterns.version and 'ON' or 'OFF'))
    if patterns.version then
        logMsg('- Version format: ' .. (patterns.versionFormat or 'v001'))
    end
    logMsg('- Add/replace date: ' .. (patterns.date and 'ON' or 'OFF'))
    if patterns.date then
        logMsg('- Date format: ' .. (patterns.dateFormat or 'YYYY-MM-DD'))
    end
    logMsg('- Append version if missing: ' .. (patterns.appendV1 and 'ON' or 'OFF'))
    if patterns.appendV1 then
        logMsg('- Version number to append: ' .. (patterns.userVersionNum or '1'))
    end
    logMsg('- Create new folders: ' .. (patterns.createNewFolder and 'ON' or 'OFF'))
    if patterns.createNewFolder then
        logMsg('- Folder naming scheme: ' .. (patterns.folderNaming or 'Date'))
    end
    logMsg('- Name formatting: ' .. (patterns.spaceMode ~= 'none' and patterns.spaceMode or 'OFF'))
    
    local pm = resolve:GetProjectManager()
    if not pm then logMsg('No ProjectManager found.') return end
    local project = pm:GetCurrentProject()
    if not project then
        logMsg('No project open.')
        return
    end
    logMsg('Project: ' .. (project:GetName() or 'Unnamed'))
    local mediaPool = project:GetMediaPool()
    if not mediaPool then logMsg('No MediaPool found.') return end
    local selected = mediaPool:GetSelectedClips()
    if not selected or #selected == 0 then
        logMsg('No timelines selected in Media Pool.')
        return
    end
    
    -- Validate settings
    if patterns.createNewFolder and not patterns.version and not patterns.date and not patterns.appendV1 then
        logMsg('Warning: Create new folders is enabled but neither Version +1, Add/replace date, nor Append version if missing is enabled. No folders will be created.')
    end
    
    local count, renamed, skipped, errors = 0, 0, 0, 0
    local rootFolder = mediaPool:GetRootFolder()

    -- Define date patterns here to be accessible for both folder and name formatting.
    local separator = "[%s%-_/]"
    local date_patterns = {
        "%d%d%d%d"..separator.."%d%d"..separator.."%d%d", -- YYYY-sep-MM-sep-DD
        "%d%d"..separator.."%d%d"..separator.."%d%d%d%d", -- DD-sep-MM-sep-YYYY or MM-sep-DD-sep-YYYY
        "%d%d%d%d%d%d%d%d",     -- YYYYMMDD
        "%d%d%d%d%d%d",        -- YYMMDD
    }

    for _, item in pairs(selected) do
        local success = false
        if type(item) == "userdata" and item.GetClipProperty then
            local props = item:GetClipProperty()
            if props and props['Type'] == 'Timeline' then
                local orig = item:GetName()
                logMsg('---')
                logMsg('Original timeline name: "' .. orig .. '"')
                local newName = orig
                local folderName = nil
                local useCustomFolder = false
                
                -- Process version first
                if patterns.version then
                    local oldVersion = extractVersion(newName)
                    newName = incrementVersion(newName, patterns.appendV1, patterns.versionFormat, patterns.userVersionNum)
                    local newVersion = extractVersion(newName)
                    if oldVersion then
                        logMsg(('Version: %d → %d'):format(oldVersion, newVersion))
                    elseif patterns.appendV1 then
                        logMsg('Added version number to name without version')
                    end
                elseif patterns.appendV1 then
                    -- If only appendV1 is ON, still use user version if missing
                    newName = incrementVersion(newName, true, patterns.versionFormat, patterns.userVersionNum)
                    if newName ~= orig then
                        logMsg('Added version number to name without version')
                    end
                end
                
                -- Then process date
                if patterns.date then
                    newName = addCurrentDate(newName, patterns.dateFormat)
                    logMsg('Added/replaced current date in name')
                end
                
                -- Determine folder name before formatting timeline name
                if patterns.createNewFolder then
                    local folder_v_str = nil
                    local folder_d_str = nil

                    -- Extract version string from the unformatted name
                    local v_num = extractVersion(newName)
                    if v_num then
                        folder_v_str = newName:match('[vV]%d+') or newName:match('[vV]ersion%d+')
                    end

                    -- Get formatted date string. If adding new date, use that. Otherwise, try to find existing.
                    if patterns.date then
                        folder_d_str = getCurrentDateFormatted(patterns.dateFormat)
                    else
                        for _, pat in ipairs(date_patterns) do
                            local found = newName:match(pat)
                            if found then folder_d_str = found; break end
                        end
                    end
                    
                    if patterns.folderNaming == 'Version + Date' then
                        if folder_v_str and folder_d_str then
                            folderName = folder_v_str .. '_' .. folder_d_str
                        elseif folder_v_str then
                            folderName = folder_v_str
                        elseif folder_d_str then
                            folderName = folder_d_str
                        else
                            folderName = 'New Folder'
                        end
                        useCustomFolder = true
                    elseif patterns.folderNaming == 'Date' then
                        if folder_d_str then
                            folderName = folder_d_str
                            useCustomFolder = true
                        end
                    elseif patterns.folderNaming == 'Version' then
                        if folder_v_str then
                            folderName = folder_v_str
                            useCustomFolder = true
                        end
                    end
                end
                
                -- Now, apply name formatting to the timeline name itself, while preserving the date format
                local onlyVersion = patterns.version and not (patterns.date or patterns.appendV1 or patterns.createNewFolder or (patterns.spaceMode and patterns.spaceMode ~= 'none'))
                if itm.formatNameBox.Checked and patterns.spaceMode and patterns.spaceMode ~= 'none' and not onlyVersion then
                    -- To preserve date separators, temporarily replace the date with a "safe" placeholder.
                    local date_placeholder = '~~DATE~~'
                    local date_str = nil
                    
                    -- First, check if a new date was just added. If so, use that.
                    if patterns.date then
                        date_str = getCurrentDateFormatted(patterns.dateFormat)
                    end

                    -- If a new date wasn't added, try to find an existing date in the name.
                    if not date_str then
                        for _, pat in ipairs(date_patterns) do
                            local found = newName:match(pat)
                            if found then
                                date_str = found
                                break
                            end
                        end
                    end
                    
                    -- If we have a date string (either new or existing), protect it.
                    if date_str then
                        -- Replace the date with the placeholder. Use a plain string find/replace to avoid regex issues.
                        local s, e = newName:find(date_str, 1, true)
                        if s then
                           newName = newName:sub(1, s-1) .. date_placeholder .. newName:sub(e+1)
                        end
                    end

                    -- Format the rest of the name. The placeholder will not be affected.
                    newName = formatNameSpaces(newName, patterns.spaceMode)
                    
                    -- Restore the date string with its original separators.
                    if date_str then
                        local s, e = newName:find(date_placeholder, 1, true)
                        if s then
                           newName = newName:sub(1, s-1) .. date_str .. newName:sub(e+1)
                        end
                    end
                end
                
                if newName ~= orig then
                    logMsg(('New timeline name: "%s"'):format(newName))
                    logMsg(('Processing "%s" → "%s"'):format(orig, newName))
                    
                    -- Find the timeline object by iterating through project timelines
                    local timeline = nil
                    local timelineCount = project:GetTimelineCount()
                    for i = 1, timelineCount do
                        local t = project:GetTimelineByIndex(i)
                        if t and t:GetName() == orig then
                            timeline = t
                            break
                        end
                    end
                    
                    if timeline then
                        if patterns.createNewFolder then
                            -- Always duplicate and move to new folder
                            local dup = timeline:DuplicateTimeline(newName)
                            if dup then
                                if useCustomFolder and folderName then
                                    local timelineFolder = findTimelineFolder(rootFolder, newName)
                                    if not timelineFolder then
                                        -- Sometimes the new timeline is not found in its original folder immediately
                                        -- Let's retry finding it at the root.
                                        timelineFolder = findTimelineFolder(rootFolder, orig)
                                    end

                                    if timelineFolder then
                                        local customFolder = createCustomFolderInParent(mediaPool, timelineFolder, folderName)
                                        if customFolder then
                                            -- bmd.wait is needed because moving clips is not always instantaneous.
                                            -- This gives Resolve time to update its internal state.
                                            bmd.wait(0.1)
                                            local clips = timelineFolder:GetClipList()
                                            local dupClip = nil
                                            for _, c in ipairs(clips) do
                                                if c:GetName() == newName then
                                                    dupClip = c
                                                    break
                                                end
                                            end
                                            if dupClip then
                                                local moved = mediaPool:MoveClips({dupClip}, customFolder)
                                                if moved then
                                                    logMsg('Moved timeline to new folder: ' .. customFolder:GetName())
                                                else
                                                    logMsg('Failed to move timeline to new folder.')
                                                end
                                            else
                                                logMsg('Could not find duplicated timeline clip to move it.')
                                            end
                                        end
                                    else
                                        logMsg("Could not find timeline's parent folder.")
                                    end
                                end
                                logMsg(('Successfully duplicated "%s" as "%s".'):format(orig, newName))
                                renamed = renamed + 1
                            else
                                logMsg(('Failed to duplicate "%s".'):format(orig))
                                errors = errors + 1
                            end
                        else
                            -- Just rename
                            if timeline:SetName(newName) then
                                logMsg(('Successfully renamed "%s" to "%s".'):format(orig, newName))
                                renamed = renamed + 1
                            else
                                logMsg(('Failed to rename "%s".'):format(orig))
                                errors = errors + 1
                            end
                        end
                    else
                        logMsg(('Could not find timeline object for "%s" in the project. Skipping.'):format(orig))
                        skipped = skipped + 1
                    end
                else
                    logMsg(('No changes needed for "%s".'):format(orig))
                    skipped = skipped + 1
                end
                count = count + 1
            else
                logMsg('Skipped non-timeline item.')
                skipped = skipped + 1
            end
        else
            logMsg('Skipped invalid item in selection.')
            skipped = skipped + 1
        end
    end
    local duration = os.time() - startTime
    logMsg(string.format('Finished in %d seconds.', duration))
    logMsg(('Done. %d processed, %d renamed, %d skipped, %d errors.'):format(count, renamed, skipped, errors))
end

-- Build UI
win = dispatcher:AddWindow({
    ID = 'TimelineVersionUpWin',
    WindowTitle = 'Timeline Version Manager',
    Geometry = {100, 100, 560, 460},
    MinimumSize = {380, 460},
    Spacing = 8,
    ui:VGroup{
        ID = 'root',
        Weight = 1,
        -- Title label
        ui:Label{
            ID = 'TitleLabel',
            Text = 'Timeline Version Manager',
            StyleSheet = [[
                QLabel {
                    font-size: 14px;
                    font-weight: bold;
                    padding: 5px;
                }
            ]],
            Alignment = { AlignHCenter = true, AlignVCenter = true },
        },
        ui:VGap(6, 0.01),
        -- Main features section label
        ui:Label{
            ID = 'MainFeaturesLabel',
            Text = 'Main features',
            StyleSheet = [[QLabel { font-weight: bold; }]],
            Alignment = { AlignHCenter = true,AlignVCenter = true },
        },
        -- Main features controls (version, date, format)
        -- Version checkbox (left-aligned)
        ui:CheckBox{ID='versionBox', Text='Version +1', Checked=true},
        -- Version format dropdown (right-aligned)
        ui:HGroup{
            Weight = 0,
            ui:Label{Text = "", Weight = 1},
            ui:Label{ID='versionFormatLabel', Text='Version format:', Alignment = { AlignRight = true, AlignVCenter = true }},
            ui:ComboBox{ID='versionFormatCombo', MinimumSize={120, 0}},
        },
        -- Date checkbox (left-aligned)
        ui:CheckBox{ID='dateBox', Text='Add or replace with current date', Checked=true},
        -- Date format dropdown (right-aligned)
        ui:HGroup{
            Weight = 0,
            ui:Label{Text = "", Weight = 1},
            ui:Label{ID='dateFormatLabel', Text='Date format:', Alignment = { AlignRight = true, AlignVCenter = true }},
            ui:ComboBox{ID='dateFormatCombo'},
        },
        ui:VGap(6, 0.01),
        -- Settings section label
        ui:Label{
            ID = 'SettingsLabel',
            Text = 'Settings',
            StyleSheet = [[QLabel { font-weight: bold; }]],
            Alignment = { AlignHCenter = true, AlignVCenter = true },
        },
        -- Settings controls
        ui:VGroup{
            Weight = 0,
            -- Append v1 checkbox and version number input field (single line)
            ui:HGroup{
                Weight = 0,
                ui:CheckBox{ID='appendV1Box', Text='Append version number if missing', Checked=true},
                ui:Label{ID='versionInputLabel', Text='Version number:', Alignment = { AlignRight = true, AlignVCenter = true }},
                ui:LineEdit{ID='versionInput', Text='1', MinimumSize={60, 0}},
            },
            -- Create new folders checkbox and folder naming scheme (single line)
            ui:HGroup{
                Weight = 0,
                ui:CheckBox{ID='createNewFolderBox', Text='Create and move to new folders', Checked=true},
                ui:Label{ID='folderNamingLabel', Text='Folder naming:', Alignment = { AlignRight = true, AlignVCenter = true }},
                ui:ComboBox{ID='folderNamingCombo'},
            },
            -- Name formatting enable checkbox and dropdown (already single line)
            ui:HGroup{
                Weight = 0,
                ui:CheckBox{ID='formatNameBox', Text='Reformat name', Checked=true},
                ui:Label{ID='formatLabel', Text=''},
                ui:ComboBox{ID='formatCombo'},
            },
        },
        ui:VGap(6, 0.01),
        -- Run/Close buttons (move above log area)
        ui:HGroup{
            Weight = 0,
            ui:Button{ID='runBtn', Text='Run actions', MinimumSize={80,0}},
            ui:Button{ID='closeBtn', Text='Close', MinimumSize={80,0}},
        },
        ui:VGap(6, 0.01),
        -- Log label
        ui:Label{
            ID = 'LogLabel',
            Text = 'Log',
            StyleSheet = [[QLabel { font-weight: bold; }]],
            Alignment = { AlignLeft = true, AlignVCenter = true },
        },
        ui:VGap(2, 0.01),
        -- Log message box
        ui:HGroup{
            Weight = 1,
            ui:TextEdit{
                ID = 'TextEdit',
                TabStopWidth = 28,
                Font = ui:Font{
                    Family = 'Droid Sans Mono',
                    StyleName = 'Regular',
                    PixelSize = 12,
                    MonoSpaced = true,
                    StyleStrategy = {
                        ForceIntegerMetrics = true
                    },
                    ReadOnly = true,
                },
                LineWrapMode = 'NoWrap',
                AcceptRichText = false,
    
                -- Use the Fusion hybrid lexer module to add syntax highlighting
                Lexer = 'fusion',
                },
            },
    }
})

itm = win:GetItems()

-- Populate ComboBox items and set default
itm.formatCombo:AddItems({'Space','Underscore _','Minus -'})
itm.formatCombo.CurrentIndex = 0
itm.dateFormatCombo:AddItems({'YYMMDD', 'YYYYMMDD', 'YYYY-MM-DD', 'MM-DD-YYYY', 'DD-MM-YYYY'})
itm.dateFormatCombo.CurrentIndex = 0
itm.versionFormatCombo:AddItems({'v1', 'v01', 'v001', 'V1', 'V01', 'V001', 'version1', 'version01', 'version001', 'Version1', 'Version01', 'Version001'})
itm.versionFormatCombo.CurrentIndex = 0
itm.folderNamingCombo:AddItems({'Version', 'Date', 'Version + Date'})
itm.folderNamingCombo.CurrentIndex = 0

-- Only format name if the checkbox is checked
function getNameFormatMode()
    if itm.formatNameBox.Checked then
        if itm.formatCombo.CurrentIndex == 0 then
            return 'space' -- keep as is
        elseif itm.formatCombo.CurrentIndex == 1 then
            return 'underscore'
        elseif itm.formatCombo.CurrentIndex == 2 then
            return 'minus'
        end
    end
    return 'none'
end

function win.On.runBtn.Clicked(ev)
    -- UI logic check: warn if createNewFolder is checked but neither version nor date is checked
    if itm.createNewFolderBox.Checked and not itm.versionBox.Checked and not itm.dateBox.Checked then
        logMsg('Warning: "Create new folders" is enabled but neither "Version +1" nor "Add/replace date" is enabled. No folders will be created.')
        -- Optionally, you could return here to prevent running, or just warn
    end
    local nameFormatMode = getNameFormatMode()
    local patterns = {
        version=itm.versionBox.Checked, 
        date=itm.dateBox.Checked, 
        appendV1=itm.appendV1Box.Checked, 
        spaceMode=nameFormatMode,
        createNewFolder=itm.createNewFolderBox.Checked,
        dateFormat=itm.dateFormatCombo.CurrentText,
        versionFormat=itm.versionFormatCombo.CurrentText,
        folderNaming=itm.folderNamingCombo.CurrentText,
        userVersionNum=itm.versionInput.Text
    }
    -- Log a summary of what will happen
    logMsg('--- Summary of selected options ---')
    logMsg('Will increment version: ' .. (patterns.version and 'YES' or 'NO'))
    logMsg('Will add/replace date: ' .. (patterns.date and 'YES' or 'NO'))
    logMsg('Will append version if missing: ' .. (patterns.appendV1 and 'YES' or 'NO'))
    logMsg('Will create new folders: ' .. (patterns.createNewFolder and 'YES' or 'NO'))
    logMsg('Name formatting: ' .. (patterns.spaceMode ~= 'none' and patterns.spaceMode or 'OFF'))
    logMsg('-----------------------------------')
    processTimelines(patterns)
end

function win.On.closeBtn.Clicked(ev)
    dispatcher:ExitLoop()
end

win:Show()
bgcol = { R=0.125, G=0.125, B=0.125, A=1 }
itm.TextEdit.BackgroundColor = bgcol
itm.TextEdit:SetPaletteColor('All', 'Base', bgcol)

dispatcher:RunLoop()
win:Hide() 