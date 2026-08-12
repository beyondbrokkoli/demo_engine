```text
demo_engine/                               │   ├── ask.py
├── bin/                                   │   ├── ask_local.py
│   ├── boot.elf                           │   └── ingest_codebase.py
│   ├── boot.exe                           ├── render/
│   ├── boot_headless.elf                  │   ├── debug/
│   ├── boot_headless.exe                  │   │   └── vk_debug.c
│   ├── glfw3.dll                          │   ├── gpu/
│   ├── libvx_net.so                       │   │   ├── vk_draw.c
│   ├── libwinpthread-1.dll                │   │   ├── vk_record.c
│   ├── lua51.dll                          │   │   └── vk_render_loop.c
│   ├── render_frag.spv                    │   ├── tenant/
│   ├── render_vert.spv                    │   │   └── vk_tenant_alloc.c
│   └── vx_net.dll                         │   └── transfer/
├── build/                                 │       ├── vk_transfer_api.c
│   ├── build.lua                          │       └── vk_transfer_loop.c
│   ├── check_build_dependencies.lua       ├── runtime/
│   ├── export_c_hdr.lua                   │   ├── boot/
│   ├── export_glsl.lua                    │   │   ├── core_abi.lua
│   ├── net_codegen.lua                    │   │   ├── engine_api.lua
│   ├── task_c_objects.lua                 │   │   ├── main.lua
│   ├── task_headless.lua                  │   │   ├── path_weaver.lua
│   ├── task_invariants.lua                │   │   ├── weaver_boot.lua
│   └── task_shaders.lua                   │   │   └── window_api.lua
├── docs/                                  │   ├── presentation/
│   ├── deps_c.md                          │   │   ├── graphics/
│   ├── deps_glsl.md                       │   │   │   ├── compute_pipeline.lua
│   ├── deps_lua.md                        │   │   │   ├── graphics_pipeline.lua
│   ├── repo_ascii.txt                     │   │   │   ├── renderer.lua
│   └── repo_tree.md                       │   │   │   └── sequence.lua
├── generated/                             │   │   └── translation/
│   ├── registry.glsl                      │   │       ├── pipeline_manifest.lua
│   ├── ssot_render.h                      │   │       └── render_queue.lua
│   └── ssot_types.h                       │   ├── services/
├── host/                                  │   │   ├── gpu/
│   ├── boot/                              │   │   │   ├── descriptors.lua
│   │   ├── lifecycle.c                    │   │   │   ├── registry_vk.lua
│   │   ├── main.c                         │   │   │   ├── swapchain.lua
│   │   └── main_headless.c                │   │   │   ├── vulkan_core.lua
│   ├── ipc/                               │   │   │   └── weaver_vram.lua
│   │   ├── mailbox.c                      │   │   ├── math/
│   │   ├── ring_stream.c                  │   │   │   ├── fixed_math.lua
│   │   └── sys_sync.c                     │   │   │   └── vmath.lua
│   ├── lua/                               │   │   ├── memory/
│   │   └── lua_vm.c                       │   │   │   └── memory.lua
│   ├── runtime/                           │   │   └── tenants/
│   │   └── main_loop.c                    │   │       ├── tenant_lifecycle.lua
│   ├── state/                             │   │       └── tenant_registry.lua
│   │   ├── state_globals.c                │   ├── shutdown/
│   │   └── state_types.c                  │   │   └── teardown.lua
│   ├── tenant/                            │   └── simulation/
│   │   ├── tenant_callbacks_key.c         │       ├── camera.lua
│   │   ├── tenant_callbacks_mouse.c       │       ├── game_state.lua
│   │   ├── tenant_callbacks_state.c       │       └── raycast.lua
│   │   ├── tenant_input.c                 ├── scripts/
│   │   └── tenant_sys.c                   │   └── parse.py
│   └── threading/                         ├── server/
│       ├── thread_lifecycle.c             │   ├── api.py
│       └── thread_pool.c                  │   ├── matchmaker.py
├── network/                               │   ├── models.py
│   ├── lockstep/                          │   ├── relay.py
│   │   ├── fsm_core.lua                   │   └── state.py
│   │   ├── fsm_pacing.lua                 ├── shaders/
│   │   ├── fsm_simulator.lua              │   ├── render.frag
│   │   ├── history_buffer.lua             │   ├── render.vert
│   │   └── wire_codec.lua                 │   └── shared.glsl
│   ├── protocol/                          ├── ssot/
│   │   ├── config_net.lua                 │   ├── config_gfx.lua
│   │   ├── dkjson.lua                     │   ├── config_sim.lua
│   │   ├── json_util.lua                  │   ├── ctx_types.lua
│   │   ├── net_01_constants.h             │   ├── registry.glsl
│   │   ├── net_02_wire.h                  │   ├── type_math.lua
│   │   ├── net_03_memory.h                │   └── type_render.lua
│   │   ├── net_04_state.h                 ├── tools/
│   │   ├── net_05_api.h                   │   ├── bot.lua
│   │   ├── shared_structs.h               │   ├── cli_args.lua
│   │   └── structs.lua                    │   └── cli_sys.lua
│   ├── session/                           └── worlds/
│   │   ├── http_client.lua                    ├── chess/
│   │   ├── ice_handshake.lua                  │   └── domain.lua
│   │   ├── matchmaker.lua                     ├── isometric/
│   │   ├── net_utils.lua                      │   └── domain.lua
│   │   ├── netcode.lua                        ├── luachess/
│   │   └── sys_time.lua                       │   ├── game/
│   └── transport/                             │   │   ├── attack.lua
│       ├── net_pump.lua                       │   │   ├── logic.lua
│       ├── network.lua                        │   │   ├── move.lua
│       ├── vx_net_internal.h                  │   │   ├── standard.lua
│       ├── vx_net_io.c                        │   │   └── turn.lua
│       ├── vx_net_state.c                     │   └── global.lua
│       └── vx_net_stun.c                      └── router_plugin.lua
├── rag/
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
