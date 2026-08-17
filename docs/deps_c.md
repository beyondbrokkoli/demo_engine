```mermaid
%%{init: {"flowchart": {"defaultRenderer": "elk"}}}%%
flowchart LR
    %% WeaverEngine C Dependencies
    subgraph generated
        generated_net_constants_h["generated/net_constants.h"]
        generated_net_ffi_bridge_h["generated/net_ffi_bridge.h"]
        generated_net_rollback_memory_h["generated/net_rollback_memory.h"]
        generated_net_wire_packets_h["generated/net_wire_packets.h"]
        generated_net_world_state_h["generated/net_world_state.h"]
        generated_shared_structs_h["generated/shared_structs.h"]
        generated_ssot_render_h["generated/ssot_render.h"]
        generated_ssot_types_h["generated/ssot_types.h"]
    end
    subgraph host
        host_boot_lifecycle_c["host/boot/lifecycle.c"]
        host_boot_main_c["host/boot/main.c"]
        host_boot_main_headless_c["host/boot/main_headless.c"]
        host_ipc_mailbox_c["host/ipc/mailbox.c"]
        host_ipc_ring_stream_c["host/ipc/ring_stream.c"]
        host_ipc_sys_sync_c["host/ipc/sys_sync.c"]
        host_lua_lua_vm_c["host/lua/lua_vm.c"]
        host_runtime_main_loop_c["host/runtime/main_loop.c"]
        host_state_state_globals_c["host/state/state_globals.c"]
        host_state_state_types_c["host/state/state_types.c"]
        host_tenant_tenant_callbacks_key_c["host/tenant/tenant_callbacks_key.c"]
        host_tenant_tenant_callbacks_mouse_c["host/tenant/tenant_callbacks_mouse.c"]
        host_tenant_tenant_callbacks_state_c["host/tenant/tenant_callbacks_state.c"]
        host_tenant_tenant_input_c["host/tenant/tenant_input.c"]
        host_tenant_tenant_sys_c["host/tenant/tenant_sys.c"]
        host_threading_thread_lifecycle_c["host/threading/thread_lifecycle.c"]
        host_threading_thread_pool_c["host/threading/thread_pool.c"]
    end
    subgraph network
        network_transport_vx_net_internal_h["network/transport/vx_net_internal.h"]
        network_transport_vx_net_io_c["network/transport/vx_net_io.c"]
        network_transport_vx_net_state_c["network/transport/vx_net_state.c"]
        network_transport_vx_net_stun_c["network/transport/vx_net_stun.c"]
    end
    subgraph render
        render_debug_vk_debug_c["render/debug/vk_debug.c"]
        render_gpu_vk_draw_c["render/gpu/vk_draw.c"]
        render_gpu_vk_record_c["render/gpu/vk_record.c"]
        render_gpu_vk_render_loop_c["render/gpu/vk_render_loop.c"]
        render_tenant_vk_tenant_alloc_c["render/tenant/vk_tenant_alloc.c"]
        render_transfer_vk_transfer_api_c["render/transfer/vk_transfer_api.c"]
        render_transfer_vk_transfer_loop_c["render/transfer/vk_transfer_loop.c"]
    end
    generated_shared_structs_h --> generated_net_constants_h
    generated_shared_structs_h --> generated_net_ffi_bridge_h
    generated_shared_structs_h --> generated_net_rollback_memory_h
    generated_shared_structs_h --> generated_net_wire_packets_h
    generated_shared_structs_h --> generated_net_world_state_h
    host_boot_main_c --> generated_ssot_render_h
    host_boot_main_c --> generated_ssot_types_h
    host_boot_main_c --> host_boot_lifecycle_c
    host_boot_main_c --> host_ipc_mailbox_c
    host_boot_main_c --> host_ipc_ring_stream_c
    host_boot_main_c --> host_ipc_sys_sync_c
    host_boot_main_c --> host_lua_lua_vm_c
    host_boot_main_c --> host_runtime_main_loop_c
    host_boot_main_c --> host_state_state_globals_c
    host_boot_main_c --> host_state_state_types_c
    host_boot_main_c --> host_tenant_tenant_callbacks_key_c
    host_boot_main_c --> host_tenant_tenant_callbacks_mouse_c
    host_boot_main_c --> host_tenant_tenant_callbacks_state_c
    host_boot_main_c --> host_tenant_tenant_input_c
    host_boot_main_c --> host_tenant_tenant_sys_c
    host_boot_main_c --> host_threading_thread_lifecycle_c
    host_boot_main_c --> host_threading_thread_pool_c
    host_boot_main_c --> render_debug_vk_debug_c
    host_boot_main_c --> render_gpu_vk_draw_c
    host_boot_main_c --> render_gpu_vk_record_c
    host_boot_main_c --> render_gpu_vk_render_loop_c
    host_boot_main_c --> render_tenant_vk_tenant_alloc_c
    host_boot_main_c --> render_transfer_vk_transfer_api_c
    host_boot_main_c --> render_transfer_vk_transfer_loop_c
    host_boot_main_headless_c --> host_ipc_sys_sync_c
    network_transport_vx_net_internal_h --> generated_shared_structs_h
    network_transport_vx_net_io_c --> network_transport_vx_net_internal_h
    network_transport_vx_net_state_c --> network_transport_vx_net_internal_h
    network_transport_vx_net_stun_c --> network_transport_vx_net_internal_h
```
