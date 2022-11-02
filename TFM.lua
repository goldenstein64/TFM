local CONVERSIONS = {
	12, -- years to months
	30, -- months to days
	24, -- days to hours
	60, -- hours to minutes
	60, -- minutes to seconds
}

local INDEXES = {y = 1, M = 2, d = 3, h = 4, m = 5, s = 6}

local SHORT_UNITS = {"yr", "mon", "d", "hr", "min", "sec"}
local SHORT_PLURALS = {[1] = true, [4] = true, [5] = true}

local FULL_UNITS = {"year", "month", "day", "hour", "minute", "second"}

local TFM = {}

--[[**
	Takes an amount of time (in seconds) and converts it to a string
	
	@param [t:integer] Seconds   "An integer representing the number of seconds you want to convert."
	@param [t:string] Form   "A string that controls how the given seconds will be formatted and displayed."
	@param [t:boolean] AddZero      "A boolean value denoting whether or not you would like to toggle a zero in front of the current largest unit."
**--]]
function TFM.Convert(Seconds, Form, AddZero)
	
	do -- input validation
		local type_Seconds = typeof(Seconds)
		assert(type_Seconds == 'number', 
			"ShortenedTFM: Seconds (arg 1) is not of type 'number'!")
		assert(Seconds%1 == 0,
			"ShortenedTFM: Seconds (arg 1) is not an integer!")
		
		local type_Form = typeof(Form)
		assert(type_Form == 'string' or type_Form == 'nil', 
			"ShortenedTFM: Form (arg 2) is not of type 'string' or 'nil'!")
		
		local type_AddZero = typeof(AddZero)
		assert(type_AddZero == 'boolean' or type_AddZero == 'nil', 
			"ShortenedTFM: AddZero (arg 3) is not of type 'boolean' or 'nil'!")
	end
	
	local firstValue
	local timeValues = {} do -- integer values for each unit of time
		for i = 1, 6 do
			local divisor = 1
			for j = i, 5 do
				divisor *= CONVERSIONS[j]
			end
			
			local result = math.floor(Seconds/divisor)
			if i > 1 then
				result %= CONVERSIONS[i - 1]
			end
			
			if not firstValue and result ~= 0 then
				firstValue = i
			end
			timeValues[i] = result
		end
	end
	firstValue = firstValue or 6
			
	local form = Form and string.lower(Form)
	
	local result
	if form == "short" then -- 00 yr(s) 00 mon 00 d 00 hr(s) 00 min(s) 00 sec
		local formatTable = {
			(AddZero and "%02d " or "%d ") 
				.. SHORT_UNITS[firstValue] 
				.. (SHORT_PLURALS[firstValue] and timeValues[firstValue] ~= 1 and "s " or " ")
		}
		for i = firstValue + 1, 6 do
			formatTable[#formatTable + 1] = "%02d " 
				.. SHORT_UNITS[i] 
				.. (SHORT_PLURALS[i] and timeValues[i] ~= 1 and "s " or " ")
		end
		
		result = string.format(table.concat(formatTable):sub(1, -2), table.unpack(timeValues, firstValue, 6))
	elseif form == "full" then -- 00 year(s) 00 month(s) 00 day(s) 00 hour(s) 00 minute(s) 00 second(s)
		local formatTable = {
			(AddZero and "%02d " or "%d ")
				.. FULL_UNITS[firstValue]
				.. (timeValues[firstValue] ~= 1 and "s " or " ")
		}
		for i = firstValue + 1, 6 do
			formatTable[#formatTable + 1] = "%02d " 
				.. FULL_UNITS[i] 
				.. (timeValues[i] ~= 1 and "s " or " ")
		end
			
		result = string.format(table.concat(formatTable):sub(1, -2), table.unpack(timeValues, firstValue, 6))
	elseif Form then -- custom format string
		local params = {}
		local subs = {}
		
		for parameter in string.gmatch(Form, "%%[0 '+-]*%d*([yMdhms])") do
			params[#params + 1] = INDEXES[parameter]
		end
		
		local largestUnit = math.min(6, table.unpack(params))
		local divisor = 1
		for i = largestUnit, 5 do
			divisor *= CONVERSIONS[i]
		end
		timeValues[largestUnit] = math.floor(Seconds/divisor)
		
		for _, index in ipairs(params) do
			subs[#subs + 1] = timeValues[index]
		end
		
		local formatString = string.gsub(Form, "(%%[0 '+-]*%d*)[yMdhms]", "%1d")
		
		result = string.format(formatString, table.unpack(subs))
	else -- 00:00:00
		local formatString = (AddZero and "%02d" or "%d") .. string.rep(":%02d", math.min(6 - firstValue, 2))
		
		timeValues[4] = math.floor(Seconds/3600) -- used to show hours without extra units
		result = string.format(formatString, table.unpack(timeValues, math.max(firstValue, 4), 6))
	end
	
	return result, timeValues
end

return TFM