import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../utility/constants/message/exception.dart';
import '../widgets/snackbar.dart';

class NetworkController extends GetxController {
  RxBool isConnected = false.obs;
  RxBool isCheckingConnection = false.obs;

  final InternetConnection _internetConnection =
      InternetConnection.createInstance();
  StreamSubscription? _connectivitySubscription;

  Future<bool> checkConnection() async {
    if (isCheckingConnection.value) return isConnected.value;

    isCheckingConnection.value = true;
    try {
      final hasConnection = await _internetConnection.hasInternetAccess;

      isConnected.value = hasConnection;

      return hasConnection;
    } catch (e) {
      if (e is SocketException) {
        AppSnackbar(
          message: ExceptionMessage.CONNECTION_ERROR.tr,
          messageType: SnackbarMessageType.ERROR,
        ).show();
      } else if (e is TimeoutException) {
        AppSnackbar(
          message: ExceptionMessage.CONNECTION_TIMEOUT.tr,
          messageType: SnackbarMessageType.ERROR,
        ).show();
      } else {
        AppSnackbar(
          message: ExceptionMessage.NO_INTERNET.tr,
          messageType: SnackbarMessageType.ERROR,
        ).show();
      }
      isConnected.value = false;
      return false;
    } finally {
      isCheckingConnection.value = false;
    }
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = _internetConnection.onStatusChange
        .listen((InternetStatus status) async {
      await Future.delayed(const Duration(seconds: 1));

      if (status == InternetStatus.disconnected) {
        await checkConnection();
      }
    });
  }

  @override
  void onInit() {
    checkConnection();
    _setupConnectivityListener();
    super.onInit();
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }
}
