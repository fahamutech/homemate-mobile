import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/core/links/link_opener.dart';

/// Where a stored document link leads, and what is refused.
void main() {
  const api = 'https://api.homemate.co.tz';

  test('an absolute web link is opened as it is', () {
    expect(documentUri('https://files.homemate.co.tz/leases/HM-LA-7.pdf', apiBaseUrl: api).toString(),
        'https://files.homemate.co.tz/leases/HM-LA-7.pdf');
    expect(documentUri('http://files.local/lease.pdf', apiBaseUrl: api)?.scheme, 'http');
  });

  test('a path is resolved against the API', () {
    expect(documentUri('/app/media/abc/raw', apiBaseUrl: api).toString(), 'https://api.homemate.co.tz/app/media/abc/raw');
    expect(documentUri('/app/media/abc/raw', apiBaseUrl: '$api/').toString(), 'https://api.homemate.co.tz/app/media/abc/raw');
  });

  test('nothing, blanks and anything but http(s) are refused', () {
    expect(documentUri(null, apiBaseUrl: api), isNull);
    expect(documentUri('   ', apiBaseUrl: api), isNull);
    expect(documentUri('javascript:alert(1)', apiBaseUrl: api), isNull);
    expect(documentUri('file:///etc/passwd', apiBaseUrl: api), isNull);
    expect(documentUri('leases/relative.pdf', apiBaseUrl: api), isNull);
  });
}
