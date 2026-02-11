//
//  StellarVPNExtension-Bridging-Header.h
//  Linphone - StellarVPN Network Extension
//

#ifndef StellarVPNExtension_Bridging_Header_h
#define StellarVPNExtension_Bridging_Header_h

#include <stdint.h>

#include "xqc_configure.h"
#include "xqc_errno.h"
#include "xqc_http3.h"
#include "xqc_list.h"
#include "xquic.h"
#include "demo_client.h"

#include "WireGuardKitC.h"

void close_xquic_client();
void update_aggregation_mode(int agg_mode);

// Multipath path count - check before force-closing on network change
int xquic_get_active_path_count(void);

// Memory pressure feedback from Swift to C
// level: 0=OK (<60%), 1=WARNING (60-80%), 2=CRITICAL (>80%)
void xquic_set_memory_pressure(int level);
int xquic_get_memory_pressure(void);
uint64_t xquic_get_memory_backpressure(void);

// Send queue stats for memory monitoring
// Returns 0 on success, -1 if no connection
int xquic_get_sendq_stats(uint64_t *packets_used, uint64_t *packets_free, uint64_t *packets_max);

#endif
