# roblox-settings-menu


## Sistema de mineria: Pickaxe + variable money

Herramienta **Pickaxe** con animacion de picazo al click izquierdo. Cada golpe saca un
**mineral** al azar y suma a la variable **money**:

```
dinero = dinero base del mineral x multiplicador de la zona
```

**Minerales** (`MiningConfig.MINERALS`):

| Mineral | Probabilidad | Base | Color del popup |
| --- | --- | --- | --- |
| Piedra | 55 % | 1 | gris |
| Carbon | 20 % | 3 | negro |
| Cobre | 10 % | 8 | marron |
| Hierro | 7 % | 15 | gris claro |
| Oro | 4 % | 40 | dorado |
| Zafiro | 2 % | 80 | azul |
| Amatista | 1 % | 150 | morado |
| Diamante | 0,8 % | 400 | cian |
| Esmeralda | 0,15 % | 1.000 | verde |
| Legendario | 0,05 % | 10.000 | arcoiris (cambia de color) |

**Zonas** (`MiningConfig.ZONE_MULTIPLIERS`):

| Zona (nombre de la Part) | Multiplicador |
| --- | --- |
| Naturaleza | x1 |
| Desierto | x5 |
| Mina | x10 |
| Luna | x25 |
| Dulces | x50 |

Ejemplos: Piedra en Naturaleza = 1, Piedra en Dulces = 50, Diamante en Dulces = 20.000,
Legendario en Dulces = 500.000.

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
| `src/ServerScriptService/Minerals.lua` | ServerScriptService | ModuleScript `Minerals` |
| `src/ServerScriptService/MiningService.server.lua` | ServerScriptService | Script `MiningService` |
| `src/ServerScriptService/ZonesSetup.server.lua` | ServerScriptService | Script opcional (5 plataformas de prueba) |
| `src/StarterPlayer/StarterPlayerScripts/PickaxeClient.client.lua` | StarterPlayerScripts | LocalScript `PickaxeClient` |

`MiningService`, `PickaxeTool`, `MoneyPopup` y `Minerals` deben quedar hermanos dentro de
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
- **Minerales**: hacen falta `HITS_PER_MINERAL` picazos (3) para sacar un mineral. Los
  golpes intermedios hacen chispas y agujero pero no dan dinero ni cartel.
- **Zona y punto de impacto**: se tira un raycast hacia abajo a `SWING.HIT_OFFSET` studs
  **delante del personaje**, ahi es donde cae el pico. Ese punto decide la zona, las chispas
  y el agujero. El cursor no se usa. Si delante no hay zona valida (un borde, un objeto
  encima...), se cobra la zona que esta pisando.
- **Agujero**: cada picazo deja una marca oscura pegada a la superficie que desaparece a los
  2 segundos (`HOLE.LIFETIME`).
- **Sincronizado con el impacto**: el popup, las chispas y el agujero salen cuando la punta
  toca el suelo, no al hacer click. El retardo se calcula con `SWING.RAISE_TIME +
  SWING.STRIKE_TIME`, asi que sigue cuadrando si cambias las duraciones.
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

**Recompensas y ritmo**: `MINERALS` (probabilidad, dinero base y color de cada mineral),
`ZONE_MULTIPLIERS`, `SWING_COOLDOWN` (0.75 s), `HITS_PER_MINERAL` (3 golpes por mineral),
`GROUND_CHECK_DISTANCE`, `DEBUG`.

Para que ganar dinero cueste mas o menos, lo que hay que tocar es `HITS_PER_MINERAL` y
`SWING_COOLDOWN`, no las probabilidades: asi las rarezas siguen siendo las de la tabla.

Para anadir un mineral basta con meter otra entrada en `MINERALS`: el sorteo usa la suma
real de las probabilidades, asi que no hay que recalcular nada para que sigan cuadrando.

**El pico** (`PICKAXE`):

| Campo | Para que sirve |
| --- | --- |
| `HANDLE_SIZE` | Tamano del mango. El largo va en Z |
| `HEAD_SIZE` | Las dos puntas van sobre el eje Y: `(grosor X, largo Y, grosor Z)` |
| `HEAD_COLOR` | Color de la cabeza |
| `HEAD_ANGLE` | `0` = cabeza recta en T. Mas alto = puntas echadas hacia atras |
| `GRIP_OFFSET` | Donde agarra la mano el mango (Z positivo = mas atras) |
| `GRIP_ROTATION` | Rotacion del agarre en grados, si queda raro en la mano |
| `REST_ANGLE` | Inclinacion en reposo. `0` = pico recto, mango horizontal |

**El picazo** (`SWING`):

| Campo | Para que sirve |
| --- | --- |
| `START_ANGLE` | Angulo del amago antes de golpear (`-105` = algo por detras de la vertical) |
| `MAX_ANGLE` | Angulo final del golpe (`95` = pasa un poco de la vertical) |
| `HEAD_REACH` | Studs desde el agarre hasta la punta (define el angulo del golpe) |
| `RAISE_TIME`, `STRIKE_TIME`, `HOLD_TIME`, `RETURN_TIME` | Duraciones de cada fase |
| `AXIS_SIGN` | Ponlo en `-1` si el pico gira al lado contrario |
| `HIT_OFFSET` | Studs delante del jugador donde cae la punta (chispas y agujero) |

**El agujero** (`HOLE`): marca que queda donde se pico y desaparece a los `LIFETIME`
segundos (2 por defecto). **Se pinta del color del mineral que ha salido**, asi se
identifica mirando el suelo; con el legendario cicla colores (`RAINBOW_SPEED`). Se ajusta
con `SIZE` (diametro), `DEPTH`, `DARKEN` (cuanto se oscurece el color del mineral) y
`USE_MINERAL_COLOR` (ponlo en `false` para que siempre sea `COLOR`). Se crea con
`CanQuery = false` para que no interfiera con los raycast de las zonas.

**El popup** (`POPUP`):

| Campo | Para que sirve |
| --- | --- |
| `IMAGE_ID` | Tu icono: `"rbxassetid://..."` (o solo el numero). Vacio = circulo |
| `ALWAYS_SHOW_CIRCLE` | `true` dibuja el circulo detras de tu imagen, para depurar |
| `IMAGE_COLOR` | Tinte de la imagen. Blanco = se ve con sus colores originales |
| `CIRCLE_COLOR` | Color del circulo que sale cuando no hay imagen |
| `TEXT_FORMAT` | Texto de abajo. `%s` es la cantidad formateada. Ej: `"+%s$"` |
| `SHOW_MINERAL_NAME` | `true` escribe tambien el nombre del mineral |
| `USE_MINERAL_COLOR` | `false` por defecto: el color del mineral va en el agujero, no aqui |
| `TEXT_COLOR`, `TEXT_STROKE_COLOR`, `FONT` | Estilo del texto |
| `WIDTH`, `HEIGHT`, `IMAGE_RATIO` | Tamano del cartel en studs y cuanto ocupa la imagen |
| `IMAGE_SCALE` | Escala fina de la imagen dentro de su hueco (`1` = a tope) |
| `MIN_RADIUS`, `MAX_RADIUS`, `MIN_HEIGHT`, `MAX_HEIGHT` | Zona random alrededor del jugador |
| `RISE_HEIGHT`, `DURATION` | Cuanto sube y cuanto dura antes de desaparecer |
| `ALWAYS_ON_TOP`, `MAX_DISTANCE` | Si se ve atravesando paredes y desde cuan lejos |

El money no se guarda entre sesiones a proposito. Para eso hay que agregar `DataStoreService`
leyendo/escribiendo `player.leaderstats.money` en `PlayerAdded` / `PlayerRemoving` + `BindToClose`.
