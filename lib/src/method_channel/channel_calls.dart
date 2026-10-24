import 'package:flutter/services.dart';

import '../models/window_operation_result.dart';
import 'failure_codes.dart';

/// Invokes [method] for a result-typed call and turns every reply into an [R].
///
/// A map reply goes through [parse], a bool reply through [fromBool] when
/// given. A `null` reply or one of any other type becomes [unknown] with the
/// standard message. A [PlatformException] with a code in [systemErrorCodes]
/// is rethrown; any other becomes [fromException].
Future<R> invokeResult<R>(
  MethodChannel channel,
  String method, {
  Object? arguments,
  required R Function(Map<dynamic, dynamic> reply) parse,
  required R Function(PlatformException e) fromException,
  required R Function(String message) unknown,
  R Function(bool reply)? fromBool,
}) async {
  try {
    final reply = await channel.invokeMethod<Object?>(method, arguments);
    if (reply == null) return unknown('No response from $method');
    if (reply is Map) return parse(reply);
    if (reply is bool && fromBool != null) return fromBool(reply);
    return unknown('Unexpected response from $method');
  } on PlatformException catch (e) {
    if (systemErrorCodes.contains(e.code)) rethrow;
    return fromException(e);
  }
}

/// Invokes [method] for a list call and parses each item through [fromMap],
/// after converting it, nested maps included, to a string-keyed map.
///
/// A `null` reply is an empty list.
Future<List<T>> invokeList<T>(
  MethodChannel channel,
  String method,
  T Function(Map<String, dynamic> map) fromMap, {
  Object? arguments,
}) async {
  final reply = await channel.invokeMethod<List<dynamic>>(method, arguments);
  if (reply == null) return [];
  return reply.map((item) => fromMap(stringKeyed(item as Map))).toList();
}

/// [map] with string keys, its nested maps converted the same way.
Map<String, dynamic> stringKeyed(Map<dynamic, dynamic> map) {
  return map.map(
    (key, value) =>
        MapEntry(key.toString(), value is Map ? stringKeyed(value) : value),
  );
}

/// Invokes [method] for a window or process operation.
///
/// Its reply is a `{"success": …}` state map or a bool.
Future<WindowOperationResult> invokeOperation(
  MethodChannel channel,
  String method,
  Map<String, dynamic> arguments,
) {
  return invokeResult(
    channel,
    method,
    arguments: arguments,
    parse: (reply) => (reply['success'] as bool? ?? false)
        ? const OperationSuccess()
        : operationFailureFromState(reply),
    fromBool: (reply) => reply
        ? const OperationSuccess()
        : const OperationFailure(
            reason: WindowOperationFailureReason.unknown,
            message: 'Operation returned false',
          ),
    fromException: operationFailureFromException,
    unknown: (message) => OperationFailure(
      reason: WindowOperationFailureReason.unknown,
      message: message,
    ),
  );
}
