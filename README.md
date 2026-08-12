```text
demo_engine/                               │   │   └── vk_debug.c
├── build/                                 │   ├── gpu/
│   ├── build.lua                          │   │   ├── vk_draw.c
│   ├── check_build_dependencies.lua       │   │   ├── vk_record.c
│   ├── export_c_hdr.lua                   │   │   └── vk_render_loop.c
│   ├── export_glsl.lua                    │   ├── tenant/
│   ├── net_codegen.lua                    │   │   └── vk_tenant_alloc.c
│   ├── task_c_objects.lua                 │   └── transfer/
│   ├── task_headless.lua                  │       ├── vk_transfer_api.c
│   ├── task_invariants.lua                │       └── vk_transfer_loop.c
│   └── task_shaders.lua                   ├── runtime/
├── generated/                             │   ├── boot/
│   ├── registry.glsl                      │   │   ├── core_abi.lua
│   ├── ssot_render.h                      │   │   ├── engine_api.lua
│   └── ssot_types.h                       │   │   ├── main.lua
├── host/                                  │   │   ├── path_weaver.lua
│   ├── boot/                              │   │   ├── weaver_boot.lua
│   │   ├── lifecycle.c                    │   │   └── window_api.lua
│   │   ├── main.c                         │   ├── presentation/
│   │   └── main_headless.c                │   │   ├── graphics/
│   ├── ipc/                               │   │   │   ├── compute_pipeline.lua
│   │   ├── mailbox.c                      │   │   │   ├── graphics_pipeline.lua
│   │   ├── ring_stream.c                  │   │   │   ├── renderer.lua
│   │   └── sys_sync.c                     │   │   │   └── sequence.lua
│   ├── lua/                               │   │   └── translation/
│   │   └── lua_vm.c                       │   │       ├── pipeline_manifest.lua
│   ├── runtime/                           │   │       └── render_queue.lua
│   │   └── main_loop.c                    │   ├── services/
│   ├── state/                             │   │   ├── gpu/
│   │   ├── state_globals.c                │   │   │   ├── descriptors.lua
│   │   └── state_types.c                  │   │   │   ├── registry_vk.lua
│   ├── tenant/                            │   │   │   ├── swapchain.lua
│   │   ├── tenant_callbacks_key.c         │   │   │   ├── vulkan_core.lua
│   │   ├── tenant_callbacks_mouse.c       │   │   │   └── weaver_vram.lua
│   │   ├── tenant_callbacks_state.c       │   │   ├── math/
│   │   ├── tenant_input.c                 │   │   │   ├── fixed_math.lua
│   │   └── tenant_sys.c                   │   │   │   └── vmath.lua
│   └── threading/                         │   │   ├── memory/
│       ├── thread_lifecycle.c             │   │   │   └── memory.lua
│       └── thread_pool.c                  │   │   └── tenants/
├── network/                               │   │       ├── tenant_lifecycle.lua
│   ├── lockstep/                          │   │       └── tenant_registry.lua
│   │   ├── fsm_core.lua                   │   ├── shutdown/
│   │   ├── fsm_pacing.lua                 │   │   └── teardown.lua
│   │   ├── fsm_simulator.lua              │   └── simulation/
│   │   ├── history_buffer.lua             │       ├── camera.lua
│   │   └── wire_codec.lua                 │       ├── game_state.lua
│   ├── protocol/                          │       └── raycast.lua
│   │   ├── config_net.lua                 ├── shaders/
│   │   ├── dkjson.lua                     │   ├── render.frag
│   │   ├── json_util.lua                  │   ├── render.vert
│   │   ├── net_01_constants.h             │   └── shared.glsl
│   │   ├── net_02_wire.h                  ├── ssot/
│   │   ├── net_03_memory.h                │   ├── config_gfx.lua
│   │   ├── net_04_state.h                 │   ├── config_sim.lua
│   │   ├── net_05_api.h                   │   ├── ctx_types.lua
│   │   ├── shared_structs.h               │   ├── registry.glsl
│   │   └── structs.lua                    │   ├── type_math.lua
│   ├── session/                           │   └── type_render.lua
│   │   ├── http_client.lua                └── worlds/
│   │   ├── ice_handshake.lua                  ├── chess/
│   │   ├── matchmaker.lua                     │   └── domain.lua
│   │   ├── net_utils.lua                      ├── isometric/
│   │   ├── netcode.lua                        │   └── domain.lua
│   │   └── sys_time.lua                       ├── luachess/
│   └── transport/                             │   ├── game/
│       ├── net_pump.lua                       │   │   ├── attack.lua
│       ├── network.lua                        │   │   ├── logic.lua
│       ├── vx_net_internal.h                  │   │   ├── move.lua
│       ├── vx_net_io.c                        │   │   ├── standard.lua
│       ├── vx_net_state.c                     │   │   └── turn.lua
│       └── vx_net_stun.c                      │   └── global.lua
├── render/                                    └── router_plugin.lua
│   ├── debug/
```

## 💻 1. Native Launchers (`launch.bat` & `launch.sh`)
1. **`launch.bat`**: The native Windows batch script (manages `.exe` binaries).
2. **`launch.sh`**: The native Linux bash script (manages `.elf` binaries).
3. **`launch.lua`**: An interactive, platform-agnostic CLI wrapper that provides command history, auto-completion, and automatic Lobby ID parsing.

### Command Reference

| Command | Arguments | Description |
| --- | --- | --- |
| `swarm` | `[graphical_count]` `[bot_count]` | Spins up a local cluster. Automatically starts a Host, waits for a Lobby ID, and injects the specified clients and bots. Max 8 players total. |
| `lab` | None | Developer shortcut to spin up a pre-configured swarm. *(Note: Windows spawns 3 nodes total; Linux spawns 8 nodes total).* |
| `host` | `[size]` | Boots a standalone Graphical Host Node. The max lobby `size` is 8. |
| `client` | `[lobby_id]` | Boots a single Graphical Client and connects it to the specified `lobby_id`. |
| `attach` | `[bot_count]` `[lobby_id]` | Injects the specified number of headless bots into an active lobby. |
| `clean` | None | Force-kills all active `boot` and `boot_headless` processes. Use this to release network sockets. |

### Examples

```bash
# Start a custom swarm with 2 graphical clients and 3 headless bots
./launch.sh swarm 2 3

# Kill all dangling processes if a crash occurs
launch.bat clean

# Manually host a 6-player lobby, then attach 5 bots to it
./launch.sh host 6
./launch.sh attach 5 <LOBBY_ID>

```

## 🎮 2. Interactive CLI (`launch.lua`)

**To start:** `lua launch.lua`

* **Auto Lobby-ID Extraction:** When you run `host`, `lab`, or `swarm`, the CLI actively monitors the engine logs and prints the `LOBBY_ID` directly to your screen in a prominent box. No need to dig through log files.
* **Smart Tab Completion:**
* Press `TAB` to auto-complete commands (e.g., typing `sw` + `TAB` yields `swarm `).
* If you need to enter a Lobby ID, typing the first few characters and pressing `TAB` will automatically grab the latest active ID from your logs.


* **Command History:** Use the `UP` and `DOWN` arrow keys to cycle through previous commands.
* **Orphan Management:** Validates and cleans up dangling processes when you exit.

Typing these directly into the `weaver>` prompt will execute CLI-specific tasks:

| Command | Description |
| --- | --- |
| `status` / `orphans` | Scans the system for lingering Weaver nodes without executing a kill command. |
| `exit` / `quit` | Gracefully shuts down the CLI wrapper and performs a final orphan check. |

*(All native launcher commands like `swarm`, `clean`, and `attach` also work perfectly inside the Lua CLI).*

## 📁 System Requirements & Directories

For these scripts to function properly, your project root must contain:

* `bin/`: Containing your compiled engine binaries (`boot` / `boot_headless`).
* `logs/`: An existing directory where the scripts output node logs (e.g., `host.log`, `bot_1.log`).
