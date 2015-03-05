
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
		commLog("My bot " .. a_SrcBot.id .. ": steering, angle is " .. a_SrcBot.angle .. ", wantAngle is " .. wantAngle .. ", angleDiff is " .. angleDiff)
		return { cmd = "steer", angle = angleDiff }
	end
	
	-- If the enemy is further than 50 pixels away, accellerate, else brake:
	local dist = botDistance(a_SrcBot, a_DstBot)
	if (dist > 2500) then
		commLog("My bot " .. a_SrcBot.id .. ": accellerating (dist is " .. dist .. ")")
		return { cmd = "accelerate" }
	else
		commLog("My bot " .. a_SrcBot.id .. ": braking (dist is " .. dist .. ")")
		return { cmd = "brake" }
	end
end





--- Updates each bot to target the nearest enemy:
local function updateTargets(a_Game)
	for idx, m in ipairs(a_Game.myBots) do
		-- Pick the nearest target:
		local minDist = a_Game.world.width * a_Game.world.width + a_Game.world.height * a_Game.world.height
		local target
		for idx2, e in ipairs(a_Game.enemyBots) do
			local dist = botDistance(m, e)
			-- commLog("  Distance between my #" .. m.id .. " and enemy #" .. e.id .. " is " .. dist)
			if (dist < minDist) then
				minDist = dist
				target = e
			end
		end  -- for idx2, e - enemyBots[]
		
		-- Navigate towards the target:
		if (target) then
			commLog("My #" .. m.id .. " is targetting enemy #" .. target.id)
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




