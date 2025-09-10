ESX = exports["es_extended"]:getSharedObject()

local isMenuOpen = false

-- Open job manager menu
RegisterNetEvent('esx-job-manager:openMenu', function()
    if isMenuOpen then return end
    
    isMenuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openMenu'
    })
    
    -- Request data from server
    TriggerServerEvent('esx-job-manager:requestData')
end)

-- Receive data from server
RegisterNetEvent('esx-job-manager:receiveData', function(data)
    SendNUIMessage({
        action = 'receiveData',
        data = data
    })
end)

-- Job events
RegisterNetEvent('esx-job-manager:jobCreated', function()
    TriggerServerEvent('esx-job-manager:requestData')
end)

RegisterNetEvent('esx-job-manager:jobUpdated', function()
    TriggerServerEvent('esx-job-manager:requestData')
end)

RegisterNetEvent('esx-job-manager:jobDeleted', function()
    TriggerServerEvent('esx-job-manager:requestData')
end)

-- Función para cerrar el menú (mejorada)
function CloseMenu()
    if not isMenuOpen then return end
    
    print("Cerrando menú...")
    isMenuOpen = false
    
    -- Cerrar NUI inmediatamente
    SendNUIMessage({
        action = 'closeMenu'
    })
    
    -- Liberar foco de forma segura
    SetNuiFocus(false, false)
    
    -- Thread de seguridad
    CreateThread(function()
        Wait(100)
        SetNuiFocus(false, false)
        print("Menú cerrado completamente")
    end)
end

-- NUI Callbacks (con mejor manejo de errores)
RegisterNUICallback('closeMenu', function(data, cb)
    CloseMenu()
    if cb then cb('ok') end
end)

RegisterNUICallback('createJob', function(data, cb)
    print('Callback createJob recibido:', json.encode(data))
    
    -- Obtener coordenadas actuales del jugador
    local playerCoords = GetEntityCoords(PlayerPedId())
    data.blip_coords = json.encode({
        x = math.floor(playerCoords.x + 0.5),
        y = math.floor(playerCoords.y + 0.5),
        z = math.floor(playerCoords.z + 0.5)
    })
    
    TriggerServerEvent('esx-job-manager:createJob', data)
    if cb then cb('ok') end
end)

RegisterNUICallback('updateJob', function(data, cb)
    print('Callback updateJob recibido:', json.encode(data))
    TriggerServerEvent('esx-job-manager:updateJob', data.id, data.jobData)
    if cb then cb('ok') end
end)

RegisterNUICallback('deleteJob', function(data, cb)
    print('Callback deleteJob recibido:', json.encode(data))
    TriggerServerEvent('esx-job-manager:deleteJob', data.id)
    if cb then cb('ok') end
end)

RegisterNUICallback('toggleJobStatus', function(data, cb)
    print('Callback toggleJobStatus recibido:', json.encode(data))
    TriggerServerEvent('esx-job-manager:toggleJobStatus', data.id, data.isActive)
    if cb then cb('ok') end
end)

-- ESC Key Handler
CreateThread(function()
    while true do
        Wait(0)
        if isMenuOpen then
            -- Deshabilitar controles
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 257, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 263, true)
            
            -- ESC para cerrar
            if IsControlJustPressed(0, 322) then
                CloseMenu()
            end
        else
            Wait(500)
        end
    end
end)

-- Comandos de emergencia
RegisterCommand('closemenu', function()
    CloseMenu()
end, false)

RegisterCommand('resetfocus', function()
    SetNuiFocus(false, false)
    isMenuOpen = false
    SendNUIMessage({ action = 'closeMenu' })
end, false)