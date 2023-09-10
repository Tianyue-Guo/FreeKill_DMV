-- SPDX-License-Identifier: GPL-3.0-or-later

local extension = Package:new("gamemode", Package.SpecialPack)

extension:addGameMode(require "packages/gamemode/1v2")
extension:addGameMode(require "packages/gamemode/2v2")
-- extension:addGameMode(require "packages/gamemode/rand")
extension:addGameMode(require "packages/gamemode/1v1")
extension:addGameMode(require "packages/gamemode/chaos_mode")
extension:addGameMode(require "packages/gamemode/espionage")
extension:addGameMode(require "packages/gamemode/variation")
extension:addGameMode(require "packages/gamemode/vanished_dragon")
extension:addGameMode(require "packages/gamemode/qixi")
extension:addGameMode(require "packages/gamemode/zombie_mode")

local chaos_mode_cards = require "packages/gamemode/chaos_mode_cards"
local espionage_cards = require "packages/gamemode/espionage_cards"
local vanished_dragon_cards = require "packages/gamemode/vanished_dragon_cards"
local variation_cards = require "packages/gamemode/variation_cards"

local zombie = require "packages/gamemode/zombie"

return {
  extension,

  chaos_mode_cards,
  espionage_cards,
  vanished_dragon_cards,
  variation_cards,

  zombie,
}
