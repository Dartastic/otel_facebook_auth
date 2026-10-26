// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_facebook_auth_suppression.dart';

const _tracerName = 'dartastic_otel_libs_facebook_auth';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

class FacebookAuthResult {
  /// Creates a result.
  const FacebookAuthResult({
    this.appId,
    this.userId,
    this.loginBehavior,
    this.loginTracking,
    this.permissionsGranted,
    this.permissionsDeclined,
    this.permissionsRequested,
    this.isExpired,
    this.isLimitedLogin,
    this.dataAccessExpirationTime,
    this.statusCode,
    this.statusMessage,
  });

  /// Facebook App ID.
  final String? appId;

  /// Facebook user id (graph id).
  final String? userId;

  /// `native_with_fallback`, `native_only`, `web_only`, `web_view_only`,
  /// `dialog_only`.
  final String? loginBehavior;

  /// iOS Limited Login tracking: `limited` / `enabled`.
  final String? loginTracking;

  final List<String>? permissionsGranted;
  final List<String>? permissionsDeclined;
  final List<String>? permissionsRequested;

  final bool? isExpired;

  /// iOS 17+ Limited Login (no marketing id, ATT-friendly).
  final bool? isLimitedLogin;

  /// Unix seconds when data-access window expires (90 days inactivity).
  final int? dataAccessExpirationTime;

  /// `success`, `cancelled`, `failed`, `operationInProgress`.
  final String? statusCode;
  final String? statusMessage;
}

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class FacebookAuthCallResult<T> {
  /// Creates a call result.
  const FacebookAuthCallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final FacebookAuthResult? result;
}

/// Wraps a Meta Login call in a CLIENT span. [operation] is one of
/// `login`, `loginWithFacebookLoginButton`, `logOut`, `getUserData`,
/// `accessToken`, `isLoggedIn`, `expressLogin`,
/// `webAndOSAuthentication`, `getRecentlyUsed`, `setUserData`,
/// `setDataProcessingOptions`, `getAuthenticationToken`,
/// `getProfileInformation`, `requestTrackingAuthorization`.
Future<T> tracedFacebookAuth<T>({
  required String operation,
  required Future<FacebookAuthCallResult<T>> Function() invoke,
}) async {
  if (facebookAuthInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'facebook_auth',
    'rpc.method': operation,
    'facebook_auth.operation': operation,
  };

  final span = _tracer().startSpan(
    'facebook_auth $operation',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final res = r.result!;
      final extras = <Attribute<Object>>[];
      if (res.appId != null) {
        extras.add(OTelAPI.attributeString('facebook_auth.app.id', res.appId!));
      }
      if (res.userId != null) {
        extras
            .add(OTelAPI.attributeString('facebook_auth.user.id', res.userId!));
      }
      if (res.loginBehavior != null) {
        extras.add(OTelAPI.attributeString(
          'facebook_auth.login.behavior',
          res.loginBehavior!,
        ));
      }
      if (res.loginTracking != null) {
        extras.add(OTelAPI.attributeString(
          'facebook_auth.login.tracking',
          res.loginTracking!,
        ));
      }
      if (res.permissionsGranted != null) {
        extras.add(OTelAPI.attributeStringList(
          'facebook_auth.permissions.granted',
          res.permissionsGranted!,
        ));
        extras.add(OTelAPI.attributeInt(
          'facebook_auth.permissions.granted.count',
          res.permissionsGranted!.length,
        ));
      }
      if (res.permissionsDeclined != null) {
        extras.add(OTelAPI.attributeStringList(
          'facebook_auth.permissions.declined',
          res.permissionsDeclined!,
        ));
        extras.add(OTelAPI.attributeInt(
          'facebook_auth.permissions.declined.count',
          res.permissionsDeclined!.length,
        ));
      }
      if (res.permissionsRequested != null) {
        extras.add(OTelAPI.attributeStringList(
          'facebook_auth.permissions.requested',
          res.permissionsRequested!,
        ));
      }
      if (res.isExpired != null) {
        extras.add(OTelAPI.attributeBool(
          'facebook_auth.token.expired',
          res.isExpired!,
        ));
      }
      if (res.isLimitedLogin != null) {
        extras.add(OTelAPI.attributeBool(
          'facebook_auth.limited_login',
          res.isLimitedLogin!,
        ));
      }
      if (res.dataAccessExpirationTime != null) {
        extras.add(OTelAPI.attributeInt(
          'facebook_auth.data_access.expires_at_sec',
          res.dataAccessExpirationTime!,
        ));
      }
      if (res.statusCode != null) {
        extras.add(OTelAPI.attributeString(
          'facebook_auth.status',
          res.statusCode!,
        ));
        if (res.statusCode == 'failed') {
          span.setStatus(SpanStatusCode.Error, 'Facebook login failed');
        }
      }
      if (res.statusMessage != null) {
        extras.add(OTelAPI.attributeString(
          'facebook_auth.status.message',
          res.statusMessage!,
        ));
      }
      if (extras.isNotEmpty) span.addAttributes(OTelAPI.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
