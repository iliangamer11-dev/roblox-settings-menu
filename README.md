# roblox-settings-menu


## Sistema de mineria: Pickaxe + variable money

Herramienta **Pickaxe** con animacion de picazo al click izquierdo. Cada golpe saca un
**mineral** al azar y suma a la variable **money**:

```
dinero = dinero base del mineral x multiplicador de la zona
```

**Minerales** (`MiningConfig.MINERALS`):

| Mineral | En el cartel | Probabilidad | 1 cada N golpes | Base | Color |
| --- | --- | --- | --- | --- | --- |
| Piedra | Stone | 70 % | 1 | 1 | gris |
| Carbon | Coal | 18 % | 6 | 2 | negro |
| Cobre | Copper | 7 % | 14 | 4 | marron |
| Hierro | Iron | 3 % | 33 | 8 | gris claro |
| Oro | Gold | 1,4 % | 71 | 20 | dorado |
| Zafiro | Sapphire | 0,4 % | 250 | 40 | azul |
| Amatista | Amethyst | 0,15 % | 667 | 75 | morado |
| Diamante | Diamond | 0,04 % | 2.500 | 150 | cian |
| Esmeralda | Emerald | 0,008 % | 12.500 | 400 | verde |
| Legendario | Legendary | 0,002 % | 50.000 | 2.500 | arcoiris (cambia de color) |

El color se usa en el agujero que queda en el suelo y en el nombre del mineral del cartel.

**Zonas** (`MiningConfig.ZONE_MULTIPLIERS`):

| Zona (nombre de la Part) | Multiplicador |
| --- | --- |
| Naturaleza | x1 |
| Desierto | x5 |
| Mina | x10 |
| Luna | x25 |
| Dulces | x50 |

Ejemplos: Piedra en Naturaleza = 1, Piedra en Dulces = 50, Diamante en Dulces = 7.500,
Legendario en Dulces = 125.000.

Con `SWING_COOLDOWN = 0.75` (80 golpes/min) la ganancia media es de unos 182/min en
Naturaleza y 9.098/min en Dulces. Para subir o bajar todo de golpe, lo mas limpio es
tocar los `ZONE_MULTIPLIERS` o el cooldown.

Las zonas pueden ser una `Part` sola o un `Model`/`Folder` con ese nombre (el script
sube por la jerarquia buscando el nombre), y pueden estar en cualquier parte de Workspace.

## Paredes de pago (Pared1..Pared4)

Al acercarse a una part llamada `Pared1`, `Pared2`, `Pared3` o `Pared4` sale un boton
(`ProximityPrompt`, se activa con **E**) para comprar el acceso. Al pagarlo, **la pared
desaparece solo para ese jugador**: los demas siguen viendo la suya.

| Pared | Precio | Texto del boton |
| --- | --- | --- |
| Pared1 | 100 | `Buy for $100` / `Desert Zone` |
| Pared2 | 1.000 | `Buy for $1.000` / `Mine Zone` |
| Pared3 | 5.000 | `Buy for $5.000` / `Moon Zone` |
| Pared4 | 10.000 | `Buy for $10.000` / `Candy Zone` |

Si no llega el dinero, el boton muestra un momento `Need $X more`. Todos los textos estan
en ingles y se cambian en `MiningConfig.WALL_PROMPT`; los precios y los titulos, en
`MiningConfig.WALLS`.

Como funciona por dentro: el servidor (`WallShop`) cobra y guarda quien ha comprado que
pared, y avisa solo a ese jugador; su cliente (`WallShopClient`) pone esas partes
invisibles y sin colision. La compra dura la sesion: al salir y volver a entrar hay que
comprarla otra vez (haria falta DataStore para guardarla).

### Opcion A: un solo script (copiar y pegar)

La mas simple, no necesita Rojo ni ModuleScripts:

1. `ServerScriptService` > Insert Object > **Script**
2. Pega el contenido de [`standalone/PickaxeAllInOne.server.lua`](standalone/PickaxeAllInOne.server.lua)
3. Play

Esta version **no** incluye las paredes de pago ni los agujeros privados: las dos cosas
necesitan LocalScripts, asi que estan solo en la version modular.

### Opcion B: version modular con Rojo

El mapeo ya esta en `default.project.json`:

```bash
rojo serve   # y conecta el plugin de Rojo desde Studio
```

| Archivo | Destino en Studio | Tipo |
| --- | --- | --- |
| `src/ReplicatedStorage/MiningConfig.lua` | ReplicatedStorage | ModuleScript `MiningConfig` |
| `src/ReplicatedStorage/Format.lua` | ReplicatedStorage | ModuleScript `Format` |
| `src/ReplicatedStorage/ClientSettings.lua` | ReplicatedStorage | ModuleScript `ClientSettings` |
| `src/ReplicatedStorage/UiTheme.lua` | ReplicatedStorage | ModuleScript `UiTheme` |
| `src/ServerScriptService/PickaxeTool.lua` | ServerScriptService | ModuleScript `PickaxeTool` |
| `src/ServerScriptService/MoneyPopup.lua` | ServerScriptService | ModuleScript `MoneyPopup` |
| `src/ServerScriptService/Minerals.lua` | ServerScriptService | ModuleScript `Minerals` |
| `src/ServerScriptService/MiningService.server.lua` | ServerScriptService | Script `MiningService` |
| `src/ServerScriptService/LevelService.lua` | ServerScriptService | ModuleScript `LevelService` |
| `src/ServerScriptService/Nameplate.server.lua` | ServerScriptService | Script `Nameplate` |
| `src/ServerScriptService/Passes.lua` | ServerScriptService | ModuleScript `Passes` |
| `src/ServerScriptService/Tags.server.lua` | ServerScriptService | Script `Tags` |
| `src/ServerScriptService/WallShop.server.lua` | ServerScriptService | Script `WallShop` |
| `src/ServerScriptService/ZonesSetup.server.lua` | ServerScriptService | Script opcional (5 plataformas de prueba) |
| `src/StarterPlayer/StarterPlayerScripts/PickaxeClient.client.lua` | StarterPlayerScripts | LocalScript `PickaxeClient` |
| `src/StarterPlayer/StarterPlayerScripts/HoleClient.client.lua` | StarterPlayerScripts | LocalScript `HoleClient` |
| `src/StarterPlayer/StarterPlayerScripts/WallShopClient.client.lua` | StarterPlayerScripts | LocalScript `WallShopClient` |
| `src/StarterPlayer/StarterPlayerScripts/LevelBar.client.lua` | StarterPlayerScripts | LocalScript `LevelBar` |
| `src/StarterPlayer/StarterPlayerScripts/SettingsMenu.client.lua` | StarterPlayerScripts | LocalScript `SettingsMenu` |
| `src/StarterPlayer/StarterPlayerScripts/MoneyHud.client.lua` | StarterPlayerScripts | LocalScript `MoneyHud` |
| `src/StarterPlayer/StarterPlayerScripts/ShopMenu.client.lua` | StarterPlayerScripts | LocalScript `ShopMenu` |
| `src/StarterPlayer/StarterPlayerScripts/AutoSwingButton.client.lua` | StarterPlayerScripts | LocalScript `AutoSwingButton` |
| `src/StarterPlayer/StarterPlayerScripts/TagsMenu.client.lua` | StarterPlayerScripts | LocalScript `TagsMenu` |

`MiningService`, `PickaxeTool`, `MoneyPopup`, `Minerals`, `LevelService` y `WallShop` deben
quedar hermanos dentro de `ServerScriptService`.

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
- **Minerales**: cada picazo saca un mineral (`HITS_PER_MINERAL = 1`), asi que el cartel
  sale siempre. Subiendo ese numero hacen falta varios golpes por mineral.
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

## Barra de nivel

Barra en la parte **de abajo, centrada**: ocupa el 34 % del ancho de la pantalla y
74 px de alto (`LEVEL_BAR.SIZE`, con el ancho en escala para que se vea igual de grande en
cualquier resolucion). El progreso en **verde**, lo que falta en **blanco**, `Level X`
dentro a la izquierda y los puntos (`83 / 116`) dentro a la derecha. Texto y cuadro con
contorno negro. Se dibuja por codigo, no hay que montar ninguna GUI.

Al subir de nivel aparece **`LEVEL UP!`** encima de la barra (sube y se desvanece) y suena
el aviso, que solo oye ese jugador. Se ajusta en `MiningConfig.LEVEL_UP`: `TEXT_FORMAT`
(si le pones un `%d` se sustituye por el nivel nuevo), `SOUND_ID`, `SOUND_VOLUME`,
`DURATION` y `RISE`. La subida se detecta comparando el atributo `level`, sin RemoteEvents.

- Los puntos se ganan al picar y no se gastan, asi que comprar paredes no baja el nivel.
- Por defecto (`XP_FROM_BASE_VALUE = true`) los puntos salen del valor **base** del mineral,
  sin el multiplicador de zona. Si se contase el dinero final, en Dulces (x50) se subiria
  de nivel 50 veces mas rapido que en Naturaleza. Con esto se sube igual en todas las
  zonas: unos 182 puntos/min picando sin parar (nivel 10 en ~9 min, nivel 15 en ~26 min).
- Cada nivel pide `BASE_XP * GROWTH^(nivel-1)`: con los valores por defecto, 100 puntos
  para el nivel 2 y un 15 % mas en cada nivel. `MAX_LEVEL = 0` es sin limite.
- `LevelService` publica `level`, `xp` y `xpNeeded` como atributos del jugador, que se
  replican solos: la barra no necesita RemoteEvents. Desde otros scripts se leen con
  `player:GetAttribute("level")`.
- El aspecto se ajusta en `MiningConfig.LEVEL_BAR` (tamano, posicion, colores, fuente,
  grosor de los contornos, formato de los textos).

## Menu de ajustes

Boton **en el centro de la pantalla** con un icono y `Settings` debajo, y justo **encima el
cartel del dinero**. Al pulsar el icono se abre el panel. Mismo estilo en todo
(`MiningConfig.UI_THEME`, montado con `UiTheme`): gris con opacidad, contorno blanco muy
fino por dentro, contorno negro por fuera y esquinas redondeadas.

Todo va **a la izquierda de la pantalla**, centrado en vertical:

```
   ┌──────────────────────┐
   │ [icono]       $1.250 │   <- MoneyHud, ancho
   └──────────────────────┘
   ┌──────┐  ┌──────┐
   │icono │  │icono │          <- SettingsMenu y ShopMenu
   └──────┘  └──────┘
   SETTINGS    SHOP             <- textos debajo de los cuadros
```

El cartel del dinero calcula su posicion desde la del boton de ajustes, asi que si mueves
`SETTINGS_BUTTON.POSITION` el dinero lo sigue solo. La cantidad se lee del atributo `money`
y se actualiza en cada picazo y en cada compra. Se ajusta en `MiningConfig.MONEY_PANEL`
(tamano, separacion, `ICON_ID` de la moneda, `ICON_SIZE` y `PREFIX`).

## Tienda

Boton `SHOP` al lado del de ajustes. Abre un panel de 820x620 con el mismo estilo: cabecera
fija con icono, titulo `Shop` y boton rojo de cerrar, y debajo un `ScrollingFrame` con el
separador `Gamepasses` y la cuadricula (3 por fila, tiles de 230x216). Como todo el
contenido va dentro del scroll, se pueden anadir todos los gamepasses que quieras: los que
no entren se ven bajando. El cartel grande de arriba viene desactivado
(`BANNER.ENABLED = false`); activalo si quieres poner una imagen promocional.

Cada gamepass lleva su icono, el nombre, **que hace en ingles** (`DESC`) y abajo un **boton
verde con el precio**. El precio se pinta al momento con el de la config y se corrige con el
real de Roblox (`GetProductInfo`); si ya lo tiene, el boton pasa a `OWNED` en gris
(`UserOwnsGamePassAsync`). Al pulsarlo se abre la compra (`PromptGamePassPurchase`) y al
terminar el boton se marca solo.

Con `ID = 0` el boton sale desactivado, para poder ver el diseno antes de tener los
gamepasses creados. `EXTRA_SCROLL` deja hueco de sobra al final para poder seguir bajando.

### Que hace cada gamepass

Los efectos estan implementados en el servidor (`Passes`), que comprueba
`UserOwnsGamePassAsync` al entrar y tambien escucha las compras para aplicarlas al momento,
sin reconectar. Los ids viven en `MiningConfig.PASSES` y los valores en `PASS_EFFECTS`.

| Pase | Efecto real |
| --- | --- |
| X2 Money | `MONEY_MULTIPLIER = 2`: el doble de dinero por mineral |
| Fast Pickaxe | `COOLDOWN_MULTIPLIER = 0.35`: cooldown de 0.75 s a 0.26 s (2.9x mas golpes) |
| Lucky Ores | `LUCK_MULTIPLIER = 5`: Gold de 1.4 % a 6.5 %, Diamond de 0.04 % a 0.185 % |
| Auto Swing | Pica solo mientras estas sobre una zona, con **boton arriba en el centro** para encenderlo o apagarlo |
| All Zones | Abre las 4 paredes sin pagarlas |
| VIP | Incluye X2 Money y Fast Pickaxe (`VIP_INCLUDES`), pone `VIP` con degradado naranja-amarillo sobre el personaje y `[VIP]` delante del nombre |

Notas de como esta hecho:

- El cooldown real se publica en el atributo `swingCooldown`, porque el cliente tambien
  frena los clics y con Fast Pickaxe tenia que saber el nuevo ritmo.
- El Auto Swing llama a la **misma** funcion que el clic (`performSwing`), que ya valida
  pico equipado, cooldown y zona: asi no puede dar mas dinero que picando a mano.
- Lucky Ores multiplica el peso de los raros y deja los comunes igual, asi que los
  porcentajes se recalculan solos sin tener que reescribir la tabla.
- El boton de Auto Swing solo manda "encendido/apagado" al servidor. Aunque alguien falsee
  ese remote, lo unico que consigue es activar su propio auto swing, y solo si tiene el pase.
- **La lista de jugadores de Roblox no permite cambiar la columna del nombre**, asi que el
  `[VIP]` va en su propia columna (`LEADERSTATS_TAG_NAME`, por defecto `Tag`) a la izquierda
  del dinero. Donde si aparece delante del nombre es en la placa sobre el personaje.
  Para tener literalmente `[VIP] nombre` en la lista habria que sustituirla por una GUI
  propia.

### Poner tus imagenes

Los dos iconos se cambian en `src/ReplicatedStorage/MiningConfig.lua`:

```lua
MiningConfig.SETTINGS_BUTTON.ICON_ID = "rbxassetid://1234567890" -- icono de ajustes
MiningConfig.MONEY_PANEL.ICON_ID = "rbxassetid://1234567890"     -- icono de la moneda
```

Para conseguir ese numero: en Studio, `View` > `Asset Manager` > `Images` > boton de
importar, eliges el PNG, y cuando se apruebe haces clic derecho sobre el > copiar el id.
Vale pegar solo el numero (`"1234567890"`), el codigo le anade el prefijo solo.

| Opcion | Que hace |
| --- | --- |
| `Music` | Bajar, subir y silenciar la musica (`rbxassetid://1848354536`) |
| `Level bar` | Muestra u oculta la barra de nivel |
| `Money popups` | Muestra u oculta los carteles de "+20 Diamond" |
| `Mining holes` | Muestra u oculta las marcas del pico en el suelo |
| `Player nameplates` | Muestra u oculta los nombres y niveles sobre los personajes |

**Tu icono**: `SETTINGS_BUTTON.ICON_ID = "rbxassetid://..."` (vale poner solo el numero). El
texto de debajo se cambia en `SETTINGS_BUTTON.LABEL` y el resto de textos, todos en ingles,
en `SETTINGS_PANEL`.

Son **ajustes locales**: cada jugador los cambia solo para el, no se mandan al servidor.
El estado vive en `ClientSettings`, un ModuleScript que comparten todos los LocalScripts del
mismo cliente, asi que no hace falta ningun RemoteEvent. Para anadir opciones basta con
meter una clave en `ClientSettings.Defaults` y una fila en `SETTINGS_PANEL.ROWS`.

Los carteles de dinero y las placas de nombre los crea el servidor, asi que ocultarlos se
hace poniendo `Enabled = false` en este cliente: los demas siguen viendolos.

Los ajustes **no se guardan al salir** (harian falta DataStore o atributos guardados).

## Tags

Etiqueta sobre el personaje, con degradado propio, que se desbloquea con el progreso:

| Tag | Como se consigue | Degradado |
| --- | --- | --- |
| Noob | lo tiene todo el mundo | marron claro -> marron oscuro |
| Principiante | comprar `Pared2` | azul claro -> azul oscuro |
| Pro | comprar `Pared4` | naranja -> rojo |
| VIP | gamepass VIP | naranja -> amarillo |

Boton **TAGS** en la fila del HUD: abre un panel con todos, el equipado marcado como
`EQUIPPED`, los que faltan como `LOCKED` con su requisito (`Buy Mine Zone`), y se equipa el
que quieras. Al desbloquear uno nuevo se equipa solo.

Como funciona por dentro:

- `Tags.server.lua` decide que tags tiene cada jugador y publica dos atributos:
  `tag` (el equipado) y `tagsUnlocked` (los que tiene, separados por comas). El menu solo
  los lee, y al pedir un cambio el **servidor comprueba** que lo tenga desbloqueado.
- `WallShop` publica `ownsPared2`, `ownsPared4`... como atributos del jugador. Asi `Tags`
  sabe que paredes tiene sin depender del script de las paredes.
- El tag equipado tambien sale en la columna `Tag` de la lista de jugadores, y con VIP el
  nombre de la placa pasa a `[VIP] Nombre`.
- Anadir un tag nuevo es meter una entrada en `MiningConfig.TAGS` con su `WALL` o `PASS`
  y sus dos colores: el menu y la placa se actualizan solos.

## Placa sobre el personaje

Sobre la cabeza de cada jugador: el **nombre en blanco con contorno negro** y debajo su
**`Level X` con degradado de azul claro a azul oscuro** (`UIGradient` girado 90 grados) y
contorno negro.

- La crea el servidor, asi que todos los jugadores ven la placa de todos.
- El nivel se actualiza solo, leyendo el atributo `level` que publica `LevelService`.
- `HIDE_DEFAULT_NAME = true` apaga el nombre que dibuja Roblox
  (`HumanoidDisplayDistanceType.None`) para que no salga duplicado.
- Ajustes en `MiningConfig.NAMEPLATE`: tamano, altura sobre la cabeza (`OFFSET`), distancia
  a la que se ve, fuente, colores del degradado, grosor del contorno y `USE_DISPLAY_NAME`
  (nombre para mostrar o nombre de usuario).

## El pico va siempre en la mano

`ALWAYS_EQUIPPED = true`: el pico se equipa al aparecer y, si algo lo desequipa (la tecla
del hotbar, backspace, otro script), el servidor lo vuelve a poner en la mano al instante.
`HIDE_BACKPACK_GUI = true` oculta la mochila de Roblox, ya que no hay nada que elegir.

### Scripts extra

- [`standalone/SetHojas1Morado.server.lua`](standalone/SetHojas1Morado.server.lua):
  pinta de morado todo lo que se llame `Hojas1`.
- [`standalone/Hojas1CambiaColor.server.lua`](standalone/Hojas1CambiaColor.server.lua):
  hace que `Hojas1` vaya cambiando de color en bucle con TweenService.

### Ajustes

Todo esta en `src/ReplicatedStorage/MiningConfig.lua` (o arriba de
`standalone/PickaxeAllInOne.server.lua` si usas la version de un archivo).

**Recompensas y ritmo**: `MINERALS` (probabilidad, dinero base y color de cada mineral),
`ZONE_MULTIPLIERS`, `SWING_COOLDOWN` (0.75 s), `HITS_PER_MINERAL` (1 = cada golpe da
mineral), `GROUND_CHECK_DISTANCE`, `DEBUG`.

Para que ganar dinero cueste mas o menos, lo mejor es tocar `SWING_COOLDOWN` y los
`ZONE_MULTIPLIERS`, no las probabilidades: asi las rarezas siguen siendo las de la tabla.

Para anadir un mineral basta con meter otra entrada en `MINERALS`: el sorteo usa la suma
real de las probabilidades, asi que no hay que recalcular nada para que sigan cuadrando.

**El pico** (`PICKAXE`):

| Campo | Para que sirve |
| --- | --- |
| `HANDLE_SIZE` | Tamano del mango. El largo va en Z |
| `HEAD_SIZE` | Tamano de cada trozo de punta: `(grosor X, largo Y, grosor Z)` |
| `HEAD_COLOR` | Color de la cabeza |
| `HEAD_SEGMENTS` | Trozos por punta. Mas trozos = curva mas suave |
| `HEAD_TAPER` | Cuanto se encoge cada trozo respecto al anterior (afila la punta) |
| `HEAD_START_ANGLE`, `HEAD_CURVE` | Inclinacion inicial y curvatura hacia atras |
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

**El agujero** (`HOLE`): marca que queda donde se pico, dura `LIFETIME` segundos (3) y se
va **desvaneciendo poco a poco** durante `FADE_TIME` (3) en vez de desaparecer de golpe.
**Se pinta del color del mineral que ha salido**, asi se identifica mirando el suelo; con
el legendario cicla colores (`RAINBOW_SPEED`). Lo dibuja el cliente del jugador que ha
picado (`HoleClient`), asi que **cada jugador ve solo sus propios agujeros**. Se ajusta con `SIZE` (diametro), `DEPTH`,
`DARKEN` (cuanto se oscurece el color del mineral) y `USE_MINERAL_COLOR` (ponlo en `false`
para que siempre sea `COLOR`). Se crea con `CanQuery = false` para que no interfiera con
los raycast de las zonas.

**El popup** (`POPUP`):

| Campo | Para que sirve |
| --- | --- |
| `IMAGE_ID` | Tu icono: `"rbxassetid://..."` (o solo el numero). Vacio = circulo |
| `ALWAYS_SHOW_CIRCLE` | `true` dibuja el circulo detras de tu imagen, para depurar |
| `IMAGE_COLOR` | Tinte de la imagen. Blanco = se ve con sus colores originales |
| `CIRCLE_COLOR` | Color del circulo que sale cuando no hay imagen |
| `TEXT_FORMAT` | Texto de abajo. `%s` es la cantidad formateada. Ej: `"+%s$"` |
| `SHOW_MINERAL_NAME` | Nombre del mineral en ingles debajo del dinero, con su color |
| `NAME_RATIO` | Cuanto del hueco de texto se lleva el nombre (el resto, el dinero) |
| `USE_MINERAL_COLOR` | `false` por defecto: el color del mineral va en el agujero, no aqui |
| `TEXT_COLOR`, `TEXT_STROKE_COLOR`, `FONT` | Estilo del texto |
| `WIDTH`, `HEIGHT`, `IMAGE_RATIO` | Tamano del cartel en studs y cuanto ocupa la imagen |
| `IMAGE_SCALE` | Escala fina de la imagen dentro de su hueco (`1` = a tope) |
| `MIN_RADIUS`, `MAX_RADIUS`, `MIN_HEIGHT`, `MAX_HEIGHT` | Zona random alrededor del jugador |
| `RISE_HEIGHT`, `DURATION` | Cuanto sube y cuanto dura antes de desaparecer |
| `ALWAYS_ON_TOP`, `MAX_DISTANCE` | Si se ve atravesando paredes y desde cuan lejos |

El money no se guarda entre sesiones a proposito. Para eso hay que agregar `DataStoreService`
leyendo/escribiendo `player.leaderstats.money` en `PlayerAdded` / `PlayerRemoving` + `BindToClose`.
