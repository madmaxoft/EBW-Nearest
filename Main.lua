
-- Main.lua

-- Implements the entire EBW-Nearest AI controller





--- Returns the square of the distance between two bots
local function botDistance(a_Bot1, a_Bot2)
	assert(type(a_Bot1) == "table")
	assert(type(a_Bot2) == "table")
	
	return (a_Bot1.x - a_Bot2.x) * (a_Bot1.x - a_Bot2.x) + (a_Bot1.y - a_Bot2.y) * (a_Bot1.y - a_Bot2.y)
end





--- Returns the command for srcBot to target dstBot
local function cmdTargetBot(a_SrcBot, a_DstBot)
	assert(type(a_SrcBot) == "table")
	assert(type(a_DstBot) == "table")
	
	local wantAngle = math.atan2(a_DstBot.y - a_SrcBot.y, a_DstBot.x - a_SrcBot.x) * 180 / math.pi
	local angleDiff = wantAngle - a_SrcBot.angle
	
	-- If the heading is too off, adjust:
	if (math.abs(angleDiff) > 5) then
		if ((a_SrcBot.speedLevel > 1) and (math.abs(angleDiff) > 3 * a_SrcBot.maxAngularSpeed)) then
			-- We're going too fast to steer, brake:
			aiLog(a_SrcBot.id, "Too fast to steer, breaking. Angle is " .. a_SrcBot.angle .. ", wantAngle is " .. wantAngle .. ", angleDiff is " .. angleDiff)
			return { cmd = "brake" }
		else
			aiLog(
				a_SrcBot.id, "Steering, angle is " .. a_SrcBot.angle .. ", wantAngle is " .. wantAngle ..
				", angleDiff is " .. angleDiff .. ", maxAngularSpeed is " .. a_SrcBot.maxAngularSpeed .. ", speed is " .. a_SrcBot.speed
			)
			return { cmd = "steer", angle = angleDiff }
		end
	end
	
	-- If the enemy is further than 200 pixels away, accellerate, else brake:
	local dist = botDistance(a_SrcBot, a_DstBot)
	if (dist > 40000) then
		aiLog(a_SrcBot.id, "Accellerating (dist is " .. dist .. ")")
		return { cmd = "accelerate" }
	elseif (a_SrcBot.speedLevel > 1) then
		aiLog(a_SrcBot.id, "Braking (dist is " .. dist .. ")")
		return { cmd = "brake" }
	else
		aiLog(a_SrcBot.id, "En route to dst, no command")
		return nil
	end
end





--- Converts bot speed to speed level index:
local function getSpeedLevelIdxFromSpeed(a_Game, a_Speed)
	for idx, level in ipairs(a_Game.speedLevels) do
		if (a_Speed <= level.linearSpeed) then
			if (idx == 1) then
				return 1
			else
				return idx - 1
			end
		end
	end
	return 1
end




--- Updates each bot to target the nearest enemy:
local function updateTargets(a_Game)
	-- Update each bot's settings, based on their speed level:
	for idx, m in ipairs(a_Game.myBots) do
		m.speedLevel = getSpeedLevelIdxFromSpeed(a_Game, m.speed)
		m.maxAngularSpeed  = a_Game.speedLevels[m.speedLevel].maxAngularSpeed
	end
	
	-- Update the targets:
	for idx, m in ipairs(a_Game.myBots) do
		-- Pick the nearest target:
		local minDist = a_Game.world.width * a_Game.world.width + a_Game.world.height * a_Game.world.height
		local target
		for idx2, e in ipairs(a_Game.enemyBots) do
			local dist = botDistance(m, e)
			-- commentLog("  Distance between my #" .. m.id .. " and enemy #" .. e.id .. " is " .. dist)
			if (dist < minDist) then
				minDist = dist
				target = e
			end
		end  -- for idx2, e - enemyBots[]
		
		-- Navigate towards the target:
		if (target) then
			aiLog(m.id, "Targetting enemy #" .. target.id)
			a_Game.botCommands[m.id] = cmdTargetBot(m, target)
		end
	end
end





function onGameStarted(a_Game)
	-- Collect all my bots into an array, and enemy bots to another array:
	a_Game.myBots = {}
	a_Game.enemyBots = {}
	for _, bot in pairs(a_Game.allBots) do
		if (bot.isEnemy) then
			table.insert(a_Game.enemyBots, bot)
		else
			table.insert(a_Game.myBots, bot)
		end
	end
	
	-- Set each bot's target:
	updateTargets(a_Game)
end





function onGameUpdate(a_Game)
	-- Update each bot's target
	updateTargets(a_Game)
end





function onGameFinished(a_Game)
	-- Nothing needed yet
end





function onBotDied(a_Game, a_BotID)
	-- Remove the bot from one of the myBots / enemyBots arrays:
	local whichArray
	if (a_Game.allBots[a_BotID].isEnemy) then
		whichArray = a_Game.enemyBots
	else
		whichArray = a_Game.myBots
	end
	for idx, bot in ipairs(whichArray) do
		if (bot.id == a_BotID) then
			table.remove(whichArray, idx)
			break;
		end
	end  -- for idx, bot - whichArray[]
	
	-- Update the bot targets:
	updateTargets(a_Game)

	-- Print an info message:
	local friendliness
	if (a_Game.allBots[a_BotID].isEnemy) then
		friendliness = "(enemy)"
	else
		friendliness = "(my)"
	end
	print("LUA: onBotDied: bot #" .. a_BotID .. friendliness)
end





function onCommandsSent(a_Game)
	-- Nothing needed
end




