```mermaid
%%{init: {"flowchart": {"defaultRenderer": "elk"}}}%%
flowchart LR
    %% WeaverEngine Lua Dependencies
    subgraph build
        build_build_lua["build/build.lua"]
        build_check_build_dependencies_lua["build/check_build_dependencies.lua"]
        build_export_c_hdr_lua["build/export_c_hdr.lua"]
        build_export_glsl_lua["build/export_glsl.lua"]
        build_net_codegen_lua["build/net_codegen.lua"]
        build_task_c_objects_lua["build/task_c_objects.lua"]
        build_task_headless_lua["build/task_headless.lua"]
        build_task_invariants_lua["build/task_invariants.lua"]
        build_task_shaders_lua["build/task_shaders.lua"]
    end
    subgraph network
        network_lockstep_fsm_core_lua["network/lockstep/fsm_core.lua"]
        network_lockstep_fsm_pacing_lua["network/lockstep/fsm_pacing.lua"]
        network_lockstep_fsm_simulator_lua["network/lockstep/fsm_simulator.lua"]
        network_lockstep_history_buffer_lua["network/lockstep/history_buffer.lua"]
        network_lockstep_wire_codec_lua["network/lockstep/wire_codec.lua"]
        network_protocol_config_net_lua["network/protocol/config_net.lua"]
        network_protocol_dkjson_lua["network/protocol/dkjson.lua"]
        network_protocol_json_util_lua["network/protocol/json_util.lua"]
        network_protocol_structs_lua["network/protocol/structs.lua"]
        network_session_http_client_lua["network/session/http_client.lua"]
        network_session_ice_handshake_lua["network/session/ice_handshake.lua"]
        network_session_matchmaker_lua["network/session/matchmaker.lua"]
        network_session_net_utils_lua["network/session/net_utils.lua"]
        network_session_netcode_lua["network/session/netcode.lua"]
        network_session_sys_time_lua["network/session/sys_time.lua"]
        network_transport_net_pump_lua["network/transport/net_pump.lua"]
        network_transport_network_lua["network/transport/network.lua"]
    end
    subgraph runtime
        runtime_boot_core_abi_lua["runtime/boot/core_abi.lua"]
        runtime_boot_engine_api_lua["runtime/boot/engine_api.lua"]
        runtime_boot_main_lua["runtime/boot/main.lua"]
        runtime_boot_main_loop_lua["runtime/boot/main_loop.lua"]
        runtime_boot_main_setup_lua["runtime/boot/main_setup.lua"]
        runtime_boot_path_weaver_lua["runtime/boot/path_weaver.lua"]
        runtime_boot_weaver_boot_lua["runtime/boot/weaver_boot.lua"]
        runtime_boot_window_api_lua["runtime/boot/window_api.lua"]
        runtime_presentation_graphics_compute_pipeline_lua["runtime/presentation/graphics/compute_pipeline.lua"]
        runtime_presentation_graphics_graphics_pipeline_lua["runtime/presentation/graphics/graphics_pipeline.lua"]
        runtime_presentation_graphics_graphics_pipeline_init_lua["runtime/presentation/graphics/graphics_pipeline_init.lua"]
        runtime_presentation_graphics_graphics_pipeline_runtime_lua["runtime/presentation/graphics/graphics_pipeline_runtime.lua"]
        runtime_presentation_graphics_graphics_pipeline_utils_lua["runtime/presentation/graphics/graphics_pipeline_utils.lua"]
        runtime_presentation_graphics_renderer_lua["runtime/presentation/graphics/renderer.lua"]
        runtime_presentation_graphics_sequence_lua["runtime/presentation/graphics/sequence.lua"]
        runtime_presentation_translation_pipeline_manifest_lua["runtime/presentation/translation/pipeline_manifest.lua"]
        runtime_presentation_translation_render_queue_lua["runtime/presentation/translation/render_queue.lua"]
        runtime_services_gpu_descriptors_lua["runtime/services/gpu/descriptors.lua"]
        runtime_services_gpu_registry_vk_lua["runtime/services/gpu/registry_vk.lua"]
        runtime_services_gpu_swapchain_lua["runtime/services/gpu/swapchain.lua"]
        runtime_services_gpu_vulkan_core_lua["runtime/services/gpu/vulkan_core.lua"]
        runtime_services_gpu_vulkan_core_destroy_lua["runtime/services/gpu/vulkan_core_destroy.lua"]
        runtime_services_gpu_vulkan_core_device_lua["runtime/services/gpu/vulkan_core_device.lua"]
        runtime_services_gpu_vulkan_core_instance_lua["runtime/services/gpu/vulkan_core_instance.lua"]
        runtime_services_gpu_vulkan_core_loader_lua["runtime/services/gpu/vulkan_core_loader.lua"]
        runtime_services_gpu_vulkan_headers_lua["runtime/services/gpu/vulkan_headers.lua"]
        runtime_services_gpu_weaver_vram_lua["runtime/services/gpu/weaver_vram.lua"]
        runtime_services_math_fixed_math_lua["runtime/services/math/fixed_math.lua"]
        runtime_services_math_vmath_lua["runtime/services/math/vmath.lua"]
        runtime_services_memory_memory_lua["runtime/services/memory/memory.lua"]
        runtime_services_tenants_tenant_lifecycle_lua["runtime/services/tenants/tenant_lifecycle.lua"]
        runtime_services_tenants_tenant_registry_lua["runtime/services/tenants/tenant_registry.lua"]
        runtime_shutdown_teardown_lua["runtime/shutdown/teardown.lua"]
        runtime_simulation_camera_lua["runtime/simulation/camera.lua"]
        runtime_simulation_game_state_lua["runtime/simulation/game_state.lua"]
        runtime_simulation_raycast_lua["runtime/simulation/raycast.lua"]
    end
    subgraph ssot
        ssot_config_gfx_lua["ssot/config_gfx.lua"]
        ssot_config_sim_lua["ssot/config_sim.lua"]
        ssot_ctx_types_lua["ssot/ctx_types.lua"]
        ssot_type_math_lua["ssot/type_math.lua"]
        ssot_type_render_lua["ssot/type_render.lua"]
    end
    subgraph tools
        tools_bot_lua["tools/bot.lua"]
        tools_cli_args_lua["tools/cli_args.lua"]
        tools_cli_lobby_lua["tools/cli_lobby.lua"]
        tools_cli_readline_lua["tools/cli_readline.lua"]
        tools_cli_sys_lua["tools/cli_sys.lua"]
    end
    subgraph worlds
        worlds_chess_domain_lua["worlds/chess/domain.lua"]
        worlds_isometric_domain_lua["worlds/isometric/domain.lua"]
        worlds_luachess_game_attack_lua["worlds/luachess/game/attack.lua"]
        worlds_luachess_game_logic_lua["worlds/luachess/game/logic.lua"]
        worlds_luachess_game_move_lua["worlds/luachess/game/move.lua"]
        worlds_luachess_game_standard_lua["worlds/luachess/game/standard.lua"]
        worlds_luachess_game_turn_lua["worlds/luachess/game/turn.lua"]
        worlds_luachess_global_lua["worlds/luachess/global.lua"]
        worlds_router_plugin_lua["worlds/router_plugin.lua"]
    end
    build_build_lua --> build_export_c_hdr_lua
    build_build_lua --> build_export_glsl_lua
    build_build_lua --> build_task_c_objects_lua
    build_build_lua --> build_task_headless_lua
    build_build_lua --> build_task_invariants_lua
    build_build_lua --> build_task_shaders_lua
    build_build_lua --> ssot_config_gfx_lua
    build_build_lua --> ssot_config_sim_lua
    build_build_lua --> ssot_ctx_types_lua
    network_lockstep_fsm_core_lua --> network_lockstep_fsm_pacing_lua
    network_lockstep_fsm_core_lua --> network_lockstep_fsm_simulator_lua
    network_lockstep_fsm_simulator_lua --> network_protocol_structs_lua
    network_protocol_config_net_lua --> network_protocol_structs_lua
    network_protocol_json_util_lua --> network_protocol_dkjson_lua
    network_session_ice_handshake_lua --> network_protocol_config_net_lua
    network_session_ice_handshake_lua --> network_session_sys_time_lua
    network_session_ice_handshake_lua --> network_transport_network_lua
    network_session_matchmaker_lua --> network_protocol_config_net_lua
    network_session_matchmaker_lua --> network_protocol_json_util_lua
    network_session_matchmaker_lua --> network_session_http_client_lua
    network_session_matchmaker_lua --> network_session_sys_time_lua
    network_session_matchmaker_lua --> network_transport_network_lua
    network_session_net_utils_lua --> network_session_http_client_lua
    network_session_net_utils_lua --> network_session_ice_handshake_lua
    network_session_net_utils_lua --> network_session_matchmaker_lua
    network_session_netcode_lua --> network_lockstep_fsm_core_lua
    network_session_netcode_lua --> network_protocol_config_net_lua
    network_session_netcode_lua --> network_protocol_structs_lua
    network_session_netcode_lua --> network_session_net_utils_lua
    network_session_netcode_lua --> network_transport_net_pump_lua
    network_session_netcode_lua --> network_transport_network_lua
    network_session_netcode_lua --> runtime_boot_path_weaver_lua
    network_session_netcode_lua --> ssot_config_sim_lua
    network_session_netcode_lua --> worlds_router_plugin_lua
    network_transport_net_pump_lua --> network_lockstep_history_buffer_lua
    network_transport_net_pump_lua --> network_lockstep_wire_codec_lua
    network_transport_net_pump_lua --> network_transport_network_lua
    runtime_boot_main_lua --> runtime_boot_engine_api_lua
    runtime_boot_main_lua --> runtime_boot_main_loop_lua
    runtime_boot_main_lua --> runtime_boot_main_setup_lua
    runtime_boot_main_lua --> runtime_shutdown_teardown_lua
    runtime_boot_main_loop_lua --> network_session_sys_time_lua
    runtime_boot_main_loop_lua --> runtime_services_tenants_tenant_lifecycle_lua
    runtime_boot_main_loop_lua --> runtime_simulation_camera_lua
    runtime_boot_main_loop_lua --> runtime_simulation_raycast_lua
    runtime_boot_main_setup_lua --> network_session_netcode_lua
    runtime_boot_main_setup_lua --> runtime_boot_core_abi_lua
    runtime_boot_main_setup_lua --> runtime_boot_engine_api_lua
    runtime_boot_main_setup_lua --> runtime_boot_path_weaver_lua
    runtime_boot_main_setup_lua --> runtime_boot_weaver_boot_lua
    runtime_boot_main_setup_lua --> runtime_boot_window_api_lua
    runtime_boot_main_setup_lua --> runtime_presentation_graphics_graphics_pipeline_lua
    runtime_boot_main_setup_lua --> runtime_presentation_graphics_sequence_lua
    runtime_boot_main_setup_lua --> runtime_presentation_translation_pipeline_manifest_lua
    runtime_boot_main_setup_lua --> runtime_presentation_translation_render_queue_lua
    runtime_boot_main_setup_lua --> runtime_services_gpu_weaver_vram_lua
    runtime_boot_main_setup_lua --> runtime_services_memory_memory_lua
    runtime_boot_main_setup_lua --> runtime_services_tenants_tenant_registry_lua
    runtime_boot_main_setup_lua --> runtime_simulation_game_state_lua
    runtime_boot_main_setup_lua --> ssot_config_gfx_lua
    runtime_boot_main_setup_lua --> ssot_config_sim_lua
    runtime_boot_main_setup_lua --> ssot_ctx_types_lua
    runtime_boot_main_setup_lua --> ssot_type_math_lua
    runtime_boot_main_setup_lua --> ssot_type_render_lua
    runtime_boot_main_setup_lua --> tools_cli_args_lua
    runtime_presentation_graphics_compute_pipeline_lua --> runtime_services_gpu_registry_vk_lua
    runtime_presentation_graphics_graphics_pipeline_lua --> runtime_presentation_graphics_graphics_pipeline_init_lua
    runtime_presentation_graphics_graphics_pipeline_lua --> runtime_presentation_graphics_graphics_pipeline_runtime_lua
    runtime_presentation_graphics_graphics_pipeline_init_lua --> runtime_presentation_graphics_graphics_pipeline_utils_lua
    runtime_presentation_graphics_graphics_pipeline_init_lua --> runtime_services_gpu_registry_vk_lua
    runtime_presentation_graphics_graphics_pipeline_runtime_lua --> runtime_presentation_graphics_graphics_pipeline_utils_lua
    runtime_presentation_graphics_graphics_pipeline_utils_lua --> runtime_services_gpu_registry_vk_lua
    runtime_presentation_graphics_renderer_lua --> runtime_services_gpu_registry_vk_lua
    runtime_presentation_graphics_sequence_lua --> runtime_boot_engine_api_lua
    runtime_presentation_graphics_sequence_lua --> runtime_boot_window_api_lua
    runtime_presentation_graphics_sequence_lua --> runtime_presentation_graphics_compute_pipeline_lua
    runtime_presentation_graphics_sequence_lua --> runtime_presentation_translation_pipeline_manifest_lua
    runtime_presentation_graphics_sequence_lua --> runtime_services_gpu_descriptors_lua
    runtime_presentation_graphics_sequence_lua --> runtime_services_gpu_registry_vk_lua
    runtime_presentation_graphics_sequence_lua --> runtime_services_gpu_vulkan_core_lua
    runtime_presentation_graphics_sequence_lua --> runtime_services_memory_memory_lua
    runtime_presentation_graphics_sequence_lua --> ssot_config_gfx_lua
    runtime_presentation_graphics_sequence_lua --> ssot_config_sim_lua
    runtime_presentation_translation_render_queue_lua --> runtime_boot_engine_api_lua
    runtime_presentation_translation_render_queue_lua --> runtime_presentation_translation_pipeline_manifest_lua
    runtime_presentation_translation_render_queue_lua --> runtime_services_math_fixed_math_lua
    runtime_presentation_translation_render_queue_lua --> ssot_config_gfx_lua
    runtime_services_gpu_descriptors_lua --> runtime_services_gpu_registry_vk_lua
    runtime_services_gpu_registry_vk_lua --> runtime_services_gpu_vulkan_headers_lua
    runtime_services_gpu_swapchain_lua --> runtime_services_gpu_registry_vk_lua
    runtime_services_gpu_vulkan_core_lua --> runtime_services_gpu_vulkan_core_destroy_lua
    runtime_services_gpu_vulkan_core_lua --> runtime_services_gpu_vulkan_core_device_lua
    runtime_services_gpu_vulkan_core_lua --> runtime_services_gpu_vulkan_core_instance_lua
    runtime_services_gpu_vulkan_core_destroy_lua --> runtime_boot_engine_api_lua
    runtime_services_gpu_vulkan_core_device_lua --> runtime_services_gpu_registry_vk_lua
    runtime_services_gpu_vulkan_core_instance_lua --> runtime_boot_engine_api_lua
    runtime_services_gpu_vulkan_core_instance_lua --> runtime_services_gpu_registry_vk_lua
    runtime_services_gpu_vulkan_core_instance_lua --> runtime_services_gpu_vulkan_core_loader_lua
    runtime_services_gpu_vulkan_core_loader_lua --> runtime_services_gpu_vulkan_headers_lua
    runtime_services_memory_memory_lua --> runtime_services_gpu_registry_vk_lua
    runtime_services_tenants_tenant_lifecycle_lua --> runtime_presentation_graphics_graphics_pipeline_lua
    runtime_services_tenants_tenant_lifecycle_lua --> runtime_presentation_graphics_renderer_lua
    runtime_services_tenants_tenant_lifecycle_lua --> runtime_services_gpu_swapchain_lua
    runtime_services_tenants_tenant_registry_lua --> runtime_boot_engine_api_lua
    runtime_services_tenants_tenant_registry_lua --> runtime_boot_window_api_lua
    runtime_services_tenants_tenant_registry_lua --> runtime_presentation_graphics_renderer_lua
    runtime_services_tenants_tenant_registry_lua --> runtime_services_gpu_swapchain_lua
    runtime_services_tenants_tenant_registry_lua --> runtime_simulation_camera_lua
    runtime_shutdown_teardown_lua --> network_transport_network_lua
    runtime_shutdown_teardown_lua --> runtime_presentation_graphics_compute_pipeline_lua
    runtime_shutdown_teardown_lua --> runtime_presentation_graphics_graphics_pipeline_lua
    runtime_shutdown_teardown_lua --> runtime_presentation_graphics_renderer_lua
    runtime_shutdown_teardown_lua --> runtime_services_gpu_descriptors_lua
    runtime_shutdown_teardown_lua --> runtime_services_gpu_swapchain_lua
    runtime_shutdown_teardown_lua --> runtime_services_gpu_vulkan_core_lua
    runtime_simulation_camera_lua --> runtime_boot_window_api_lua
    runtime_simulation_camera_lua --> runtime_services_math_vmath_lua
    runtime_simulation_game_state_lua --> runtime_services_math_fixed_math_lua
    runtime_simulation_raycast_lua --> runtime_services_math_fixed_math_lua
    runtime_simulation_raycast_lua --> runtime_services_math_vmath_lua
    runtime_simulation_raycast_lua --> ssot_config_sim_lua
    ssot_ctx_types_lua --> ssot_type_math_lua
    ssot_ctx_types_lua --> ssot_type_render_lua
    tools_bot_lua --> network_session_netcode_lua
    tools_bot_lua --> network_session_sys_time_lua
    tools_bot_lua --> runtime_boot_path_weaver_lua
    tools_bot_lua --> runtime_simulation_game_state_lua
    tools_bot_lua --> ssot_config_sim_lua
    tools_bot_lua --> tools_cli_args_lua
    tools_cli_lobby_lua --> tools_cli_sys_lua
    tools_cli_readline_lua --> tools_cli_lobby_lua
    tools_cli_readline_lua --> tools_cli_sys_lua
    worlds_chess_domain_lua --> runtime_services_math_fixed_math_lua
    worlds_chess_domain_lua --> worlds_luachess_game_standard_lua
    worlds_chess_domain_lua --> worlds_luachess_game_turn_lua
    worlds_chess_domain_lua --> worlds_luachess_global_lua
    worlds_isometric_domain_lua --> runtime_services_math_fixed_math_lua
    worlds_luachess_game_logic_lua --> worlds_luachess_game_attack_lua
    worlds_luachess_game_logic_lua --> worlds_luachess_game_move_lua
    worlds_luachess_game_logic_lua --> worlds_luachess_global_lua
    worlds_luachess_game_move_lua --> worlds_luachess_global_lua
    worlds_luachess_game_standard_lua --> worlds_luachess_global_lua
    worlds_luachess_game_turn_lua --> worlds_luachess_game_logic_lua
    worlds_luachess_game_turn_lua --> worlds_luachess_global_lua
    worlds_router_plugin_lua --> network_transport_network_lua
    worlds_router_plugin_lua --> worlds_chess_domain_lua
    worlds_router_plugin_lua --> worlds_isometric_domain_lua
```
