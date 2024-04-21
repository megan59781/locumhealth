// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:fyp/pages/login.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';

// void main() {
//   late MockGoogleSignIn googleSignIn;
//   setUp(() {
//     googleSignIn = MockGoogleSignIn();
//   });

//   test('should return idToken and accessToken when authenticating', () async {
//     final signInAccount = await googleSignIn.signIn();
//     final signInAuthentication = await signInAccount!.authentication;
//     expect(signInAuthentication, isNotNull);
//     expect(googleSignIn.currentUser, isNotNull);
//     expect(signInAuthentication.accessToken, isNotNull);
//     expect(signInAuthentication.idToken, isNotNull);
//   });

//   test('should return null when google login is cancelled by the user',
//       () async {
//     googleSignIn.setIsCancelled(true);
//     final signInAccount = await googleSignIn.signIn();
//     expect(signInAccount, isNull);
//   });

//   test(
//       'testing google login twice, once cancelled, once not cancelled at the same test.',
//       () async {
//     googleSignIn.setIsCancelled(true);
//     final signInAccount = await googleSignIn.signIn();
//     expect(signInAccount, isNull);
//     googleSignIn.setIsCancelled(false);
//     final signInAccountSecondAttempt = await googleSignIn.signIn();
//     expect(signInAccountSecondAttempt, isNotNull);
//   });

//   group('Login class test', () {
//     final testPosition = Position(
//         longitude: 100.0,
//         latitude: 100.0,
//         timestamp: DateTime.now(),
//         accuracy: 50.6,
//         altitude: 20.0,
//         heading: 120,
//         speed: 150.9,
//         speedAccuracy: 10.0,
//         altitudeAccuracy: 0.0,
//         headingAccuracy: 0.0);

//     //this will enter our plugin is initialize pperly before we fire the test
//     TestWidgetsFlutterBinding.ensureInitialized();

//     const MethodChannel locationChannel =
//         MethodChannel('flutter.baseflow.com/geolocator');

//     Future locationHandler(MethodCall methodCall) async {
//       //whenever `getCurrentPosition` method is called we want to return a testPosition
//       if (methodCall.method == 'getCurrentLatLong') {
//         return testPosition.toJson();
//       }
//       // this is the check that's supposed to happend
//       // on the Device before you try to get user's
//       //location, so I set it to true
//       if (methodCall.method == 'isLocationServiceEnabled') {
//         return true;
//       }
//       //Here's another check that's happens on the user's device, we defaulted
//       //it to authorized, and this is simulating when the user grants
//       //access to their location
//       if (methodCall.method == 'checkPermission') {
//         return 3;
//       }
//     }

//     group("Test Location", () {
//     setUpAll(() {
//       TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
//           .setMockMethodCallHandler(locationChannel, locationHandler);
//     });

//     test('get location', () async {
//       final res = await loginState.getCurrentLatLong();
//       //we're testing to be sure that what we get a datatype of Position.
//       expect(res, isA<Position>());
//     });
//   });

