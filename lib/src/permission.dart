// import 'package:flutter/material.dart';
// import 'package:permission_handler/permission_handler.dart';

// class PermissionUtil {
//   static Set checkedPermissions = {};

//   /// 检查并请求麦克风权限
//   static Future<bool> checkMicrophone(BuildContext context) async {
//     final status = await Permission.microphone.status;
//     if (status.isGranted) return true;
//     final result = await Permission.microphone.request();
//     if (result.isGranted) return true;
//     if (result.isPermanentlyDenied) {
//       _showPermissionDialog(context, '麦克风');
//     }
//     return false;
//   }

//   /// 检查并请求相机权限
//   static Future<bool> checkCamera(BuildContext context) async {
//     final status = await Permission.camera.status;
//     if (status.isGranted) return true;
//     if (status.isPermanentlyDenied) {
//       _showPermissionDialog(context, '相机');
//       return false;
//     }
//     final result = await Permission.camera.request();
//     if (result.isGranted) return true;
//     if (result.isPermanentlyDenied) {
//       _showPermissionDialog(context, '相机');
//     }
//     return false;
//   }

//   /// 检查并请求存储权限
//   static Future<bool> checkStorage(BuildContext context) async {
//     final status = await Permission.storage.status;
//     if (status.isGranted) return true;
//     if (status.isPermanentlyDenied) {
//       _showPermissionDialog(context, '存储');
//       return false;
//     }
//     final result = await Permission.storage.request();
//     if (result.isGranted) return true;
//     if (result.isPermanentlyDenied) {
//       _showPermissionDialog(context, '存储');
//     }
//     return false;
//   }

//   /// 检查语音识别请求权限
//   static Future<bool> checkMicAndSpeeh(BuildContext context) async {
//     bool ok = await PermissionUtil.requestPermissions(context, [Permission.microphone, Permission.speech]);
//     return ok;
//   }

//   /// 组合权限请求
//   static Future<bool> requestPermissions(BuildContext context, List<Permission> permissions, {String? permissionDesc}) async {
//     List<String> waitCheckPermissions = permissions.map((e) => e.value.toString()).toList();
//     bool firstCheck = !waitCheckPermissions.any((element) => checkedPermissions.contains(element));
//     checkedPermissions.addAll(waitCheckPermissions);
//     // 先检查所有权限状态
//     Map<Permission, PermissionStatus> statuses = await permissions.request();
//     // 检查是否全部授权
//     bool allGranted = statuses.values.every((status) => status.isGranted);
//     if (allGranted) return true;

//     // 找到第一个被永久拒绝的权限
//     Permission? deniedPerm;
//     for (var entry in statuses.entries) {
//       final status = entry.value;
//       if (!status.isGranted) {
//         deniedPerm = entry.key;
//         break;
//       }
//     }

//     if (deniedPerm != null && !firstCheck) {
//       String name = _permissionName(deniedPerm);

//       _showPermissionDialog(context, name.isNotEmpty ? name : (permissionDesc ?? '相关'));
//     }
//     return false;
//   }

//   /// 权限类型转中文名
//   static String _permissionName(Permission permission) {
//     switch (permission) {
//       case Permission.microphone:
//         return '麦克风';
//       case Permission.camera:
//         return '相机';
//       case Permission.storage:
//         return '存储';
//       case Permission.photos:
//         return '相册';
//       default:
//         return '';
//     }
//   }

//   /// 通用权限弹窗
//   static void _showPermissionDialog(BuildContext context, String permissionName) {
//     // XMAlert.show(
//     //   context: context,
//     //   content: '需要$permissionName权限才能正常使用该功能，请前往设置开启权限。',
//     //   cancelText: '取消',
//     //   confirmText: '去设置',
//     //   onConfirm: () async {
//     //     await openAppSettings();
//     //   },
//     // );
//   }
// }
