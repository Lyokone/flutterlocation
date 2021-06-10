// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:location_platform_interface/location_platform_interface.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('$LocationPlatform', () {
    final LocationPlatform defaultInstance = LocationPlatform.instance;
    late ExtendsLocationPlatform locationPlatform;

    setUp(() {
      locationPlatform = ExtendsLocationPlatform();
    });

    tearDown(() {
      LocationPlatform.instance = defaultInstance;
    });

    test('$MethodChannelLocation is the default instance', () {
      expect(LocationPlatform.instance, isA<MethodChannelLocation>());
    });

    test('Cannot be implemented with `implements`', () {
      expect(() {
        LocationPlatform.instance = ImplementsLocationPlatform();
      }, throwsNoSuchMethodError);
    });

    test('Can be extended', () {
      LocationPlatform.instance = ExtendsLocationPlatform();
    });

    test('Can be mocked with `implements`', () {
      final MockLocationPlatform mock = MockLocationPlatform();
      LocationPlatform.instance = mock;
    });

    test(
        'Default implementation of changeSettings should throw unimplemented error',
        () {
      expect(
        () => locationPlatform.changeSettings(),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of isBackgroundModeEnabled should throw unimplemented error',
        () {
      expect(
        () => locationPlatform.isBackgroundModeEnabled(),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of enableBackgroundMode should throw unimplemented error',
        () {
      expect(
        () => locationPlatform.enableBackgroundMode(),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of getLocation should throw unimplemented error',
        () {
      expect(
        () => locationPlatform.getLocation(),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of hasPermission should throw unimplemented error',
        () {
      expect(
        () => locationPlatform.hasPermission(),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of requestPermission should throw unimplemented error',
        () {
      expect(
        () => locationPlatform.requestPermission(),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of serviceEnabled should throw unimplemented error',
        () {
      expect(
        () => locationPlatform.serviceEnabled(),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of requestService should throw unimplemented error',
        () {
      expect(
        () => locationPlatform.requestService(),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of onLocationChanged should throw unimplemented error',
        () {
      expect(
        () => locationPlatform.onLocationChanged,
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of changeNotificationOptions should throw unimplemented error',
        () {
      expect(
        () => locationPlatform.changeNotificationOptions(),
        throwsUnimplementedError,
      );
    });
  });
}

class ImplementsLocationPlatform implements LocationPlatform {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockLocationPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements LocationPlatform {}

class ExtendsLocationPlatform extends LocationPlatform {}
