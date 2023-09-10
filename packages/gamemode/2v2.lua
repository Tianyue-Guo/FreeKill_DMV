local desc_2v2 = [[
  # 2v2简介

  游戏由两名忠臣和两名反贼进行，胜利目标为击杀所有敌人。

  座位排列可能是忠-反-反-忠或者忠-反-忠-反，以及对应的反贼在一号位的情况。

  一人死亡后，其队友会摸一张牌。

  第一回合角色摸牌阶段少摸一张牌。四号位多摸一张初始手牌。

  队友手牌可见。
]]

local m_2v2_getLogic = function()
  local m_2v2_logic = GameLogic:subclass("m_2v2_logic")

  function m_2v2_logic:assignRoles()
    local room = self.room
    local n = #room.players
    local roles = table.random {
      { "loyalist", "rebel", "rebel", "loyalist" },
      { "rebel", "loyalist", "loyalist", "rebel"},
    }

    for i = 1, n do
      local p = room.players[i]
      p.role = roles[i]
      p.role_shown = true
      room:broadcastProperty(p, "role")
    end

    room.players[1]:addBuddy(room.players[4])
    room.players[4]:addBuddy(room.players[1])
    room.players[2]:addBuddy(room.players[3])
    room.players[3]:addBuddy(room.players[2])

    self.start_role = roles[1]
    -- for adjustSeats
    room.players[1].role = "lord"
  end

  function m_2v2_logic:chooseGenerals()
    local room = self.room
    local generalNum = room.settings.generalNum

    local lord = room:getLord()
    room.current = lord
    lord.role = self.start_role

    local nonlord = room.players
    local generals = Fk:getGeneralsRandomly(#nonlord * generalNum)
    table.shuffle(generals)
    for _, p in ipairs(nonlord) do
      local arg = {}
      for i = 1, generalNum do
        table.insert(arg, table.remove(generals, 1).name)
      end
      p.request_data = json.encode({ arg, 1 })
      p.default_reply = arg[1]
    end

    room:doBroadcastRequest("AskForGeneral", nonlord)
    for _, p in ipairs(nonlord) do
      if p.general == "" and p.reply_ready then
        local general = json.decode(p.client_reply)[1]
        room:setPlayerGeneral(p, general, true, true)
      else
        room:setPlayerGeneral(p, p.default_reply, true, true)
      end
      p.default_reply = ""
    end

    room:askForChooseKingdom(nonlord)
  end

  return m_2v2_logic
end
local m_2v2_rule = fk.CreateTriggerSkill{
  name = "#m_2v2_rule",
  priority = 0.001,
  refresh_events = {fk.DrawInitialCards, fk.DrawNCards, fk.GameOverJudge, fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DrawNCards then
      if player.seat == 1 and player:getMark(self.name) == 0 then
        room:addPlayerMark(player, self.name, 1)
        room:setTag("SkipNormalDeathProcess", true)
        data.n = data.n - 1
      end
    elseif event == fk.DrawInitialCards then
      if player.seat == 4 then
        data.num = data.num + 1
      end
    elseif event == fk.GameOverJudge then
      local winner = Fk.game_modes[room.settings.gameMode]:getWinner(player)
      if winner ~= "" then
        room:gameOver(winner)
        return true
      end
    else
      for _, p in ipairs(room.alive_players) do
        if p.role == player.role then
          p:drawCards(1)
        end
      end
    end
  end,
}
Fk:addSkill(m_2v2_rule)
local m_2v2_mode = fk.CreateGameMode{
  name = "m_2v2_mode",
  minPlayer = 4,
  maxPlayer = 4,
  rule = m_2v2_rule,
  logic = m_2v2_getLogic,
  surrender_func = function(self, playedTime)
    local surrenderJudge = { { text = "time limitation: 2 min", passed = playedTime >= 120 },
    { text = "2v2: left you alive", passed = table.find(Fk:currentRoom().players, function(p)
      return p.role == Self.role and p.dead
    end) and true } }
    return surrenderJudge
  end,
  winner_getter = function(self, victim)
    local room = victim.room
    local alive = table.filter(room.alive_players, function(p)
      return not p.surrendered
    end)
    local winner = alive[1].role
    for _, p in ipairs(alive) do
      if p.role ~= winner then
        return ""
      end
    end
    return winner
  end,
}
Fk:loadTranslationTable{
  ["m_2v2_mode"] = "2v2",
  [":m_2v2_mode"] = desc_2v2,
  ["time limitation: 2 min"] = "游戏时长达到2分钟",
  ["2v2: left you alive"] = "你所处队伍仅剩你存活",
}

return m_2v2_mode
