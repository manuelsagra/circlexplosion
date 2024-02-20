local hiScore = {
    value = 0
}

function hiScore:load() 
    local hiScoreRead = system.getPreference("app", "hiScore", "number")
	if (hiScoreRead == nil) then
		self.value = 0
    else 
        self.value = hiScoreRead
	end
end

function hiScore:save()
    system.setPreferences("app", {
        hiScore = self.value
    })
end

return hiScore