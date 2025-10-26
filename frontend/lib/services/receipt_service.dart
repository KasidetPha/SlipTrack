import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:frontend/models/category_detail.dart';
import 'package:frontend/models/category_summary.dart';
import 'package:frontend/models/category_total.dart';
import 'package:frontend/models/first_Username_icon.dart';
import 'package:frontend/models/monthly_kind.dart';
import 'package:frontend/models/monthly_total.dart';
import 'package:frontend/models/receipt_item.dart';
import 'package:frontend/models/stats_summary.dart';
import 'package:frontend/services/api_client.dart';
import 'package:intl/intl.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode) : $message';
}

class ReceiptService {
  ReceiptService._();
  static final ReceiptService _i = ReceiptService._();
  factory ReceiptService() => _i;

  final Dio _dio = ApiClient().dio;

  // ดึงรายการสินค้าตามเดือน/รายปี
  Future<List<ReceiptItem>> fetchReceiptItems({
    required int month,
    required int year,
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await _dio.post(
        '/receipt_item',
        data: {'month': month, 'year': year},
        cancelToken: cancelToken
      );

      if (res.statusCode == 200) {
        final data = res.data;
        if (data is! List) {
          throw ApiException('Unexpected response shape', statusCode: res.statusCode);
        }
        return data.map((e) => ReceiptItem.fromJson(e as Map<String, dynamic>)).toList();
      }

      if (res.statusCode == 401 || res.statusCode == 403) {
        throw ApiException('Unauthorized', statusCode: res.statusCode);
      }
      throw ApiException('Fetch failed', statusCode: res.statusCode);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final dynamic body = e.response?.data;
      final msg = (body is Map && (body['message'] != null || body['Message'] != null))
        ? (body['message'] ?? body['Message']).toString()
        : e.message ?? 'Network error';

      throw ApiException(msg, statusCode: code);
    }
  }

  // ดึงยอดรวมเดือนเดียว
  Future<MonthlyTotal> GetMonthlyTotal({
    required int month,
    required int year,
    MonthlyKind type = MonthlyKind.net,
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await _dio.post(
        '/monthlyTotal',
        data: {'month': month, 'year': year, 'type': type.wire},
        cancelToken: cancelToken
      );

      if (res.statusCode == 200) {
        if (res.data is! Map) {
          throw ApiException('Unexpected response shape', statusCode: res.statusCode);
        }
        return MonthlyTotal.fromJson(Map<String, dynamic>.from(res.data as Map));
      }

      if (res.statusCode == 401 || res.statusCode == 403) {
        throw ApiException('Unauthorized', statusCode: res.statusCode);
      }
      throw ApiException('Fetch failed', statusCode: res.statusCode);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final body = e.response?.data;
      final msg = (body is Map && (body['message'] != null || body['Message'] != null))
        ? (body['message'] ?? body['Message']).toString()
        : e.message ?? 'Network error';
      throw ApiException(msg, statusCode: code);
    }
  }

  Future<StatsSummary> GetMonthlyComparison({
    required int month,
    required int year,
    MonthlyKind type = MonthlyKind.net,
    CancelToken? cancelToken,
  }) async {
    final prev = _previousMonth(month, year);

    final results = await Future.wait([
      GetMonthlyTotal(month: month, year: year, type: type, cancelToken: cancelToken),
      GetMonthlyTotal(month: prev.$1, year: prev.$2,type: type, cancelToken: cancelToken),
    ]);

    final thisMonth = results[0].amount;
    final lastMonth = results[1].amount;
    final pct = _percentChange(current: thisMonth, previous: lastMonth);

    return StatsSummary(thisMonth: thisMonth, percentChange: pct);
  }

  // คืน prevMonth, prevYear
  (int, int) _previousMonth(int month, int year) {
    if (month > 1) return (month - 1, year);
    return (12, year - 1);
  }

  // percent change from previous -> current
  // previous = 0 แล้ว current > 0 -> คืน 100 
  double _percentChange({
    required double current,
    required double previous,
  }) {
    if (previous == 0) {
      if (current == 0) return 0;
      return 100.0;
    }
    return ((current - previous) / previous) * 100.0;
  }

  // ดึงยอดรวม ตามหมวดหมู่
  Future<List<CategoryTotal>> fetchCategoryTotals({
    required int month,
    required int year,
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await _dio.post(
        '/receipt_item/categories',
        data: {'month':month, 'year':year},
        cancelToken: cancelToken
      );

      if (res.statusCode == 200) {
        final data = res.data;
        if (data is! List) {
          throw ApiException('Unexpected response shape', statusCode: res.statusCode);
        }

        final list = data
          .whereType<Map>()
          .cast<Map<String, dynamic>>()
          .map(CategoryTotal.fromJson)
          .toList()
          ..sort((a,b) => b.totalSpent.compareTo(a.totalSpent)); // เรียงจากมากไปน้อย
        return list;
      }

      if (res.statusCode == 401 || res.statusCode == 403) {
        throw ApiException('Unauthorized', statusCode: res.statusCode);
      }
      throw ApiException('Fetch failed', statusCode: res.statusCode);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final body = e.response?.data;
      final msg = (body is Map && (body['message'] != null || body['Message'] != null))
        ? (body['message'] ?? body['Message']).toString()
        : e.message ?? 'Network error';
      
      throw ApiException(msg, statusCode: code);
    }
  }

  // นำตัวแรกของ Username มาทำ เป็น icon
  Future<FirstUsernameIcon> fetchInitial({
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await _dio.get(
        '/firstUsername/icon',
        cancelToken: cancelToken
      );

      if (res.statusCode == 200) {
        final data = res.data;
        if (data is! Map) {
          throw ApiException('Unexpected response shape', statusCode: res.statusCode);
        }
        return FirstUsernameIcon.fromJson(Map<String, dynamic>.from(data));
      }

      if (res.statusCode == 401 || res.statusCode == 403) {
        throw ApiException('Unauthorized', statusCode: res.statusCode);
      }
      throw ApiException('Fecth failed', statusCode: res.statusCode);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final body = e.response?.data;
      final msg = (body is Map && (body['message'] != null || body['Message'] != null))
        ? (body['message'] ?? body['Message']).toString()
        : e.message ?? 'Network error';
      throw ApiException(msg, statusCode: code);
    }
  }

  // ทำหน้า seeall แสดงผลหมวดหมู่ที่ใช้ทั้งหมด
  Future<List<CategorySummary>> fetchCategorySummary({
    required int month,
    required int year,
    CancelToken? cancelToken
  }) async {
    try {
      final res = await _dio.post(
        '/categories/summary',
        data: {'month': month, 'year': year},
        cancelToken: cancelToken
      );

      if (res.statusCode == 200) {
        final data = res.data;
        if (data is! Map || data['categories'] == null) {
          throw ApiException('Unexpected response shape', statusCode: res.statusCode);
        }

        final List<dynamic> list = data['categories'];
        final totalMonth = double.tryParse(data['totalMonth']?.toString() ?? '0') ?? 0.0;

        // เพิ่ม percent ต่อ หมวดหมู่
        return list.map((e) {
          final total = double.tryParse(e['total'].toString()) ?? 0.0;
          final percent = totalMonth == 0 ? 0.0 : (total / totalMonth) * 100;

          return CategorySummary(
            categoryId: e['category_id'] ?? 0,
            categoryName: e['category_name'] ?? '',
            total: total,
            itemCount: e['item_count'] ?? 0,
            percent: percent
          );
        }).toList();
      }
      throw ApiException('Fecth failed', statusCode: res.statusCode);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final body = e.response?.data;
      final msg = (body is Map && body['message'] != null)
        ? body['message'].toString()
        : e.message ?? 'Network error';
      throw ApiException(msg, statusCode: code);
    }
  }

  Future<void> updateReceiptItem( {
    required int id,
    required String itemName,
    required int quantity,
    required double totalPrice,
    required DateTime receiptDate,
    required int categoryId,
    CancelToken? cancelToken,
  }) async {

    final dateStr = DateFormat('yyyy-MM-dd').format(receiptDate);

    final price2 = double.parse(totalPrice.toStringAsFixed(2));

    
    final body = {
      'item_name': itemName,
      'quantity': quantity,
      'total_price': price2,
      'receipt_date': dateStr,
      'category_id': categoryId,
    };

    try {
    final res = await _dio.put(
      '/receipt_item/$id',
      data: body, 
      cancelToken: cancelToken,
      options:  Options(headers: {'Content-Type': 'application/json'})
    );

    final code = res.statusCode ?? 0;
    if (code >= 200 && code < 300) {
      // ok หรือ 204 No content
      return;
    }
    throw ApiException('Failed to update item', statusCode: code);

    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final data = e.response?.data;
      final msg = (data is Map && (data['message'] != null || data['Message'] != null))
      ? (data['message'] ?? data['Message']).toString()
      : e.message ?? 'Network error';
    throw ApiException('Update failed: $msg', statusCode: code);
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  // เมื่อเลือก หมวดหมู่ใน category seeall แล้วจะแสดง หมวดหมู่ของรายการนั้นๆ ทั้งหมด
  Future<List<ReceiptItem>> fetchReceiptItemsByCategory({
    required int categoryId,
    int? month,
    int? year,
    CancelToken? cancelToken
  }) async {
    try {
      final String path = '/categories/$categoryId/items';

      final Map<String, dynamic> body = {
        if (month != null) 'month': month,
        if (year != null) 'year': year,
      };

      final res = await _dio.post(
        path,
        data: body,
        cancelToken: cancelToken,
      );

      if (res.statusCode == 200) {
        // final data = res.data;
        // if (data is! List) {
        //   throw ApiException('Unexpected response shape', statusCode: res.statusCode);
        // }

        final raw = res.data;

        final List list = switch (raw) {
          List l => l,
          Map m when m['data'] is List => m['data'] as List,
          _ => throw ApiException('Unexpected response shape', statusCode: res.statusCode)
        };

        return list
        .whereType<Map>()
        .cast<Map<String, dynamic>>()
        .map(ReceiptItem.fromJson)
        .toList();
      }

      if (res.statusCode == 401 || res.statusCode == 403) {
        throw ApiException('Unauthorized', statusCode: res.statusCode);
      }
      throw ApiException('Fetch failed', statusCode: res.statusCode);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final body = e.response?.data;
      final msg = (body is Map && (body['message'] != null || body['Message'] != null))
        ? (body['message'] ?? body['Message']).toString()
        : e.message ?? 'Network error';

      throw ApiException(msg, statusCode: code);
    }
  }
}