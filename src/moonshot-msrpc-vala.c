/* Allocation functions required to bind the MSRPC interface to
 * Vala: these functions are required for all structs/classes that
 * are accessed from inside Vala.
 */

#include "moonshot-msrpc.h"

MoonshotRpcInterfaceIdentity *moonshot_rpc_interface_identity_new () {
    MoonshotRpcInterfaceIdentity *data = MIDL_user_allocate (sizeof (MoonshotRpcInterfaceIdentity));
    memset (data, 0, sizeof(MoonshotRpcInterfaceIdentity));
    return data;
}

void moonshot_rpc_interface_identity_free (MoonshotRpcInterfaceIdentity *data) {
    MIDL_user_free (data);
}
