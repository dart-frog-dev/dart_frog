import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:test/test.dart';

void main() {
  group('serve', () {
    test('creates an HttpServer on the provided port/address', () async {
      final server = await serve((_) => Response(), 'localhost', 3000);
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('http://localhost:3000'));
      final response = await request.close();
      expect(response.statusCode, equals(HttpStatus.ok));
      await server.close();
    });

    test('can return multiple 404s', () async {
      final server = await serve(Router().call, 'localhost', 3001);
      final client = HttpClient();
      var request = await client.getUrl(Uri.parse('http://localhost:3001'));
      var response = await request.close();
      expect(response.statusCode, equals(HttpStatus.notFound));
      request = await client.getUrl(Uri.parse('http://localhost:3001'));
      response = await request.close();
      expect(response.statusCode, equals(HttpStatus.notFound));
      await server.close();
    });

    test('exposes connectionInfo on the incoming request', () async {
      late HttpConnectionInfo connectionInfo;
      final server = await serve(
        (context) {
          connectionInfo = context.request.connectionInfo;
          return Response();
        },
        'localhost',
        3000,
      );
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('http://localhost:3000'));
      await request.close();
      expect(connectionInfo.remoteAddress.address, equals('::1'));
      await server.close();
    });

    group('X-Powered-By-Header', () {
      test('is configured by default', () async {
        final server = await serve((_) => Response(), 'localhost', 3000);
        final client = HttpClient();
        final request = await client.getUrl(Uri.parse('http://localhost:3000'));
        final response = await request.close();
        expect(
          response.headers.value('X-Powered-By'),
          equals('Dart with package:dart_frog'),
        );
        await server.close();
      });

      test('can be overridden', () async {
        const poweredByHeader = 'custom powered by header';
        final server = await serve(
          (_) => Response(),
          'localhost',
          3000,
          poweredByHeader: poweredByHeader,
        );
        final client = HttpClient();
        final request = await client.getUrl(Uri.parse('http://localhost:3000'));
        final response = await request.close();
        expect(
          response.headers.value('X-Powered-By'),
          equals(poweredByHeader),
        );
        await server.close();
      });

      test('can be removed', () async {
        final server = await serve(
          (_) => Response(),
          'localhost',
          3000,
          poweredByHeader: null,
        );
        final client = HttpClient();
        final request = await client.getUrl(Uri.parse('http://localhost:3000'));
        final response = await request.close();
        expect(response.headers.value('X-Powered-By'), isNull);
        await server.close();
      });
    });

    group('shared', () {
      test(
          '''when false throws a SocketException when binding bind to the same combination of address and port''',
          () async {
        final server1 = await serve((_) => Response(), 'localhost', 3000);

        await expectLater(
          () async => serve((_) => Response(), 'localhost', 3000),
          throwsA(isA<SocketException>()),
        );

        await server1.close();
      });

      test(
          '''when true serves requests successfully when binding bind to the same combination of address and port''',
          () async {
        final server1 = await serve(
          (_) => Response(headers: {'server': '1'}),
          'localhost',
          3200,
          shared: true,
        );
        final server2 = await serve(
          (_) => Response(headers: {'server': '2'}),
          'localhost',
          3200,
          shared: true,
        );

        final client = HttpClient();
        final request = await client.getUrl(Uri.parse('http://localhost:3200'));
        final response = await request.close();

        expect(response.headers.value('server'), equals('1'));

        await server1.close();
        await server2.close();
      });
    });

    test('creates an HttpsServer on the provided securityContext', () async {
      const chain = '''
-----BEGIN CERTIFICATE-----
MIIEYTCCAsmgAwIBAgIQL36luIvjA/lXJN/q6t6XXDANBgkqhkiG9w0BAQsFADCB
lzEeMBwGA1UEChMVbWtjZXJ0IGRldmVsb3BtZW50IENBMTYwNAYDVQQLDC1jb2Jh
bHRATWFjQm9vay1Qcm8tVW5nZXIubG9jYWwgKFVuZ2VyIEFuZHJleSkxPTA7BgNV
BAMMNG1rY2VydCBjb2JhbHRATWFjQm9vay1Qcm8tVW5nZXIubG9jYWwgKFVuZ2Vy
IEFuZHJleSkwHhcNMjEwMzI5MDgxNTEwWhcNMjMwNjI5MDgxNTEwWjBhMScwJQYD
VQQKEx5ta2NlcnQgZGV2ZWxvcG1lbnQgY2VydGlmaWNhdGUxNjA0BgNVBAsMLWNv
YmFsdEBNYWNCb29rLVByby1Vbmdlci5sb2NhbCAoVW5nZXIgQW5kcmV5KTCCASIw
DQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALg8cToisQsz8lKsija4C3WeCa2M
V20Zk6SFs1kQU+/Z/9dyExQlDTnMN8d8Dvkij+2rDa7PoiAFRkWafm0BCtLEv5/+
V4sCApbhbqP4iqntA7VDC6GiDAjL/yqgZ9btaHnvUqKDXYMyuyVL0dWOILFhPqDf
/0r3mwSVXXcFsQvY43lZ1/tteCiONMmWiPL9wuIJa0wqA6LwtGzjLTyXUmO7tYLA
T1Mz1XjqZnhSW41FTLKjA0fsKAMp1tzaZl8DzMnAmrLOEe3E+JVzThy4PfD3J8+a
cC/DsUVxKGkKcSQPXR3GGNp/VWbs7w+qqTD/PHI5J4r69GBR5ZXu8l24i8UCAwEA
AaNeMFwwDgYDVR0PAQH/BAQDAgWgMBMGA1UdJQQMMAoGCCsGAQUFBwMBMB8GA1Ud
IwQYMBaAFDptHqlxKExeYwjJh6dg0wXdlaocMBQGA1UdEQQNMAuCCWxvY2FsaG9z
dDANBgkqhkiG9w0BAQsFAAOCAYEANRtOVP1GypaeTXBeKnoOGycPexnVIwpPgysM
v2LCsoQzWbZJkOeZadjOODBoJSCblLAQvx6deo8isGOYJO73lrLuX3CldVBuwP1q
nBlotfJN+kk42ixT+ETxD/vSOY6CxClo4pw4f8SXlyZ6RX3pKTyXLC5vud4z4kIt
X5SUy6moZfagBn2lntBx1qnKpXYPsaQQN23dDJE44PQX9o78ZffUn81E39sGJFQt
V5ktO6WJh+5J+6TdEd1xnhC51QSJhRNuD2H8H5PVhoAWiyMK8te+lMUpK6x4Mlbo
eOjaAAhQ8UcVmvJrtt5GoDh9Bl/jB60gVGL0XFr9E1b3DZWgMpgyzBreGlpXPL87
47P6RMmzpAp/efrY+scKk9UH/6CElsWt2lYrv4XUBjsCXdrGrYpuG3aS5ohowvWd
lM5/EJeo2XQrb5AOE+mGMOZrI1F113IjZkP73OVrUyAKg5vsHDvHwRQ/blz3W2fG
iTz7oBJ+5dtzLcZNFkDgNhBGKSu8
-----END CERTIFICATE-----
''';
      const key = '''
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC4PHE6IrELM/JS
rIo2uAt1ngmtjFdtGZOkhbNZEFPv2f/XchMUJQ05zDfHfA75Io/tqw2uz6IgBUZF
mn5tAQrSxL+f/leLAgKW4W6j+Iqp7QO1QwuhogwIy/8qoGfW7Wh571Kig12DMrsl
S9HVjiCxYT6g3/9K95sElV13BbEL2ON5Wdf7bXgojjTJlojy/cLiCWtMKgOi8LRs
4y08l1Jju7WCwE9TM9V46mZ4UluNRUyyowNH7CgDKdbc2mZfA8zJwJqyzhHtxPiV
c04cuD3w9yfPmnAvw7FFcShpCnEkD10dxhjaf1Vm7O8Pqqkw/zxyOSeK+vRgUeWV
7vJduIvFAgMBAAECggEAfa3lw7XUtoK6RMGlC4zjbFnh2j0JishO2oXGgfRMfitl
hvAvqadY7VutlWzAvh1gt83faKgFvfg7JtIsemmim4NSAW+9AnvdjlW8ZyjuVtrz
k5xn+9wSf5HBwK9qBskvYzbqVShuC0j5N4kQXLE3BioDUjVb7yUX37mQ59e/Hgev
TlmBRlQ1m6lXTu7slsOhrCF830acFullZcFQhhPeh9d4f32vMiCyCd3BhC0r50Jd
45qdsQO1IGXKT4HYhdwI66BzV03kBM6rlsOltuhw0e+4ygXbLB5NOiuHNXz8Vju3
d7Q13rc79udiXLcLxN+RgdVRR0F+imgRu/zq/gRGBQKBgQDUdfkFvxTYwmLV4OUD
c8I/hjRX+RDgRfze0JhByp5VfGZ4NRhfo3JORmUU2fI+3jKxFineabtIl31ebBCc
yK7hZPsdgluiLjrt/bAxOq4v47hOpyMQI9qxiBrJYDpID+emT/K3jfA0gYmZfl/c
vYR5jSSD3d29UW3zqHNxni+d1wKBgQDd/cGVkWCH5k3k3Y94fSn//vbfECx0xltp
025+rJ+go7T0ywSfNM3g5n1lt8jE0yJziiWF5PIM0qRo4YBWcPoI8sdFIaS+rHv7
Oh1vSnX7vL5t0RNTjVpxpcxqAut2v03tMcuJo+8llEq+midp8beAmzsufKBONauX
zCEk30MXwwKBgQC9qF5XEd9DLCtcb7kgHsrtOBkr2wuEmRWFtcHlIUG8YCN89TC/
10EnvNFpDrGgC2xHBtjzUYE86PaiPmeJ/d+XFzTPf9na6dfzMX6CQ7bQy0Bw/eRf
+RG1XyFCWKNORtxsa3vo/UzLIkO6AMUEYS2L8EIDcSALa1ByrRH4/9PT2wKBgQDZ
f+2ysIxmuoQpL9eJEwEam+GfbgZQp6QbDJgfLtz7lEoQ6fTuU9s/djT4e1gPWFpR
39Gh3U42uA9z3zVR/EFOkSgimLMESpTy8d6zEr6EVkox6H5KB53M6chdOd0gLJGa
S4aDpgYCyMdu9jSVvcmwDOewRVT/K+CiytLSgJkI5wKBgE9Lun9U4sW8uKDL0q9g
GhAvwnx67SU85gBKK+C1P9yBp8QGQEjFHtRBLUh5R4lXBvPW9e+VuS0vcj6QKGuy
4fWk4JDF7cwbR/HqlyNQrynnSIm1qats3Oe2AiJzKNXMzQj/IiVgF/cp5z1qjkKZ
SFTrELxay/xfdivEUxK9wEIG
-----END PRIVATE KEY-----
''';

      final securityContext = SecurityContext()
        ..useCertificateChainBytes(utf8.encode(chain))
        ..usePrivateKeyBytes(utf8.encode(key));
      final server = await serve(
        (_) => Response(),
        'localhost',
        3000,
        securityContext: securityContext,
      );
      final client = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => cert.pem == chain;
      final request = await client.getUrl(Uri.parse('https://localhost:3000'));
      final response = await request.close();
      expect(response.statusCode, equals(HttpStatus.ok));
      await server.close();
    });

    test(
        '''throws a HandshakeException when trying to use https without a securityContext''',
        () async {
      await serve((_) => Response(), 'localhost', 3000);
      final client = HttpClient();

      await expectLater(
        () => client.getUrl(Uri.parse('https://localhost:3000')),
        throwsA(isA<HandshakeException>()),
      );
    });

    test('can read request.body across middleware:handler gap', () async {
      Middleware middleware() {
        return (handler) {
          return (context) async {
            await context.request.body(); // Read #1
            return handler(context);
          };
        };
      }

      Handler handler() {
        return (context) async {
          await context.request.body(); // Read #2
          return Response();
        };
      }

      const address = 'localhost';
      const port = 3000;
      final pipeline = const Pipeline().addMiddleware(middleware());
      final router = Router()..mount('/', handler());
      final server = await serve(
        pipeline.addHandler(router.call),
        address,
        port,
      );
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('http://$address:$port'));
      final response = await request.close();
      expect(response.statusCode, equals(HttpStatus.ok));
      await server.close();
    });
  });
}
