--[[
	PickaxeBackpackFix (OPCIONAL)

	Usalo solo si en el Output ves que el pico SI esta en el Backpack pero no
	aparece en la barra de abajo de la pantalla. Eso pasa cuando algun script
	del juego desactiva la mochila de Roblox.

	INSTALACION:
	StarterPlayer > StarterPlayerScripts > Insert Object > LocalScript
	y pega este codigo.
]]

local StarterGui = game:GetService("StarterGui")

-- Se reintenta porque otros scripts pueden desactivarla despues de este
for _ = 1, 10 do
	local ok, err = pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
	end)
	if not ok then
		warn("[Pickaxe] No se pudo activar la mochila: " .. tostring(err))
	end
	task.wait(1)
end

print("[Pickaxe] Mochila de Roblox activada")
