// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_facebook_auth/otel_facebook_auth.dart';

/// Traces Meta Login calls with OpenTelemetry.
///
/// `otel_facebook_auth` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Meta Login call in
/// [tracedFacebookAuth]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'facebook-auth-example');

  // Wraps a Meta Login call in a CLIENT span.
  final facebookAuthId = await tracedFacebookAuth<String>(
    operation: 'create',
    invoke: () async {
      // Make the Meta Login call here, then report what it returned.
      const id = 'facebook_auth_8f3a2c';
      return const FacebookAuthCallResult(
          value: id,
          result: FacebookAuthResult(
              appId: 'app_8f3a2c',
              userId: 'user_8f3a2c',
              loginBehavior: 'native_with_fallback',
              loginTracking: 'limited',
              permissionsGranted: ['example'],
              permissionsDeclined: ['example'],
              permissionsRequested: ['example'],
              isExpired: true,
              isLimitedLogin: true,
              dataAccessExpirationTime: 1,
              statusCode: 'success',
              statusMessage: 'succeeded'));
    },
  );
  OTelLog.info('tracedFacebookAuth create returned $facebookAuthId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutFacebookAuthInstrumentationAsync.
  await runWithoutFacebookAuthInstrumentationAsync(
    () => tracedFacebookAuth<String>(
      operation: 'create',
      invoke: () async {
        const id = 'facebook_auth_8f3a2c';
        return const FacebookAuthCallResult(
            value: id,
            result: FacebookAuthResult(
                appId: 'app_8f3a2c',
                userId: 'user_8f3a2c',
                loginBehavior: 'native_with_fallback',
                loginTracking: 'limited',
                permissionsGranted: ['example'],
                permissionsDeclined: ['example'],
                permissionsRequested: ['example'],
                isExpired: true,
                isLimitedLogin: true,
                dataAccessExpirationTime: 1,
                statusCode: 'success',
                statusMessage: 'succeeded'));
      },
    ),
  );

  await OTel.shutdown();
}
