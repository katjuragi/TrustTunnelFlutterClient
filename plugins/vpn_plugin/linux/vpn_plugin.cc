#include "include/vpn_plugin/vpn_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <glib-object.h>
#include <gtk/gtk.h>

#include <string.h>

typedef enum {
  VPN_STATE_DISCONNECTED = 0,
  VPN_STATE_CONNECTING   = 1,
  VPN_STATE_CONNECTED    = 2,
} VpnState;

typedef enum {
  ROUTING_MODE_VPN    = 0,
  ROUTING_MODE_BYPASS = 1,
} RoutingMode;

typedef enum {
  VPN_PROTO_QUIC  = 0,
  VPN_PROTO_HTTP2 = 1,
} VpnProtocol;

typedef struct {
  gint64  id;
  gchar*  ip_address;
  gchar*  domain;
  gchar*  login;
  gchar*  password;
  GPtrArray* dns_servers;
  gint64  routing_profile_id;
  VpnProtocol vpn_protocol;
} Server;

typedef struct {
  gint64  id;
  gchar*  name;
  RoutingMode default_mode;
  GPtrArray* bypass_rules;
  GPtrArray* vpn_rules;
} RoutingProfile;

typedef struct {
  gchar* zoned_date_time;
  gchar* protocol_name;
  RoutingMode decision;
  gchar* source_ip_address;
  gchar* destination_ip_address;
  gchar* source_port;
  gchar* destination_port;
  gchar* domain;
} VpnRequest;

typedef struct {
  GPtrArray* servers;
  GPtrArray* routing_profiles;
  gboolean   has_selected_server;
  gint64     selected_server_id;
  gchar*     excluded_routes;
  VpnState   vpn_state;
  GPtrArray* requests;
} MockStorage;


static gchar* g_strdup_or_empty(const gchar* s) { return g_strdup(s ? s : ""); }

static void string_array_free(GPtrArray* arr) {
  if (!arr) return;
  for (guint i = 0; i < arr->len; i++) g_free(g_ptr_array_index(arr, i));
  g_ptr_array_free(arr, TRUE);
}

static GPtrArray* string_split_csv(const gchar* csv, const gchar* delim) {
  GPtrArray* out = g_ptr_array_new_with_free_func(g_free);
  if (!csv || !*csv) return out;
  gchar** parts = g_strsplit(csv, delim, -1);
  for (gchar** p = parts; p && *p; ++p) {
    gchar* trimmed = g_strstrip(g_strdup(*p));
    if (trimmed && *trimmed) g_ptr_array_add(out, trimmed);
    else g_free(trimmed);
  }
  g_strfreev(parts);
  return out;
}

static gboolean is_valid_ipv4(const gchar* ip) {
  if (!ip) return FALSE;
  gchar** parts = g_strsplit(ip, ".", 4);
  int count = 0; gboolean ok = TRUE;
  for (gchar** p = parts; p && *p; ++p) {
    count++;
    char* end = NULL;
    long v = strtol(*p, &end, 10);
    if (end == *p || *end != '\0' || v < 0 || v > 255) { ok = FALSE; break; }
  }
  if (count != 4) ok = FALSE;
  g_strfreev(parts);
  return ok;
}

static Server* server_new(gint64 id, const gchar* ip, const gchar* domain,
                          const gchar* login, const gchar* pass,
                          GPtrArray* dns, VpnProtocol proto, gint64 profile_id) {
  Server* s = g_new0(Server, 1);
  s->id = id;
  s->ip_address = g_strdup_or_empty(ip);
  s->domain = g_strdup_or_empty(domain);
  s->login = g_strdup_or_empty(login);
  s->password = g_strdup_or_empty(pass);
  s->dns_servers = dns ? dns : g_ptr_array_new_with_free_func(g_free);
  s->vpn_protocol = proto;
  s->routing_profile_id = profile_id;
  return s;
}

static void server_free(Server* s) {
  if (!s) return;
  g_free(s->ip_address);
  g_free(s->domain);
  g_free(s->login);
  g_free(s->password);
  string_array_free(s->dns_servers);
  g_free(s);
}

static RoutingProfile* profile_new(gint64 id, const gchar* name, RoutingMode mode,
                                   GPtrArray* bypass, GPtrArray* vpn) {
  RoutingProfile* p = g_new0(RoutingProfile, 1);
  p->id = id;
  p->name = g_strdup_or_empty(name);
  p->default_mode = mode;
  p->bypass_rules = bypass ? bypass : g_ptr_array_new_with_free_func(g_free);
  p->vpn_rules = vpn ? vpn : g_ptr_array_new_with_free_func(g_free);
  return p;
}
static void profile_free(RoutingProfile* p) {
  if (!p) return;
  g_free(p->name);
  string_array_free(p->bypass_rules);
  string_array_free(p->vpn_rules);
  g_free(p);
}

static VpnRequest* request_new(const gchar* zdt, const gchar* proto, RoutingMode decision,
                               const gchar* sip, const gchar* dip,
                               const gchar* sport, const gchar* dport, const gchar* domain) {
  VpnRequest* r = g_new0(VpnRequest, 1);
  r->zoned_date_time = g_strdup_or_empty(zdt);
  r->protocol_name = g_strdup_or_empty(proto);
  r->decision = decision;
  r->source_ip_address = g_strdup_or_empty(sip);
  r->destination_ip_address = g_strdup_or_empty(dip);
  r->source_port = g_strdup_or_empty(sport);
  r->destination_port = g_strdup_or_empty(dport);
  r->domain = g_strdup_or_empty(domain);
  return r;
}
static void request_free(VpnRequest* r) {
  if (!r) return;
  g_free(r->zoned_date_time);
  g_free(r->protocol_name);
  g_free(r->source_ip_address);
  g_free(r->destination_ip_address);
  g_free(r->source_port);
  g_free(r->destination_port);
  g_free(r->domain);
  g_free(r);
}

static MockStorage* storage_new(void) {
  MockStorage* m = g_new0(MockStorage, 1);
  m->servers = g_ptr_array_new_with_free_func((GDestroyNotify)server_free);
  m->routing_profiles = g_ptr_array_new_with_free_func((GDestroyNotify)profile_free);
  m->requests = g_ptr_array_new_with_free_func((GDestroyNotify)request_free);
  m->excluded_routes = g_strdup("");
  m->vpn_state = VPN_STATE_DISCONNECTED;

  // profiles
  g_ptr_array_add(m->routing_profiles, profile_new(
    1, "Default Profile", ROUTING_MODE_VPN,
    string_split_csv("192.168.1.0/24,10.0.0.0/8", ","),
    string_split_csv("*", ",")
  ));
  g_ptr_array_add(m->routing_profiles, profile_new(
    2, "Work Profile", ROUTING_MODE_BYPASS,
    string_split_csv("company.com,*.internal", ","),
    string_split_csv("social.com,*.entertainment", ",")
  ));

  // servers
  g_ptr_array_add(m->servers, server_new(
    1, "192.168.1.100", "vpn1.example.com", "user1", "password1",
    string_split_csv("8.8.8.8,8.8.4.4", ","), VPN_PROTO_QUIC, 1
  ));
  g_ptr_array_add(m->servers, server_new(
    2, "10.0.0.50", "vpn2.example.com", "user2", "password2",
    string_split_csv("1.1.1.1,1.0.0.1", ","), VPN_PROTO_HTTP2, 2
  ));

  m->has_selected_server = TRUE;
  m->selected_server_id = 1;
  g_free(m->excluded_routes);
  m->excluded_routes = g_strdup("192.168.0.0/16,10.0.0.0/8");

  // requests
  g_ptr_array_add(m->requests, request_new(
    "2024-08-22T12:00:00Z", "HTTPS", ROUTING_MODE_VPN,
    "192.168.1.10", "8.8.8.8", "54321", "443", "google.com"
  ));

  return m;
}

static void storage_free(MockStorage* m) {
  if (!m) return;
  g_ptr_array_free(m->servers, TRUE);
  g_ptr_array_free(m->routing_profiles, TRUE);
  g_ptr_array_free(m->requests, TRUE);
  g_free(m->excluded_routes);
  g_free(m);
}


struct _VpnPlugin {
  GObject parent_instance;

  MockStorage* storage;

  // EventChannel: vpn_plugin_event_channel
  FlEventChannel* event_channel;
  FlEventSink* event_sink;

  // MethodChannels
  FlMethodChannel* ch_ivpn;
  FlMethodChannel* ch_storage;
  FlMethodChannel* ch_servers;
  FlMethodChannel* ch_routing;

  guint connect_timeout_id;
};

G_DEFINE_TYPE(VpnPlugin, vpn_plugin, g_object_get_type())

// -------- EventChannel emit --------
static void emit_vpn_state(VpnPlugin* self, VpnState st) {
  if (!self->event_sink) return;
  FlValue* value = fl_value_new_int(st);
  fl_event_sink_send(self->event_sink, value, NULL);
}

// -------- IVpnManager handlers (MethodChannel "ivpn_manager") --------
static FlMethodResponse* ivpn_start(VpnPlugin* self) {
  self->storage->vpn_state = VPN_STATE_CONNECTING;
  emit_vpn_state(self, self->storage->vpn_state);

  if (self->connect_timeout_id) g_source_remove(self->connect_timeout_id);
  self->connect_timeout_id = g_timeout_add(2000, (GSourceFunc) (^(gpointer data) -> gboolean {
    VpnPlugin* plugin = (VpnPlugin*)data;
    plugin->storage->vpn_state = VPN_STATE_CONNECTED;
    emit_vpn_state(plugin, plugin->storage->vpn_state);
    plugin->connect_timeout_id = 0;
    return G_SOURCE_REMOVE;
  }), self);

  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_null()));
}

static FlMethodResponse* ivpn_stop(VpnPlugin* self) {
  if (self->connect_timeout_id) { g_source_remove(self->connect_timeout_id); self->connect_timeout_id = 0; }
  self->storage->vpn_state = VPN_STATE_DISCONNECTED;
  emit_vpn_state(self, self->storage->vpn_state);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_null()));
}

static FlMethodResponse* ivpn_get_state(VpnPlugin* self) {
  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_int(self->storage->vpn_state)));
}

static void ivpn_method_cb(FlMethodChannel* channel, FlMethodCall* call, gpointer user_data) {
  VpnPlugin* self = VPN_PLUGIN(user_data);
  const gchar* method = fl_method_call_get_name(call);
  g_autoptr(FlMethodResponse) resp = NULL;

  if (g_strcmp0(method, "start") == 0) resp = ivpn_start(self);
  else if (g_strcmp0(method, "stop") == 0) resp = ivpn_stop(self);
  else if (g_strcmp0(method, "getCurrentState") == 0) resp = ivpn_get_state(self);
  else resp = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());

  fl_method_call_respond(call, resp, NULL);
}

// -------- StorageManager ("storage_manager") --------
static FlMethodResponse* storage_get_servers(VpnPlugin* self) {
  FlValue* list = fl_value_new_list();
  for (guint i = 0; i < self->storage->servers->len; i++) {
    Server* s = g_ptr_array_index(self->storage->servers, i);
    FlValue* m = fl_value_new_map();
    fl_value_set_string_take(m, "id", fl_value_new_int(s->id));
    fl_value_set_string_take(m, "ipAddress", fl_value_new_string(s->ip_address));
    fl_value_set_string_take(m, "domain", fl_value_new_string(s->domain));
    fl_value_set_string_take(m, "login", fl_value_new_string(s->login));
    fl_value_set_string_take(m, "password", fl_value_new_string(s->password));
    FlValue* dns = fl_value_new_list();
    for (guint d = 0; d < s->dns_servers->len; d++) {
      fl_value_append_take(dns, fl_value_new_string(g_ptr_array_index(s->dns_servers, d)));
    }
    fl_value_set_string_take(m, "dnsServers", dns);
    fl_value_set_string_take(m, "vpnProtocol", fl_value_new_int(s->vpn_protocol));
    fl_value_set_string_take(m, "routingProfileId", fl_value_new_int(s->routing_profile_id));
    fl_value_append_take(list, m);
  }
  return FL_METHOD_RESPONSE(fl_method_success_response_new(list));
}

static FlMethodResponse* storage_get_profiles(VpnPlugin* self) {
  FlValue* list = fl_value_new_list();
  for (guint i = 0; i < self->storage->routing_profiles->len; i++) {
    RoutingProfile* p = g_ptr_array_index(self->storage->routing_profiles, i);
    FlValue* m = fl_value_new_map();
    fl_value_set_string_take(m, "id", fl_value_new_int(p->id));
    fl_value_set_string_take(m, "name", fl_value_new_string(p->name));
    fl_value_set_string_take(m, "defaultMode", fl_value_new_int(p->default_mode));
    FlValue* bypass = fl_value_new_list();
    for (guint b = 0; b < p->bypass_rules->len; b++)
      fl_value_append_take(bypass, fl_value_new_string(g_ptr_array_index(p->bypass_rules, b)));
    fl_value_set_string_take(m, "bypassRules", bypass);

    FlValue* vpn = fl_value_new_list();
    for (guint b = 0; b < p->vpn_rules->len; b++)
      fl_value_append_take(vpn, fl_value_new_string(g_ptr_array_index(p->vpn_rules, b)));
    fl_value_set_string_take(m, "vpnRules", vpn);

    fl_value_append_take(list, m);
  }
  return FL_METHOD_RESPONSE(fl_method_success_response_new(list));
}

static FlMethodResponse* storage_get_selected_id(VpnPlugin* self) {
  if (!self->storage->has_selected_server)
    return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_null()));
  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_int(self->storage->selected_server_id)));
}

static FlMethodResponse* storage_set_selected_id(VpnPlugin* self, FlValue* args) {
  FlValue* v = fl_value_lookup_string(args, "id");
  if (!v || fl_value_get_type(v) != FL_VALUE_TYPE_INT) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new("bad-args", "id is required", NULL));
  }
  self->storage->has_selected_server = TRUE;
  self->storage->selected_server_id = fl_value_get_int(v);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_null()));
}

static FlMethodResponse* storage_get_excluded(VpnPlugin* self) {
  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_string(self->storage->excluded_routes)));
}

static FlMethodResponse* storage_set_excluded(VpnPlugin* self, FlValue* args) {
  FlValue* v = fl_value_lookup_string(args, "routes");
  const gchar* s = (v && fl_value_get_type(v) == FL_VALUE_TYPE_STRING) ? fl_value_get_string(v) : "";
  g_free(self->storage->excluded_routes);
  self->storage->excluded_routes = g_strdup_or_empty(s);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_null()));
}

static void storage_method_cb(FlMethodChannel* channel, FlMethodCall* call, gpointer user_data) {
  VpnPlugin* self = VPN_PLUGIN(user_data);
  const gchar* method = fl_method_call_get_name(call);
  FlValue* args = fl_method_call_get_args(call);
  g_autoptr(FlMethodResponse) resp = NULL;

  if (g_strcmp0(method, "getAllServers") == 0) resp = storage_get_servers(self);
  else if (g_strcmp0(method, "getRoutingProfiles") == 0) resp = storage_get_profiles(self);
  else if (g_strcmp0(method, "getSelectedServerId") == 0) resp = storage_get_selected_id(self);
  else if (g_strcmp0(method, "setSelectedServerId") == 0) resp = storage_set_selected_id(self, args);
  else if (g_strcmp0(method, "getExcludedRoutes") == 0) resp = storage_get_excluded(self);
  else if (g_strcmp0(method, "setExcludedRoutes") == 0) resp = storage_set_excluded(self, args);
  else resp = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());

  fl_method_call_respond(call, resp, NULL);
}

// -------- ServersManager ("servers_manager") --------
static FlMethodResponse* servers_add(VpnPlugin* self, FlValue* args) {
  const gchar* ip        = fl_value_get_string(fl_value_lookup_string(args, "ipAddress"));
  const gchar* domain    = fl_value_get_string(fl_value_lookup_string(args, "domain"));
  const gchar* username  = fl_value_get_string(fl_value_lookup_string(args, "username"));
  const gchar* password  = fl_value_get_string(fl_value_lookup_string(args, "password"));
  gint64 profile_id      = fl_value_get_int(fl_value_lookup_string(args, "routingProfileId"));
  gint   proto           = fl_value_get_int(fl_value_lookup_string(args, "protocol"));
  const gchar* dns_csv   = fl_value_get_string(fl_value_lookup_string(args, "dnsServers"));

  if (!ip || !is_valid_ipv4(ip)) return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_int(1))); // ip incorrect
  if (!domain || !*domain) return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_int(2)));
  if (!username || !*username) return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_int(3)));
  if (!password || !*password) return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_int(4)));

  GPtrArray* dns = string_split_csv(dns_csv, ",");
  if (dns->len == 0) { string_array_free(dns); return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_int(5))); }

  // new id
  gint64 nid = 1;
  for (guint i = 0; i < self->storage->servers->len; i++) {
    Server* s = g_ptr_array_index(self->storage->servers, i);
    if (s->id >= nid) nid = s->id + 1;
  }
  g_ptr_array_add(self->storage->servers, server_new(nid, ip, domain, username, password, dns, (VpnProtocol)proto, profile_id));
  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_int(0))); // ok
}

static FlMethodResponse* servers_get_all(VpnPlugin* self) { return storage_get_servers(self); }

static FlMethodResponse* servers_set(VpnPlugin* self, FlValue* args) {
  gint64 id            = fl_value_get_int(fl_value_lookup_string(args, "id"));
  const gchar* ip      = fl_value_get_string(fl_value_lookup_string(args, "ipAddress"));
  const gchar* domain  = fl_value_get_string(fl_value_lookup_string(args, "domain"));
  const gchar* user    = fl_value_get_string(fl_value_lookup_string(args, "username"));
  const gchar* pass    = fl_value_get_string(fl_value_lookup_string(args, "password"));
  gint64 profile_id    = fl_value_get_int(fl_value_lookup_string(args, "routingProfileId"));
  gint   proto         = fl_value_get_int(fl_value_lookup_string(args, "protocol"));
  const gchar* dns_csv = fl_value_get_string(fl_value_lookup_string(args, "dnsServers"));

  if (!ip || !is_valid_ipv4(ip)) return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_int(1)));
  if (!domain || !*domain) return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_int(2)));
  if (!user || !*user) return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_int(3)));
  if (!pass || !*pass) return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_int(4)));

  GPtrArray* dns = string_split_csv(dns_csv, ",");
  if (dns->len == 0) { string_array_free(dns); return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_int(5))); }

  for (guint i = 0; i < self->storage->servers->len; i++) {
    Server* s = g_ptr_array_index(self->storage->servers, i);
    if (s->id == id) {
      Server* updated = server_new(id, ip, domain, user, pass, dns, (VpnProtocol)proto, profile_id);
      server_free(s);
      g_ptr_array_index(self->storage->servers, i) = updated;
      break;
    }
  }
  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_int(0)));
}

static FlMethodResponse* servers_set_selected(VpnPlugin* self, FlValue* args) {
  FlValue* v = fl_value_lookup_string(args, "id");
  if (!v || fl_value_get_type(v) != FL_VALUE_TYPE_INT)
    return FL_METHOD_RESPONSE(fl_method_error_response_new("bad-args","id required",NULL));
  self->storage->has_selected_server = TRUE;
  self->storage->selected_server_id = fl_value_get_int(v);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_null()));
}

static FlMethodResponse* servers_remove(VpnPlugin* self, FlValue* args) {
  FlValue* v = fl_value_lookup_string(args, "id");
  if (!v || fl_value_get_type(v) != FL_VALUE_TYPE_INT)
    return FL_METHOD_RESPONSE(fl_method_error_response_new("bad-args","id required",NULL));
  gint64 id = fl_value_get_int(v);

  for (guint i = 0; i < self->storage->servers->len; ) {
    Server* s = g_ptr_array_index(self->storage->servers, i);
    if (s->id == id) {
      server_free(s);
      g_ptr_array_remove_index_fast(self->storage->servers, i);
    } else { i++; }
  }
  if (self->storage->has_selected_server && self->storage->selected_server_id == id) {
    self->storage->has_selected_server = FALSE;
  }
  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_null()));
}

static void servers_method_cb(FlMethodChannel* channel, FlMethodCall* call, gpointer user_data) {
  VpnPlugin* self = VPN_PLUGIN(user_data);
  const gchar* method = fl_method_call_get_name(call);
  FlValue* args = fl_method_call_get_args(call);
  g_autoptr(FlMethodResponse) resp = NULL;

  if (g_strcmp0(method, "addNewServer") == 0) resp = servers_add(self, args);
  else if (g_strcmp0(method, "getAllServers") == 0) resp = servers_get_all(self);
  else if (g_strcmp0(method, "setNewServer") == 0) resp = servers_set(self, args);
  else if (g_strcmp0(method, "setSelectedServerId") == 0) resp = servers_set_selected(self, args);
  else if (g_strcmp0(method, "removeServer") == 0) resp = servers_remove(self, args);
  else resp = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());

  fl_method_call_respond(call, resp, NULL);
}

// -------- RoutingProfilesManager ("routing_profiles_manager") --------
static FlMethodResponse* routing_add_profile(VpnPlugin* self) {
  // new id
  gint64 nid = 1;
  for (guint i = 0; i < self->storage->routing_profiles->len; i++) {
    RoutingProfile* p = g_ptr_array_index(self->storage->routing_profiles, i);
    if (p->id >= nid) nid = p->id + 1;
  }
  g_ptr_array_add(self->storage->routing_profiles,
                  profile_new(nid, g_strdup_printf("Profile %ld", (long)nid),
                              ROUTING_MODE_VPN, NULL, NULL));
  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_null()));
}

static FlMethodResponse* routing_get_all(VpnPlugin* self) { return storage_get_profiles(self); }

static FlMethodResponse* routing_set_mode(VpnPlugin* self, FlValue* args) {
  gint64 id = fl_value_get_int(fl_value_lookup_string(args, "id"));
  gint   mode = fl_value_get_int(fl_value_lookup_string(args, "mode"));
  for (guint i = 0; i < self->storage->routing_profiles->len; i++) {
    RoutingProfile* p = g_ptr_array_index(self->storage->routing_profiles, i);
    if (p->id == id) { p->default_mode = (RoutingMode)mode; break; }
  }
  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_null()));
}

static FlMethodResponse* routing_set_name(VpnPlugin* self, FlValue* args) {
  gint64 id = fl_value_get_int(fl_value_lookup_string(args, "id"));
  const gchar* name = fl_value_get_string(fl_value_lookup_string(args, "name"));
  for (guint i = 0; i < self->storage->routing_profiles->len; i++) {
    RoutingProfile* p = g_ptr_array_index(self->storage->routing_profiles, i);
    if (p->id == id) { g_free(p->name); p->name = g_strdup_or_empty(name); break; }
  }
  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_null()));
}

static FlMethodResponse* routing_set_rules(VpnPlugin* self, FlValue* args) {
  gint64 id   = fl_value_get_int(fl_value_lookup_string(args, "id"));
  gint   mode = fl_value_get_int(fl_value_lookup_string(args, "mode"));
  const gchar* rules = fl_value_get_string(fl_value_lookup_string(args, "rules"));

  GPtrArray* arr = string_split_csv(rules, "\n");
  for (guint i = 0; i < self->storage->routing_profiles->len; i++) {
    RoutingProfile* p = g_ptr_array_index(self->storage->routing_profiles, i);
    if (p->id == id) {
      if (mode == ROUTING_MODE_BYPASS) { string_array_free(p->bypass_rules); p->bypass_rules = arr; }
      else { string_array_free(p->vpn_rules); p->vpn_rules = arr; }
      arr = NULL;
      break;
    }
  }
  if (arr) string_array_free(arr);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_null()));
}

static FlMethodResponse* routing_remove_all_rules(VpnPlugin* self, FlValue* args) {
  gint64 id = fl_value_get_int(fl_value_lookup_string(args, "id"));
  for (guint i = 0; i < self->storage->routing_profiles->len; i++) {
    RoutingProfile* p = g_ptr_array_index(self->storage->routing_profiles, i);
    if (p->id == id) {
      string_array_free(p->bypass_rules); p->bypass_rules = g_ptr_array_new_with_free_func(g_free);
      string_array_free(p->vpn_rules);    p->vpn_rules    = g_ptr_array_new_with_free_func(g_free);
      break;
    }
  }
  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_null()));
}

static void routing_method_cb(FlMethodChannel* channel, FlMethodCall* call, gpointer user_data) {
  VpnPlugin* self = VPN_PLUGIN(user_data);
  const gchar* method = fl_method_call_get_name(call);
  FlValue* args = fl_method_call_get_args(call);
  g_autoptr(FlMethodResponse) resp = NULL;

  if (g_strcmp0(method, "addNewProfile") == 0) resp = routing_add_profile(self);
  else if (g_strcmp0(method, "getAllProfiles") == 0) resp = routing_get_all(self);
  else if (g_strcmp0(method, "setDefaultRoutingMode") == 0) resp = routing_set_mode(self, args);
  else if (g_strcmp0(method, "setProfileName") == 0) resp = routing_set_name(self, args);
  else if (g_strcmp0(method, "setRules") == 0) resp = routing_set_rules(self, args);
  else if (g_strcmp0(method, "removeAllRules") == 0) resp = routing_remove_all_rules(self, args);
  else resp = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());

  fl_method_call_respond(call, resp, NULL);
}

// -------- EventChannel handler --------
static FlStreamHandle* on_event_listen(FlEventChannel* channel,
                                       FlValue* args,
                                       gpointer user_data) {
  VpnPlugin* self = VPN_PLUGIN(user_data);
  self->event_sink = fl_event_channel_create_stream(channel, NULL);
  emit_vpn_state(self, self->storage->vpn_state);
  return (FlStreamHandle*)self->event_sink;
}

static void on_event_cancel(FlEventChannel* channel, FlStreamHandle* handle, gpointer user_data) {
  VpnPlugin* self = VPN_PLUGIN(user_data);
  self->event_sink = NULL;
}

// -------- GObject lifecycle --------
static void vpn_plugin_dispose(GObject* object) {
  VpnPlugin* self = VPN_PLUGIN(object);
  if (self->connect_timeout_id) g_source_remove(self->connect_timeout_id);
  if (self->storage) { storage_free(self->storage); self->storage = NULL; }
  G_OBJECT_CLASS(vpn_plugin_parent_class)->dispose(object);
}

static void vpn_plugin_class_init(VpnPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = vpn_plugin_dispose;
}

static void vpn_plugin_init(VpnPlugin* self) {
  self->storage = storage_new();
  self->event_channel = NULL;
  self->event_sink = NULL;
  self->ch_ivpn = self->ch_storage = self->ch_servers = self->ch_routing = NULL;
  self->connect_timeout_id = 0;
}

void vpn_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  VpnPlugin* plugin = VPN_PLUGIN(g_object_new(vpn_plugin_get_type(), NULL));
  FlBinaryMessenger* messenger = fl_plugin_registrar_get_messenger(registrar);

  // EventChannel: vpn state
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  plugin->event_channel = fl_event_channel_new(messenger, "vpn_plugin_event_channel", FL_METHOD_CODEC(codec));
  fl_event_channel_set_stream_handlers(plugin->event_channel, on_event_listen, on_event_cancel, g_object_ref(plugin), g_object_unref);

  // MethodChannels
  plugin->ch_ivpn = fl_method_channel_new(messenger, "ivpn_manager", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(plugin->ch_ivpn, ivpn_method_cb, g_object_ref(plugin), g_object_unref);

  plugin->ch_storage = fl_method_channel_new(messenger, "storage_manager", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(plugin->ch_storage, storage_method_cb, g_object_ref(plugin), g_object_unref);

  plugin->ch_servers = fl_method_channel_new(messenger, "servers_manager", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(plugin->ch_servers, servers_method_cb, g_object_ref(plugin), g_object_unref);

  plugin->ch_routing = fl_method_channel_new(messenger, "routing_profiles_manager", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(plugin->ch_routing, routing_method_cb, g_object_ref(plugin), g_object_unref);

  g_object_unref(plugin);
}