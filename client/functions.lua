VORPcore = exports.vorp_core:GetCore()
FeatherMenu = exports['feather-menu'].initiate()
BccUtils = exports['bcc-utils'].initiate()

ClientReportCallbacks = {}
local RequestId = 0

-- Custom callback function to trigger server events
function TriggerServerCallback(name, cb, ...)
    RequestId = RequestId + 1
    ClientReportCallbacks[RequestId] = cb

    TriggerServerEvent('bcc_reports:triggerServerCallback', name, RequestId, ...)
end

-- Handle server callback responses
RegisterNetEvent('bcc_reports:serverCallbackResponse')
AddEventHandler('bcc_reports:serverCallbackResponse', function(requestId, ...)
    if ClientReportCallbacks[requestId] then
        ClientReportCallbacks[requestId](...)
        ClientReportCallbacks[requestId] = nil
    end
end)

-- Register and configure the BCCStoresMainMenu with FeatherMenu
BCCReportMenu = FeatherMenu:RegisterMenu('bcc-reports:mainmenu', {
    top = '5%',
    left = '5%',
    ['720width'] = '500px',
    ['1080width'] = '600px',
    ['2kwidth'] = '700px',
    ['4kwidth'] = '900px',
    style = {},
    contentslot = {
      style = {
        ['height'] = '450px',
        ['min-height'] = '350px'
      }
    },
    draggable = true
  }, {
    opened = function()
        DisplayRadar(false)
    end,
    closed = function()
        DisplayRadar(true)
    end,
})