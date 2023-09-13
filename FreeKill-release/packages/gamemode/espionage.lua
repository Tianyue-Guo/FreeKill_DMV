-- SPDX-License-Identifier: GPL-3.0-or-later
local description = [[
  # 用间模式简介

  ---

  ## 喵喵喵
]]
--什么都没有！
local espionage = fk.CreateGameMode{
  name = "espionage",
  minPlayer = 2,
  maxPlayer = 8,
  whitelist = {"espionage"},
  blacklist = {},
}

Fk:loadTranslationTable{
  ["espionage"] = "用间测试版",
  [":espionage"] = description,
}

return espionage
