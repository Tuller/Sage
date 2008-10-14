--[[
	Localization_frFR.lua
		Translations for Dominos

	French
--]]
-- French version (by Kubik) 2008-08-11
-- � = \195\160
-- � = \195\162
-- � = \195\167
-- � = \195\168
-- � = \195\169
-- � = \195\170
-- � = \195\174
-- � = \195\175
-- � = \195\180
-- � = \195\187

local L = LibStub('AceLocale-3.0'):NewLocale('Dominos', 'frFR')
if not L then return end

--system messages
L.NewPlayer = 'Nouveau profil cr\195\169\195\169 pour %s'
L.Updated = 'Mise \195\160 jour de v%s'

--profiles
L.ProfileCreated = 'Cr\195\169ation nouveau profil "%s"'
L.ProfileLoaded = 'Charger profil "%s"'
L.ProfileDeleted = 'Effacer profil "%s"'
L.ProfileCopied = 'R\195\169glages copi\195\169s de "%s"'
L.ProfileReset = 'R\195\169initialisation profil "%s"'
L.CantDeleteCurrentProfile = 'Le profil courant ne peut \195\170tre effac\195\169'
L.InvalidProfile = 'Profile invalide "%s"'

--slash command help
L.ShowOptionsDesc = 'Afficher le menu options'
L.ConfigDesc = 'Basculer en mode configuration'

L.SetScaleDesc = 'Fixe l\'\195\169chelle de <frameList>'
L.SetAlphaDesc = 'Fixe l\'opacit\195\169 de <frameList>'
L.SetFadeDesc = 'Fixe l\'opacit\195\169 att\195\169nu\195\169e de <frameList>'

L.SetColsDesc = 'Fixe le nombre de colonnes pour <frameList>'
L.SetPadDesc = 'Fixe le niveau de remplissage de <frameList>'
L.SetSpacingDesc = 'Fixe l\'espacement de <frameList>'

L.ShowFramesDesc = 'Montre la <frameList>'
L.HideFramesDesc = 'Cache la <frameList>'
L.ToggleFramesDesc = 'Bascule entre <frameList>'

--slash commands for profiles
L.SetDesc = 'R\195\169glages activ\195\169s : <profile>'
L.SaveDesc = 'R\195\169glages enregistr\195\169s et bascule sur <profile>'
L.CopyDesc = 'Copie des r\195\169glages de <profile>'
L.DeleteDesc = 'Effacer <profile>'
L.ResetDesc = 'Retourn aux r\195\169glages par d\195\169faut'
L.ListDesc = 'Liste des profils'
L.AvailableProfiles = 'Profils disponibles'
L.PrintVersionDesc = 'Afficher la version'

--dragFrame tooltips
L.ShowConfig = '<Clic droit> pour configurer'
L.HideBar = '<Clic milieu ou Shift-Clic droit> pour cacher'
L.ShowBar = '<Clic milieu ou Shift-Clic droit> pour montrer'
L.SetAlpha = "<Roue de souris> pour r�gler l'opacit\195\169 (|cffffffff%d|r)"