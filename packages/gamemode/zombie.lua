-- SPDX-License-Identifier: GPL-3.0-or-later
local extension = Package("zombie")
extension.extensionName = "gamemode"

local zombie = General(extension, "zombie", "god", 1)
zombie.hidden = true
local xunmeng = fk.CreateTriggerSkill{
  name = "zombie_xunmeng",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(self.name) then
      return
    end

    local c = data.card
    return c and c.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.damage = data.damage + 1
    if player.hp > 1 then
      room:loseHp(player, 1, self.name)
    end
  end,
}
local zaibian = fk.CreateTriggerSkill{
  name = "zombie_zaibian",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.DrawNCards},
  can_trigger = function(self, event, target, player, data)
    if not (player == target and player:hasSkill(self.name)) then return end
    local room = player.room
    local human = #table.filter(room.alive_players, function(p)
      return p.role == "lord" or p.role == "loyalist"
    end)
    local zombie = #room.alive_players - human
    return human - zombie + 1 > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local human = #table.filter(room.alive_players, function(p)
      return p.role == "lord" or p.role == "loyalist"
    end)
    local zombie = #room.alive_players - human
    data.n = data.n + (human - zombie + 1)
  end,
}
local ganran = fk.CreateFilterSkill{
  name = "zombie_ganran",
  card_filter = function(self, to_select, player)
    return player:hasSkill(self.name) and to_select.type == Card.TypeEquip and
      not table.contains(player.player_cards[Player.Equip], to_select.id) and
      not table.contains(player.player_cards[Player.Judge], to_select.id)
      -- table.contains(player.player_cards[Player.Hand], to_select.id) --不能用getCardArea！
  end,
  view_as = function(self, to_select)
    local card = Fk:cloneCard("iron_chain", to_select.suit, to_select.number)
    card.skillName = self.name
    return card
  end,
}
zombie:addSkill("ex__paoxiao")
zombie:addSkill("ol_ex__wansha")
zombie:addSkill(xunmeng)
zombie:addSkill(zaibian)
zombie:addSkill(ganran)

return extension
