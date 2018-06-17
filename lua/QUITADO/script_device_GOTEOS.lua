#!/usr/bin/lua
commandArray = {}
if (devicechanged['GOTEOS'] == 'On') then
	local mintRiego = uservariables["TIEMPO-RIEGO"]
	local patiotRiego = uservariables["PATIO-RIEGO"]
	local sectRiego = mintRiego * 60
	local secPatiotRiego = patiotRiego * 60
	local onStr = 'On FOR ' .. mintRiego

	print('COMENZANDO RIEGO GOTEOS')
	--Abrimos la valvula general
	commandArray['EV-GENERAL'] = 'On FOR ' .. (3*mintRiego + patiotRiego)
	commandArray['EV-GOTEOBAJO']= onStr
  commandArray['EV-GOTEOALTO'] = onStr .. " AFTER " .. sectRiego
  commandArray['EV-GOTEOOLIVO'] = onStr .. " AFTER " .. 2*sectRiego
  commandArray['EV-PATIO'] = 'On FOR ' .. patiotRiego .. " AFTER " .. 3*sectRiego
	commandArray['GOTEOS'] = 'Off AFTER ' .. (3*sectRiego + secPatiotRiego)
end

if (devicechanged['GOTEOS'] == 'Off') then
	-- Paramos
	print('PARADA FORZADA DE RIEGO GOTEOS')
	commandArray['EV-GENERAL'] = 'Off'
	commandArray['EV-GOTEOBAJO']= 'Off'
	commandArray['EV-GOTEOALTO']= 'Off'
	commandArray['EV-GOTEOOLIVO']= 'Off'
	commandArray['EV-PATIO']= 'Off'
end

return commandArray
