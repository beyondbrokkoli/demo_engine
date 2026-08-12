### DEMO ENGINE

```text
demo_engine/                               ├── python/
├── .gitattributes                         │   ├── ascii_tree_cols.py
├── .gitignore                             │   ├── trace_deps_c.py
├── LICENSE                                │   ├── trace_deps_glsl.py
├── bin/                                   │   ├── trace_deps_lua.py
│   ├── boot.elf                           │   └── trace_tree.py
│   ├── boot.exe                           ├── rag/
│   ├── boot_headless.elf                  │   ├── ask.py
│   ├── boot_headless.exe                  │   ├── ask_local.py
│   ├── glfw3.dll                          │   └── ingest_codebase.py
│   ├── libvx_net.so                       ├── render/
│   ├── libwinpthread-1.dll                │   ├── debug/
│   ├── lua51.dll                          │   │   └── vk_debug.c
│   ├── render_frag.spv                    │   ├── gpu/
│   ├── render_vert.spv                    │   │   ├── vk_draw.c
│   └── vx_net.dll                         │   │   ├── vk_record.c
├── build/                                 │   │   └── vk_render_loop.c
│   ├── build.lua                          │   ├── tenant/
│   ├── check_build_dependencies.lua       │   │   └── vk_tenant_alloc.c
│   ├── export_c_hdr.lua                   │   └── transfer/
│   ├── export_glsl.lua                    │       ├── vk_transfer_api.c
│   ├── net_codegen.lua                    │       └── vk_transfer_loop.c
│   ├── task_c_objects.lua                 ├── runtime/
│   ├── task_headless.lua                  │   ├── boot/
│   ├── task_invariants.lua                │   │   ├── core_abi.lua
│   └── task_shaders.lua                   │   │   ├── engine_api.lua
├── cli_sys.lua                            │   │   ├── main.lua
├── docs/                                  │   │   ├── path_weaver.lua
│   ├── deps_c.md                          │   │   ├── weaver_boot.lua
│   ├── deps_glsl.md                       │   │   └── window_api.lua
│   ├── deps_lua.md                        │   ├── presentation/
│   ├── repo_ascii.txt                     │   │   ├── graphics/
│   └── repo_tree.md                       │   │   │   ├── compute_pipeline.lua
├── generated/                             │   │   │   ├── graphics_pipeline.lua
│   ├── registry.glsl                      │   │   │   ├── renderer.lua
│   ├── ssot_render.h                      │   │   │   └── sequence.lua
│   └── ssot_types.h                       │   │   └── translation/
├── host/                                  │   │       ├── pipeline_manifest.lua
│   ├── boot/                              │   │       └── render_queue.lua
│   │   ├── lifecycle.c                    │   ├── services/
│   │   ├── main.c                         │   │   ├── gpu/
│   │   └── main_headless.c                │   │   │   ├── descriptors.lua
│   ├── ipc/                               │   │   │   ├── registry_vk.lua
│   │   ├── mailbox.c                      │   │   │   ├── swapchain.lua
│   │   ├── ring_stream.c                  │   │   │   ├── vulkan_core.lua
│   │   └── sys_sync.c                     │   │   │   └── weaver_vram.lua
│   ├── lua/                               │   │   ├── math/
│   │   └── lua_vm.c                       │   │   │   ├── fixed_math.lua
│   ├── runtime/                           │   │   │   └── vmath.lua
│   │   └── main_loop.c                    │   │   ├── memory/
│   ├── state/                             │   │   │   └── memory.lua
│   │   ├── state_globals.c                │   │   └── tenants/
│   │   └── state_types.c                  │   │       ├── tenant_lifecycle.lua
│   ├── tenant/                            │   │       └── tenant_registry.lua
│   │   ├── tenant_callbacks_key.c         │   ├── shutdown/
│   │   ├── tenant_callbacks_mouse.c       │   │   └── teardown.lua
│   │   ├── tenant_callbacks_state.c       │   └── simulation/
│   │   ├── tenant_input.c                 │       ├── camera.lua
│   │   └── tenant_sys.c                   │       ├── game_state.lua
│   └── threading/                         │       └── raycast.lua
│       ├── thread_lifecycle.c             ├── scripts/
│       └── thread_pool.c                  │   └── parse.py
├── launch.bat                             ├── server/
├── launch.lua                             │   ├── api.py
├── launch.sh                              │   ├── matchmaker.py
├── logs/                                  │   ├── models.py
├── network/                               │   ├── relay.py
│   ├── lockstep/                          │   └── state.py
│   │   ├── fsm_core.lua                   ├── shaders/
│   │   ├── fsm_pacing.lua                 │   ├── render.frag
│   │   ├── fsm_simulator.lua              │   ├── render.vert
│   │   ├── history_buffer.lua             │   └── shared.glsl
│   │   └── wire_codec.lua                 ├── snapshots/
│   ├── protocol/                          │   └── tmp/
│   │   ├── config_net.lua                 │       └── upload/
│   │   ├── dkjson.lua                     ├── ssot/
│   │   ├── json_util.lua                  │   ├── config_gfx.lua
│   │   ├── net_01_constants.h             │   ├── config_sim.lua
│   │   ├── net_02_wire.h                  │   ├── ctx_types.lua
│   │   ├── net_03_memory.h                │   ├── registry.glsl
│   │   ├── net_04_state.h                 │   ├── type_math.lua
│   │   ├── net_05_api.h                   │   └── type_render.lua
│   │   ├── shared_structs.h               ├── tools/
│   │   └── structs.lua                    │   └── bot.lua
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
```
