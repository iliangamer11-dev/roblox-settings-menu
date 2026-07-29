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
| Aparición de globos | `BalloonConfig.Spawning.Enabled = true` + `BalloonService:_spawnLoop` |
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
