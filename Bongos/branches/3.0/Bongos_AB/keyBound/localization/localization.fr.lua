--[[
	KeyBound localization file
		French
--]]

local L = LibStub('AceLocale-3.0'):NewLocale('KeyBound', 'frFR')
if not L then return end

L.Enabled = "Bindings mode enabled"
L.Disabled = "Bindings mode disabled"
L.ClearTip = format("Appuyer sur %s pour effacer tous les bindings", GetBindingText("ESCAPE", "KEY_"))
L.NoKeysBoundTip = "No current bindings"
L.ClearedBindings = "Suppression de tous les binding de %s"
L.BoundKey = "D�finir %s � %s"
L.UnboundKey = "Unbound %s depuis %s"
L.CannotBindInCombat = "Cannot bind keys in combat"
L.CombatBindingsEnabled = "Sortie de combat, keybinding mode activ�"
L.CombatBindingsDisabled = "Entr�e en combat, keybinding mode d�sactiv�"