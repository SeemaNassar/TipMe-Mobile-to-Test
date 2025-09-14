//lib\services\tipReceiverService.dart
import 'dart:typed_data';
import 'package:tipme_app/core/dio/client/dio_client.dart';
import 'package:tipme_app/core/storage/storage_service.dart';
import 'package:tipme_app/dtos/paymentInfoDto.dart';
import 'package:tipme_app/dtos/fcmTokenDto.dart';
import 'package:tipme_app/viewModels/apiResponse.dart';
import 'package:tipme_app/viewModels/paymentInfoData.dart';
import 'package:tipme_app/viewModels/tipReceiveerData.dart';
import 'package:tipme_app/services/cacheService.dart';
import 'package:dio/dio.dart';

class TipReceiverService {
  final DioClient dioClient;
  final CacheService? cacheService;

  TipReceiverService(this.dioClient, {this.cacheService});

  Future<ApiResponse<TipReceiveerData>?> GetMe() async {
    String? user_id = await StorageService.get('user_id');
    if (user_id == null) {
      return null;
    }

    // Try to get from cache first
    if (cacheService != null) {
      final cachedUserData = cacheService!.getUserDataFromCache(user_id);
      if (cachedUserData != null) {
        return ApiResponse<TipReceiveerData>(
          success: true,
          message: 'User data loaded from cache',
          data: cachedUserData,
          errors: [],
          errorCode: null,
        );
      }
    }

    // If not in cache, fetch from server
    final response = await dioClient.get(
      user_id,
      options: Options(
        headers: {
          'Authorization': 'Bearer ${await StorageService.get("user_token")}',
        },
      ),
    );

    final apiResponse = ApiResponse<TipReceiveerData>.fromJson(
      response.data,
      (data) => TipReceiveerData.fromJson(data),
    );

    // Cache the fetched user data
    if (apiResponse.success &&
        apiResponse.data != null &&
        cacheService != null) {
      cacheService!.cacheUserData(user_id, apiResponse.data!);
    }

    return apiResponse;
  }

  Future<ApiResponse> GetPaymentInfo() async {
    String? user_id = await StorageService.get('user_id');
    if (user_id == null) {
      throw Exception('User ID not found');
    }
    final response = await dioClient.get(
      'PaymentInfo/$user_id',
      options: Options(
        headers: {
          'Authorization': 'Bearer ${await StorageService.get("user_token")}',
        },
      ),
    );
    return ApiResponse<PaymentInfoData>.fromJson(
      response.data,
      (data) => PaymentInfoData.fromJson(data),
    );
  }

  Future<ApiResponse<PaymentInfoData>> updatePaymentInfo(
      PaymentInfoDto dto) async {
    String? user_id = await StorageService.get('user_id');
    if (user_id == null) {
      throw Exception('User ID not found');
    }

    final response = await dioClient.put(
      'PaymentInfo/$user_id',
      data: dto.toJson(),
      options: Options(
        headers: {
          'Authorization': 'Bearer ${await StorageService.get("user_token")}',
        },
      ),
    );

    return ApiResponse<PaymentInfoData>.fromJson(
      response.data,
      (data) => PaymentInfoData.fromJson(data),
    );
  }

  Future<void> clearUserCache() async {
    if (cacheService != null) {
      final userId = await StorageService.get('user_id');
      if (userId != null) {
        cacheService!.clearUserDataCache(userId);
      }
    }
  }

  /// Gets profile image as file bytes from the server
  /// Returns null if imagePath is null/empty or if request fails
  Future<Uint8List?> getProfileImageAsFile(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return null;
    }

    try {
      final response = await dioClient.get(
        'File/$imagePath',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${await StorageService.get("user_token")}',
          },
          responseType: ResponseType.bytes,
        ),
      );

      return Uint8List.fromList(response.data);
    } catch (e) {
      print('Error fetching profile image: $e');
      return null;
    }
  }

  Future<ApiResponse<String>?> registerDevice(FcmTokenDto dto) async {
    try {
      String? userId = await StorageService.get('user_id');
      if (userId == null) {
        throw Exception('User ID not found');
      }
      final response = await dioClient.post(
        'RegisterDevice/$userId',
        data: dto.toJson(),
        options: Options(
          headers: {
            'Authorization': 'Bearer ${await StorageService.get("user_token")}',
            'Content-Type': 'application/json',
          },
        ),
      );

      return ApiResponse<String>.fromJson(
        response.data,
        (data) => data.toString(),
      );
    } catch (e) {
      print('Error registering device: $e');
      return ApiResponse<String>(
        success: false,
        message: 'Failed to register device: $e',
        data: null,
        errors: [e.toString()],
        errorCode: null,
      );
    }
  }

}
