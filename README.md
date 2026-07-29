# roblox-settings-menu


## Sistema de mineria: Pickaxe + variable money

Herramienta **Pickaxe** con animacion de picazo al click izquierdo, y una variable
**money** que sube segun la zona donde esta parado el jugador.

| Zona (nombre de la Part) | money por picazo |
| --- | --- |
| Naturaleza | +1 |
| Desierto | +5 |
| Mina | +10 |
| Luna | +25 |
| Dulces | +50 |

Las zonas pueden ser una `Part` sola o un `Model`/`Folder` con ese nombre (el script
sube por la jerarquia buscando el nombre), y pueden estar en cualquier parte de Workspace.

### Opcion A: un solo script (copiar y pegar)

La mas simple, no necesita Rojo ni ModuleScripts:

1. `ServerScriptService` > Insert Object > **Script**
2. Pega el contenido de [`standalone/PickaxeAllInOne.server.lua`](standalone/PickaxeAllInOne.server.lua)
3. Play

### Opcion B: version modular con Rojo

El mapeo ya esta en `default.project.json`:

```bash
rojo serve   # y conecta el plugin de Rojo desde Studio
```

| Archivo | Destino en Studio | Tipo |
| --- | --- | --- |
| `src/ReplicatedStorage/MiningConfig.lua` | ReplicatedStorage | ModuleScript `MiningConfig` |
| `src/ServerScriptService/PickaxeTool.lua` | ServerScriptService | ModuleScript `PickaxeTool` |
| `src/ServerScriptService/MiningService.server.lua` | ServerScriptService | Script `MiningService` |
| `src/ServerScriptService/ZonesSetup.server.lua` | ServerScriptService | Script opcional (5 plataformas de prueba) |
| `src/StarterPlayer/StarterPlayerScripts/PickaxeClient.client.lua` | StarterPlayerScripts | LocalScript `PickaxeClient` |

`MiningService` y `PickaxeTool` deben quedar hermanos dentro de `ServerScriptService`.

### Como funciona

- **money**: se crea `player.leaderstats.money` (IntValue), asi se ve en la lista de
  jugadores. Tambien se copia a un atributo: `player:GetAttribute("money")`.
- **Tool**: el pico se construye por codigo (mango + cabeza de metal) y se copia a
  `StarterPack`, con una red de seguridad que lo entrega al Backpack si no llego.
- **Click izquierdo**: `Tool.Activated` (tambien cubre el tap en movil).
- **Animacion del picazo**: se interpola `Tool.Grip` (sube 75 grados, baja de golpe 60 y
  vuelve). Corre en el servidor para que **todos** los jugadores vean el golpe, y no hace
  falta subir ninguna animacion. Si subes una propia, pon su id en `ANIMATION_ID`.
- **Zona**: raycast hacia abajo desde el jugador. En la version modular, primero se usa la
  part apuntada con el mouse y si no es zona, se cae al raycast.
- **Anti-exploit**: cooldown por jugador (0.55 s) y todo el dinero se calcula en el servidor.
- **Efecto**: chispas del color de la zona en el punto golpeado.

### Debug

Los scripts traen `DEBUG = true`. En Output veras:

```
[Pickaxe] MiningService listo
[Pickaxe] Pico agregado a StarterPack
[Pickaxe] Contenido del Backpack de Jugador: Pickaxe (Tool)
[Pickaxe] Jugador pico en Mina +10 => money: 10
```

Si al picar sale `Piso detectado: ... - no es una zona valida`, ahi te dice el nombre real
de lo que estas pisando. Ponlo en `false` cuando ya funcione.

### Scripts extra

- [`standalone/PickaxeBackpackFix.client.lua`](standalone/PickaxeBackpackFix.client.lua):
  LocalScript que reactiva la mochila de Roblox, por si algun script del juego la desactiva
  y por eso no se ve el pico.
- [`standalone/SetHojas1Morado.server.lua`](standalone/SetHojas1Morado.server.lua):
  pinta de morado todo lo que se llame `Hojas1`.
- [`standalone/Hojas1CambiaColor.server.lua`](standalone/Hojas1CambiaColor.server.lua):
  hace que `Hojas1` vaya cambiando de color en bucle con TweenService.

### Ajustes

En `standalone/PickaxeAllInOne.server.lua` (o en `src/ReplicatedStorage/MiningConfig.lua`):
`REWARDS` (cuanto suma cada zona), `SWING_COOLDOWN` (velocidad de picado),
`GROUND_CHECK_DISTANCE`, `ANIMATION_ID` y `HIT_SOUND_ID`.

El money no se guarda entre sesiones a proposito. Para eso hay que agregar `DataStoreService`
leyendo/escribiendo `player.leaderstats.money` en `PlayerAdded` / `PlayerRemoving` + `BindToClose`.
