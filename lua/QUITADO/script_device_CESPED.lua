#!/usr/bin/lua
--Script para regar solo el cesped

commandArray = {}
_ENV.aguaInicial = 0
aguaFinal = 0
consumo = 0

if (devicechanged['CESPED'] == 'On') then
	aguaInicial = tonumber(otherdevices_svalues['CONTADOR AGUA'])
	print('inicial: ' .. aguaInicial)
	local mintRiego = uservariables["TIEMPO-RIEGO"]
	local sectRiego = mintRiego * 60
	local onStr = 'On FOR ' .. mintRiego

	print('COMENZANDO RIEGO CESPED')
	--Abrimos la valvula general
	commandArray['EV-GENERAL'] = 'On FOR ' .. 4*mintRiego
	commandArray['EV-TURBINAS'] = onStr
	commandArray['EV-PORCHE'] = onStr .. " AFTER " .. sectRiego
	commandArray['EV-CUARTILLO'] = onStr .. " AFTER " .. 2*sectRiego
	commandArray['EV-PIEDRAS'] = onStr .. " AFTER " .. 3*sectRiego
	commandArray['CESPED'] = 'Off AFTER ' .. 4*sectRiego
end

if (devicechanged['CESPED'] == 'Off') then
	-- Paramos
	print('PARADA FORZADA DE RIEGO CESPED')
	commandArray['EV-GENERAL']= 'Off'
	commandArray['EV-TURBINAS']= 'Off'
	commandArray['EV-PORCHE']= 'Off'
	commandArray['EV-CUARTILLO']= 'Off'
	commandArray['EV-PIEDRAS'] = 'Off'
        aguaFinal = tonumber(otherdevices_svalues['CONTADOR AGUA'])
        print('final: ' .. aguaFinal)
	print('inicial en final: ' .. _ENV.aguaInicial)
        consumo = (aguaFinal - _ENV.aguaInicial)
        commandArray['SendNotification'] = 'CONSUMO RIEGO CESPED: ' .. tostring(consumo) .. " litros."
end

return commandArray
