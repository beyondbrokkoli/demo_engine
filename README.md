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
demo_engine/                               ├── rag/
├── .gitattributes                         │   ├── ask.py
├── .gitignore                             │   └── ingest_codebase.py
├── bin/                                   ├── render/
│   ├── boot.elf                           │   ├── debug/
│   ├── boot.exe                           │   │   └── vk_debug.c
│   ├── boot_headless.elf                  │   ├── gpu/
│   ├── boot_headless.exe                  │   │   ├── vk_draw.c
│   ├── glfw3.dll                          │   │   ├── vk_record.c
│   ├── libvx_net.so                       │   │   └── vk_render_loop.c
│   ├── libwinpthread-1.dll                │   ├── tenant/
│   ├── lua51.dll                          │   │   └── vk_tenant_alloc.c
│   ├── render_frag.spv                    │   └── transfer/
│   ├── render_vert.spv                    │       ├── vk_transfer_api.c
│   └── vx_net.dll                         │       └── vk_transfer_loop.c
├── build/                                 ├── runtime/
│   ├── build.lua                          │   ├── boot/
│   ├── check_build_dependencies.lua       │   │   ├── core_abi.lua
│   ├── export_c_hdr.lua                   │   │   ├── engine_api.lua
│   ├── export_glsl.lua                    │   │   ├── main.lua
│   ├── task_c_objects.lua                 │   │   ├── path_weaver.lua
│   ├── task_headless.lua                  │   │   ├── weaver_boot.lua
│   ├── task_invariants.lua                │   │   └── window_api.lua
│   └── task_shaders.lua                   │   ├── presentation/
├── docs/                                  │   │   ├── graphics/
│   ├── deps_c.md                          │   │   │   ├── compute_pipeline.lua
│   ├── deps_glsl.md                       │   │   │   ├── graphics_pipeline.lua
│   ├── deps_lua.md                        │   │   │   ├── renderer.lua
│   ├── repo_ascii.txt                     │   │   │   └── sequence.lua
│   └── repo_tree.md                       │   │   └── translation/
├── generated/                             │   │       ├── pipeline_manifest.lua
│   ├── registry.glsl                      │   │       └── render_queue.lua
│   ├── ssot_render.h                      │   ├── services/
│   └── ssot_types.h                       │   │   ├── gpu/
├── host/                                  │   │   │   ├── descriptors.lua
│   ├── boot/                              │   │   │   ├── registry_vk.lua
│   │   ├── lifecycle.c                    │   │   │   ├── swapchain.lua
│   │   ├── main.c                         │   │   │   ├── vulkan_core.lua
│   │   └── main_headless.c                │   │   │   └── weaver_vram.lua
│   ├── ipc/                               │   │   ├── math/
│   │   ├── mailbox.c                      │   │   │   ├── fixed_math.lua
│   │   ├── ring_stream.c                  │   │   │   └── vmath.lua
│   │   └── sys_sync.c                     │   │   ├── memory/
│   ├── lua/                               │   │   │   └── memory.lua
│   │   └── lua_vm.c                       │   │   └── tenants/
│   ├── runtime/                           │   │       ├── tenant_lifecycle.lua
│   │   └── main_loop.c                    │   │       └── tenant_registry.lua
│   ├── state/                             │   ├── shutdown/
│   │   ├── state_globals.c                │   │   └── teardown.lua
│   │   └── state_types.c                  │   └── simulation/
│   ├── tenant/                            │       ├── camera.lua
│   │   ├── tenant_callbacks.c             │       ├── game_state.lua
│   │   ├── tenant_callbacks_key.c         │       └── raycast.lua
│   │   ├── tenant_callbacks_mouse.c       ├── scripts/
│   │   ├── tenant_callbacks_state.c       │   └── parse.py
│   │   ├── tenant_input.c                 ├── server/
│   │   └── tenant_sys.c                   │   ├── api.py
│   └── threading/                         │   ├── matchmaker.py
│       ├── thread_lifecycle.c             │   ├── models.py
│       └── thread_pool.c                  │   ├── relay.py
├── launch.bat                             │   └── state.py
├── launch.lua                             ├── shaders/
├── launch.sh                              │   ├── render.frag
├── logs/                                  │   ├── render.vert
├── network/                               │   └── shared.glsl
│   ├── lockstep/                          ├── ssot/
│   │   ├── fsm_core.lua                   │   ├── config_gfx.lua
│   │   ├── fsm_pacing.lua                 │   ├── config_sim.lua
│   │   ├── fsm_simulator.lua              │   ├── ctx_types.lua
│   │   ├── history_buffer.lua             │   ├── registry.glsl
│   │   └── wire_codec.lua                 │   ├── type_math.lua
│   ├── protocol/                          │   └── type_render.lua
│   │   ├── config_net.lua                 ├── tools/
│   │   ├── dkjson.lua                     │   └── bot.lua
│   │   ├── json_util.lua                  └── worlds/
│   │   ├── shared_structs.h                   ├── chess/
│   │   └── structs.lua                        │   └── domain.lua
│   ├── session/                               ├── isometric/
│   │   ├── net_utils.lua                      │   └── domain.lua
│   │   └── netcode.lua                        ├── luachess/
│   └── transport/                             │   ├── game/
│       ├── net_pump.lua                       │   │   ├── attack.lua
│       ├── network.lua                        │   │   ├── game.lua
│       └── vx_net.c                           │   │   ├── input.lua
├── nul                                        │   │   ├── logic.lua
├── python/                                    │   │   ├── move.lua
│   ├── ascii_tree_cols.py                     │   │   ├── standard.lua
│   ├── trace_deps_c.py                        │   │   └── turn.lua
│   ├── trace_deps_glsl.py                     │   └── global.lua
│   ├── trace_deps_lua.py                      └── router_plugin.lua
│   └── trace_tree.py

```
