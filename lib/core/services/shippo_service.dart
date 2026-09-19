import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutx_core/flutx_core.dart';

import '../constants/shippo_key.dart';

class AdminShippoService {
  static const String baseUrl = 'https://api.goshippo.com';
  static const String apiToken = shippoLiveKey;

  final headers = {
    'Authorization': 'ShippoToken $apiToken',
    'Content-Type': 'application/json',
  };

  // Re-use address creation (same as user)
  Future<Map<String, dynamic>> createAddress({
    required String name,
    String? company,
    required String street1,
    String? street2,
    required String city,
    required String state,
    required String zip,
    required String country,
    String? phone,
    String? email,
    bool isResidential = true,
  }) async {
    final url = Uri.parse('$baseUrl/addresses/');
    final body = jsonEncode({
      'name': name,
      if (company != null) 'company': company,
      'street1': street1,
      if (street2 != null) 'street2': street2,
      'city': city,
      'state': state,
      'zip': zip,
      'country': country,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      'is_residential': isResidential,
      'validate': true,
    });

    try {
      final res = await http.post(url, headers: headers, body: body);
      if (res.statusCode == 201) {
        return jsonDecode(res.body);
      } else {
        DPrint.error('Address Error: ${res.statusCode} - ${res.body}');
        throw Exception('Address Error: ${res.body}');
      }
    } catch (e) {
      DPrint.error('Address Exception: $e');
      rethrow;
    }
  }

  // Create Parcel
  Future<String> createParcel({
    required double length,
    required double width,
    required double height,
    required String distanceUnit, // 'in', 'cm'
    required double weight,
    required String massUnit, // 'lb', 'oz', 'g', 'kg'
  }) async {
    final url = Uri.parse('$baseUrl/parcels/');
    final body = jsonEncode({
      'length': length.toString(),
      'width': width.toString(),
      'height': height.toString(),
      'distance_unit': distanceUnit,
      'weight': weight.toString(),
      'mass_unit': massUnit,
    });

    try {
      final res = await http.post(url, headers: headers, body: body);
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return data['object_id'];
      } else {
        DPrint.error('Parcel Error: ${res.body}');
        throw Exception('Parcel Error: ${res.body}');
      }
    } catch (e) {
      DPrint.error('Parcel Exception: $e');
      rethrow;
    }
  }

  // Create Customs Item
  Future<String> createCustomsItem({
    required String description,
    required double quantity,
    required double netWeight, // mass unit relative
    required String massUnit, // 'lb', 'oz', 'g', 'kg'
    required double valueAmount,
    required String valueCurrency,
    required String originCountry, // 'US'
    String? tariffNumber,
  }) async {
    final url = Uri.parse('$baseUrl/customs/items/');
    final body = jsonEncode({
      'description': description,
      'quantity': quantity.toInt(),
      'net_weight': netWeight.toString(),
      'mass_unit': massUnit,
      'value_amount': valueAmount.toString(),
      'value_currency': valueCurrency,
      'origin_country': originCountry,
      if (tariffNumber != null) 'tariff_number': tariffNumber,
    });

    try {
      final res = await http.post(url, headers: headers, body: body);
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return data['object_id'];
      } else {
        DPrint.error('Customs Item Error: ${res.body}');
        throw Exception('Customs Item Error: ${res.body}');
      }
    } catch (e) {
      DPrint.error('Customs Item Exception: $e');
      rethrow;
    }
  }

  // Create Customs Declaration
  Future<String> createCustomsDeclaration({
    required List<String> customsItemIds,
    required bool certify,
    required String signer,
    String type = 'MERCHANDISE',
    String incoterm = 'DDU',
    String eelPfc = 'NOEEI_30_37_a',
  }) async {
    final url = Uri.parse('$baseUrl/customs/declarations/');
    final body = jsonEncode({
      'items': customsItemIds,
      'certify': certify,
      'certify_signer': signer,
      'type': type,
      'incoterm': incoterm,
      'eel_pfc': eelPfc,
    });

    try {
      final res = await http.post(url, headers: headers, body: body);
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return data['object_id'];
      } else {
        DPrint.error('Customs Declaration Error: ${res.body}');
        throw Exception('Customs Declaration Error: ${res.body}');
      }
    } catch (e) {
      DPrint.error('Customs Declaration Exception: $e');
      rethrow;
    }
  }

  // Create Shipment
  Future<Map<String, dynamic>> createShipment({
    required String addressFromId,
    required String addressToId,
    required List<String> parcelIds,
    String? customsDeclarationId,
  }) async {
    final url = Uri.parse('$baseUrl/shipments/');
    final body = jsonEncode({
      'address_from': addressFromId,
      'address_to': addressToId,
      'parcels': parcelIds,
      if (customsDeclarationId != null)
        'customs_declaration': customsDeclarationId,
      'async': false,
    });

    try {
      final res = await http.post(url, headers: headers, body: body);
      if (res.statusCode == 201) {
        return jsonDecode(res.body);
      } else {
        DPrint.error('Shipment Error: ${res.body}');
        throw Exception('Shipment Error: ${res.body}');
      }
    } catch (e) {
      DPrint.error('Shipment Exception: $e');
      rethrow;
    }
  }

  // Buy Label
  Future<Map<String, dynamic>> buyLabel(String rateId) async {
    final url = Uri.parse('$baseUrl/transactions/');
    final body = jsonEncode({
      'rate': rateId,
      'label_file_type': 'PDF',
      'async': false,
    });

    try {
      final res = await http.post(url, headers: headers, body: body);
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        DPrint.log('Transaction Success: $data');
        return data;
      } else {
        DPrint.error('Transaction Error: ${res.body}');
        throw Exception('Transaction Error: ${res.body}');
      }
    } catch (e) {
      DPrint.error('Transaction Exception: $e');
      rethrow;
    }
  }

  // Void/refund a previously purchased label so a corrected one can be bought.
  // Shippo labels are immutable once purchased, so a correction is a
  // refund request against the original transaction, not an edit.
  Future<Map<String, dynamic>> refundLabel(String transactionId) async {
    final url = Uri.parse('$baseUrl/refunds/');
    final body = jsonEncode({'transaction': transactionId});

    try {
      final res = await http.post(url, headers: headers, body: body);
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        DPrint.log('Refund requested: $data');
        return data;
      } else {
        DPrint.error('Refund Error: ${res.body}');
        throw Exception('Refund Error: ${res.body}');
      }
    } catch (e) {
      DPrint.error('Refund Exception: $e');
      rethrow;
    }
  }
}
