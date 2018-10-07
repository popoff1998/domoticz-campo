-- Variables de control
nriegosCESPED = 4
nriegosGOTEOS = 5
abreGeneral = true

-- Funciones
local function RiegaCesped(domoticz,delay,tRiego)
    domoticz.devices('EV-TURBINAS').switchOn().afterMin(delay).forMin(tRiego)
    domoticz.devices('EV-PORCHE').switchOn().afterMin(tRiego + delay).forMin(tRiego)
    domoticz.devices('EV-CUARTILLO').switchOn().afterMin(2*tRiego + delay).forMin(tRiego)
    domoticz.devices('EV-PIEDRAS').switchOn().afterMin(3*tRiego + delay).forMin(tRiego)
end

local function RiegaGoteos(domoticz,delay,tRiego,tPatio)
    domoticz.devices('EV-GOTEOBAJO').switchOn().afterMin(delay).forMin(tRiego)
    domoticz.devices('EV-GOTEOALTO').switchOn().afterMin(tRiego + delay).forMin(tRiego)
    domoticz.devices('EV-GOTEOOLIVO').switchOn().afterMin(2*tRiego + delay).forMin(tRiego)
    domoticz.devices('EV-ROCALLA').switchOn().afterMin(3*tRiego + delay).forMin(tRiego)
    domoticz.devices('EV-PATIO').switchOn().afterMin(4*tRiego + delay).forMin(tPatio)
end

local function TerminaCesped(domoticz)
    domoticz.devices('EV-TURBINAS').switchOff()
    domoticz.devices('EV-PORCHE').switchOff()
    domoticz.devices('EV-CUARTILLO').switchOff()
    domoticz.devices('EV-PIEDRAS').switchOff()
end

local function TerminaGoteos(domoticz)
    domoticz.devices('EV-GOTEOBAJO').switchOff()
    domoticz.devices('EV-GOTEOALTO').switchOff()
    domoticz.devices('EV-GOTEOOLIVO').switchOff()
    domoticz.devices('EV-ROCALLA').switchOff()
    domoticz.devices('EV-PATIO').switchOff()
end

local function AbreGeneral(domoticz,tiempo)
    if(abreGeneral) then
        domoticz.devices('EV-GENERAL').switchOn().forMin(tiempo)
    end
end

-- Programa principal
return {
    active = true,
	on = {
		devices = {
		    'COMPLETO',
			'CESPED',
			'GOTEOS'
		}
	},
	logging = {
	    level = domoticz.LOG_DEBUG,
	    marker = "MYDEBUG"
	},
	data = {
	    -- semaforo controlara si se esta regando en un riego de grupo
	    semaforo = { initial = false },
	    -- offInterno conrolara si ha sido el propio script quien ha apagado el boton
	    offInterno = { initial = false },
	    -- Almacenará el contador de agua al comenzar el riego
        contadorInicial = { initial = 0 },
        -- Tabla de estados de los botones
        estado = { initial = {['COMPLETO'] = false, ['CESPED'] = false, ['GOTEOS'] = false }}
	},
	execute = function(domoticz,boton)
        tRiego = domoticz.variables('TIEMPO-RIEGO').value
        tPatio = domoticz.variables('PATIO-RIEGO').value

        -- EL BOTON SE ENCIENDE
        -- Antes que nada deshabilitamos los dobles clicks de botones de grupos
	    if(boton.state == 'On' and domoticz.data.semaforo) then
	        -- Mandamos la notificacion
	        domoticz.notify('RIEGOERROR','*Riego ' .. boton.name .. ' no activado por bloqueo de semaforo*',domoticz.PRIORITY_HIGH)
	        -- Comprobamos que no es un "rebote" por programacion
	        if(not domoticz.data.estado[boton.name]) then
	            domoticz.data.offInterno = true
                boton.switchOff()
            else
                domoticz.notify('RIEGOINFO','*Riego ' .. boton.name .. ' debia ser una programacion de un riego lanzado a mano antes*',domoticz.PRIORITY_HIGH)
            end
	    elseif(boton.state == 'On') then
	        -- Mandamos la notificacion
	        domoticz.notify('RIEGOON','*Riego ' .. boton.name .. ' comenzado*',domoticz.PRIORITY_HIGH)
            -- Habilitamos el semaforo
	        domoticz.data.semaforo = true
	        -- Cambiamos su estado
	        domoticz.data.estado[boton.name] = true
	        -- Leemos el contador
	        domoticz.data.contadorInicial = domoticz.devices('CONTADOR AGUA').counter
	        domoticz.log('CONTADOR: ' .. domoticz.data.contadorInicial,domoticz.LOG_FORCE)
	        -- Operamos segun el boton pulsado
	        if(boton.name == 'COMPLETO') then
                AbreGeneral(domoticz,((nriegosCESPED + nriegosGOTEOS -1) * tRiego) + tPatio)
                RiegaCesped(domoticz,0,tRiego)
                RiegaGoteos(domoticz,nriegosCESPED * tRiego,tRiego,tPatio)
                boton.switchOff().afterMin(((nriegosCESPED + nriegosGOTEOS -1) * tRiego) + tPatio)            
	        elseif(boton.name == 'CESPED') then
                AbreGeneral(domoticz,nriegosCESPED * tRiego)
                RiegaCesped(domoticz,0,tRiego)
                boton.switchOff().afterMin(nriegosCESPED * tRiego)            
            elseif(boton.name == 'GOTEOS') then
                AbreGeneral(domoticz,((nriegosGOTEOS -1) * tRiego) + tPatio)
                RiegaGoteos(domoticz,0,tRiego,tPatio)
                boton.switchOff().afterMin(((nriegosGOTEOS -1) * tRiego) + tPatio)            
            end
        end
        
        -- EL BOTON SE APAGA
	    if(boton.state == 'Off') then
            domoticz.log('DEVICE: ' .. boton.name .. 
                         ' Estados: ' .. tostring(domoticz.data.estado['COMPLETO']) .. 
                         ' ' .. tostring(domoticz.data.estado['CESPED']) .. 
                         ' ' .. tostring(domoticz.data.estado['GOTEOS']) ,
                         domoticz.LOG_FORCE)
	        if(domoticz.data.offInterno) then
                -- El off se ha producido por un doble click y lo ignoramos
                domoticz.data.offInterno = false
            -- PROBLEMA:    Aqui vamos a llegar tanto por el apagado a mano como por el apagado por el temporizador
            --              Hay que evitar que si llegamos por el temporizador de alguno que se apago a mano
            --              se cumpla la condicion ya que semaforo pertenece a otro boton distinto. Voy a hacer una comprobacion ...
            --elseif(domoticz.data.semaforo) then
            elseif(domoticz.data.estado[boton.name]) then
                -- Se ha producido el off y estabamos regando
        	    -- Mandamos el mensaje del consumo
        	    local consumo = domoticz.devices('CONTADOR AGUA').counter - domoticz.data.contadorInicial
        	    domoticz.notify('CONSUMO','*Consumidos ' .. consumo .. ' m3*',domoticz.PRIORITY_LOW)
    	        -- Mandamos la notificacion
        	    domoticz.notify('RIEGOFF','*Riego ' .. boton.name .. ' terminado*',domoticz.PRIORITY_HIGH)
                -- Deshabilitamos el semaforo
                domoticz.data.semaforo = false
                -- Cambiamos su estado
    	        domoticz.data.estado[boton.name] = false
    	        -- Paramos el/los riegos
    	        domoticz.devices('EV-GENERAL').switchOff()
    	        if(boton.name == 'COMPLETO') then
        	        TerminaCesped(domoticz)
    	            TerminaGoteos(domoticz)
    	        elseif(boton.name == 'CESPED') then
        	        TerminaCesped(domoticz)
                elseif(boton.name == 'GOTEOS') then
    	            TerminaGoteos(domoticz)
                end	       
    	   end
    	   -- Si no se ha cumplido ninguna de las dos anteriores no hacemos nada
    	   -- pues el off se ha producido por el temporizador que se puso en el on.
        end
	end
}