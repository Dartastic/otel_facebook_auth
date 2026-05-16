// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_facebook_auth/otel_facebook_auth.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_facebook_auth-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('login records limited_login + permissions split', () async {
    await tracedFacebookAuth<String>(
      operation: 'login',
      invoke: () async => const FacebookAuthCallResult(
        value: 'ok',
        result: FacebookAuthResult(
          appId: '1234567890',
          userId: 'u_1',
          isLimitedLogin: true,
          loginTracking: 'limited',
          permissionsGranted: ['public_profile', 'email'],
          permissionsDeclined: ['user_friends'],
          permissionsRequested: ['public_profile', 'email', 'user_friends'],
          statusCode: 'success',
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('facebook_auth login')!);
    expect(a['facebook_auth.limited_login'], true);
    expect(a['facebook_auth.permissions.granted.count'], 2);
    expect(a['facebook_auth.permissions.declined.count'], 1);
  });

  test('failed status sets span error', () async {
    await tracedFacebookAuth<String>(
      operation: 'login',
      invoke: () async => const FacebookAuthCallResult(
        value: 'ok',
        result: FacebookAuthResult(statusCode: 'failed'),
      ),
    );
    expect(
      spans.findSpanByName('facebook_auth login')!.status,
      SpanStatusCode.Error,
    );
  });

  test('cancelled does NOT set span error', () async {
    await tracedFacebookAuth<String>(
      operation: 'login',
      invoke: () async => const FacebookAuthCallResult(
        value: 'ok',
        result: FacebookAuthResult(statusCode: 'cancelled'),
      ),
    );
    expect(
      spans.findSpanByName('facebook_auth login')!.status,
      isNot(SpanStatusCode.Error),
    );
  });

  test('suppression skips spans', () async {
    await runWithoutFacebookAuthInstrumentationAsync(() async {
      await tracedFacebookAuth<String>(
        operation: 'logOut',
        invoke: () async => const FacebookAuthCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('facebook_auth '), isEmpty);
  });
}
