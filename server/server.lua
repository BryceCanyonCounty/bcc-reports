VORPcore = exports.vorp_core:GetCore()
BccUtils = exports['bcc-utils'].initiate()
--local Discord = BccUtils.Discord.setup(Config.Webhook.webhookUrl, Config.Webhook.webhookTitle, Config.Webhook.webhookAvatar)
Discord = BccUtils.Discord.setup(Config.WebhookLink, Config.WebhookTitle, Config.WebhookAvatar) -- Setup Discord webhook

local Callbacks = {}
local reports = {}

-- Helper function for debugging in DevMode
if Config.DevMode then
    function devPrint(message)
        print("^1[DEV MODE] ^4" .. message)
    end
else
    function devPrint(message) end -- No-op if DevMode is disabled
end

-- Register server callback
function RegisterServerCallback(name, cb)
    if not Callbacks then Callbacks = {} end
    Callbacks[name] = cb
end

-- Handle server callback requests
RegisterNetEvent('bcc_reports:triggerServerCallback')
AddEventHandler('bcc_reports:triggerServerCallback', function(name, requestId, ...)
    local src = source
    if Callbacks[name] then
        -- Print the callback request for debugging
        print('Callback triggered: ' .. name .. ' for player ID: ' .. tostring(src))
        Callbacks[name](src, function(...)
            TriggerClientEvent('bcc_reports:serverCallbackResponse', src, requestId, ...)
        end, ...)
    else
        print('No callback found for: ' .. name)
    end
end)

-- Function to generate a UUID for reports
local function uuid()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

-- Admin Check Event
RegisterServerEvent("bcc_reports:AdminCheck")
AddEventHandler("bcc_reports:AdminCheck", function()
    local src = source -- Get the player's source
    local admin = false -- Variable to track admin status
    local user = VORPcore.getUser(src) -- Get the user
    local character = user.getUsedCharacter -- Get the player's character

    -- Debug log
    devPrint("AdminCheck triggered for user: " .. tostring(character.identifier))

    -- Check if the player's group is in the adminGroup list
    for _, group in pairs(Config.adminGroup) do
        if character.group == group then
            admin = true
            TriggerClientEvent('bcc_reports:AdminVarCatch', src, true) -- Send admin status to client
            devPrint("Admin status granted based on group: " .. group)
            break -- Exit the loop once we find a match
        end
    end

    -- If no admin status is granted
    if not admin then
        TriggerClientEvent('bcc_reports:AdminVarCatch', src, false) -- Send false to client
        devPrint("Admin status denied.")
    end
end)

local function sendNotificationToStaff()
    for _, playerId in ipairs(GetPlayers()) do
        -- Fetch the user object using VORPcore
        local user = VORPcore.getUser(playerId)

        -- Check if the user object is valid
        if user then
            local character = user.getUsedCharacter

            -- Ensure the character object exists and has the necessary group
            if character and character.group then
                -- Check if the player's group matches any admin group in the config
                for _, group in pairs(Config.adminGroup) do
                    if character.group == group then
                        devPrint("Sending notification to admin player ID: " .. tostring(playerId))
                        
                        -- Notify the staff using VORPcore's NotifyLeft
                        VORPcore.NotifyLeft(playerId, _U('newReport'), _U('newReportSubmitted'), "menu_textures", "menu_icon_alert", 15000, "COLOR_RED")
                        break -- Exit the loop once we send the notification
                    end
                end
            else
                devPrint("Character or group not found for player ID: " .. tostring(playerId))
            end
        else
            devPrint("User not found for player ID: " .. tostring(playerId))
        end
    end
end

-- Get current reports and format the created_at date using SQL's DATE_FORMAT
RegisterServerCallback('bcc_reports:getCurrentReports', function(source, cb)
    MySQL.query([[
        SELECT
            report_id,
            charIdentifier,
            firstname,
            lastname,
            DATE_FORMAT(created_at, '%d-%m-%Y %H:%i:%s') AS created_at, -- Ensure date is formatted
            completed,
            details,
            player_id
        FROM bcc_reports
        ORDER BY created_at DESC
    ]], {}, function(reports)
        if reports then
            cb(reports)
        else
            cb({})
        end
    end)
end)

-- Creating a report and inserting it into the database
RegisterServerEvent('bcc_reports:createReport')
AddEventHandler('bcc_reports:createReport', function(data)
    local src = source
    local reportId = uuid()

    -- Debugging log to confirm the received player_id
    devPrint("Creating report for player_id: " .. tostring(src))

    -- Get the player and character information from VORPcore
    local user = VORPcore.getUser(src)

    -- Check if the user is valid and exists in the session
    if not user then
        devPrint(_U('userNotFound', tostring(src)))
        return
    end

    -- Get the character information
    local character = user.getUsedCharacter
    local steamname = GetPlayerName(src)

    -- Check if the character exists
    if not character then
        devPrint(_U('characterNotFound', tostring(src)))
        return
    end

    local reportTypeValue = data.report_type.value or data.report_type -- Extract 'value'

    -- Insert the report into the database
    MySQL.insert('INSERT INTO bcc_reports (report_id, title, details, type, player_id, steamname, charIdentifier, firstname, lastname) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
    {
        reportId,
        data.name,
        data.detail,
        reportTypeValue, -- Use the extracted 'value' for the type
        src,
        steamname,
        character.charIdentifier,
        character.firstname,
        character.lastname
    }, function(id)
        if id then
            devPrint("Report successfully created with ID: " .. reportId)
            -- Notify staff of the new report
            sendNotificationToStaff()
            Discord:sendMessage("Test message to ensure Discord integration works.", function(success)
                if success then
                    devPrint("Test Discord message sent successfully.")
                else
                    devPrint("Failed to send test Discord message.")
                end
            end)
            -- Send Discord notification if webhook is enabled
            if Config.WebhookEnabled then
                devPrint("Sending Discord notification...") -- Debug message

                -- Send the Discord message with the report details
                Discord:sendMessage("New Report Created: \n\n" ..
                    "**Title:** " .. data.name .. "\n" ..
                    "**Message:** " .. data.detail .. "\n" ..
                    "**Type:** " .. data.report_type.display .. "\n" ..
                    "**Player ID:** " .. tostring(src) .. "\n" ..
                    "**Steam Name:** " .. steamname .. "\n" ..
                    "**Character Name:** " .. character.firstname .. " " .. character.lastname .. "\n" ..
                    "**Character ID:** " .. character.charIdentifier .. "\n" ..
                    "**Report ID:** " .. reportId
                )
            end
        else
            devPrint("Failed to insert report.")
        end
    end)
end)

-- Teleport to player
RegisterNetEvent('bcc_reports:TeleportToPlayer')
AddEventHandler('bcc_reports:TeleportToPlayer', function(targetPlayerId)
    local src = source

    -- Ensure targetPlayerId is valid
    if not targetPlayerId or not tonumber(targetPlayerId) then
        devPrint(_U('invalidPlayerIdTeleport'))
        return
    end

    local targetPed = GetPlayerPed(targetPlayerId)
    if targetPed then
        local targetCoords = GetEntityCoords(targetPed)

        -- Ensure admin is valid and teleport to the player's location
        local srcPed = GetPlayerPed(src)
        if srcPed then
            SetEntityCoords(srcPed, targetCoords.x, targetCoords.y, targetCoords.z, false, false, false, true)
        else
            devPrint(_U('adminPedNotFound'))
        end
    else
        devPrint(_U('targetPedNotFound'))
    end
end)

-- Bring player to admin
RegisterNetEvent('bcc_reports:BringPlayer')
AddEventHandler('bcc_reports:BringPlayer', function(targetPlayerId)
    local src = source

    -- Ensure targetPlayerId is valid
    if not targetPlayerId or not tonumber(targetPlayerId) then
        devPrint(_U('invalidPlayerIdBring'))
        return
    end

    local adminPed = GetPlayerPed(src)
    if adminPed then
        local adminCoords = GetEntityCoords(adminPed)

        -- Ensure target player exists and bring them to admin's location
        local targetPed = GetPlayerPed(targetPlayerId)
        if targetPed then
            SetEntityCoords(targetPed, adminCoords.x, adminCoords.y, adminCoords.z, false, false, false, true)
        else
            devPrint(_U('targetPedNotFound'))
        end
    else
        devPrint(_U('adminPedNotFound'))
    end
end)

-- Check report and mark it as completed
RegisterNetEvent('bcc_reports:CheckReport')
AddEventHandler('bcc_reports:CheckReport', function(reportId)
    local src = source

    -- Ensure src is valid
    if not src or not tonumber(src) then
        devPrint(_U('invalidAdminId'))
        return
    end

    local user = VORPcore.getUser(src)
    if not user then
        devPrint(_U('adminUserNotFound'))
        return
    end

    local character = user.getUsedCharacter
    if not character then
        devPrint(_U('adminCharacterNotFound'))
        return
    end

    local steamname = GetPlayerName(src)
    if not steamname then
        devPrint(_U('adminSteamNameNotFound'))
        return
    end

    -- Mark the report as completed and store the admin details
    MySQL.update([[
        UPDATE bcc_reports
        SET completed = 1,
            completed_by_steamname = ?,
            completed_by_charid = ?,
            completed_by_name = ?
        WHERE report_id = ?
    ]], {
        steamname,                                        -- Admin's Steam name
        character.charIdentifier,                         -- Admin's character ID
        character.firstname .. " " .. character.lastname, -- Admin's name
        reportId                                          -- Report ID to update
    }, function(affectedRows)
        if affectedRows > 0 then
            devPrint(_U('reportCompleted', reportId, steamname))
        else
            devPrint(_U('reportUpdateFailed', reportId))
        end
    end)
end)

-- Register a callback to delete a report
RegisterServerCallback('bcc_reports:deleteReport', function(source, cb, data)
    -- Ensure the data object is valid and contains the report_id
    if not data or not data.report_id then
        devPrint("Error: Invalid data or missing report_id") -- Use devPrint for debugging
        cb(false)
        return
    end

    -- Delete the report from the database
    MySQL.update('DELETE FROM bcc_reports WHERE report_id = ?', { data.report_id }, function(affectedRows)
        if affectedRows > 0 then
            cb(true)
        else
            devPrint("Error: Failed to delete report with ID: " .. tostring(data.report_id)) -- Debugging log
            cb(false)
        end
    end)
end)

BccUtils.Versioner.checkFile(GetCurrentResourceName(), 'https://github.com/BryceCanyonCounty/bcc-reports')
