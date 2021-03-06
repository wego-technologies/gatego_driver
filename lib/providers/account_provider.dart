import 'dart:convert';
import 'providers.dart';
import '../utils/string_to_role.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod/riverpod.dart';
import 'dart:async';

import '../models/account.dart';
import '../models/carrier.dart';
import '../models/driver.dart';
import '../models/organization.dart';
import '../utils/debug_mode.dart';

class AccountProvider extends StateNotifier<Account?> {
  AccountProvider(this.ref) : super(null);
  final Ref ref;

  Future<Account?> getMe({String? token}) async {
    token ??= ref.read(authProvider).token;

    /*if (retryTimer != null) {
      retryTimer.cancel();
    }*/
    if (token != null && state == null) {
      final url = "${DebugUtils().baseUrl}api/account/me";

      try {
        final res = await http.get(
          Uri.parse(url),
          headers: {
            "Accept": "application/json",
            "content-type": "application/json",
            "Authorization": "Bearer $token",
          },
        );

        if (res.statusCode == 200) {
          final resData = json.decode(res.body);

          DateTime? deletedAt;

          if (resData["deleted_at"] != null) {
            deletedAt = DateTime.tryParse(resData["deleted_at"]);
          }

          state = Account(
            active: resData["active"],
            canViewCarrierIds: resData["can_view_carrier_ids"],
            role: stringToRole(resData["role"]),
            name: resData["name"],
            id: resData["id"],
            carrier: genCarrier(resData),
            deletedAt: deletedAt,
            driver: genDriver(resData),
            email: resData["email"],
            organization: Organization.fromMap(resData["organization"]),
            phoneNumber: resData["phone_number"],
            yardId: resData["yard_id"],
          );
        }

        return state;
      } catch (e) {
        /*print("Trying to reconnet");
        retryTimer = Timer(
            Duration(
              seconds: 5,
            ), () {
          getMe();
        });*/
        rethrow;
      }
    }
    return null;
  }

  get me {
    return state;
  }

  Carrier? genCarrier(data) {
    if (data["carrier"] != null) {
      Carrier(
        createdAt: data["carrier"]["created_at"],
        createdBy: data["carrier"]["created_by"],
        fleetId: data["carrier"]["fleet_id"],
        lastModifiedAt: data["carrier"]["last_modified_at"],
        lastModifiedBy: data["carrier"]["last_modified_by"],
        name: data["carrier"]["name"],
        scac: data["carrier"]["scac"],
        yards: data["carrier"]["yards"],
        id: data["carrier"]["id"],
      );
    }

    return null;
  }

  Driver? genDriver(data) {
    if (data["driver"] != null) {
      Driver(
        license: data["driver"]["license"],
        licensePictureId: data["driver"]["license_picture_id"],
        truckNumber: data["driver"]["truck_number"],
      );
    }

    return null;
  }

  Organization? genOrg(data) {
    if (data["organization"] != null) {
      Organization(
        id: data["organization"]["id"],
        name: data["organization"]["name"],
      );
    }

    return null;
  }

  void clear() {
    state = null;
  }
}
