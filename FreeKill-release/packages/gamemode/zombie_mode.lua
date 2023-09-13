-- SPDX-License-Identifier: GPL-3.0-or-later

local zombie_desc = [=====[
  # 僵尸模式简介

  僵尸模式，当年太阳神三国杀中由 trinfly 和 hypercross 设计，并由 hypercross 实现。
  （膜拜！）又名生化模式。如今挪到新月杀中又实现一下。

  ___

  ## 身份说明

  游戏初始身份配置为一个主公和七名忠臣。

  各个身份胜利条件：

  - 主公：幸存者的头目，目标是杀死全部僵尸或者集齐8枚“退治”标记，拯救世界。
  - 忠臣：诸多幸存者之一，目标是辅佐主公消灭僵尸，胜利条件与主公一致。
  - 反贼：僵尸病毒的感染源头，目标是杀死所有人类玩家，使天下大乱。
  - 内奸：被僵尸感染的可怜人，无论如何无法获胜。但是可以通过杀死人类玩家将身份变为反贼。

  ___

  ## 流程说明

  游戏开始时，由主公选择武将。之后，其他玩家选择武将。
  此时，场上的身份配置是1主7忠。主公的生命上限+1。

  主公在准备阶段获得1枚“退治”标记。若“退治”标记数量达到8，主忠直接获胜。

  在游戏的第二轮，有两名忠臣会在回合开始时立刻死亡，然后变成反贼复活。
  复活时，该玩家将体力值和体力上限调整为5，并获得僵尸副将，且在复活时摸5张牌。

  ___

  ## 专属副将：僵尸

  成为僵尸的玩家，其副将会变成“僵尸”。僵尸具有以下技能：

  - **咆哮**：标咆哮
  - **完杀**：OL界完杀
  - **迅猛**：锁定技，你的杀造成的伤害+1。
  如果你的杀造成伤害时你的体力大于2，则你流失1点体力。
  - **灾变**：锁定技，你的出牌阶段开始时，
  若人类玩家数-僵尸玩家数+1大于0，则你摸取该数目的牌。
  - **感染**：锁定技，你的装备牌都视为铁锁连环。

  ___

  ## 奖惩规则

  任意玩家杀死僵尸时，该玩家摸3张牌，生命值回复至上限。

  人类玩家杀死人类时弃掉所有牌。

  僵尸玩家杀死人类时，该人类玩家在死亡后成为内奸复活，
  生命上限为杀死他的僵尸玩家的生命上限的一半（向上取整）。
  复活时该玩家生命值回复至上限，主武将不变、副武将为僵尸。
  之后杀死人类的僵尸玩家身份若为内奸，则该玩家身份变为反贼。

  若主公死亡，则下一名忠臣玩家立即成为主公，生命与上限+1，
  并获取相当于原主公退治标记数-1的退治标记。

  ___

  ## 游戏结束条件

  - 主公集齐8枚“退治”标记：僵尸被退治，主忠获胜。
  - 僵尸全部死亡：主忠获胜。
  - 人类全部死亡：反贼获胜。注意内奸在杀死最后一名人类的时候，
  身份会先变成反贼再结算胜负。
  - 同类相残惩罚：当场上在没有僵尸（包括死亡的僵尸）时，只剩一名人类存活，则反贼获胜；
  或者在第三轮开始时，若场上没有僵尸（包括已死亡），那么反贼也获胜。
  所以人类切勿在灾变开始之前就自相残杀啊。
]=====]

local zombie_getLogic = function()
  local zombie_logic = GameLogic:subclass("zombie_logic")

  function zombie_logic:assignRoles()
    local room = self.room
    local n = #room.players
    local roles = {
      "lord", "loyalist", "loyalist", "loyalist",
      "loyalist", "loyalist", "loyalist", "loyalist",
    }

    for i = 1, n do
      local p = room.players[i]
      p.role = roles[i]
      p.role_shown = true
      room:broadcastProperty(p, "role")
    end
  end

  return zombie_logic
end

local human_role = { "lord", "loyalist" }
local zombie_role = { "rebel", "renegade" }

local function zombify(victim, role, maxHp)
  local room = victim.room
  local gender = victim.gender
  local kingdom = victim.kingdom
  room:changeHero(victim, "zombie", false, true)
  victim.role = role
  victim.maxHp = math.ceil(maxHp / 2)
  room:revivePlayer(victim, true)
  room:broadcastProperty(victim, "role")
  room:broadcastProperty(victim, "maxHp")
  room:setPlayerProperty(victim, "kingdom", kingdom)
  room:setPlayerProperty(victim, "gender", gender)
  room:broadcastPlaySound("./packages/gamemode/audio/zombify-" ..
    (gender == General.Male and "male" or "female"))
end

local zombie_rule = fk.CreateTriggerSkill{
  name = "#zombie_rule",
  priority = 0.001,
  events = {
    fk.GameStart, fk.EventPhaseStart, fk.RoundStart, fk.TurnStart,
    fk.GameOverJudge, fk.BuryVictim, fk.Deathed
  },
  can_trigger = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then return player.role == "lord" end
    if target ~= player then return end
    if event == fk.EventPhaseStart then
      return player.role == "lord" and player.phase == Player.Start
    elseif event == fk.TurnStart then
      return player:getMark("zombie_mustdie") ~= 0
    end
    return true
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      room:setTag("SkipNormalDeathProcess", true)
    elseif event == fk.RoundStart then
      local count = room:getTag("RoundCount")
      if count == 2 then
        local loyalist = table.filter(room.alive_players, function(p) return p.role == "loyalist" end)
        local zombie = table.random(loyalist, 2)
        for _, p in ipairs(zombie) do
          room:addPlayerMark(p, "zombie_mustdie", 1)
        end
      elseif count > 2 then
        local haszombie = table.find(room.players, function(p)
          return table.contains(zombie_role, p.role)
        end)
        local haslivezombie = table.find(room.alive_players, function(p)
          return table.contains(zombie_role, p.role)
        end)
        if not haszombie then room:gameOver("rebel") end
        if not haslivezombie then room:gameOver("lord+loyalist") end
      end
    elseif event == fk.TurnStart then
      room:removePlayerMark(player, "zombie_mustdie", 1)
      room:killPlayer{
        who = player.id,
      }
      zombify(player, "rebel", 10)
      player:drawCards(5)
    elseif event == fk.EventPhaseStart then
      room:addPlayerMark(player, "@zombie_tuizhi", 1)
      if player:getMark("@zombie_tuizhi") >= 8 then
        room:sendLog { type = "zombie_tuizhi_success" }
        room:gameOver("lord+loyalist")
        return true
      end
    elseif event == fk.GameOverJudge then
      room:setTag("SkipGameRule", true)
    elseif event == fk.BuryVictim then
      local damage = data.damage
      local victim = room:getPlayerById(data.who)

      if victim.role == "lord" then
        local tmp = victim:getNextAlive()
        local nextp = tmp
        repeat
          if nextp.role == "loyalist" then
            room:setPlayerMark(nextp, "@zombie_tuizhi", math.max(victim:getMark("@zombie_tuizhi") - 1, 0))
            nextp.role = "lord"
            room:broadcastProperty(nextp, "role")
            room:changeMaxHp(nextp, 1)
            room:recover({
              who = nextp,
              num = 1,
              skillName = self.name
            })
            break
          end
          nextp = nextp:getNextAlive()
        until nextp == tmp
      end

      if damage and damage.from then
        local killer = damage.from
        -- print(killer.dead)
        if killer.dead then return end
        if victim.role == "rebel" or victim.role == "renegade" then
          killer:drawCards(3, "kill")
          if killer:isWounded() then
            room:recover({
              who = killer,
              num = killer:getLostHp(),
              skillName = self.name
            })
          end
        elseif table.contains(human_role, victim.role) then
          if table.contains(human_role, killer.role) then
            killer:throwAllCards("he")
          end
        end
      end
    elseif event == fk.Deathed then
      local damage = data.damage
      local victim = room:getPlayerById(data.who)
      if damage and damage.from then
        local killer = damage.from
        if killer.dead then return end
        if table.contains(human_role, victim.role) then
          if killer.role == "renegade" then
            killer.role = "rebel"
            room:broadcastProperty(killer, "role")
          end
          if table.contains(zombie_role, killer.role) then
            local current = room.logic:getCurrentEvent()
            local last_event
            if room.current == victim then
              last_event = current:findParent(GameEvent.Turn, true)
            else
              last_event = current
              if last_event.parent then
                repeat
                  if table.contains({GameEvent.Round, GameEvent.Turn, GameEvent.Phase}, last_event.parent.event) then break end
                  last_event = last_event.parent
                until (not last_event.parent)
              end
            end
            last_event:addExitFunc(function()
              zombify(victim, "renegade", killer.maxHp)
            end)
          end
        end
      end

      local winner = Fk.game_modes[room.settings.gameMode]:getWinner(victim)
      if winner then
        room:gameOver(winner)
        return true
      end
    end
  end,
}
Fk:addSkill(zombie_rule)

local zombie_mode = fk.CreateGameMode{
  name = "zombie_mode",
  minPlayer = 8,
  maxPlayer = 8,
  logic = zombie_getLogic,
  rule = zombie_rule,
  winner_getter = function(self, victim)
    local room = victim.room
    local haszombie = table.find(room.players, function(p) return p.role == "rebel" end)

    local alive = table.filter(room.alive_players, function(p)
      return not p.surrendered
    end)
    if #alive == 1 and not haszombie then
      return "rebel"
    end

    local rebel_win = true
    local lord_win = haszombie
    for _, p in ipairs(alive) do
      if table.contains(human_role, p.role) then
        rebel_win = false
      end
      if table.contains(zombie_role, p.role) then
        lord_win = false
      end
    end

    local winner
    if lord_win then winner = "lord+loyalist" end
    if rebel_win then winner = "rebel" end

    return winner
  end,
}

Fk:loadTranslationTable{
  ["zombie"] = "僵尸",
  ["zombie_xunmeng"] = "迅猛",
  [":zombie_xunmeng"] = "锁定技，你的杀造成伤害时，令此伤害+1，" ..
    "若此时你的体力值大于1，则你失去1点体力。",
  ["zombie_zaibian"] = "灾变",
  [":zombie_zaibian"] = "锁定技，摸牌阶段，若人类玩家数-僵尸玩家数+1大于0，则你多摸该数目的牌。",
  ["zombie_ganran"] = "感染",
  [":zombie_ganran"] = "锁定技，你手牌中的装备牌视为【铁锁连环】。",
  ["zombie_mode"] = "僵尸模式",
  [":zombie_mode"] = zombie_desc,
  ["@zombie_tuizhi"] = "退治",
  ["zombie_tuizhi_success"] = "主公已经集齐8个退治标记！僵尸被退治！",
}

return zombie_mode
