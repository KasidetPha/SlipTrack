import 'package:dio/dio.dart';
import 'package:frontend/models/monthly_total.dart';
import 'package:frontend/models/receipt_item.dart';
import 'package:frontend/models/stats_summary.dart';
import 'package:frontend/services/api_client.dart';

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
  Future<MonthlyTotal> getMonthlyTotal({
    required int month,
    required int year,
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await _dio.post(
        '/monthlyTotal',
        data: {'month': month, 'year': year},
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

  Future<StatsSummary> getMonthlyComparison({
    required int month,
    required int year,
    CancelToken? cancelToken,
  }) async {
    final prev = _previousMonth(month, year);

    final results = await Future.wait([
      getMonthlyTotal(month: month, year: year, cancelToken: cancelToken),
      getMonthlyTotal(month: prev.$1, year: prev.$2, cancelToken: cancelToken),
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
}