-- DaVinci Resolve Timeline Version Updater (GUI)

-- Version: v1.03  (2025-09-03)
local SCRIPT_VERSION = 'v1.03'

-- Helper: log to both console and GUI
function logMsg(msg)
    print(msg)
    if itm.TextEdit then
        itm.TextEdit:Append(msg .. '\n')
    end
    appendToLogFile(msg)
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

-- Log-to-file state
local saveLogToFile = false
local selectedLogFolder = nil
local currentLogFilePath = nil
local logFileWritesEnabled = false

-- Helper: get OS-specific default Documents folder
local function getDefaultDocumentsFolder()
    local home = os.getenv('HOME') or os.getenv('USERPROFILE') or '.'
    local documents = nil
    if package.config:sub(1,1) == '\\' then
        -- Windows: prefer USERPROFILE, fallback to HOME
        local userprofile = os.getenv('USERPROFILE') or home
        documents = userprofile .. '\\Documents'
    else
        -- macOS/Linux: use HOME
        documents = home .. '/Documents'
    end
    return documents
end

-- Helper: normalize path separators for current platform
local function normalizePath(path)
    if not path then return path end
    local isWindows = package.config:sub(1,1) == '\\'
    if isWindows then
        -- Convert forward slashes to backslashes on Windows
        return path:gsub('/', '\\')
    else
        -- Convert backslashes to forward slashes on macOS/Linux
        return path:gsub('\\', '/')
    end
end

-- Helper: ensure directory exists (creates if missing)
local function ensureDirectory(dirpath)
    if not dirpath or dirpath == '' then return false end
    
    -- Try Fusion API first (most reliable in Resolve environment)
    if bmd and bmd.mkdir then
        bmd.mkdir(dirpath)
        return true
    end
    
    -- Fallback to OS commands
    local isWindows = package.config:sub(1,1) == '\\'
    local success = false
    
    if isWindows then
        -- Windows: use md command with proper quoting
        local cmd = 'md "' .. dirpath .. '" 2>nul'
        success = os.execute(cmd) == 0
    else
        -- macOS/Linux: use mkdir -p (creates parent directories)
        local cmd = 'mkdir -p ' .. string.format("%q", dirpath) .. ' 2>/dev/null'
        success = os.execute(cmd) == 0
    end
    
    -- Final fallback: try simple mkdir
    if not success then
        if isWindows then
            success = os.execute('md "' .. dirpath .. '"') == 0
        else
            success = os.execute('mkdir ' .. string.format("%q", dirpath)) == 0
        end
    end
    
    return success
end

-- Helper: generate new log file path in selected or default folder
local function generateLogFilePath()
    local baseFolder = selectedLogFolder or (getDefaultDocumentsFolder() .. (package.config:sub(1,1) == '\\' and '\\TimelineVersionManager\\Logs' or '/TimelineVersionManager/Logs'))
    baseFolder = normalizePath(baseFolder)
    ensureDirectory(baseFolder)
    local ts = os.date('%Y-%m-%d_%H-%M-%S')
    local filename = 'TimelineVersionManager_' .. ts .. '.txt'
    local sep = (package.config:sub(1,1) == '\\' and '\\' or '/')
    return baseFolder .. sep .. filename
end

function appendToLogFile(line)
    if not saveLogToFile or not logFileWritesEnabled then return end
    -- If a custom path is provided in the UI, prefer it
    if itm and itm.SaveLogPathInput and itm.SaveLogPathInput.Text and itm.SaveLogPathInput.Text ~= '' then
        local customPath = normalizePath(itm.SaveLogPathInput.Text)
        if selectedLogFolder ~= customPath then
            selectedLogFolder = customPath
            ensureDirectory(selectedLogFolder)
            currentLogFilePath = nil -- force regeneration with new folder
        end
    end
    if not currentLogFilePath then
        currentLogFilePath = generateLogFilePath()
    end
    local fh, err = io.open(currentLogFilePath, 'a')
    if fh then
        fh:write(line .. '\n')
        fh:close()
    else
        saveLogToFile = false
        print('Failed to write log file: ' .. tostring(err))
    end
end

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
    -- Handle different version format patterns
    if versionFormat:match('^[vV]%d+$') then
        -- Format like 'v1', 'v01', 'v001', 'V1', 'V01', 'V001'
        local prefix = versionFormat:match('^[vV]')
        local numPart = versionFormat:match('%d+$')
        if prefix and numPart then
            return string.format('%s%0' .. #numPart .. 'd', prefix, versionNum)
        end
    elseif versionFormat:match('^version%d+$') then
        -- Format like 'version1', 'version01', 'version001'
        local prefix = 'version'
        local numPart = versionFormat:match('%d+$')
        if numPart then
            return string.format('%s%0' .. #numPart .. 'd', prefix, versionNum)
        end
    elseif versionFormat:match('^Version%d+$') then
        -- Format like 'Version1', 'Version01', 'Version001'
        local prefix = 'Version'
        local numPart = versionFormat:match('%d+$')
        if numPart then
            return string.format('%s%0' .. #numPart .. 'd', prefix, versionNum)
        end
    end
    
    -- Fallback for any unrecognized format
    local p = versionFormat:match('^%a+') or 'v'
    return p .. tostring(versionNum)
end

-- Helper: increment version in name, or add if missing
function incrementVersion(name, appendV1, versionFormat, userVersionNum, shouldIncrement)
    local v = extractVersion(name)
    if v then
        if shouldIncrement then
            local newv = v + 1
            local vstr = getVersionString(newv, versionFormat)
            -- Remove old version, then insert new version before date if present
            -- The order of gsub is important to avoid 'version' becoming 'ersion'
            local name_wo_version = name:gsub('[vV]ersion%d+', ''):gsub('[vV]%d+', ''):gsub('^%s*', ''):gsub('%s*$', '')
            return insertVersionBeforeDate(name_wo_version, vstr)
        else
            -- Don't increment existing version, just return original name
            return name
        end
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

-- Helper: add current date to name, replacing existing date in original position
function addCurrentDate(name, dateFormat)
    -- Find the position of existing date first
    local datePatterns = {
        "%d%d%d%d%-%d%d%-%d%d", -- YYYY-MM-DD
        "%d%d%d%d%d%d%d%d",     -- YYYYMMDD
        "%d%d%d%d%d%d",        -- YYMMDD
        "%d%d%-%d%d%-%d%d%d%d",-- DD-MM-YYYY or MM-DD-YYYY
    }
    
    local dateStart, dateEnd = nil, nil
    local foundDate = nil
    
    -- Find existing date and its position
    for _, pattern in ipairs(datePatterns) do
        dateStart, dateEnd = name:find(pattern)
        if dateStart then
            foundDate = name:sub(dateStart, dateEnd)
            break
        end
    end
    
    local newDate = getCurrentDateFormatted(dateFormat)
    
    if dateStart then
        -- Replace date in original position
        return name:sub(1, dateStart-1) .. newDate .. name:sub(dateEnd+1)
    else
        -- No existing date, append at end
        return name .. ' ' .. newDate
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
        dash = function(n) return n:gsub('[%s%-_]+', '-') end,
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
    
    -- Get current time for log header
    local currentTime = os.date('%H:%M:%S')
    logMsg('Timeline versioning started at ' .. currentTime .. ' with script ' .. SCRIPT_VERSION .. '.')
    
    local pm = resolve:GetProjectManager()
    if not pm then logMsg('No ProjectManager found.') return end
    local project = pm:GetCurrentProject()
    if not project then
        logMsg('No project open.')
        return
    end
    logMsg('Project Name: ' .. (project:GetName() or 'Unnamed'))
    
    logMsg('---')
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
    logMsg('- Operation mode: ' .. (patterns.selectedActionText or 'Duplicate'))
    if patterns.actionMode == 'duplicate' and patterns.moveToFolder then
        logMsg('- Folder naming scheme: ' .. (patterns.folderNaming or 'Date'))
    end
    logMsg('- Name formatting: ' .. (patterns.nameFormatText or 'OFF'))
    
    local mediaPool = project:GetMediaPool()
    if not mediaPool then logMsg('No MediaPool found.') return end
    local selected = mediaPool:GetSelectedClips()
    if not selected or #selected == 0 then
        logMsg('No timelines selected in Media Pool.')
        return
    end
    
    -- Validate settings
    if patterns.actionMode == 'duplicate' and patterns.moveToFolder and not patterns.version and not patterns.date and not patterns.appendV1 then
        logMsg('Warning: Move to new folder is enabled but neither Version +1, Add/replace date, nor Append version if missing is enabled. No folders will be created.')
    end
    
    local count, renamed, skipped, errors = 0, 0, 0, 0
    local skippedItems = {}
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
                logMsg('Processing timeline: "' .. orig .. '"')
                local newName = orig
                local folderName = nil
                useCustomFolder = false
                
                -- Process version first
                if patterns.version then
                    local oldVersion = extractVersion(newName)
                    newName = incrementVersion(newName, patterns.appendV1, patterns.versionFormat, patterns.userVersionNum, true)
                    local newVersion = extractVersion(newName)
                    if oldVersion then
                        logMsg(('Incrementing version: %d → %d'):format(oldVersion, newVersion))
                    elseif patterns.appendV1 then
                        logMsg('Adding version number to name without version')
                    end
                elseif patterns.appendV1 then
                    -- If only appendV1 is ON, still use user version if missing
                    newName = incrementVersion(newName, true, patterns.versionFormat, patterns.userVersionNum, false)
                    if newName ~= orig then
                        logMsg('Adding version number to name without version')
                    end
                end
                
                -- Version format adjustment for Rename mode (independent of other settings)
                if patterns.actionMode == 'rename' then
                    local oldVersion = extractVersion(newName)
                    if oldVersion then
                        local oldVersionStr = newName:match('[vV]%d+') or newName:match('[vV]ersion%d+')
                        local newVersionStr = getVersionString(oldVersion, patterns.versionFormat)
                        if oldVersionStr and oldVersionStr ~= newVersionStr then
                            newName = newName:gsub(oldVersionStr, newVersionStr)
                            logMsg(('Adjusting version format: %s → %s'):format(oldVersionStr, newVersionStr))
                        end
                    end
                end
                
                -- Then process date
                if patterns.date then
                    newName = addCurrentDate(newName, patterns.dateFormat)
                    logMsg('Adding/replacing current date in name')
                end
                
                -- Date format adjustment for Rename mode (independent of other settings)
                if patterns.actionMode == 'rename' then
                    -- Find existing date in the name
                    local datePatterns = {
                        "%d%d%d%d%-%d%d%-%d%d", -- YYYY-MM-DD
                        "%d%d%d%d%d%d%d%d",     -- YYYYMMDD
                        "%d%d%d%d%d%d",        -- YYMMDD
                        "%d%d%-%d%d%-%d%d%d%d",-- DD-MM-YYYY or MM-DD-YYYY
                    }
                    
                    local dateStart, dateEnd = nil, nil
                    local foundDate = nil
                    
                    -- Find existing date and its position
                    for _, pattern in ipairs(datePatterns) do
                        dateStart, dateEnd = newName:find(pattern)
                        if dateStart then
                            foundDate = newName:sub(dateStart, dateEnd)
                            break
                        end
                    end
                    
                    if foundDate then
                        -- Parse the found date to get year, month, day
                        local year, month, day = nil, nil, nil
                        
                        -- Try different date formats to extract components
                        if foundDate:match("^%d%d%d%d%-%d%d%-%d%d$") then
                            -- YYYY-MM-DD format
                            year, month, day = foundDate:match("(%d%d%d%d)%-(%d%d)%-(%d%d)")
                        elseif foundDate:match("^%d%d%d%d%d%d%d%d$") then
                            -- YYYYMMDD format
                            year, month, day = foundDate:match("(%d%d%d%d)(%d%d)(%d%d)")
                        elseif foundDate:match("^%d%d%d%d%d%d$") then
                            -- YYMMDD format
                            local yy, mm, dd = foundDate:match("(%d%d)(%d%d)(%d%d)")
                            year = "20" .. yy
                            month = mm
                            day = dd
                        elseif foundDate:match("^%d%d%-%d%d%-%d%d%d%d$") then
                            -- DD-MM-YYYY or MM-DD-YYYY format (assume DD-MM-YYYY)
                            day, month, year = foundDate:match("(%d%d)%-(%d%d)%-(%d%d%d%d)")
                        end
                        
                        if year and month and day then
                            -- Convert to the selected date format
                            local newDateStr = nil
                            if patterns.dateFormat == 'YYYY-MM-DD' then
                                newDateStr = string.format("%04d-%02d-%02d", year, month, day)
                            elseif patterns.dateFormat == 'YYYYMMDD' then
                                newDateStr = string.format("%04d%02d%02d", year, month, day)
                            elseif patterns.dateFormat == 'YYMMDD' then
                                newDateStr = string.format("%02d%02d%02d", year % 100, month, day)
                            elseif patterns.dateFormat == 'MM-DD-YYYY' then
                                newDateStr = string.format("%02d-%02d-%04d", month, day, year)
                            elseif patterns.dateFormat == 'DD-MM-YYYY' then
                                newDateStr = string.format("%02d-%02d-%04d", day, month, year)
                            end
                            
                            if newDateStr and newDateStr ~= foundDate then
                                newName = newName:sub(1, dateStart-1) .. newDateStr .. newName:sub(dateEnd+1)
                                logMsg(('Adjusting date format: %s → %s'):format(foundDate, newDateStr))
                            end
                        end
                    end
                end
                
                -- Determine folder name before formatting timeline name
                if patterns.actionMode == 'duplicate' and patterns.moveToFolder then
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
                local onlyVersion = patterns.version and not (patterns.date or patterns.appendV1 or (patterns.actionMode == 'duplicate' and patterns.moveToFolder) or (patterns.spaceMode and patterns.spaceMode ~= 'none'))
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
                    logMsg(('Setting new timeline name: "%s"'):format(newName))
                    logMsg('Processing...')
                    
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
                        if patterns.actionMode == 'duplicate' then
                            local dup = timeline:DuplicateTimeline(newName)
                            if dup then
                                if patterns.moveToFolder and useCustomFolder and folderName then
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
                        else -- rename
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
                    -- Provide immediate feedback for timelines that don't need changes
                    logMsg('No changes needed - keeping original name')
                    table.insert(skippedItems, 'No changes needed: "' .. orig .. '"')
                    skipped = skipped + 1
                end
                count = count + 1
            else
                local itemName = item:GetName() or 'Unknown item'
                table.insert(skippedItems, 'Non-timeline item: "' .. itemName .. '"')
                skipped = skipped + 1
            end
        else
            table.insert(skippedItems, 'Invalid item in selection')
            skipped = skipped + 1
        end
    end
    
    -- Display skipped items if any
    if #skippedItems > 0 then
        logMsg('---')
        logMsg('Skipped items:')
        for _, skippedItem in ipairs(skippedItems) do
            logMsg(skippedItem)
        end
    end
    
    logMsg('---')
    logMsg('Done.')
    local duration = os.time() - startTime
    logMsg(string.format('Finished in %d seconds at ' .. currentTime .. '.', duration))
    logMsg(('%d processed, %d renamed, %d skipped, %d errors.'):format(count, renamed, skipped, errors))
end

-- Build UI
win = dispatcher:AddWindow({
    ID = 'TimelineVersionManager',
    WindowTitle = 'Timeline Version Manager',
    Geometry = {100, 100, 560, 460},
    MinimumSize = {380, 460},
    Spacing = 8,
    ui:VGroup{
        ID = 'root',
        Weight = 1,
        -- Main features section label
        ui:Label{
            ID = 'MainFeaturesLabel',
            Text = 'Main features',
            StyleSheet = [[QLabel { font-size: 14px; font-weight: bold; padding: 5px; }]],
            Alignment = { AlignHCenter = true,AlignVCenter = true },
        },
        -- Main features controls: operation mode, version format and date
        ui:HGroup{
            Weight = 0,
            ui:Label{Text = "Operation Mode:", Weight = 0.1}, -- indent
            ui:Label{ID='actionLabel', Text='Duplicate and/or move:', Alignment = { AlignRight = true, AlignVCenter = true }},
            ui:ComboBox{ID='actionCombo', MinimumSize={90, 0}},
        },
        ui:HGroup{
        Weight = 0,
        ui:CheckBox{ID='versionBox', Text='Version +1', Checked=true},
        ui:Label{ID='versionFormatLabel', Text='Version format:', Alignment = { AlignRight = true, AlignVCenter = true }},
        ui:ComboBox{ID='versionFormatCombo', MinimumSize={120, 0}},
        },
        ui:HGroup{
            Weight = 0,
            ui:CheckBox{ID='dateBox', Text='Add or replace with current date', Checked=true},
            ui:Label{ID='dateFormatLabel', Text='Date format:', Alignment = { AlignRight = true, AlignVCenter = true }},
            ui:ComboBox{ID='dateFormatCombo'},
        },
        ui:VGap(6, 0.01),
        -- Settings section label
        ui:Label{
            ID = 'SettingsLabel',
            Text = 'Settings',
            StyleSheet = [[QLabel { font-size: 14px; font-weight: bold; padding: 5px; }]],
            Alignment = { AlignHCenter = true, AlignVCenter = true },
        },
        -- Settings controls
            -- Folder naming controls
            ui:HGroup{
                Weight = 0,
                ui:Label{Text = "Folder naming:", Weight = 0.1}, -- indent
                ui:Label{ID='folderNamingLabel', Text="Only when 'Move'-Operation selected:", StyleSheet = [[QLabel { font-size: 11px; }]], Alignment = { AlignRight = true, AlignVCenter = true }},
                ui:ComboBox{ID='folderNamingCombo'},
            },
            -- Append v1 checkbox and version number input field (single line)
            ui:HGroup{
                Weight = 0,
                ui:CheckBox{ID='appendV1Box', Text='Append version number if missing', Checked=true},
                ui:Label{ID='versionInputLabel', Text='Version number:', Alignment = { AlignRight = true, AlignVCenter = true }},
                ui:LineEdit{ID='versionInput', Text='1', MinimumSize={60, 0}},
            },
            -- Name formatting enable checkbox and dropdown (already single line)
            ui:HGroup{
                Weight = 0,
                ui:CheckBox{ID='formatNameBox', Text='Reformat name', Checked=true},
                ui:Label{ID='formatLabel', Text=''},
                ui:ComboBox{ID='formatCombo'},
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
        ui:HGroup{
            Weight = 0,
            ui:Label{Text = "Log", Weight = 0.1},
            ui:HGap(0.1, 2),
            ui:CheckBox{ID='SaveLogBox', Text='Save log to file', Checked=false, Alignment = { AlignRight = true }},
            ui:Label{Text = "Custom path for logs:", Weight = 0.1},
            ui:LineEdit{ID='SaveLogPathInput', Text='', MinimumSize={80, 0}},
        },
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
itm.formatCombo:AddItems({'Space','Underscore _','Dash -'})
itm.formatCombo.CurrentIndex = 1
itm.dateFormatCombo:AddItems({'YYMMDD', 'YYYYMMDD', 'YYYY-MM-DD', 'MM-DD-YYYY', 'DD-MM-YYYY'})
itm.dateFormatCombo.CurrentIndex = 0
itm.versionFormatCombo:AddItems({'v1', 'v01', 'v001', 'V1', 'V01', 'V001', 'version1', 'version01', 'version001', 'Version1', 'Version01', 'Version001'})
itm.versionFormatCombo.CurrentIndex = 0
itm.folderNamingCombo:AddItems({'Version + Date', 'Version', 'Date'})
itm.folderNamingCombo.CurrentIndex = 0
itm.actionCombo:AddItems({'Duplicate', 'Duplicate + Move', 'Rename only'})
itm.actionCombo.CurrentIndex = 0

-- Helper: validate UI state and provide user feedback
function validateUIState()
    local warnings = {}
    
    -- Check if "Duplicate + Move" is selected but no naming changes are selected
    local selectedAction = itm.actionCombo.CurrentText
    if selectedAction == 'Duplicate + Move' and not itm.versionBox.Checked and not itm.dateBox.Checked and not itm.appendV1Box.Checked then
        table.insert(warnings, 'Duplicate + Move is selected but no naming changes are selected. No folders will be created.')
    end
    
    return warnings
end

-- Only format name if the checkbox is checked
function getNameFormatMode()
    if itm.formatNameBox.Checked then
        if itm.formatCombo.CurrentIndex == 0 then
            return 'space'
        elseif itm.formatCombo.CurrentIndex == 1 then
            return 'underscore'
        elseif itm.formatCombo.CurrentIndex == 2 then
            return 'dash'
        end
    end
    return 'none'
end

function win.On.runBtn.Clicked(ev)
    -- Validate UI state and show warnings
    local warnings = validateUIState()
    for _, warning in ipairs(warnings) do
        logMsg('Warning: ' .. warning)
    end
    
    local nameFormatMode = getNameFormatMode()
    local selectedAction = itm.actionCombo.CurrentText
    local actionMode = 'duplicate'
    local moveToFolder = false
    
    -- If saving logs is enabled, start a NEW log file for this run
    if itm.SaveLogBox and itm.SaveLogBox.Checked then
        local uiPath = (itm.SaveLogPathInput and itm.SaveLogPathInput.Text ~= '' and itm.SaveLogPathInput.Text) or nil
        if uiPath then
            selectedLogFolder = normalizePath(uiPath)
        elseif not selectedLogFolder then
            selectedLogFolder = getDefaultDocumentsFolder() .. (package.config:sub(1,1) == '\\' and '\\TimelineVersionManager\\Logs' or '/TimelineVersionManager/Logs')
        end
        ensureDirectory(selectedLogFolder)
        currentLogFilePath = generateLogFilePath()
        logMsg('Saving log to: ' .. currentLogFilePath)
        saveLogToFile = true
        logFileWritesEnabled = true
    end

    if selectedAction == 'Duplicate' then
        actionMode = 'duplicate'
        moveToFolder = false
    elseif selectedAction == 'Duplicate + Move' then
        actionMode = 'duplicate'
        moveToFolder = true
    elseif selectedAction == 'Rename only' then
        actionMode = 'rename'
        moveToFolder = false
    end

    local patterns = {
        version = itm.versionBox.Checked, 
        date = itm.dateBox.Checked, 
        appendV1 = itm.appendV1Box.Checked, 
        spaceMode = nameFormatMode,
        actionMode = actionMode,
        moveToFolder = moveToFolder,
        dateFormat = itm.dateFormatCombo.CurrentText,
        versionFormat = itm.versionFormatCombo.CurrentText,
        folderNaming = itm.folderNamingCombo.CurrentText,
        userVersionNum = itm.versionInput.Text,
        -- Add UI text values for logging
        selectedActionText = selectedAction,
        nameFormatText = itm.formatNameBox.Checked and itm.formatCombo.CurrentText or 'OFF',
    }
    
    -- Log a summary of what will happen
    logMsg('--- Summary of selected options ---')
    logMsg('Will increment version: ' .. (patterns.version and 'YES' or 'NO'))
    logMsg('Will add/replace date: ' .. (patterns.date and 'YES' or 'NO'))
    logMsg('Will append version if missing: ' .. (patterns.appendV1 and 'YES' or 'NO'))
    logMsg('Action: ' .. selectedAction)
    if patterns.actionMode == 'duplicate' and patterns.moveToFolder then
        logMsg('Will move to new folder: YES')
    end
    logMsg('Name formatting: ' .. (patterns.spaceMode ~= 'none' and patterns.spaceMode or 'OFF'))
    logMsg('-----------------------------------')
    processTimelines(patterns)
end

function win.On.closeBtn.Clicked(ev)
    dispatcher:ExitLoop()
end

-- Handle Save log to file checkbox
function win.On.SaveLogBox.Clicked(ev)
    saveLogToFile = itm.SaveLogBox.Checked
    if saveLogToFile then
        local uiPath = (itm.SaveLogPathInput and itm.SaveLogPathInput.Text ~= '' and itm.SaveLogPathInput.Text) or nil
        if uiPath then
            selectedLogFolder = normalizePath(uiPath)
        elseif not selectedLogFolder then
            local defaultFolder = getDefaultDocumentsFolder() .. (package.config:sub(1,1) == '\\' and '\\TimelineVersionManager\\Logs' or '/TimelineVersionManager/Logs')
            selectedLogFolder = defaultFolder
        end
        -- Do not create a file yet; only inform the user
        ensureDirectory(selectedLogFolder)
        currentLogFilePath = nil
        logFileWritesEnabled = false
        logMsg('Saving log to folder: ' .. selectedLogFolder)
    else
        logMsg('Save log to file disabled.')
    end
end

-- Handle Choose folder button
function win.On.browseLogBtn.Clicked(ev)
    -- With custom input line present, prefer updating it instead of native pickers
    local defaultPath = selectedLogFolder or (getDefaultDocumentsFolder() .. (package.config:sub(1,1) == '\\' and '\\TimelineVersionManager\\Logs' or '/TimelineVersionManager/Logs'))
    local input, ok = ui:RequestTextInput(ev, {
        Title = 'Enter log folder path',
        Text = 'Enter a folder path for logs:',
        Default = defaultPath,
    })
    if ok and input and input ~= '' then
        local normalizedPath = normalizePath(input)
        if itm.SaveLogPathInput then
            itm.SaveLogPathInput.Text = input -- Keep original input in UI
        end
        selectedLogFolder = normalizedPath
        ensureDirectory(selectedLogFolder)
        -- Do not generate a file yet; only update folder and inform the user
        currentLogFilePath = nil
        logMsg('Log folder set to: ' .. selectedLogFolder)
        if itm.SaveLogBox.Checked then
            saveLogToFile = true
            logFileWritesEnabled = false
            logMsg('Saving log to folder: ' .. selectedLogFolder)
        end
    else
        logMsg('No folder entered.')
    end
end

win:Show()
bgcol = { R=0.125, G=0.125, B=0.125, A=1 }
itm.TextEdit.BackgroundColor = bgcol
itm.TextEdit:SetPaletteColor('All', 'Base', bgcol)

dispatcher:RunLoop()
win:Hide()