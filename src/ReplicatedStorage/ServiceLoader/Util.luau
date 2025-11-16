local ServerTime = workspace:GetServerTimeNow()
local ClientTime = DateTime.now().UnixTimestampMillis / 1000
local TimeOffset = ServerTime - ClientTime
local LastOffsetChange = time()

local function RecurseCopy<T>(v : {[any] : any?} & T) : T
    local Clone = table.clone(v)

    for Index, Value in Clone do
        if typeof(Value) == "table" then
            Clone[Index] = RecurseCopy(Value)
        end
    end

    return Clone
end

return {
	GetDictionaryLength = function(Dictionary : {[any] : any?}) : number
		local Amount = 0

		for _ in Dictionary do
			Amount += 1
		end

		return Amount
	end,
	DeepCopy = RecurseCopy,
	GetUnixTime = function(InMilliseconds : boolean?) : number
		if (time() - LastOffsetChange) > 1 then
			LastOffsetChange = time()

			ServerTime = workspace:GetServerTimeNow()
			ClientTime = DateTime.now().UnixTimestampMillis / 1000
			TimeOffset = ServerTime - ClientTime
		end

		if InMilliseconds == true then
			return (DateTime.now().UnixTimestampMillis / 1000) + TimeOffset
		else
			return math.round(DateTime.now().UnixTimestamp + TimeOffset)
		end
	end
}