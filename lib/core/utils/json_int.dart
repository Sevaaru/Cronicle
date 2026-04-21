/// Enteros desde JSON/Dio/GraphQL: a veces llegan como [num] (p. ej. double).
int jsonInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.round();
  return int.tryParse(v.toString()) ?? 0;
}
