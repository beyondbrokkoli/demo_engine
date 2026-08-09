### DEMO ENGINE

Whether you are on Linux (`./launch.sh`) or Windows (`launch.bat`), the syntax is identical.

| Command | Syntax | Description |
| --- | --- | --- |
| **Host** | `host [size]` | Creates a new graphical host node. (Default size: 8) |
| **Client** | `client <lobby_id> [size]` | Joins an existing lobby as a graphical client. |
| **Attach** | `attach <bot_count> <lobby_id> [size]` | Injects headless chaos bots into an active lobby. |
| **Lab** | `lab` | Boots a full 8-player local test (4 graphical, 4 headless). |
| **Swarm** | `swarm [gui_count] [bot_count]` | Custom local cluster testing. |
| **Clean** | `clean` | Force-kills all running engine processes and frees sockets. |

```text
demo_engine/                               │   ├── gpu/
├── .gitattributes                         │   │   ├── vk_draw.c
├── .gitignore                             │   │   ├── vk_record.c
├── 1_lab_domain.lua                       │   │   └── vk_render_loop.c
├── bin/                                   │   ├── tenant/
│   ├── boot.elf                           │   │   └── vk_tenant_alloc.c
│   ├── boot.exe                           │   └── transfer/
│   ├── boot_headless.elf                  │       ├── vk_transfer_api.c
│   ├── boot_headless.exe                  │       └── vk_transfer_loop.c
│   ├── glfw3.dll                          ├── runtime/
│   ├── libvx_net.so                       │   ├── boot/
│   ├── libwinpthread-1.dll                │   │   ├── core_abi.lua
│   ├── lua51.dll                          │   │   ├── engine_api.lua
│   ├── render_frag.spv                    │   │   ├── main.lua
│   ├── render_vert.spv                    │   │   ├── path_weaver.lua
│   └── vx_net.dll                         │   │   ├── weaver_boot.lua
├── build/                                 │   │   └── window_api.lua
│   ├── check_deps.lua                     │   ├── presentation/
│   ├── ctx_build.lua                      │   │   ├── graphics/
│   ├── export_c_hdr.lua                   │   │   │   ├── compute_pipeline.lua
│   ├── export_glsl.lua                    │   │   │   ├── graphics_pipeline.lua
│   ├── task_c_objects.lua                 │   │   │   ├── renderer.lua
│   ├── task_headless.lua                  │   │   │   └── sequence.lua
│   ├── task_invariants.lua                │   │   └── translation/
│   └── task_shaders.lua                   │   │       ├── pipeline_manifest.lua
├── docs/                                  │   │       └── render_queue.lua
│   ├── deps_c.md                          │   ├── services/
│   ├── deps_glsl.md                       │   │   ├── gpu/
│   ├── deps_lua.md                        │   │   │   ├── descriptors.lua
│   ├── repo_ascii.txt                     │   │   │   ├── registry_vk.lua
│   └── repo_tree.md                       │   │   │   ├── swapchain.lua
├── generated/                             │   │   │   ├── vulkan_core.lua
│   ├── registry.glsl                      │   │   │   └── weaver_vram.lua
│   ├── ssot_render.h                      │   │   ├── math/
│   └── ssot_types.h                       │   │   │   ├── fixed_math.lua
├── host/                                  │   │   │   └── vmath.lua
│   ├── boot/                              │   │   ├── memory/
│   │   ├── lifecycle.c                    │   │   │   └── memory.lua
│   │   ├── main.c                         │   │   └── tenants/
│   │   └── main_headless.c                │   │       ├── tenant_lifecycle.lua
│   ├── ipc/                               │   │       └── tenant_registry.lua
│   │   ├── mailbox.c                      │   ├── shutdown/
│   │   ├── ring_stream.c                  │   │   └── teardown.lua
│   │   └── sys_sync.c                     │   └── simulation/
│   ├── lua/                               │       ├── camera.lua
│   │   └── lua_vm.c                       │       ├── game_state.lua
│   ├── runtime/                           │       └── raycast.lua
│   │   └── main_loop.c                    ├── server/
│   ├── state/                             │   ├── api.py
│   │   ├── state_globals.c                │   ├── matchmaker.py
│   │   └── state_types.c                  │   ├── models.py
│   ├── tenant/                            │   ├── relay.py
│   │   ├── tenant_callbacks.c             │   └── state.py
│   │   ├── tenant_callbacks_key.c         ├── shaders/
│   │   ├── tenant_callbacks_mouse.c       │   ├── render.frag
│   │   ├── tenant_callbacks_state.c       │   ├── render.vert
│   │   ├── tenant_input.c                 │   └── shared.glsl
│   │   └── tenant_sys.c                   ├── ssot/
│   └── threading/                         │   ├── config_gfx.lua
│       ├── thread_lifecycle.c             │   ├── config_sim.lua
│       └── thread_pool.c                  │   ├── ctx_types.lua
├── launch.bat                             │   ├── registry.glsl
├── launch.lua                             │   ├── type_math.lua
├── launch.sh                              │   └── type_render.lua
├── logs/                                  ├── tools/
│   ├── ...                                │   ├── ascii_tree_cols.py
│   └── folder.txt                         │   ├── bot.lua
├── network/                               │   ├── diagnostic_monitor.lua
│   ├── lockstep/                          │   ├── lab_domain.lua
│   │   ├── fsm_core.lua                   │   ├── login_test.sh
│   │   ├── fsm_pacing.lua                 │   ├── parse.py
│   │   ├── fsm_simulator.lua              │   ├── trace_deps_c.py
│   │   ├── history_buffer.lua             │   ├── trace_deps_glsl.py
│   │   └── wire_codec.lua                 │   ├── trace_deps_lua.py
│   ├── protocol/                          │   └── trace_tree.py
│   │   ├── config_net.lua                 └── worlds/
│   │   ├── dkjson.lua                         ├── chess/
│   │   ├── json_util.lua                      │   ├── domain.lua
│   │   ├── shared_structs.h                   │   └── plugin_backup.lua
│   │   └── structs.lua                        ├── isometric/
│   ├── session/                               │   └── domain.lua
│   │   ├── net_utils.lua                      ├── luachess/
│   │   └── netcode.lua                        │   ├── game/
│   └── transport/                             │   │   ├── attack.lua
│       ├── net_pump.lua                       │   │   ├── game.lua
│       ├── network.lua                        │   │   ├── input.lua
│       └── vx_net.c                           │   │   ├── logic.lua
├── rag/                                       │   │   ├── move.lua
│   ├── ask.py                                 │   │   ├── standard.lua
│   └── ingest_codebase.py                     │   │   └── turn.lua
├── render/                                    │   └── global.lua
│   ├── debug/                                 └── router_plugin.lua
│   │   └── vk_debug.c

```
