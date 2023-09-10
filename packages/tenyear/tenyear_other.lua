local extension = Package("tenyear_other")
extension.extensionName = "tenyear"
extension.game_modes_whitelist = { "m_1v2_mode" }

Fk:loadTranslationTable{
  ["tenyear_other"] = "十周年-斗地主模式",
  ["tycl"] = "典",
}

local longwang = General(extension, "longwang", "god", 3)
local ty__longgong = fk.CreateTriggerSkill{
  name = "ty__longgong",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.from and not data.from.dead and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#longgong-invoke::"..data.from.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:getCardsFromPileByRule(".|.|.|.|.|equip")
    if #card > 0 then
      room:moveCards({
        ids = card,
        to = data.from.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    end
    return true
  end,
}
local ty__sitian = fk.CreateActiveSkill{
  name = "ty__sitian",
  anim_type = "offensive",
  card_num = 2,
  target_num = 0,
  can_use = function(self, player)
    return player:getHandcardNum() > 1
  end,
  card_filter = function(self, to_select, selected)
    if Fk:currentRoom():getCardArea(to_select) == Player.Hand and #selected < 2 then
      if #selected == 1 then
        return Fk:getCardById(to_select).suit ~= Fk:getCardById(selected[1]).suit
      end
      return true
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    local choices = table.random({"sitian1", "sitian2", "sitian3", "sitian4", "sitian5"}, 2)
    local choice = room:askForChoice(player, choices, self.name, "#ty__sitian-choice", true)
    local targets = room:getOtherPlayers(player)
    if choice ~= "sitian4" then
      room:doIndicate(player.id, table.map(targets, function(p) return p.id end))
    end
    if choice == "sitian1" then
      for _, p in ipairs(targets) do
        if not p.dead then
          room:damage{
            from = player,
            to = p,
            damage = 1,
            damageType = fk.FireDamage,
            skillName = self.name
          }
        end
      end
    end
    if choice == "sitian2" then
      for _, p in ipairs(targets) do
        if not p.dead then
          local judge = {
            who = p,
            reason = "lightning",
            pattern = ".|2~9|spade",
          }
          room:judge(judge)
          local result = judge.card
          if result.suit == Card.Spade and result.number >= 2 and result.number <= 9 then
            room:damage{
              to = p,
              damage = 3,
              card = effect.card,
              damageType = fk.ThunderDamage,
              skillName = self.name,
            }
          end
        end
      end
    end
    if choice == "sitian3" then
      for _, p in ipairs(targets) do
        if not p.dead then
          if #p.player_cards[Player.Equip] > 0 then
            p:throwAllCards("e")
          else
            room:loseHp(p, 1, self.name)
          end
        end
      end
    end
    if choice == "sitian4" then
      local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p) return p.id end), 1, 1,
        "#sitian-choose", self.name, true)
      local to
      if #tos > 0 then
        to = room:getPlayerById(tos[1])
        if not to:isKongcheng() then
          to:throwAllCards("h")
        else
          room:loseHp(to, 1, self.name)
        end
      end
    end
    if choice == "sitian5" then
      for _, p in ipairs(targets) do
        if not p.dead then
          room:setPlayerMark(p, "@@lw_dawu", 1)
        end
      end
    end
  end,
}
local sitian_trigger = fk.CreateTriggerSkill{
  name = "#sitian_trigger",
  mute = true,
  events = {fk.PreCardEffect},
  can_trigger = function(self, event, target, player, data)
    return target:getMark("@@lw_dawu") > 0 and data.card.type == Card.TypeBasic
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(target, "@@lw_dawu", 0)
    return true
  end,
}
ty__sitian:addRelatedSkill(sitian_trigger)
longwang:addSkill(ty__longgong)
longwang:addSkill(ty__sitian)
Fk:loadTranslationTable{
  ["longwang"] = "东海龙王",
  ["ty__longgong"] = "龙宫",
  [":ty__longgong"] = "每回合限一次，当你受到伤害时，你可以防止此伤害，改为令伤害来源随机获得牌堆中的一张装备牌。",
  ["ty__sitian"] = "司天",
  [":ty__sitian"] = "出牌阶段，你可以弃置两张不同花色的手牌，然后改变天气（从两个选项中选择一项）：<br>烈日：对其他角色各造成1点火焰伤害；<br>"..
  "雷电：所有其他角色各进行一次【闪电】判定；<br>大浪：所有其他角色弃置装备区所有牌（没有装备则失去1点体力）；<br>"..
  "暴雨：弃置一名角色所有手牌（没有手牌则失去1点体力）；<br>大雾：所有其他角色使用的下一张基本牌无效。",
  ["#longgong-invoke"] = "龙宫：你可以防止你受到的伤害，令 %dest 随机获得一张装备牌。",
  ["#ty__sitian-choice"] = "司天：选择执行的一项",
  ["#sitian-choose"] = "暴雨：令一名角色弃置所有手牌，若其没有手牌则改为失去1点体力。",
  ["sitian1"] = "烈日",
  [":sitian1"] = "对其他角色各造成1点火焰伤害",
  ["sitian2"] = "雷电",
  [":sitian2"] = "所有其他角色各进行一次【闪电】判定",
  ["sitian3"] = "大浪",
  [":sitian3"] = "所有其他角色弃置装备区所有牌（没有装备则失去1点体力）",
  ["sitian4"] = "暴雨",
  [":sitian4"] = "弃置一名角色所有手牌（没有手牌则失去1点体力）",
  ["sitian5"] = "大雾",
  [":sitian5"] = "所有其他角色使用的下一张基本牌无效",
  ["@@lw_dawu"] = "雾",

  ["$ty__longgong1"] = "停手，大哥！给东西能换条命不？",
  ["$ty__longgong2"] = "冤家宜解不宜结。",
  ["$ty__longgong3"] = "莫要伤了和气。",
  ["$ty__sitian1"] = "观众朋友大家好，欢迎收看天气预报！",
  ["$ty__sitian2"] = "这一喷嚏，不知要掀起多少狂风暴雨。",
  ["~longwang"] = "三年之期已到，哥们要回家啦…",
}

local wuzixu = General(extension, "wuzixu", "god", 4)
local ty__nutao = fk.CreateTriggerSkill{
  name = "ty__nutao",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecifying, fk.Damage},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if event == fk.TargetSpecifying then
        return data.card.type == Card.TypeTrick and data.firstTarget and
          table.find(AimGroup:getAllTargets(data.tos), function(id) return id ~= player.id end)
      else
        return player.phase == Player.Play and data.damageType == fk.ThunderDamage
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetSpecifying then
      local targets = table.filter(AimGroup:getAllTargets(data.tos), function(id)
        return id ~= player.id and not room:getPlayerById(id).dead end)
      local to = room:getPlayerById(table.random(targets))
      room:doIndicate(player.id, {to.id})
      room:damage{
        from = player,
        to = to,
        damage = 1,
        damageType = fk.ThunderDamage,
        skillName = self.name,
      }
    else
      room:addPlayerMark(player, "@ty__nutao-phase", 1)
    end
  end,
}
local ty__nutao_targetmod = fk.CreateTargetModSkill{
  name = "#ty__nutao_targetmod",
  residue_func = function(self, player, skill, scope, card, to)
    if card and card.trueName == "slash" and player:getMark("@ty__nutao-phase") > 0 and scope == Player.HistoryPhase then
      return player:getMark("@ty__nutao-phase")
    end
  end,
}
ty__nutao:addRelatedSkill(ty__nutao_targetmod)
wuzixu:addSkill(ty__nutao)
Fk:loadTranslationTable{
  ["wuzixu"] = "涛神",
  ["ty__nutao"] = "怒涛",
  [":ty__nutao"] = "锁定技，当你使用锦囊牌指定目标时，你随机对一名其他目标角色造成1点雷电伤害；当你于出牌阶段造成雷电伤害后，你本阶段使用【杀】次数上限+1。",
  ["@ty__nutao-phase"] = "怒涛",
}

local libai = General(extension, "libai", "god", 3)
local jiuxian = fk.CreateViewAsSkill{
  name = "jiuxian",
  anim_type = "offensive",
  pattern = "analeptic",
  card_filter = function(self, to_select, selected)
    local names = {"savage_assault", "archery_attack", "amazing_grace", "god_salvation", "iron_chain", "redistribute"}
    return #selected == 0 and table.contains(names, Fk:getCardById(to_select).trueName)
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return nil end
    local card = Fk:cloneCard("analeptic")
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
}
local jiuxian_targetmod = fk.CreateTargetModSkill{
  name = "#jiuxian_targetmod",
  bypass_times = function(self, player, skill, scope, card)
    return player:hasSkill("jiuxian") and card.trueName == "analeptic" and scope == Player.HistoryTurn
  end,
}
local shixian_pairs = {
  {"slash", "archery_attack", "vine", "enemy_at_the_gates", "glittery_armor", "shangyang_reform"},
  {"steel_lance", "wd_crossbow_tank", "wd_stop_thirst"},
  {"looting"},
  {"dark_armor", "underhanding"},
  {"redistribute", "defeating_the_double", "floating_thunder", "wd_save_energy"},
  {"peach", "blade", "spear", "dismantlement", "guding_blade", "daggar_in_smile", "seven_stars_sword", 
    "crafty_escape", "reinforcement", "await_exhausted", "triblade", "wd_seven_stars_sword"},
  {"ex_nihilo", "duel", "huailiu", "analeptic", "wd_run"},
  {"jink", "lightning", "qinggang_sword", "double_swords", "ice_sword", "zhuahuangfeidian", "dayuan",
    "supply_shortage", "fan", "iron_chain", "black_chain", "five_elements_fan", "chasing_near", "n_brick", "six_swords", "qin_dragon_sword"},
  {"collateral", "savage_assault", "eight_diagram", "nioh_shield", "drowning", "horsetail_whisk", "wd_drowning", "wd_gold"},
  {"snatch", "substituting", "moon_spear", "wd_rice"},
  {"amazing_grace", "kylin_bow", "jueying", "zixing", "fire_attack", "breastplate", "raid_and_frontal_attack",
    "abandoning_armor", "paranoid", "befriend_attacking", "wd_breastplate", "wd_let_off_enemy"},
  {"god_salvation", "nullification", "halberd", "silver_lion", "unexpectation", "foresight", "honey_trap",
    "avoiding_disadvantages", "diversion", "time_flying", "known_both", "wd_sun_moon_halberd"},
  {"indulgence", "crossbow", "axe", "chitu", "dilu", "wonder_map", "taigong_tactics", "poison", 
    "replace_with_a_fake", "sincere_treat", "wenhe_chaos", "n_relx_v", "peace_spell", "golden_comb", "jade_comb", "rhino_comb",
    "celestial_calabash", "talisman", "wd_baihu", "wd_lure_in_deep"},
}
--a ia ua：杀，万箭齐发，藤甲，兵临城下，烂银甲，商鞅变法
--o e uo：衠钢槊，连弩战车，望梅止渴
--ie ve：趁火打劫
--ai uai：黑光铠，瞒天过海
--ei ui：调剂盐梅，以半击倍，浮雷，养精蓄锐
--ao iao：桃，青龙偃月刀，丈八蛇矛，过河拆桥，古锭刀，笑里藏刀，七宝刀，金蝉脱壳，增兵减灶，以逸待劳，三尖两刃刀，七星刀
--ou iu：无中生有，决斗，骅骝，酒，走
--an ian uan van：闪，闪电，青釭剑，雌雄双股剑，寒冰剑，爪黄飞电，大宛，兵粮寸断，朱雀羽扇，铁索连环，乌铁锁链，五行鹤翎扇，逐近弃远，砖，吴六剑，真龙长剑
--en in un vn：借刀杀人，南蛮入侵，八卦阵，仁王盾，水淹七军，太极拂尘，金
--ang iang uang：顺手牵羊，李代桃僵，银月枪，粮
--eng ing ong ung：五谷丰登，麒麟弓，绝影，紫骍，火攻，护心镜，奇正相生，弃甲曳兵，草木皆兵，远交近攻，欲擒故纵
--i er v：桃园结义，无懈可击，方天画戟，白银狮子，出其不意，洞烛先机，美人计，违害就利，声东击西，斗转星移，知己知彼，日月戟
--u：乐不思蜀，诸葛连弩，贯石斧，赤兔，的卢，天机图，太公阴符，毒，偷梁换柱，推心置腹，文和乱武，悦刻五，太平要术，金梳，琼梳，犀梳，灵宝仙葫，冲应神符，白鹄，诱敌深入
local shixian = fk.CreateTriggerSkill{
  name = "shixian",
  anim_type = "special",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@shixian-turn") == 0 then
      room:setPlayerMark(player, "@shixian-turn", data.card.trueName)
      return
    else
      if data.card.trueName == player:getMark("@shixian-turn") then
        self:doCost(event, target, player, data)
      else
        local name = player:getMark("@shixian-turn")
        room:setPlayerMark(player, "@shixian-turn", data.card.trueName)
        for _, p in ipairs(shixian_pairs) do
          if table.contains(p, name) and table.contains(p, data.card.trueName) then
            self:doCost(event, target, player, data)
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#shixian-invoke:::"..data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
    if data.card.type ~= Card.TypeEquip and data.card.sub_type ~= Card.SubtypeDelayedTrick and
      not table.contains({"jink", "nullification"}, data.card.trueName) and
      not (data.card.trueName == "peach" and player:isWounded()) then
      data.extra_data = data.extra_data or {}
      data.extra_data.shixian = data.extra_data.shixian or true
    end
  end,

  refresh_events = {fk.CardUseFinished, fk.AfterCardUseDeclared, fk.AfterCardsMove, fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    if event == fk.CardUseFinished then
      return data.extra_data and data.extra_data.shixian
    elseif event == fk.AfterCardUseDeclared then
      return player == target
    elseif event == fk.AfterCardsMove then
      return player:hasSkill(self.name, true) and player:getMark("shixian_name") ~= 0
    elseif event == fk.TurnEnd then
      return player:getMark("shixian_name") ~= 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUseFinished then
      player.room:doCardUseEffect(data)
      data.extra_data.shixian = false
      return false
    elseif event == fk.AfterCardUseDeclared then
      room:setPlayerMark(player, "shixian_name", data.card.trueName)
    elseif event == fk.TurnEnd then
      room:setPlayerMark(player, "shixian_name", 0)
    elseif event == fk.AfterCardsMove then
      local no_change = true
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            room:setCardMark(Fk:getCardById(info.cardId), "@@shixian_rhyme", 0)
          end
        end
        if move.to == player.id and move.toArea == Card.PlayerHand then
          no_change = false
        end
      end
      if no_change then return false end
    end
    local lastcardname = player:getMark("shixian_name")
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      local card = Fk:getCardById(id)
      local cardname = card.trueName
      local marked = 0
      if player:hasSkill(self.name, true) then
        for _, p in ipairs(shixian_pairs) do
          if table.contains(p, cardname) and table.contains(p, lastcardname) then
            marked = 1
            break
          end
        end
      end
      if marked ~= card:getMark("@@shixian_rhyme") then
        room:setCardMark(card, "@@shixian_rhyme", marked)
      end
    end
  end,
}
jiuxian:addRelatedSkill(jiuxian_targetmod)
libai:addSkill(jiuxian)
libai:addSkill(shixian)
Fk:loadTranslationTable{
  ["libai"] = "李白",
  ["jiuxian"] = "酒仙",
  [":jiuxian"] = "你使用【酒】无次数限制，你可将多目标锦囊牌当【酒】使用。",
  ["shixian"] = "诗仙",
  [":shixian"] = "你使用一张牌时，若此牌与你本回合使用的上一张牌押韵，你可以摸一张牌并令此牌额外执行一次效果。",
  ["@shixian-turn"] = "诗仙",
  ["#shixian-invoke"] = "诗仙：%arg押韵！你可以摸一张牌并令此牌额外执行一次效果！",

  ["@@shixian_rhyme"] = "押韵",

  ["$jiuxian1"] = "地若不爱酒，地应无酒泉。",
  ["$jiuxian2"] = "天若不爱酒，酒星不在天。",
  ["$shixian1"] = "武侯立岷蜀，壮志吞咸京。",
  ["$shixian2"] = "鱼水三顾合，风云四海生。",
  ["~libai"] = "谁识卧龙客，长吟愁鬓斑。",
}

local khan = General(extension, "khan", "god", 3)
local tongliao = fk.CreateTriggerSkill{
  name = "tongliao",
  anim_type = "special",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == player.Draw and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local ids = table.filter(player.player_cards[Player.Hand], function(id)
      return table.every(player.player_cards[Player.Hand], function(id2)
        return Fk:getCardById(id).number <= Fk:getCardById(id2).number end) end)
    local cards = room:askForCard(player, 1, 1, false, self.name, true, ".|.|.|.|.|.|"..table.concat(ids, ","), "#tongliao-invoke")
    if #cards > 0 then
      self.cost_data = cards[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:setCardMark(Fk:getCardById(self.cost_data), "@@tongliao", 1)
  end,
}
local tongliao_trigger = fk.CreateTriggerSkill{
  name = "#tongliao_trigger",
  mute = true,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill("tongliao") then
      for _, move in ipairs(data) do
        if move.from == player.id and move.extra_data and move.extra_data.tongliao then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, "tongliao", "drawcard")
    player:broadcastSkillInvoke("tongliao")
    local n = 0
    for _, move in ipairs(data) do
      if move.from == player.id and move.extra_data and move.extra_data.tongliao then
        n = n + move.extra_data.tongliao
      end
    end
    player:drawCards(n, "tongliao")
  end,

  refresh_events = {fk.BeforeCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill("tongliao") then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand and Fk:getCardById(info.cardId):getMark("@@tongliao") > 0 then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player.id then
        local n = 0
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand and Fk:getCardById(info.cardId):getMark("@@tongliao") > 0 then
            player.room:setCardMark(Fk:getCardById(info.cardId), "@@tongliao", 0)
            n = n + Fk:getCardById(info.cardId).number
          end
        end
        if n > 0 then
          move.extra_data = move.extra_data or {}
          move.extra_data.tongliao = n
        end
      end
    end
  end,
}
local wudao = fk.CreateTriggerSkill{
  name = "wudao",
  anim_type = "offensive",
  events = {fk.CardUseFinished, fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if event == fk.CardUseFinished then
        return data.extra_data and data.extra_data.wudao and
          (player:getMark("wudao-turn") == 0 or not table.contains(player:getMark("wudao-turn"), data.extra_data.wudao))
      else
        return player:getMark("wudao-turn") ~= 0 and table.contains(player:getMark("wudao-turn"), data.card:getTypeString())
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.CardUseFinished then
      return player.room:askForSkillInvoke(player, self.name, nil, "#wudao-invoke:::"..data.extra_data.wudao)
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUseFinished then
      local mark = player:getMark("wudao-turn")
      if mark == 0 then mark = {} end
      table.insertIfNeed(mark, data.extra_data.wudao)
      room:setPlayerMark(player, "@wudao-turn", table.concat(mark, ","))
      room:setPlayerMark(player, "wudao-turn", mark)
    else
      data.disresponsiveList = table.map(room.alive_players, function(p) return p.id end)
      if data.card.is_damage_card then
        data.additionalDamage = (data.additionalDamage or 0) + 1
      end
    end
  end,

  refresh_events = {fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local mark = player:getMark(self.name)
    if mark ~= 0 and mark == data.card:getTypeString() and data.card.type ~= Card.TypeEquip and
      (player:getMark("wudao-turn") == 0 or not table.contains(player:getMark("wudao-turn"), data.card:getTypeString())) then
      data.extra_data = data.extra_data or {}
      data.extra_data.wudao = data.card:getTypeString()
    end
    player.room:setPlayerMark(player, self.name, data.card:getTypeString())
  end,
}
tongliao:addRelatedSkill(tongliao_trigger)
khan:addSkill(tongliao)
khan:addSkill(wudao)
Fk:loadTranslationTable{
  ["khan"] = "小约翰可汗",
  ["tongliao"] = "通辽",
  [":tongliao"] = "摸牌阶段结束时，你可以将手牌中点数最小的一张牌标记为“通辽”。当你失去“通辽”牌后，你摸X张牌（X为“通辽”牌的点数）。",
  ["wudao"] = "悟道",
  [":wudao"] = "当你连续使用两张相同类型的牌后，你使用此类型的牌伤害+1且不可被响应直到回合结束。",
  ["#tongliao-invoke"] = "通辽：你可以将一张点数最小的手牌标记为“通辽”牌",
  ["@@tongliao"] = "通辽",
  ["#wudao-invoke"] = "悟道：你可以令你使用%arg伤害+1且不可被响应直到当前回合结束",
  ["@wudao-turn"] = "悟道",
}

local zhutiexiong = General(extension, "zhutiexiong", "god", 3)
local bianzhuang_skills = {
  --standard
  "wushuang", "tieqi", "ex__tieji",
  "liegong", "kuanggu", "mengjin", "lieren", "wansha",
  "moukui", "kuangfu", "nuzhan", "zhiman", "re__pojun",
  "jueqing", "pojun", "nos__qianxi", "anjian", "zenhui", "qingxi",
  --ol
  "fengpo", "fuji", "gangzhi", "lingren", "qigong", "saodi", "huanfu", "yimie", "guangao",
  "ol_ex__kuanggu", "ol_ex__liegong", "ol_ex__jianchu", "qin__shanwu",
  --mobile
  "shidi", "dengli", "quedi",
  --overseas
  "os__cuijin", "os__zhenxi", "os__moukui", "os__hengjiang", "os__jintao", "os__gongge", "os__fenghan", "os__yulong", "os__zhenhu",
  "os_ex__qingxi",
  --tenyear
  "ty__wuniang", "zhuilie", "xiaojun", "qingshi", "xingluan", "jiedao", "yangzhong", "funing", "benshi", "choutao", "yiyong", "jinglan",
  "wanggui", "suoliang", "ty_ex__jueqing", "ty_ex__zhiman",
  --jsrg
  "juelie", "fendi", "zhenqiao",
  --yjtw
  "tw__baobian",
  --wandian
  "wd__ciqiu", "wd__fenkai",
  --tuguo
  "tg__fenwei", "tg__danding",
}
local bianzhuang = fk.CreateActiveSkill{
  name = "bianzhuang",
  anim_type = "special",
  card_num = 0,
  target_num = 0,
  prompt = "#bianzhuang",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local n = player:usedSkillTimes(self.name, Player.HistoryGame) > 3 and 3 or 2
    local skills = table.random(bianzhuang_skills, n)
    local generals = {}
    for _, name in ipairs(Fk.package_names) do
      if Fk.packages[name].type == Package.GeneralPack then
        for _, general in ipairs(Fk.packages[name].generals) do
          for _, skill in ipairs(general:getSkillNameList()) do
            if table.contains(skills, skill) and not player:hasSkill(skill, true) then
              table.insertIfNeed(generals, general.name)
            end
          end
        end
      end
    end
    generals = table.random(generals, n)
    local general = room:askForGeneral(player, generals, 1)
    local bianzhuang_info = {player.general, player.gender, player.kingdom}
    player.general = general
    room:broadcastProperty(player, "general")
    player.gender = Fk.generals[general].gender
    room:broadcastProperty(player, "gender")
    player.kingdom = Fk.generals[general].kingdom
    room:broadcastProperty(player, "kingdom")
    local skill_name = table.filter(Fk.generals[general]:getSkillNameList(), function(s) return table.contains(skills, s) end)[1]
    room:handleAddLoseSkills(player, skill_name, nil, false, false)

    local success, data = room:askForUseActiveSkill(player, "bianzhuang_viewas", "#bianzhuang-slash:::"..skill_name, false)
    if success then
      local card = Fk:cloneCard("slash")
      card.skillName = self.name
      room:useCard{
        from = player.id,
        tos = table.map(data.targets, function(id) return {id} end),
        card = card,
        extraUse = true,
      }
    end

    room:handleAddLoseSkills(player, "-"..skill_name, nil, false, false)
    player.general = bianzhuang_info[1]
    room:broadcastProperty(player, "general")
    player.gender = bianzhuang_info[2]
    room:broadcastProperty(player, "gender")
    player.kingdom = bianzhuang_info[3]
    room:broadcastProperty(player, "kingdom")
  end,
}
local bianzhuang_viewas = fk.CreateViewAsSkill{
  name = "bianzhuang_viewas",
  card_filter = function(self, to_select, selected)
    return false
  end,
  view_as = function(self, cards)
    local card = Fk:cloneCard("slash")
    card.skillName = "bianzhuang"
    return card
  end,
}
local bianzhuang_targetmod = fk.CreateTargetModSkill{
  name = "#bianzhuang_targetmod",
  distance_limit_func =  function(self, player, skill, card)
    if card and table.contains(card.skillNames, "bianzhuang") then
      return 999
    end
  end,
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, "bianzhuang")
  end,
}
local bianzhuang_record = fk.CreateTriggerSkill{
  name = "#bianzhuang_record",

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card.type == Card.TypeEquip and player:usedSkillTimes("bianzhuang", Player.HistoryPhase) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player:setSkillUseHistory("bianzhuang", 0, Player.HistoryPhase)
  end,
}
Fk:addSkill(bianzhuang_viewas)
bianzhuang:addRelatedSkill(bianzhuang_targetmod)
bianzhuang:addRelatedSkill(bianzhuang_record)
zhutiexiong:addSkill(bianzhuang)
Fk:loadTranslationTable{
  ["zhutiexiong"] = "朱铁雄",
  ["bianzhuang"] = "变装",
  [":bianzhuang"] = "出牌阶段限一次，你可以从两名武将中选择一个进行变装，然后视为使用一张【杀】（无距离和次数限制），根据变装此【杀】获得额外效果。"..
  "当你使用装备牌后，重置本阶段〖变装〗发动次数。当你发动三次〖变装〗后，本局游戏你进行变装时增加一个选项。",
  ["#bianzhuang"] = "变装：你可以进行“变装”！然后视为使用一张【杀】",
  ["bianzhuang_viewas"] = "变装",
  ["#bianzhuang-slash"] = "变装：视为使用一张【杀】，附带“%arg”的技能效果！",
}

local cl__caocao = General(extension, "tycl__caocao", "wei", 4)
local tycl__jianxiong = fk.CreateTriggerSkill{
  name = "tycl__jianxiong",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = math.min(player:usedSkillTimes(self.name, Player.HistoryGame), 5)
    player:drawCards(n, self.name)
    if not player.dead and table.every(data.card and data.card:isVirtual() and data.card.subcards or {data.card.id}, function(id)
      return room:getCardArea(id) == Card.Processing end) then
      room:obtainCard(player.id, data.card, true, fk.ReasonJustMove)
    end
  end,
}
cl__caocao:addSkill(tycl__jianxiong)
Fk:loadTranslationTable{
  ["tycl__caocao"] = "曹操",
  ["tycl__jianxiong"] = "奸雄",
  [":tycl__jianxiong"] = "当你受到伤害后，你可以摸一张牌，并获得造成伤害的牌。当你发动此技能后，摸牌数+1（至多为5）。",
}

local cl__liubei = General(extension, "tycl__liubei", "shu", 4)
local tycl__rende = fk.CreateActiveSkill{
  name = "tycl__rende",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#tycl__rende",
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and to_select ~= Self.id and target:getMark("tycl__rende-phase") == 0 and target:getHandcardNum() > 1
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(target, "tycl__rende-phase", 1)
    local cards = room:askForCardsChosen(player, target, 2, 2, "h", self.name)
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(cards)
    room:obtainCard(player.id, dummy, false, fk.ReasonPrey)
    if player.dead then return end
    local success, dat = room:askForUseViewAsSkill(player, "#ex__rende_vs", "#ex__rende-ask", true)
    if success then
      local card = Fk.skills["#ex__rende_vs"]:viewAs(dat.cards)
      local use = {
        from = player.id,
        tos = table.map(dat.targets, function(e) return {e} end),
        card = card,
      }
      room:useCard(use)
    end
  end,
}
cl__liubei:addSkill(tycl__rende)
Fk:loadTranslationTable{
  ["tycl__liubei"] = "刘备",
  ["tycl__rende"] = "章武",
  [":tycl__rende"] = "出牌阶段每名其他角色限一次，你可以获得一名其他角色两张手牌，然后视为使用一张基本牌。",
  ["#tycl__rende"] = "章武：获得一名其他角色两张手牌，然后视为使用一张基本牌",
}

local cl__sunquan = General(extension, "tycl__sunquan", "wu", 4)
local tycl__zhiheng = fk.CreateActiveSkill{
  name = "tycl__zhiheng",
  anim_type = "drawcard",
  min_card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 + Self:getMark("@tycl__zhiheng-phase")
  end,
  card_filter = function(self, to_select, selected)
    return not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local hand = player:getCardIds(Player.Hand)
    local more = #hand > 0
    for _, id in ipairs(hand) do
      if not table.contains(effect.cards, id) then
        more = false
        break
      end
    end
    room:throwCard(effect.cards, self.name, player, player)
    if player.dead then return end
    room:drawCards(player, #effect.cards + (more and 1 or 0), self.name)
  end
}
local tycl__zhiheng_record = fk.CreateTriggerSkill{
  name = "#tycl__zhiheng_record",

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill("tycl__zhiheng") and player.phase == Player.Play and data.to ~= player.id
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("tycl__zhiheng_record-phase")
    if mark == 0 then mark = {} end
    if not table.contains(mark, data.to.id) then
      table.insert(mark, data.to.id)
      room:setPlayerMark(player, "tycl__zhiheng_record-phase", mark)
      room:addPlayerMark(player, "@tycl__zhiheng-phase", 1)
    end
  end,
}
tycl__zhiheng:addRelatedSkill(tycl__zhiheng_record)
cl__sunquan:addSkill(tycl__zhiheng)
Fk:loadTranslationTable{
  ["tycl__sunquan"] = "孙权",
  ["tycl__zhiheng"] = "制衡",
  [":tycl__zhiheng"] = "出牌阶段限一次，你可以弃置任意张牌，然后摸等量的牌。若你以此法弃置了所有的手牌，额外摸1张牌。出牌阶段对每名角色限一次，"..
  "当你对其他角色造成伤害后，此技能本阶段可发动次数+1。",
  ["@tycl__zhiheng-phase"] = "制衡",
}

return extension
