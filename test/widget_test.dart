// Basic test file
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/constants/app_constants.dart';

void main() {
  test('App constants are correct', () {
    expect(AppConstants.appName, 'Smriti');
    expect(AppConstants.chunkSize, 500);
  });
}
