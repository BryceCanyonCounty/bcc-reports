if Config.DevMode then
    -- Helper function for debugging
    function devPrint(message)
        print("^1[DEV MODE] ^4" .. message)
    end
else
    -- Define devPrint as a no-op function if DevMode is not enabled
    function devPrint(message)
    end
end

local admin = false -- Local variable to store admin status
RegisterNetEvent('vorp:SelectedCharacter')
AddEventHandler('vorp:SelectedCharacter', function()
    TriggerServerEvent("bcc_reports:AdminCheck")
end)

-- Trigger the server-side check when the player loads or at the appropriate time
CreateThread(function()
    TriggerServerEvent("bcc_reports:AdminCheck")
end)

-- Catch the admin check result from the server
RegisterNetEvent('bcc_reports:AdminVarCatch')
AddEventHandler('bcc_reports:AdminVarCatch', function(var)
    devPrint("AdminVarCatch event triggered. Admin status: " .. tostring(var))
    admin = var -- Update the local admin status
end)

-- Command to view reports, only if the player is an admin
RegisterCommand(Config.ViewReportsMenu, function()
    if admin then
        devPrint("ViewReportsMenu executed by admin. Opening report viewer.")
        Viewreports() -- Function to open the report viewer
    else
        devPrint("ViewReportsMenu attempted but player is not admin.")
        VORPcore.NotifyObjective(_U('youAreNotAdmin'), 4000) -- Notify the player they are not an admin
    end
end, false)

RegisterCommand(Config.CreateReportCommand, function()
    CreateReport()
end, false)

function CreateReport()
    local ReportPage = BCCReportMenu:RegisterPage('create_report_page')

    -- Header for the report menu
    ReportPage:RegisterElement('header', {
        value = _U('createReport'),
        slot = "header",
    })

    -- Input for report title
    local reportTitle = ''
    ReportPage:RegisterElement('input', {
        label = _U('reportTitle'),
        placeholder = _U('enterReportTitle'),
    }, function(data)
        reportTitle = data.value or ''                              -- Ensure a value is captured
        devPrint("Report Title Entered: " .. tostring(reportTitle)) -- Use devPrint for debugging
    end)

-- Function to convert a table to a string for debugging
function TableToString(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. TableToString(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

-- Dropdown for selecting report type
local reportType = ''
ReportPage:RegisterElement('arrows', {
    label = _U('reportType'),
    start = 1, -- This will set the first option as the default selected
    options = {
        { display = _U('playerReport'), value = 'playerReport' },
        { display = _U('bugReport'),    value = 'bugReport' },
        { display = _U('staffReport'),  value = 'staffReport' },
        { display = _U('otherReport'),  value = 'otherReport' }
    }
}, function(data)
    reportType = data.value or ''
    devPrint("Report Type Selected: " .. TableToString(data)) -- Use TableToString for structured output
end)

    -- Example of how it would look with a localized label and placeholder
    local reportDescription = ''
    ReportPage:RegisterElement('textarea', {
        label = _U('reportDescription'),            -- Translated label
        placeholder = _U('enterReportDescription'), -- Translated placeholder
        rows = "6",
        resize = false,
        style = {}
    }, function(data)
        reportDescription = data.value or ''
        devPrint("Report Description Entered: " .. tostring(reportDescription)) -- Debugging log
    end)

    ReportPage:RegisterElement('line', {
        slot = "footer"
    })

-- Submit button for the report
ReportPage:RegisterElement('button', {
    label = _U('submitReport'),
    slot = "footer"
}, function()
    -- Ensure all fields are filled before submitting
    if reportTitle ~= '' and reportType ~= '' and reportDescription ~= '' then
        -- Trigger the server-side report creation event
        TriggerServerEvent('bcc_reports:createReport', {
            name = reportTitle,
            detail = reportDescription,
            report_type = reportType,
            player_id = GetPlayerServerId(PlayerId()) -- Ensure player_id is passed
        })

        VORPcore.NotifyObjective(_U('newReportSubmitted'), 5000) -- Debug log indicating the report was submitted

        -- Close the menu after submission
        BCCReportMenu:Close()
    else
        VORPcore.NotifyObjective(_U('fillAllFields'), 4000) -- Use devPrint to indicate missing fields
    end
end)

    ReportPage:RegisterElement('bottomline', {
        slot = "footer"
    })

    -- Open the menu
    BCCReportMenu:Open({
        startupPage = ReportPage
    })
end

function Viewreports()
    -- Fetch the list of reports from the server
    TriggerServerCallback('bcc_reports:getCurrentReports', function(reports)
        devPrint("Server callback triggered. Number of reports: " .. #reports)

        -- Page for viewing reports
        local ViewReportsPage = BCCReportMenu:RegisterPage('bcc:view:reports:page')
        devPrint("ViewReportsPage registered.")

        -- Header for the report viewing menu
        ViewReportsPage:RegisterElement('header', {
            value = _U('submittedReports'),
            slot = "header",
        })
        devPrint("Header element registered.")

        if #reports > 0 then
            -- Number the reports
            for index, report in ipairs(reports) do
                -- Use the created_at field as is (already formatted on the server-side)
                local buttonLabel = string.format(
                    "%d. Char ID: %s | Name: %s %s",
                    index,                 -- Report number based on the order
                    report.charIdentifier, -- Character Identifier
                    report.firstname,      -- Character First Name
                    report.lastname        -- Character Last Name
                )

                -- Display each report in the menu as a button with relevant details
                ViewReportsPage:RegisterElement('button', {
                    label = buttonLabel,
                    style = {}
                }, function()
                    devPrint("Button clicked for report: " .. buttonLabel)
                    -- After clicking on the report, open the action menu for the report
                    OpenReportActionMenu(report)
                end)
            end
        else
            -- Show a message if there are no reports
            ViewReportsPage:RegisterElement('button', {
                label = _U('noReportsAvailable'),
                style = {}
            })
            devPrint("No reports available.")
        end

        -- Open the menu after the reports are populated
        BCCReportMenu:Open({
            startupPage = ViewReportsPage
        })
        devPrint("Menu opened.")
    end)
end

-- Client Event to Handle Transformation after Teleportation
RegisterNetEvent('bcc-reports:client:teleportAndTransform')
AddEventHandler('bcc-reports:client:teleportAndTransform', function(model)
    local modelHash = GetHashKey(model)
    
    -- Request and load the model
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(1)
    end

    -- Execute Transformation
    local player = PlayerId()
    Citizen.Wait(250)
    Citizen.InvokeNative(0xED40380076A31506, player, modelHash, false)  -- Set player model
    Citizen.Wait(250)
    Citizen.InvokeNative(0x283978A15512B2FE, PlayerPedId(), false)      -- Randomize outfit variation
    Citizen.Wait(250)
    Citizen.InvokeNative(0x77FF8D35EEC6BBC4, PlayerPedId(), 4, 0)       -- Apply outfit components
    Citizen.Wait(250)
    SetEntityMaxHealth(PlayerPedId(), 1000)
    Citizen.Wait(250)
    SetEntityHealth(PlayerPedId(), 1000)
    Citizen.Wait(250)
    SetModelAsNoLongerNeeded(model)

    -- Trigger Timer Effect
    inform = true
end)

-- Timer Effect (bcc-report:client:timer)
RegisterNetEvent('bcc-reports:client:timer')
AddEventHandler('bcc-reports:client:timer', function()
    while inform do
        Citizen.InvokeNative(0xE4CB5A3F18170381, PlayerId(), 20.0)  -- Apply transformation effect
        Citizen.Wait(3)
    end
    ExecuteCommand('rc')                                             -- Execute reset command
    TriggerServerEvent('bcc-reports:server:rc')                       -- Notify server reset
end)

-- Reset Command (bcc-report:client:rc)
RegisterNetEvent('bcc-reports:client:rc')
AddEventHandler('bcc-reports:client:rc', function()
    inform = false
    Citizen.InvokeNative(0xE4CB5A3F18170381, PlayerId(), 1.0)       -- Reset transformation effect
    ExecuteCommand('rc')                                             -- Execute reset command again
    TriggerServerEvent('bcc-reports:server:rc')                       -- Notify server of reset
end)

-- Function to open the report actions menu
function OpenReportActionMenu(report)
    -- Page for report actions
    local ReportActionsPage = BCCReportMenu:RegisterPage('bcc:report:actions:page')

    -- Header for the actions menu
    ReportActionsPage:RegisterElement('header', {
        value = _U('actionsForReport'),
        slot = "header",
    })

    -- Display the report details as text using HTML
    local reportStatus = report.completed and _U('completed') or _U('pending')
    local reportDetailsHTML = string.format([[
        <div style="border: 1px solid #ccc; padding: 10px; border-radius: 5px; width: 80%%; margin: 0 auto; text-align: center;">
            <strong style="color: #4CAF50; font-size: 18px;">%s</strong><br>
            <p><strong style="color: #333;">%s:</strong> <span style="color: #007BFF;">%s</span></p>
            <p><strong style="color: #333;">%s:</strong> <span style="color: #007BFF;">%s %s</span></p>
            <p><strong style="color: #333;">%s:</strong> <span style="color: #FF5733;">%s</span></p>
            <p><strong style="color: #333;">%s:</strong> <span style="color: %s;">%s</span></p>
            <p><strong style="color: #333;">%s:</strong> <span style="color: #555;">%s</span></p>
        </div>
    ]],
        _U('reportDetails'),                   -- Report header
        _U('charId'), report.charIdentifier,   -- Character Identifier
        _U('name'), report.firstname, report.lastname,  -- Name (First + Last)
        _U('reportDate'), report.created_at,   -- Report Creation Date
        _U('status'), report.completed and "#4CAF50" or "#FF0000", reportStatus,  -- Status (Completed/Pending)
        _U('message'), report.details or _U('noDetailsAvailable')  -- Details
    )

    -- Add the report details to the menu as HTML
    ReportActionsPage:RegisterElement('html', {
        value = reportDetailsHTML
    })

    -- Option: Teleport to Player
    ReportActionsPage:RegisterElement('button', {
        label = _U('teleportToPlayer'),
        style = {}
    }, function()
        -- Ensure report.player_id is valid
        if report.player_id and tonumber(report.player_id) then
            -- Trigger server event to teleport to player
            TriggerServerEvent('bcc_reports:TeleportToPlayer', report.player_id)
        else
            devPrint(_U('invalidPlayerIdTeleport'))
        end
    end)

    -- Option: Bring Player
    ReportActionsPage:RegisterElement('button', {
        label = _U('bringPlayer'),
        style = {}
    }, function()
        -- Ensure report.player_id is valid
        if report.player_id and tonumber(report.player_id) then
            -- Trigger server event to bring player to you
            TriggerServerEvent('bcc_reports:BringPlayer', report.player_id)
        else
            devPrint(_U('invalidPlayerIdBring'))
        end
    end)

    -- Option: Check Report
    ReportActionsPage:RegisterElement('button', {
        label = _U('checkReport'),
        style = {}
    }, function()
        TriggerServerEvent('bcc_reports:CheckReport', report.report_id)
        ExecuteCommand('rc')                                             -- Execute reset command
        TriggerServerEvent('bcc-report:server:rc')                       -- Notify server reset
        BCCReportMenu:Close()
    end)

    ReportActionsPage:RegisterElement('line', {
        slot = "footer"
    })

    ReportActionsPage:RegisterElement('button', {
        label = _U('deleteReport'),
        slot = "footer",
        style = {}
    }, function()
        TriggerServerCallback('bcc_reports:deleteReport', function(success)
            if success then
                -- You can display a success message
                VORPcore.NotifyObjective(_U('reportDeletedSuccessfully'), 4000)
            else
                -- You can display a failure message
                VORPcore.NotifyObjective(_U('reportDeletionFailed'), 4000)
            end
        end, {
            report_id = report.report_id -- Ensure you're passing report_id as part of a table
        })
        Viewreports(report)
    end)

    -- Option: Delete Report
    ReportActionsPage:RegisterElement('button', {
        label = _U('backButton'),
        slot = "footer",
        style = {}
    }, function()
        Viewreports(report)
    end)

    ReportActionsPage:RegisterElement('bottomline', {
        slot = "footer"
    })

    -- Open the action menu after the report is clicked
    BCCReportMenu:Open({
        startupPage = ReportActionsPage
    })
end
