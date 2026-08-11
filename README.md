### DEMO ENGINE

```text
demo_engine/                               │   ├── trace_deps_lua.py
├── .gitattributes                         │   └── trace_tree.py
├── .gitignore                             ├── rag/
├── LICENSE                                │   ├── ask.py
├── bin/                                   │   └── ingest_codebase.py
│   ├── boot.elf                           ├── render/
│   ├── boot.exe                           │   ├── debug/
│   ├── boot_headless.elf                  │   │   └── vk_debug.c
│   ├── boot_headless.exe                  │   ├── gpu/
│   ├── glfw3.dll                          │   │   ├── vk_draw.c
│   ├── libvx_net.so                       │   │   ├── vk_record.c
│   ├── libwinpthread-1.dll                │   │   └── vk_render_loop.c
│   ├── lua51.dll                          │   ├── tenant/
│   ├── render_frag.spv                    │   │   └── vk_tenant_alloc.c
│   ├── render_vert.spv                    │   └── transfer/
│   └── vx_net.dll                         │       ├── vk_transfer_api.c
├── build/                                 │       └── vk_transfer_loop.c
│   ├── build.lua                          ├── runtime/
│   ├── check_build_dependencies.lua       │   ├── boot/
│   ├── export_c_hdr.lua                   │   │   ├── core_abi.lua
│   ├── export_glsl.lua                    │   │   ├── engine_api.lua
│   ├── task_c_objects.lua                 │   │   ├── main.lua
│   ├── task_headless.lua                  │   │   ├── path_weaver.lua
│   ├── task_invariants.lua                │   │   ├── weaver_boot.lua
│   └── task_shaders.lua                   │   │   └── window_api.lua
├── cli_sys.lua                            │   ├── presentation/
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
│       ├── network.lua                        │   │   ├── logic.lua
│       └── vx_net.c                           │   │   ├── move.lua
├── python/                                    │   │   ├── standard.lua
│   ├── ascii_tree_cols.py                     │   │   └── turn.lua
│   ├── trace_deps_c.py                        │   └── global.lua
│   ├── trace_deps_glsl.py                     └── router_plugin.lua
```
