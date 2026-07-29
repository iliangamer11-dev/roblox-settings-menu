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
| `src/ServerScriptService/MoneyPopup.lua` | ServerScriptService | ModuleScript `MoneyPopup` |
| `src/ServerScriptService/MiningService.server.lua` | ServerScriptService | Script `MiningService` |
| `src/ServerScriptService/ZonesSetup.server.lua` | ServerScriptService | Script opcional (5 plataformas de prueba) |
| `src/StarterPlayer/StarterPlayerScripts/PickaxeClient.client.lua` | StarterPlayerScripts | LocalScript `PickaxeClient` |

`MiningService`, `PickaxeTool` y `MoneyPopup` deben quedar hermanos dentro de
`ServerScriptService`.

### Como funciona

- **money**: se crea `player.leaderstats.money` (IntValue), asi se ve en la lista de
  jugadores. Tambien se copia a un atributo: `player:GetAttribute("money")`.
- **Tool**: el pico se construye por codigo con el **mango sobre el eje Z** (la punta mira
  hacia -Z) y se copia a `StarterPack`, con una red de seguridad que lo entrega al Backpack
  si no llego.
- **Click izquierdo**: `Tool.Activated` (tambien cubre el tap en movil).
- **Animacion del picazo**: el pico **gira sobre el punto donde lo agarra la mano** y baja
  hasta tocar la part. El angulo del golpe se calcula con un raycast desde la mano al suelo
  (`asin(altura / HEAD_REACH)`), asi que en una zona alta el golpe es corto y en una baja es
  mas largo, sin atravesar el piso. Se interpola `Tool.Grip` en el servidor para que **todos**
  los jugadores vean el golpe, y no hace falta subir ninguna animacion. Si subes una propia,
  pon su id en `ANIMATION_ID`.
- **Popup de dinero**: al sumar, aparece un cartel con un `ImageLabel` arriba (tu icono) y un
  `TextLabel` debajo (`+1`, `+5`, ...) en un punto **random alrededor del jugador**, que sube
  y se desvanece. Todo configurable en `POPUP`.
- **Zona y punto de impacto**: se tira un raycast hacia abajo a `SWING.HIT_OFFSET` studs
  **delante del personaje**, ahi es donde cae el pico. Ese punto decide la zona, las chispas
  y el agujero. El cursor no se usa. Si delante no hay zona valida (un borde, un objeto
  encima...), se cobra la zona que esta pisando.
- **Agujero**: cada picazo deja una marca oscura pegada a la superficie que desaparece a los
  2 segundos (`HOLE.LIFETIME`).
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

**Si pusiste `IMAGE_ID` y no se ve la imagen**: pon `POPUP.ALWAYS_SHOW_CIRCLE = true`.
Si aparece el circulo de color pero no tu icono, el problema es el id, no el cartel.
Causas mas comunes:

- Subiste la imagen como **Decal** y copiaste el id del decal. `ImageLabel` necesita el id
  de la **imagen**: en Studio, `Asset Manager` > `Images` > clic derecho > copiar el id.
- La imagen todavia esta en moderacion (tarda un rato en aprobarse).
- Falta el prefijo. Los scripts ya lo agregan si pones solo numeros, pero el formato
  correcto es `"rbxassetid://123456789"`.

### Scripts extra

- [`standalone/PickaxeBackpackFix.client.lua`](standalone/PickaxeBackpackFix.client.lua):
  LocalScript que reactiva la mochila de Roblox, por si algun script del juego la desactiva
  y por eso no se ve el pico.
- [`standalone/SetHojas1Morado.server.lua`](standalone/SetHojas1Morado.server.lua):
  pinta de morado todo lo que se llame `Hojas1`.
- [`standalone/Hojas1CambiaColor.server.lua`](standalone/Hojas1CambiaColor.server.lua):
  hace que `Hojas1` vaya cambiando de color en bucle con TweenService.

### Ajustes

Todo esta en `src/ReplicatedStorage/MiningConfig.lua` (o arriba de
`standalone/PickaxeAllInOne.server.lua` si usas la version de un archivo).

**Recompensas y ritmo**: `REWARDS`, `SWING_COOLDOWN`, `GROUND_CHECK_DISTANCE`.

**El pico** (`PICKAXE`):

| Campo | Para que sirve |
| --- | --- |
| `HANDLE_SIZE` | Tamano del mango. El largo va en Z |
| `HEAD_SIZE` | Las dos puntas van sobre el eje Y: `(grosor X, largo Y, grosor Z)` |
| `HEAD_COLOR`, `HEAD_ANGLE` | Color y cuanto se echan las puntas hacia atras |
| `GRIP_OFFSET` | Donde agarra la mano el mango (Z positivo = mas atras) |
| `GRIP_ROTATION` | Rotacion del agarre en grados, si queda raro en la mano |
| `REST_ANGLE` | Inclinacion en reposo (negativo = punta levantada) |

**El picazo** (`SWING`):

| Campo | Para que sirve |
| --- | --- |
| `START_ANGLE` | Cuanto se levanta el pico antes de golpear |
| `MAX_ANGLE` | Limite hacia abajo, para no atravesar el piso |
| `HEAD_REACH` | Studs desde el agarre hasta la punta (define el angulo del golpe) |
| `RAISE_TIME`, `STRIKE_TIME`, `HOLD_TIME`, `RETURN_TIME` | Duraciones de cada fase |
| `AXIS_SIGN` | Ponlo en `-1` si el pico gira al lado contrario |
| `HIT_OFFSET` | Studs delante del jugador donde cae la punta (chispas y agujero) |

**El agujero** (`HOLE`): marca oscura que queda donde se pico y desaparece a los
`LIFETIME` segundos (2 por defecto). Se ajusta con `SIZE` (diametro), `DEPTH`, `COLOR`,
`MATERIAL` y `USE_ZONE_COLOR` (usa el color de la zona oscurecido). Se crea con
`CanQuery = false` para que no interfiera con los raycast de las zonas.

**El popup** (`POPUP`):

| Campo | Para que sirve |
| --- | --- |
| `IMAGE_ID` | Tu icono: `"rbxassetid://..."` (o solo el numero). Vacio = circulo de color |
| `ALWAYS_SHOW_CIRCLE` | `true` dibuja el circulo detras de tu imagen, para depurar |
| `IMAGE_COLOR`, `IMAGE_TRANSPARENCY` | Color y transparencia del icono |
| `TEXT_FORMAT` | Texto de abajo, `%d` es la cantidad. Ej: `"+%d money"` |
| `TEXT_COLOR`, `TEXT_STROKE_COLOR`, `FONT` | Estilo del texto |
| `WIDTH`, `HEIGHT`, `IMAGE_RATIO` | Tamano del cartel en studs y cuanto ocupa la imagen |
| `IMAGE_SCALE` | Escala fina de la imagen dentro de su hueco (`1` = a tope) |
| `MIN_RADIUS`, `MAX_RADIUS`, `MIN_HEIGHT`, `MAX_HEIGHT` | Zona random alrededor del jugador |
| `RISE_HEIGHT`, `DURATION` | Cuanto sube y cuanto dura antes de desaparecer |
| `ALWAYS_ON_TOP`, `MAX_DISTANCE` | Si se ve atravesando paredes y desde cuan lejos |

El money no se guarda entre sesiones a proposito. Para eso hay que agregar `DataStoreService`
leyendo/escribiendo `player.leaderstats.money` en `PlayerAdded` / `PlayerRemoving` + `BindToClose`.
