import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// DESCO's server sends only its leaf certificate, omitting the DigiCert
/// Global G2 intermediate CA. Browsers paper over this via AIA fetching;
/// Android's TLS stack does not, so the handshake fails with a bad
/// certificate chain error. We bundle the intermediate cert ourselves and
/// trust it explicitly, scoped to this client only.
Future<http.Client> createDescoHttpClient() async {
  final context = SecurityContext(withTrustedRoots: true);
  final certBytes = await rootBundle.load('assets/certs/digicert_global_g2.pem');
  context.setTrustedCertificatesBytes(certBytes.buffer.asUint8List());

  final httpClient = HttpClient(context: context);
  return IOClient(httpClient);
}
