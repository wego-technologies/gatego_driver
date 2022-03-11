import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';

import 'package:background_locator/background_locator.dart';
import 'package:background_locator/location_dto.dart';
import 'package:background_locator/settings/android_settings.dart';
import 'package:background_locator/settings/ios_settings.dart';
import 'package:background_locator/settings/locator_settings.dart';
import 'package:flutter/material.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod/riverpod.dart';

import 'package:guard_app/providers/providers.dart';

class LocationState {
  bool isLocating;
  bool isPermissionGranted;
  bool isAwaitingPermissions;
  GeoCoordinates? latestCoordinates;

  LocationState(
      {required this.isLocating,
      required this.isPermissionGranted,
      required this.isAwaitingPermissions,
      this.latestCoordinates});

  LocationState copyWith({
    bool? isLocating,
    bool? isPermissionGranted,
    bool? isAwaitingPermissions,
    GeoCoordinates? latestCoordinates,
  }) {
    return LocationState(
      isLocating: isLocating ?? this.isLocating,
      isPermissionGranted: isPermissionGranted ?? this.isPermissionGranted,
      isAwaitingPermissions:
          isAwaitingPermissions ?? this.isAwaitingPermissions,
      latestCoordinates: latestCoordinates ?? this.latestCoordinates,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isLocating': isLocating,
      'isPermissionGranted': isPermissionGranted,
      'isAwaitingPermissions': isAwaitingPermissions,
      'latestCoordinates':
          "${latestCoordinates?.latitude}, ${latestCoordinates?.longitude}, ${latestCoordinates?.altitude}",
    };
  }

  factory LocationState.fromMap(Map<String, dynamic> map) {
    return LocationState(
      isLocating: map['isLocating'] ?? false,
      isPermissionGranted: map['isPermissionGranted'] ?? false,
      isAwaitingPermissions: map['isAwaitingPermissions'] ?? false,
      //latestCoordinates: map['latestCoordinates'] != null ? GeoCoordinates.fromMap(map['latestCoordinates']) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory LocationState.fromJson(String source) =>
      LocationState.fromMap(json.decode(source));

  @override
  String toString() {
    return 'LocationState(isLocating: $isLocating, isPermissionGranted: $isPermissionGranted, isAwaitingPermissions: $isAwaitingPermissions, latestCoordinates: $latestCoordinates)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LocationState &&
        other.isLocating == isLocating &&
        other.isPermissionGranted == isPermissionGranted &&
        other.isAwaitingPermissions == isAwaitingPermissions &&
        other.latestCoordinates == latestCoordinates;
  }

  @override
  int get hashCode {
    return isLocating.hashCode ^
        isPermissionGranted.hashCode ^
        isAwaitingPermissions.hashCode ^
        latestCoordinates.hashCode;
  }
}

class LocationProvider extends StateNotifier<LocationState> {
  LocationProvider(this.ref)
      : super(LocationState(
          isLocating: false,
          isPermissionGranted: false,
          isAwaitingPermissions: true,
        ));
  final Ref ref;

  ReceivePort port = ReceivePort();
  StreamController controller = StreamController();

  Future<bool> checkPremission() async {
    try {
      final premissionStatus = await Permission.locationAlways.status;
      if (premissionStatus.isGranted) {
        state = state.copyWith(isPermissionGranted: true);
        return true;
      } else if (state.isPermissionGranted) {
        state = state.copyWith(isPermissionGranted: false);
      }
      return false;
    } catch (e) {
      if (state.isPermissionGranted) {
        state = state.copyWith(isPermissionGranted: false);
      }
      return false;
    }
  }

  void launchPermission() {
    openAppSettings();
  }

  void beginTracking() {
    if (state.isLocating) return;
    BackgroundLocator.registerLocationUpdate(
      callback,
      initCallback: initCallback,
      initDataCallback: {},
      disposeCallback: disposedCallback,
      autoStop: false,
      iosSettings: const IOSSettings(
          accuracy: LocationAccuracy.NAVIGATION, distanceFilter: 0),
      androidSettings: const AndroidSettings(
        accuracy: LocationAccuracy.NAVIGATION,
        interval: 5,
        distanceFilter: 0,
        androidNotificationSettings: AndroidNotificationSettings(
          notificationChannelName: 'Location tracking',
          notificationTitle: 'Gatego Tracking',
          notificationMsg: 'Gatego is tracking your location',
          notificationBigMsg:
              'Background location is on to keep the gatego up-tp-date with your location. Click here to open the app and stop the tracking.',
          notificationIcon: '',
          notificationIconColor: Colors.grey,
          notificationTapCallback: notificationCallback,
        ),
      ),
    );
    state = state.copyWith(isLocating: true);
  }

  voidf 

  Future<void> initializeTracking() async {
    final isRegistered = await BackgroundLocator.isRegisterLocationUpdate();
    final isServiceRunning = await BackgroundLocator.isServiceRunning();

    if (!(isRegistered && isServiceRunning)) {
      IsolateNameServer.registerPortWithName(port.sendPort, isolateName);
    }
    await BackgroundLocator.initialize();

    state = state.copyWith(isLocating: isRegistered && isServiceRunning);
  }

  Future<void> stopAndDispose() async {
    IsolateNameServer.removePortNameMapping(isolateName);
    await BackgroundLocator.unRegisterLocationUpdate();
    port.close();
    state = state.copyWith(isLocating: false);
  }

  void handlLocationUpdates(dynamic data) {
    final locationData = data as LocationDto;
    print(locationData);
    ref.read(hereGeoCoords.state).state =
        GeoCoordinates(locationData.latitude, locationData.longitude);
  }

  static const String isolateName = "LocatorIsolate";
}

void callback(LocationDto locationDto) async {
  final SendPort? send =
      IsolateNameServer.lookupPortByName(LocationProvider.isolateName);
  send?.send(locationDto);
  print(locationDto);
}

//Optional
void notificationCallback() {
  print('User clicked on the notification');
}

void initCallback(Map<String, dynamic>? data) {
  print('Initialized');
}

void disposedCallback() {
  print('Disposed');
}
