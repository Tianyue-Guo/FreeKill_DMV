local desc_1v2 = [[
  # 欢乐斗地主模式简介

  ___

  总体规则类似身份局。游戏由三人进行，一人扮演地主（主公），其他两人扮演农民（反贼）。

  地主增加一点体力上限和体力，且拥有以下额外技能：

  - **飞扬**：判定阶段开始时，你可以弃置两张手牌并弃置自己判定区内的一张牌。

  - **跋扈**：锁定技，准备阶段，你摸一张牌；出牌阶段，你可以多使用一张杀。

  当农民被击杀后，另一名农民可以选择：摸两张牌，或者回复一点体力。

  *击杀农民的人没有摸三张牌的奖励。*

  胜利规则与身份局一致。
]]

-- Because packages are loaded before gamelogic.lua loaded
-- so we can not directly create subclass of gamelogic in the top of lua
local m_1v2_getLogic = function()
  local m_1v2_logic = GameLogic:subclass("m_1v2_logic")

  function m_1v2_logic:initialize(room)
    GameLogic.initialize(self, room)
    self.role_table = {nil, nil, {"lord", "rebel", "rebel"}}
  end

  function m_1v2_logic:chooseGenerals()
    local room = self.room
    local generalNum = room.settings.generalNum
    for _, p in ipairs(room.players) do
      p.role_shown = true
      room:broadcastProperty(p, "role")
    end

    local lord = room:getLord()
    room.current = lord
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

    for _, p in ipairs(nonlord) do
      room:broadcastProperty(p, "general")
      if p.role == "lord" then
        room:broadcastProperty(p, "kingdom")
      end
    end
  end

  return m_1v2_logic
end

local m_feiyang = fk.CreateTriggerSkill{
  name = "m_feiyang",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Judge and
      #player:getCardIds(Player.Hand) >= 2 and
      #player:getCardIds(Player.Judge) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:askForDiscard(player, 2, 2, false, self.name, false)
    local card = room:askForCardChosen(player, player, "j", self.name)
    room:throwCard(card, self.name, player, player)
  end
}
Fk:addSkill(m_feiyang)
local m_bahubuff = fk.CreateTargetModSkill{
  name = "#m_bahubuff",
  residue_func = function(self, player, skill, scope)
    if player:hasSkill(self.name) and skill.trueName == "slash_skill"
      and scope == Player.HistoryPhase then
      return 1
    end
  end,
}
local m_bahu = fk.CreateTriggerSkill{
  name = "m_bahu",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1)
  end,
}
m_bahu:addRelatedSkill(m_bahubuff)
Fk:addSkill(m_bahu)
local m_1v2_rule = fk.CreateTriggerSkill{
  name = "#m_1v2_rule",
  priority = 0.001,
  refresh_events = {fk.GameStart, fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    return event == fk.GameStart and player.role == "lord" or target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      room:handleAddLoseSkills(player, "m_feiyang|m_bahu", nil, false)
      player.maxHp = player.maxHp + 1
      player.hp = player.hp + 1
      room:broadcastProperty(player, "maxHp")
      room:broadcastProperty(player, "hp")
      room:setTag("SkipNormalDeathProcess", true)
    else
      for _, p in ipairs(room.alive_players) do
        if p.role == "rebel" then
          local choices = {"m_1v2_draw2", "Cancel"}
          if p:isWounded() then
            table.insert(choices, 2, "m_1v2_heal")
          end
          local choice = room:askForChoice(p, choices, self.name)
          if choice == "m_1v2_draw2" then p:drawCards(2, self.name)
          else room:recover{ who = p, num = 1, skillName = self.name } end
        end
      end
    end
  end,
}
Fk:addSkill(m_1v2_rule)
local m_1v2_mode = fk.CreateGameMode{
  name = "m_1v2_mode",
  minPlayer = 3,
  maxPlayer = 3,
  rule = m_1v2_rule,
  logic = m_1v2_getLogic,
  surrender_func = function(self, playedTime)
    local surrenderJudge = { { text = "time limitation: 2 min", passed = playedTime >= 120 } }
    if Self.role ~= "lord" then
      table.insert(surrenderJudge, { text = "1v2: left you alive", passed = #Fk:currentRoom().alive_players == 2 })
    end

    return surrenderJudge
  end,
}

Fk:loadTranslationTable{
  ["m_1v2_mode"] = "欢乐斗地主",
  ["m_feiyang"] = "飞扬",
  [":m_feiyang"] = "判定阶段开始时，你可以弃置两张手牌，然后弃置自己判定区的一张牌。",
  ["m_bahu"] = "跋扈",
  [":m_bahu"] = "锁定技，准备阶段，你摸一张牌；出牌阶段，你可以多使用一张【杀】。",
  ["#m_1v2_rule"] = "挑选遗产",
  ["m_1v2_draw2"] = "摸两张牌",
  ["m_1v2_heal"] = "回复1点体力",

  ["time limitation: 2 min"] = "游戏时长达到2分钟",
  ["1v2: left you alive"] = "仅剩你和地主存活",

  [":m_1v2_mode"] = desc_1v2,
}

return m_1v2_mode
