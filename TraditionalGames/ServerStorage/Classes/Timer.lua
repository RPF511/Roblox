local Timer = {}
Timer.__index = Timer

function Timer.new()
	local self = setmetatable({}, Timer)

	self._finishedEvent = Instance.new("BindableEvent")
	self.finished = self._finishedEvent.Event

	self._running = false
	self._startTime = nil
	self._duration = nil

	return self
end

function Timer:stop()
	if self and self._running then
		self._running = false
	end
end

function Timer:start(duration)
	if not self._running then
		local timerThread = coroutine.wrap(function()
			self._running = true
			self._duration = duration
			self._startTime = tick()
			while self._running and tick() - self._startTime < self._duration do
				wait()
			end
			local completed = self._running
			self._running = false
			self._startTime = nil
			self._duration = nil
			self._finishedEvent:Fire(completed)
		end)
		timerThread()
	--else
	--	warn("Timer could not start again as it is already running")
	end
end

function Timer:getTimeLeft()
	if self._running then
		local now = tick()
		--print(now)
		local timeLeft = self._startTime + self._duration - now
		if timeLeft < 0 then
			timeLeft = 0
		end
		return timeLeft
	else
		warn("Could not get remaining time; timer is not running")
		return 0
	end
end

function Timer:isRunning()
	return self._running
end


return Timer