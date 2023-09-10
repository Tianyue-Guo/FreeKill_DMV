local desc_chaos = [[
  # 文和乱武简介

  ---

  ## 身份说明

  游戏由八名玩家进行，**一人一伙，各自为战**，胜利目标为活到最后吃鸡！

  游戏目标：按照角色阵亡顺序进行排名，最终存活的玩家为第一名，依照名次结算积分。

  击杀奖惩：击杀一名其他角色后，击杀者增加1点体力上限并摸三张牌。

  另外每名角色都有〖完杀〗。首轮时，已受伤角色视为拥有〖八阵〗。

  ---

  ## 特殊事件
  
  每轮开始时，执行一个特殊事件。第一轮固定为“乱武”，之后每一轮均随机执行一个。共有以下7条特殊事件：

  **乱武**：从随机一名角色开始结算〖乱武〗（所有角色，需对距离最近的一名角色使用一张【杀】，否则失去1点体力）。

  **重赏**：本轮中，击杀角色奖励翻倍。

  **破釜沉舟**：每个回合开始时，当前回合角色失去1点体力，摸三张牌。

  **横刀跃马**：每个回合结束时，所有装备最少的角色失去1点体力，随机将牌堆里的一张装备牌置入其装备区。

  **横扫千军**：本轮中，所有伤害值+1。

  **饿莩载道**：本轮结束时，所有手牌最少的角色失去X点体力。（X为轮数）

  **宴安鸩毒**：本轮中，所有的【桃】均视为【毒】。（【毒】：锁定技，当此牌正面朝上离开你的手牌区后，你失去1点体力。出牌阶段，你可对自己使用。）

  ---

  ## 特殊锦囊牌

  【**斗转星移**】：出牌阶段，对一名其他角色使用。随机分配你和其的体力（至少为1且无法超出上限）。<font color="#CC3131">♥</font>A/<font color="#CC3131">♦</font>5。

  【**李代桃僵**】：出牌阶段，对一名其他角色使用。随机分配你和其的手牌。♦Q/<font color="#CC3131">♥</font>A/<font color="#CC3131">♥</font>K。

  【**偷梁换柱**】：出牌阶段，对你使用。随机分配所有角色装备区里的牌。♠J/♣Q/♣K/♠K。

  【**文和乱武**】：出牌阶段，对其他角色使用。目标角色各选择一项：1. 对距离最近的一名角色使用【杀】；2. 失去1点体力。♠10/♣4。

  移除兵、乐、无懈、桃园和木马

  ---

  鼓励收人头来“舔包”来加快游戏节奏。

  特殊规则均为了加快游戏进度的效果，并且含有极大随机性，玩家需要提前提防某些情况发生。

  特殊锦囊设置将拖慢游戏节奏的牌移除，改为引进了具有随机性甚至足以改变战局的锦囊牌。
]]

local chaos_getLogic = function()
  local chaos_logic = GameLogic:subclass("chaos_logic")

  function chaos_logic:assignRoles()
    local room = self.room
    local n = #room.players

    for i = 1, n do
      local p = room.players[i]
      p.role = "hidden"
      p.role_shown = true
      room:broadcastProperty(p, "role")
      --p.role = p._splayer:getScreenName() --结算显示更好，但身份图标疯狂报错
    end

    self.start_role = "hidden"
    -- for adjustSeats
    room.players[1].role = "lord"
  end

  function chaos_logic:prepareDrawPile()
    local room = self.room
    local allCardIds = Fk:getAllCardIds()
    local blacklist = {"god_salvation", "indulgence", "supply_shortage", "nullification"}
    local whitelist = {"time_flying", "substituting", "replace_with_a_fake", "wenhe_chaos"}
    for i = #allCardIds, 1, -1 do
      local card = Fk:getCardById(allCardIds[i])
      local name = card.name
      if (card.is_derived and not table.contains(whitelist, name)) or table.contains(blacklist, name) then
        local id = allCardIds[i]
        table.removeOne(allCardIds, id)
        table.insert(room.void, id)
        room:setCardArea(id, Card.Void, nil)
      end
    end
  
    table.shuffle(allCardIds)
    room.draw_pile = allCardIds
    for _, id in ipairs(room.draw_pile) do
      room:setCardArea(id, Card.DrawPile, nil)
    end
  end

  function chaos_logic:chooseGenerals()
    local room = self.room
    local generalNum = room.settings.generalNum
    local n = room.settings.enableDeputy and 2 or 1
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
      p.request_data = json.encode({ arg, n })
      p.default_reply = table.random(arg, n)
    end

    room:doBroadcastNotify("ShowToast", Fk:translate("chaos_intro"))

    room:notifyMoveFocus(nonlord, "AskForGeneral")
    room:doBroadcastRequest("AskForGeneral", nonlord)

    for _, p in ipairs(nonlord) do
      if p.general == "" and p.reply_ready then
        local generals = json.decode(p.client_reply)
        local general = generals[1]
        local deputy = generals[2]
        room:setPlayerGeneral(p, general, true, true)
        room:setDeputyGeneral(p, deputy)
      else
        room:setPlayerGeneral(p, p.default_reply[1], true, true)
        room:setDeputyGeneral(p, p.default_reply[2])
      end
      p.default_reply = ""
    end

    room:askForChooseKingdom(nonlord)
  end

  return chaos_logic
end

local chaos_event = { "luanwu", "generous_reward", "burning_one's_boats", "leveling_the_blades", "sweeping_all", "starvation", "poisoned_banquet" }

local chaos_rule = fk.CreateTriggerSkill{
  name = "#chaos_rule",
  priority = 0.001,
  refresh_events = {fk.GameStart, fk.GameOverJudge, fk.Deathed, fk.RoundStart, fk.EventPhaseChanging, fk.DamageInflicted, fk.RoundEnd, fk.HpChanged, fk.MaxHpChanged},
  can_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then return player.seat == 1 end
    if target ~= player then return false end
    local num = room:getTag("chaos_mode_event")
    if event == fk.EventPhaseChanging then
      return (data.from == Player.NotActive and num == 3) or (data.to == Player.NotActive and num == 4)
    elseif event == fk.DamageInflicted then
      return num == 5
    elseif event == fk.RoundEnd then
      return num == 6 or room:getTag("RoundCount") == 1
    elseif event == fk.HpChanged or event == fk.MaxHpChanged then
      return room:getTag("RoundCount") == 1
    end
    return true
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      room:setTag("SkipNormalDeathProcess", true)
      for _, p in ipairs(room.players) do
        room:handleAddLoseSkills(p, "wansha", nil, false, true)
      end
    elseif event == fk.GameOverJudge then
      room:setTag("SkipGameRule", true)
      if #room.alive_players == 1 then
        local winner = Fk.game_modes[room.settings.gameMode]:getWinner(player)
        if winner ~= "" then
          room:gameOver(winner)
          return true
        end
      end
    elseif event == fk.Deathed then
      if data.damage then
        local killer = data.damage.from
        if killer and not killer.dead then --……
          local invoked = room:getTag("chaos_mode_event") == 2
          killer:drawCards(invoked and 6 or 3, "kill")
          if not killer.dead then
            room:changeMaxHp(killer, invoked and 2 or 1)
          end
        end
      end
    elseif event == fk.RoundStart then
      local index = math.random(1, 7)
      if room:getTag("RoundCount") == 1 then
        room:doBroadcastNotify("ShowToast", Fk:translate("chaos_fisrt_round"))
        index = 1
      end
      room:setTag("chaos_mode_event", index)
      for _, p in ipairs(room.alive_players) do
        room:setPlayerMark(p, "@chaos_mode_event", chaos_event[index])
      end
      room:notifyMoveFocus(room.alive_players, self.name)
      room:doBroadcastNotify("ShowToast", Fk:translate("chaos_e: " .. tostring(index)))
      room:sendLog{
        type = "chaos_mode_event_log",
        arg = "chaos_e: " .. tostring(index),
      }
      room:delay(3500)
      if index == 1 then
        room:broadcastSkillInvoke("luanwu")
        local from = table.random(room.alive_players)
        room:notifySkillInvoked(from, "luanwu", "big")
        local temp = from.next
        local targets = {from}
        while temp ~= from do
          if not temp.dead then
            table.insert(targets, temp)
          end
          temp = temp.next
        end
        for _, target in ipairs(targets) do
          if not target.dead then
            local other_players = room:getOtherPlayers(target)
            local luanwu_targets = table.map(table.filter(other_players, function(p2)
              return table.every(other_players, function(p1)
                return target:distanceTo(p1) >= target:distanceTo(p2)
              end)
            end), function (p)
              return p.id
            end)
            local use = room:askForUseCard(target, "slash", "slash", "#luanwu-use", true, {exclusive_targets = luanwu_targets})
            if use then
              room:useCard(use)
            else
              room:loseHp(target, 1, self.name)
            end
          end
        end
      end
    elseif event == fk.HpChanged or event == fk.MaxHpChanged then
      if not player:isWounded() and player:getMark("_chaos_mode_bazhen") > 0 then
        room:removePlayerMark(player, "_chaos_mode_bazhen")
        room:handleAddLoseSkills(player, "-bazhen", nil, false, false)
      elseif not player:hasSkill("bazhen") and player:isWounded() then
        room:addPlayerMark(player, "_chaos_mode_bazhen")
        room:handleAddLoseSkills(player, "bazhen", nil, false, false)
      end
    elseif event == fk.EventPhaseChanging then
      if room:getTag("chaos_mode_event") == 3 then
        room:loseHp(player, 1, self.name)
        if not player.dead then
          player:drawCards(3, self.name)
        end
      else
        local num = 9
        local targets = {}
        for _, p in ipairs(room.alive_players) do
          local n = #p:getCardIds("e")
          if n < num then
            num = n
            targets = {}
            table.insert(targets, p.id)
          elseif n == num then
            table.insert(targets, p.id)
          end
        end
        room:sortPlayersByAction(targets)
        local types = {Card.SubtypeWeapon, Card.SubtypeArmor, Card.SubtypeDefensiveRide, Card.SubtypeOffensiveRide, Card.SubtypeTreasure}
        for _, pid in ipairs(targets) do
          local p = room:getPlayerById(pid)
          if not p.dead then
            room:loseHp(p, 1, self.name)
            if not p.dead then
              local cards = {}
              local draw_pile = table.clone(room.draw_pile)
              table.shuffle(draw_pile)
              for i = 1, #draw_pile, 1 do
                local card = Fk:getCardById(draw_pile[i])
                if table.contains(types, card.sub_type) and p:getEquipment(card.sub_type) == nil then
                  table.insert(cards, draw_pile[i])
                  break
                end
              end
              if #cards > 0 then
                room:sendLog{
                  type = "#chaos_mode_event_4_log",
                  from = pid,
                  arg = "leveling_the_blades",
                  arg2 = Fk:getCardById(cards[1], true):toLogString(),
                }
                room:moveCardTo(cards, Card.PlayerEquip, p, fk.ReasonJustMove, self.name)
              end
            end
          end
        end
      end
    elseif event == fk.DamageInflicted then
      data.damage = data.damage + 1
    else
      if room:getTag("RoundCount") == 1 then
        for _, p in ipairs(room.alive_players) do
          if p:getMark("_chaos_mode_bazhen") > 0 then
            room:handleAddLoseSkills(p, "-bazhen", nil, false, false)
          end
        end
      else --第一轮一定是乱武
        local num = 998
        local targets = {}
        for _, p in ipairs(room.alive_players) do
          local n = p:getHandcardNum()
          if n < num then
            num = n
            targets = {}
            table.insert(targets, p.id)
          elseif n == num then
            table.insert(targets, p.id)
          end
        end
        room:sortPlayersByAction(targets)
        num = room:getTag("RoundCount")
        for _, pid in ipairs(targets) do
          local p = room:getPlayerById(pid)
          if not p.dead then
            room:loseHp(p, num, self.name)
          end
        end
      end
    end
  end,
}
local chaos_rule_filter = fk.CreateFilterSkill{
  name = "#chaos_rule_filter",
  anim_type = "negative",
  global = true,
  card_filter = function(self, to_select, player)
    return player:getMark("@chaos_mode_event") == "poisoned_banquet" and to_select.name == "peach"
  end,
  view_as = function(self, to_select)
    local card = Fk:cloneCard("poison", to_select.suit, to_select.number)
    card.skillName = self.name
    return card
  end,
}
chaos_rule:addRelatedSkill(chaos_rule_filter)
Fk:addSkill(chaos_rule)
local chaos_mode = fk.CreateGameMode{
  name = "chaos_mode",
  minPlayer = 6,
  maxPlayer = 8,
  rule = chaos_rule,
  logic = chaos_getLogic,
  surrender_func = function(self, playedTime)
    local surrenderJudge = { { text = "chaos: left two alive", passed = #Fk:currentRoom().alive_players == 2 } }
    return surrenderJudge
  end,
  winner_getter = function(self, victim)
    local room = victim.room
    local alive = table.filter(room.alive_players, function(p)
      return not p.surrendered
    end)
    if #alive > 1 then return "" end
    alive[1].role = "renegade" --生草
    return "renegade"
  end,
}

Fk:loadTranslationTable{
  ["chaos_mode"] = "文和乱武",
  [":chaos_mode"] = desc_chaos,
  ["chaos: left two alive"] = "仅剩两名角色存活",
  ["#chaos_rule"] = "乱武事件",
  ["chaos_e: 1"] = "事件：乱武。从随机一名角色开始，所有角色，需对距离最近的一名角色使用一张【杀】，否则失去1点体力。",
  ["chaos_e: 2"] = "事件：重赏。本轮中，击杀角色奖励翻倍。",
  ["chaos_e: 3"] = "事件：破釜沉舟。一名角色的回合开始时，失去1点体力，摸三张牌。",
  ["chaos_e: 4"] = "事件：横刀跃马。每个回合结束时，所有装备最少的角色失去1点体力，随机将一张装备牌置入其装备区。",
  ["chaos_e: 5"] = "事件：横扫千军。本轮中，所有伤害值+1。",
  ["chaos_e: 6"] = "事件：饿莩载道。本轮结束时，所有手牌最少的角色失去X点体力。（X为轮数）",
  ["chaos_e: 7"] = "事件：宴安鸩毒。本轮中，所有的【桃】均视为【毒】。（【毒】：锁定技，当此牌正面朝上离开你的手牌区后，你失去1点体力。出牌阶段，你可对自己使用。）",
  ["@chaos_mode_event"] = "事件",
  ["generous_reward"] = "重赏",
  ["burning_one's_boats"] = "破釜沉舟",
  ["leveling_the_blades"] = "横刀跃马",
  ["sweeping_all"] = "横扫千军",
  ["starvation"] = "饿莩载道",
  ["poisoned_banquet"] = "宴安鸩毒",
  ["#chaos_mode_event_4_log"] = "%from 由于“%arg”，将 %arg2 置入装备区",
  ["#chaos_rule_filter"] = "宴安鸩毒",
  ["chaos_mode_event_log"] = "本轮的“文和乱武” %arg",
  ["chaos_intro"] = "一人一队，文和乱武的大吃鸡时代，你能入主长安吗？<br>每一轮开始会有随机事件发生，祝你好运。（贾诩的谜之笑容）",
  ["chaos_fisrt_round"] = "第一轮时，已受伤角色视为拥有〖八阵〗。",
}

return chaos_mode
