#!/usr/bin/lua
commandArray = {}
if (devicechanged['COMPLETO'] == 'On') then
        local mintRiego = uservariables["TIEMPO-RIEGO"]
        local patiotRiego = uservariables["PATIO-RIEGO"]
        local sectRiego = mintRiego * 60
        local secPatiotRiego = patiotRiego * 60
        local onStr = 'On FOR ' .. mintRiego

        print('COMENZANDO RIEGO COMPLETO')
        --Abrimos la valvula general
        commandArray['EV-GENERAL'] = 'On FOR ' .. 7*mintRiego + patiotRiego
        commandArray['EV-TURBINAS'] = onStr 
        commandArray['EV-PORCHE'] = onStr .. " AFTER " .. sectRiego
        commandArray['EV-CUARTILLO'] = onStr .. " AFTER " .. 2*sectRiego
        commandArray['EV-PIEDRAS'] = onStr .. " AFTER " .. 3*sectRiego
        commandArray['EV-GOTEOBAJO']= onStr .. " AFTER " .. 4*sectRiego
        commandArray['EV-GOTEOALTO'] = onStr .. " AFTER " .. 5*sectRiego
        commandArray['EV-GOTEOOLIVO'] = onStr .. " AFTER " .. 6*sectRiego
        commandArray['EV-PATIO'] = 'On FOR ' .. patiotRiego .. " AFTER " .. 7*sectRiego
        commandArray['COMPLETO'] = 'Off AFTER ' .. 7*sectRiego + secPatiotRiego
end

if (devicechanged['COMPLETO'] == 'Off') then
        -- Paramos
        print('PARADA FORZADA DE RIEGO COMPLETO')
        commandArray['EV-GENERAL'] = 'Off'
        commandArray['EV-TURBINAS']= 'Off'
        commandArray['EV-PORCHE']= 'Off'
        commandArray['EV-CUARTILLO']= 'Off'
        commandArray['EV-PIEDRAS'] = 'Off'
        commandArray['EV-GOTEOBAJO']= 'Off'
        commandArray['EV-GOTEOALTO']= 'Off'
        commandArray['EV-GOTEOOLIVO'] = 'Off'
        commandArray['EV-PATIO'] = 'Off'
end

return commandArray
