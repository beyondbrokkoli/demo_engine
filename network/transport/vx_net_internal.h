/* network/transport/vx_net_internal.h */
#pragma once
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <stddef.h>

#include "../protocol/shared_structs.h"

#if defined(_WIN32)
    #define EXPORT __declspec(dllexport)
    #include <winsock2.h>
    #include <ws2tcpip.h>
    #include <mstcpip.h>
    #pragma comment(lib, "ws2_32.lib")
    typedef int socklen_t;
    typedef SSIZE_T ssize_t;
    typedef SOCKET vx_socket_t;
    #define NET_CLOSE closesocket
    #define NET_ERROR SOCKET_ERROR
    #define NET_INVALID INVALID_SOCKET
    #define NET_WOULDBLOCK WSAEWOULDBLOCK
    #define NET_LASTERR WSAGetLastError()
    #ifndef SIO_UDP_CONNRESET
        #define SIO_UDP_CONNRESET _WSAIOW(IOC_VENDOR, 12)
    #endif
#else
    #define EXPORT __attribute__((visibility("default")))
    #include <sys/socket.h>
    #include <netinet/in.h>
    #include <arpa/inet.h>
    #include <netdb.h>
    #include <fcntl.h>
    #include <unistd.h>
    #include <errno.h>
    typedef int vx_socket_t;
    #define NET_CLOSE close
    #define NET_ERROR -1
    #define NET_INVALID -1
    #define NET_WOULDBLOCK EWOULDBLOCK
    #define NET_LASTERR errno
#endif

typedef struct {
    struct sockaddr_in addr;
    socklen_t addr_len;
    int active;
} NetPeer;

typedef struct {
    vx_socket_t sock;
    uint64_t session_token;
    uint8_t local_id;
    NetPeer peers[8];
} NetContext;

// Expose the global state to the other chunks
extern NetContext g_net;
extern uint32_t g_relay_ip_addr;
