local desc_rand = [[
  # 随机模式

  ___

  规则很简单的模式；每轮游戏开始时，除主公外所有存活角色重新分配身份和座位。

  游戏全程所有人明着身份打牌。

  是不是很简单呢？不过至于玩起来究竟如何就有待商榷了...
]]

local n_rand_rule = fk.CreateTriggerSkill{
  name = "#n_rand_rule",
  priority = 0.001,
  events = {fk.RoundStart},
  can_trigger = function() return true end,
  on_trigger = function()
    local room = RoomInstance
    local lord = room:getLord()
    local others = room:getOtherPlayers(lord)
    local roles = table.map(others, function(p) return p.role end)
    table.shuffle(roles)
    local new_others = table.simpleClone(others)
    table.shuffle(new_others)
    local swapped = {}

    for i, p in ipairs(others) do
      room:setPlayerProperty(p, "role", roles[i])
      local p2 = new_others[i]
      if p ~= p2 and (not swapped[p]) and (not swapped[p2]) then 
        swapped[p] = true
        swapped[p2] = true
        room:swapSeat(p, p2)
      end
    end
  end,
}
Fk:addSkill(n_rand_rule)

local n_rand_mode = fk.CreateGameMode{
  name = "n_rand_mode",
  minPlayer = 2,
  maxPlayer = 8,
  rule = n_rand_rule,
}
Fk:loadTranslationTable{
  ["n_rand_mode"] = "随机模式",
  [":n_rand_mode"] = desc_rand,
}

return n_rand_mode
