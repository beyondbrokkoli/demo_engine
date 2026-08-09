### DEMO ENGINE

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
├── cli_sys.lua                            │   │   ├── graphics/
├── docs/                                  │   │   │   ├── compute_pipeline.lua
│   ├── deps_c.md                          │   │   │   ├── graphics_pipeline.lua
│   ├── deps_glsl.md                       │   │   │   ├── renderer.lua
│   ├── deps_lua.md                        │   │   │   └── sequence.lua
│   ├── repo_ascii.txt                     │   │   └── translation/
│   └── repo_tree.md                       │   │       ├── pipeline_manifest.lua
├── generated/                             │   │       └── render_queue.lua
│   ├── registry.glsl                      │   ├── services/
│   ├── ssot_render.h                      │   │   ├── gpu/
│   └── ssot_types.h                       │   │   │   ├── descriptors.lua
├── host/                                  │   │   │   ├── registry_vk.lua
│   ├── boot/                              │   │   │   ├── swapchain.lua
│   │   ├── lifecycle.c                    │   │   │   ├── vulkan_core.lua
│   │   ├── main.c                         │   │   │   └── weaver_vram.lua
│   │   └── main_headless.c                │   │   ├── math/
│   ├── ipc/                               │   │   │   ├── fixed_math.lua
│   │   ├── mailbox.c                      │   │   │   └── vmath.lua
│   │   ├── ring_stream.c                  │   │   ├── memory/
│   │   └── sys_sync.c                     │   │   │   └── memory.lua
│   ├── lua/                               │   │   └── tenants/
│   │   └── lua_vm.c                       │   │       ├── tenant_lifecycle.lua
│   ├── runtime/                           │   │       └── tenant_registry.lua
│   │   └── main_loop.c                    │   ├── shutdown/
│   ├── state/                             │   │   └── teardown.lua
│   │   ├── state_globals.c                │   └── simulation/
│   │   └── state_types.c                  │       ├── camera.lua
│   ├── tenant/                            │       ├── game_state.lua
│   │   ├── tenant_callbacks.c             │       └── raycast.lua
│   │   ├── tenant_callbacks_key.c         ├── scripts/
│   │   ├── tenant_callbacks_mouse.c       │   └── parse.py
│   │   ├── tenant_callbacks_state.c       ├── server/
│   │   ├── tenant_input.c                 │   ├── api.py
│   │   └── tenant_sys.c                   │   ├── matchmaker.py
│   └── threading/                         │   ├── models.py
│       ├── thread_lifecycle.c             │   ├── relay.py
│       └── thread_pool.c                  │   └── state.py
├── launch.bat                             ├── shaders/
├── launch.lua                             │   ├── render.frag
├── launch.sh                              │   ├── render.vert
├── logs/                                  │   └── shared.glsl
├── network/                               ├── ssot/
│   ├── lockstep/                          │   ├── config_gfx.lua
│   │   ├── fsm_core.lua                   │   ├── config_sim.lua
│   │   ├── fsm_pacing.lua                 │   ├── ctx_types.lua
│   │   ├── fsm_simulator.lua              │   ├── registry.glsl
│   │   ├── history_buffer.lua             │   ├── type_math.lua
│   │   └── wire_codec.lua                 │   └── type_render.lua
│   ├── protocol/                          ├── tools/
│   │   ├── config_net.lua                 │   └── bot.lua
│   │   ├── dkjson.lua                     └── worlds/
│   │   ├── json_util.lua                      ├── chess/
│   │   ├── shared_structs.h                   │   └── domain.lua
│   │   └── structs.lua                        ├── isometric/
│   ├── session/                               │   └── domain.lua
│   │   ├── net_utils.lua                      ├── luachess/
│   │   └── netcode.lua                        │   ├── game/
│   └── transport/                             │   │   ├── attack.lua
│       ├── net_pump.lua                       │   │   ├── game.lua
│       ├── network.lua                        │   │   ├── input.lua
│       └── vx_net.c                           │   │   ├── logic.lua
├── python/                                    │   │   ├── move.lua
│   ├── ascii_tree_cols.py                     │   │   ├── standard.lua
│   ├── trace_deps_c.py                        │   │   └── turn.lua
│   ├── trace_deps_glsl.py                     │   └── global.lua
│   ├── trace_deps_lua.py                      └── router_plugin.lua
│   └── trace_tree.py
```
