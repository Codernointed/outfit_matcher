import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionHandlerService {
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> requestPhotosPermission() async {
    // On Android, photos permission can be tricky (SDK levels)
    // Permission.photos grants access to the entire library (Android 10+)
    // Permission.storage might be needed for older Android versions or broader access
    // For simplicity, using Permission.photos for now.
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  Future<bool> requestNotificationsPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  // Helper to show a dialog if permission is permanently denied
  Future<void> showPermissionDeniedDialog(
    BuildContext context,
    String permissionName,
    String rationale,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('$permissionName Permission Denied'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(rationale),
                const Text(
                  'Please enable this permission in app settings to use this feature.',
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                openAppSettings();
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<PermissionStatus> getCameraPermissionStatus() async {
    return await Permission.camera.status;
  }

  Future<PermissionStatus> getPhotosPermissionStatus() async {
    return await Permission.photos.status;
  }
}
