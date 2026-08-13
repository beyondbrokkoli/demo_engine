```text
demo_engine/                               │   │   ├── main_setup.lua
├── build/                                 │   │   ├── path_weaver.lua
│   ├── build.lua                          │   │   ├── weaver_boot.lua
│   ├── check_build_dependencies.lua       │   │   └── window_api.lua
│   ├── export_c_hdr.lua                   │   ├── presentation/
│   ├── export_glsl.lua                    │   │   ├── graphics/
│   ├── net_codegen.lua                    │   │   │   ├── compute_pipeline.lua
│   ├── task_c_objects.lua                 │   │   │   ├── graphics_pipeline.lua
│   ├── task_headless.lua                  │   │   │   ├── graphics_pipeline_init.lua
│   ├── task_invariants.lua                │   │   │   ├── graphics_pipeline_runtime.l
│   └── task_shaders.lua                   │   │   │   ├── graphics_pipeline_utils.lua
├── generated/                             │   │   │   ├── renderer.lua
│   ├── registry.glsl                      │   │   │   └── sequence.lua
│   ├── ssot_render.h                      │   │   └── translation/
│   └── ssot_types.h                       │   │       ├── pipeline_manifest.lua
├── host/                                  │   │       └── render_queue.lua
│   ├── boot/                              │   ├── services/
│   │   ├── lifecycle.c                    │   │   ├── gpu/
│   │   ├── main.c                         │   │   │   ├── descriptors.lua
│   │   └── main_headless.c                │   │   │   ├── registry_vk.lua
│   ├── ipc/                               │   │   │   ├── swapchain.lua
│   │   ├── mailbox.c                      │   │   │   ├── vulkan_core.lua
│   │   ├── ring_stream.c                  │   │   │   ├── vulkan_core_destroy.lua
│   │   └── sys_sync.c                     │   │   │   ├── vulkan_core_device.lua
│   ├── lua/                               │   │   │   ├── vulkan_core_instance.lua
│   │   └── lua_vm.c                       │   │   │   ├── vulkan_core_loader.lua
│   ├── runtime/                           │   │   │   └── weaver_vram.lua
│   │   └── main_loop.c                    │   │   ├── math/
│   ├── state/                             │   │   │   ├── fixed_math.lua
│   │   ├── state_globals.c                │   │   │   ├── vmath.lua
│   │   └── state_types.c                  │   │   │   ├── vmath_cam.lua
│   ├── tenant/                            │   │   │   ├── vmath_mat.lua
│   │   ├── tenant_callbacks_key.c         │   │   │   ├── vmath_mat_inv.lua
│   │   ├── tenant_callbacks_mouse.c       │   │   │   └── vmath_mat_mult.lua
│   │   ├── tenant_callbacks_state.c       │   │   ├── memory/
│   │   ├── tenant_input.c                 │   │   │   ├── memory.lua
│   │   └── tenant_sys.c                   │   │   │   ├── memory_alloc.lua
│   └── threading/                         │   │   │   ├── memory_alloc_cpu.lua
│       ├── thread_lifecycle.c             │   │   │   ├── memory_alloc_gpu.lua
│       └── thread_pool.c                  │   │   │   ├── memory_base.lua
├── network/                               │   │   │   ├── memory_platform.lua
│   ├── lockstep/                          │   │   │   └── memory_transfer.lua
│   │   ├── fsm_core.lua                   │   │   └── tenants/
│   │   ├── fsm_pacing.lua                 │   │       ├── tenant_lifecycle.lua
│   │   ├── fsm_simulator.lua              │   │       └── tenant_registry.lua
│   │   ├── history_buffer.lua             │   ├── shutdown/
│   │   └── wire_codec.lua                 │   │   └── teardown.lua
│   ├── protocol/                          │   └── simulation/
│   │   ├── config_net.lua                 │       ├── camera.lua
│   │   ├── dkjson.lua                     │       ├── game_state.lua
│   │   ├── json_util.lua                  │       └── raycast.lua
│   │   ├── net_01_constants.h             ├── shaders/
│   │   ├── net_02_wire.h                  │   ├── render.frag
│   │   ├── net_03_memory.h                │   ├── render.vert
│   │   ├── net_04_state.h                 │   └── shared.glsl
│   │   ├── net_05_api.h                   ├── ssot/
│   │   ├── shared_structs.h               │   ├── config_gfx.lua
│   │   └── structs.lua                    │   ├── config_sim.lua
│   ├── session/                           │   ├── ctx_types.lua
│   │   ├── http_client.lua                │   ├── registry.glsl
│   │   ├── ice_handshake.lua              │   ├── type_math.lua
│   │   ├── matchmaker.lua                 │   └── type_render.lua
│   │   ├── net_utils.lua                  └── worlds/
│   │   ├── netcode.lua                        ├── chess/
│   │   └── sys_time.lua                       │   ├── domain.lua
│   └── transport/                             │   ├── domain_base.lua
│       ├── net_pump.lua                       │   ├── domain_contract.lua
│       ├── network.lua                        │   ├── domain_contract_base.lua
│       ├── vx_net_internal.h                  │   ├── domain_contract_commit.lua
│       ├── vx_net_io.c                        │   ├── domain_contract_decode.lua
│       ├── vx_net_state.c                     │   ├── domain_contract_logic.lua
│       └── vx_net_stun.c                      │   ├── domain_contract_simulate.lua
├── render/                                    │   ├── domain_lifecycle.lua
│   ├── debug/                                 │   └── domain_terrain.lua
│   │   └── vk_debug.c                         ├── isometric/
│   ├── gpu/                                   │   └── domain.lua
│   │   ├── vk_draw.c                          ├── luachess/
│   │   ├── vk_record.c                        │   ├── game/
│   │   └── vk_render_loop.c                   │   │   ├── attack.lua
│   ├── tenant/                                │   │   ├── logic.lua
│   │   └── vk_tenant_alloc.c                  │   │   ├── logic_base.lua
│   └── transfer/                              │   │   ├── logic_core.lua
│       ├── vk_transfer_api.c                  │   │   ├── logic_gen.lua
│       └── vk_transfer_loop.c                 │   │   ├── logic_pools.lua
├── runtime/                                   │   │   ├── move.lua
│   ├── boot/                                  │   │   ├── standard.lua
│   │   ├── core_abi.lua                       │   │   └── turn.lua
│   │   ├── engine_api.lua                     │   └── global.lua
│   │   ├── main.lua                           └── router_plugin.lua
│   │   ├── main_loop.lua
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
