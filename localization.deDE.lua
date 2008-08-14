if( GetLocale() ~= "deDE" ) then
	return
end

PartyCCLocals = setmetatable({
}, {__index = PartyCCLocals})