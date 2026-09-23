import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutx_core/core/debug_print.dart';
import '../../domain/entrity/product.dart';
import 'package:flutter/material.dart';

Future<bool> sendProductNotification(
  BuildContext context,
  Product product,
) async {
  final callable = FirebaseFunctions.instance.httpsCallable(
    "sendProductNotification",
    options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
  );

  try {
    final result = await callable.call({
      "id": product.id,
      "name": product.title,
      "shortDescription": product.description,
      "imageUrl": product.imageUrls.isNotEmpty ? product.imageUrls.first : "",
    });

    DPrint.log(
      "Push notification request sent to Cloud Function: ${result.data}",
    );

    if (result.data['success'] == true) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notification sent successfully for ${product.title}!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
      return true;
    } else {
      throw Exception(result.data['error'] ?? "Unknown error");
    }
  } catch (e) {
    DPrint.error("Failed to send product notification: $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return false;
  }
}

/// Shows a confirmation dialog before notifying all users about [product],
/// so admins don't accidentally mass-notify with a stray click.
Future<void> confirmAndSendProductNotification(
  BuildContext context,
  Product product,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Notify all users?'),
      content: SizedBox(
        width: 320,
        child: Text(
          'This will send a push notification to every user about '
          '"${product.title}". Only do this for new or noteworthy items, '
          'not routine stock updates.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Send Notification'),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    await sendProductNotification(context, product);
  }
}
