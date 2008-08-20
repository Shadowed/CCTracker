if( GetLocale() ~= "deDE" ) then
	return
end

CCTrackerLocals = setmetatable({
}, {__index = CCTrackerLocals})