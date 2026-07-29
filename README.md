# Balloon Popping Simulator — base del proyecto

Estructura profesional para un simulador de pinchar globos en Roblox.
**Este paso solo monta la arquitectura: todavía no hay mecánicas de juego.**

El proyecto se gestiona con [Rojo](https://rojo.space), así que el código vive en
archivos versionables y se sincroniza con Roblox Studio.

## Puesta en marcha

```bash
rokit install          # instala rojo, stylua y selene
rojo serve             # y conectar el plugin de Rojo desde Studio
```

Alternativa sin plugin: `rojo build -o BalloonSimulator.rbxlx` y abrir el archivo.

## Árbol que se genera en Roblox Studio

```
ReplicatedStorage
├── Shared
│   ├── Config              (ModuleScript agregador, congelado con table.freeze)
│   │   ├── GameConfig      ajustes globales, límites anti-exploit
│   │   ├── DataConfig      DataStore, autosave, bloqueo de sesión
│   │   ├── EconomyConfig   monedas               -> dinero
│   │   ├── BalloonConfig   catálogo y spawn      -> globos
│   │   ├── ToolConfig      catálogo + mejoras    -> Cuchillo / mejoras
│   │   ├── ShopConfig      tiendas               -> tiendas
│   │   ├── LevelConfig     curva de experiencia  -> niveles
│   │   ├── MultiplierConfig                      -> multiplicadores
│   │   ├── PetConfig                             -> mascotas
│   │   ├── QuestConfig                           -> misiones
│   │   └── ZoneConfig                            -> nuevas zonas
│   ├── Types               tipos Luau compartidos (PlayerProfile, etc.)
│   ├── Data
│   │   ├── ProfileTemplate forma canónica del perfil guardado
│   │   └── Migrations      cambios de esquema entre versiones
│   ├── Network
│   │   ├── RemoteDefinitions  fuente única de verdad de todos los remotes
│   │   └── Net                acceso validado + rate limit + pcall
│   ├── Framework
│   │   └── Loader          carga de módulos con ciclo Init/Start
│   └── Util                Signal, TableUtil, Format, Logger, RateLimiter
└── Remotes                 (creado en runtime por RemoteBuilder)
    ├── Events              18 RemoteEvent / RemoteFunction en total
    └── Functions

ServerScriptService
└── Server
    ├── Bootstrap           ÚNICO Script del servidor
    ├── Network/RemoteBuilder
    ├── Data/DataStoreWrapper   reintentos + store simulado en Studio
    └── Services
        ├── DataService         perfiles, autosave, session lock
        ├── ReplicationService  único camino servidor -> cliente
        ├── PlayerService       leaderstats, tiempo jugado, señales
        ├── StatsService        estadísticas del jugador
        ├── CurrencyService     monedero
        ├── UpgradeService      mejoras de herramientas
        ├── ToolService         propiedad y equipamiento de Tools
        ├── LevelService        experiencia y niveles
        ├── MultiplierService   multiplicadores acumulables
        ├── BalloonService      esqueleto: spawn y pinchado
        ├── ShopService         esqueleto: compras
        ├── PetService          esqueleto: mascotas
        ├── QuestService        esqueleto: misiones
        ├── ZoneService         esqueleto: zonas
        └── SettingsService     ajustes persistidos

StarterPlayer.StarterPlayerScripts
└── Client
    ├── Bootstrap            ÚNICO LocalScript del juego
    ├── State/ClientState    copia local del perfil (fuente para la UI)
    └── Controllers
        ├── DataController          remotes de datos -> ClientState
        ├── UIController            registro y apertura de pantallas
        ├── HudController           monedas, nivel, multiplicadores
        ├── InputController         atajos centralizados
        ├── ToolController          esqueleto de la Tool Cuchillo
        ├── BalloonController       esqueleto de efectos de globos
        ├── ShopController          compras / mejoras / equipar
        ├── MultiplierController    resumen de multiplicadores
        ├── ProgressionController   niveles, misiones, mascotas, zonas
        └── NotificationController  cola de avisos

ServerStorage.Assets
├── Balloons                (vacío: modelos de globo)
├── Tools/Cuchillo          Tool placeholder con Handle
├── Pets                    (vacío)
└── Effects                 (vacío)

StarterGui.Interface        (vacío: aquí irán los ScreenGui)

Workspace.World
├── Zones                   modelos de zona
├── Spawners                puntos de aparición
└── Balloons                contenedor en runtime
```

## Decisiones de arquitectura

**Un solo Script y un solo LocalScript.** Todo lo demás son ModuleScripts que
carga `Loader` con dos fases: `Init()` (crear estado, sin dependencias) y
`Start()` (ya se puede llamar a `Loader.Get("OtroServicio")`). El orden lo fija
`Priority`, así que el arranque es determinista y no hay carreras.

**Remotes declarativos.** Se declaran en `RemoteDefinitions` y los crea
`RemoteBuilder` al arrancar. `Net` valida cada nombre contra la definición, así
que un typo falla al instante en lugar de silenciosamente. Los remotes
entrantes llevan rate limit y los handlers van envueltos en `pcall`.

**Un único dueño por dato.** El DataStore solo lo toca `DataService`; las
monedas solo `CurrencyService`; las estadísticas solo `StatsService`; y la
replicación al cliente solo `ReplicationService`. Los demás sistemas piden.

**Datos a prueba de cambios.** Al cargar, el perfil se reconcilia contra
`ProfileTemplate`, de modo que añadir un campo nuevo no rompe a los jugadores
existentes. Para cambios incompatibles se sube `SchemaVersion` y se añade una
migración.

**El cliente nunca decide.** `ClientState` es una copia de lectura para pintar
la interfaz; toda validación (precio, propiedad, distancia, cooldown) se repite
en el servidor.

## Siguientes pasos sugeridos

| Sistema | Dónde tocar |
|---|---|
| ~~Aparición de globos~~ | hecho — ver sección siguiente |
| Pinchar globos | `BalloonService:_onPopRequest` + `ToolController:_onActivated` |
| Tool Cuchillo | modelo en `ServerStorage.Assets.Tools.Cuchillo` |
| Dinero | recompensas en `BalloonService` vía `CurrencyService:Add` |
| Mejoras | balancear `ToolConfig.Tools.Cuchillo.Upgrades` |
| Tiendas | rellenar `ShopConfig.Shops` + `ShopService:_deliver` |
| Niveles | `LevelService:AddExperience` desde el pop + `LevelConfig.LevelRewards` |
| Multiplicadores | `MultiplierService:AddSource` (gamepass, mascotas, pociones) |
| Mascotas | `PetConfig.Pets` + modelo seguidor en `PetService` |
| Misiones | `QuestConfig.Quests` (se auto-enlazan a `StatsService.StatChanged`) |
| Nuevas zonas | modelo en `Workspace.World.Zones` + entrada en `ZoneConfig.Zones` |


---

# Sistema de aparición de globos

## Módulos

```
ServerScriptService.Server
├── Balloons
│   ├── BalloonManager       núcleo: registro, planificador, daño
│   ├── BalloonFactory       construcción, atributos y pooling
│   └── SpawnPointRegistry   descubrimiento y selección de puntos
└── Services
    └── BalloonService       arranca el manager y expone su API
```

`BalloonManager` no depende de ningún servicio: recibe sus contenedores por
parámetro, así que se puede instanciar aislado.

## Contenedores

```
Workspace.World
├── Balloons          globos activos (se replican a los clientes)
└── Spawners          áreas de aparición

ServerStorage
├── Assets.Balloons   modelos opcionales
└── BalloonReserve    instancias recicladas (NO se replican)
```

## Puntos de aparición

**Lo más rápido: coloca una Part y llámala `BalloonSpawn`.** Los globos saldrán
encima, esté donde esté en el `Workspace`.

Un punto de aparición es cualquier `BasePart` que cumpla una de estas tres:

1. Llamarse `BalloonSpawn` (configurable en `Spawning.SpawnPartName`)
2. Estar dentro de `Workspace.World.Spawners`
3. Tener el tag `BalloonSpawn` de CollectionService

Define un **área**, no un punto exacto: la posición final es aleatoria dentro del
volumen de la Part respetando su rotación, así que una sola Part plana y grande
cubre toda una zona. La altura es la cara superior de la Part más un valor
aleatorio entre `FloatHeightMin` y `FloatHeightMax`.

El tope de globos de cada área **se calcula solo** a partir de su superficie y de
`MinSeparation`, con `MaxActivePerSpawnPoint` como mínimo. Así una Part de
200×200 aprovecha su tamaño y una de 4×4 no se apelmaza, sin configurar nada.

Atributos opcionales en la Part:

| Atributo | Tipo | Efecto |
|---|---|---|
| `ZoneId` | string | Zona a la que pertenece (por defecto `Spawn`) |
| `Weight` | number | Peso relativo de aparición (por defecto 1) |
| `MaxActive` | number | Tope propio de globos vivos |
| `BalloonId` | string | Fuerza un tipo concreto de globo |

Se actualiza en caliente: añadir o borrar Parts en Studio se refleja al instante.

Si el mapa no tiene ninguna, se crea una temporal de 160×160 centrada en el
`SpawnLocation` (o en el origen si no hay), para que el sistema no parezca roto en
un Baseplate vacío.

## Tipos de globo

Añadir un tipo es **solo** añadir una entrada en `BalloonConfig.Balloons` y
referenciar su id en `ZoneConfig.Zones[].BalloonIds`. Ningún script cambia.

Vienen 5 de ejemplo: Red, Blue, Green, Purple y Golden (legendario, con
`Lifetime = 90` para que desaparezca si nadie lo pincha).

Si `Model` apunta a un modelo de `ServerStorage.Assets.Balloons` se clona; si no
existe, el globo se genera por código como Part esférica. El sistema funciona sin
ningún asset.

## Atributos de cada globo

Los datos viajan como atributos de la instancia, no como `ValueObject` hijos:
menos instancias que replicar y se leen con `instance:GetAttribute()`. Los
nombres están centralizados en `BalloonConfig.Attributes`.

| Atributo | Contenido |
|---|---|
| `BalloonId` | Identificador único de la instancia |
| `BalloonType` | Id de la definición (`Red`, `Golden`…) |
| `DisplayName` | Nombre visible |
| `Rarity` | Rareza |
| `Reward` | Monedas |
| `RewardExperience` | Experiencia |
| `Health` / `MaxHealth` | Vida actual y máxima |
| `ZoneId` | Zona de origen |

## Optimización

1. **Un solo hilo planificador** para todo el servidor. El coste no crece con el
   número de jugadores, solo con el tope de globos.
2. **Globos compartidos**: 30 jugadores ven los mismos 150 globos, no 4.500.
3. **Pooling**: las instancias se reciclan en `ServerStorage` en vez de
   destruirse. `Instance.new` solo ocurre en el precalentamiento.
4. **Cero replicación manual**: Roblox ya replica la instancia y sus atributos;
   mandar además un RemoteEvent por globo sería tráfico duplicado.
5. **Presupuesto por ciclo** (`SpawnsPerTick`): el trabajo se reparte en el
   tiempo en lugar de crear 150 globos en un frame.
6. **Sin física**: partes ancladas, sin colisión y sin sombra.
7. **Balanceo en el cliente**, con culling por distancia y tope por frame. Coste
   cero para el servidor y sin tráfico de red.
8. **Búsqueda O(1)** de globo por instancia, lista para validar los hits del
   cliente.
9. **Distancias al cuadrado** en los bucles calientes, sin raíces cuadradas.

## Topes (en `BalloonConfig.Spawning`)

| Ajuste | Valor |
|---|---|
| `MaxActive` | 150 globos en el servidor |
| `MaxActivePerZone` | 40 |
| `MaxActivePerSpawnPoint` | 6 como mínimo, más si el área lo permite |
| `Interval` | 0.4 s por ciclo |
| `SpawnsPerTick` | 4 (12 durante el llenado inicial) |
| `MinSeparation` | 4 studs entre globos del mismo punto |
| `PrewarmPerType` | 10 instancias por tipo |

## Preparado para el siguiente paso

`BalloonManager:ApplyDamage(balloonId, cantidad, player)` ya aplica daño,
actualiza el atributo `Health` y emite `BalloonDestroyed` cuando llega a 0. **No
reparte recompensas a propósito**: quien pague será `CurrencyService`, para que el
dinero siga teniendo un único dueño.

El handler `RequestPopBalloon` ya está enganchado en `BalloonService`. Falta
validar distancia y cooldown, y llamar a `ApplyDamage` con la potencia de la Tool.
