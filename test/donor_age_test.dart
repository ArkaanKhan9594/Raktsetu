import 'package:flutter_test/flutter_test.dart';
import 'package:raktsetu/models/donor.dart';
import 'package:raktsetu/services/data_repository.dart';

void main() {
  group('Donor Age and Eligibility Tests', () {
    test('Calculates age correctly from DOB', () {
      final now = DateTime.now();
      final donor20 = Donor(
        id: 'test-1',
        name: 'Adult Donor',
        phone: '9999999999',
        bloodGroup: BloodGroup.oPos,
        city: 'Ahmedabad',
        dob: DateTime(now.year - 20, now.month, now.day),
        gender: 'Male',
      );

      expect(donor20.age, 20);
      expect(donor20.isUnder18, isFalse);
      expect(donor20.isEligibleNow, isTrue);
    });

    test('Donor age < 18 is strictly ineligible to donate blood', () {
      final now = DateTime.now();
      final minorDonor = Donor(
        id: 'test-2',
        name: 'Minor',
        phone: '9999999998',
        bloodGroup: BloodGroup.aPos,
        city: 'Ahmedabad',
        dob: DateTime(now.year - 17, now.month, now.day),
        gender: 'Female',
      );

      expect(minorDonor.age, 17);
      expect(minorDonor.isUnder18, isTrue);
      expect(minorDonor.isEligibleNow, isFalse);
      expect(minorDonor.daysUntilEligible > 0, isTrue);
    });

    test('Donor age > 65 is ineligible for voluntary blood donation', () {
      final now = DateTime.now();
      final seniorDonor = Donor(
        id: 'test-3',
        name: 'Senior Citizen',
        phone: '9999999997',
        bloodGroup: BloodGroup.oPos,
        city: 'Ahmedabad',
        dob: DateTime(now.year - 68, now.month, now.day),
        gender: 'Male',
      );

      expect(seniorDonor.age, 68);
      expect(seniorDonor.isOverAge, isTrue);
      expect(seniorDonor.isAgeEligible, isFalse);
      expect(seniorDonor.isEligibleNow, isFalse);
    });

    test('DataRepository rejects donation logging for under 18 donors', () async {
      final now = DateTime.now();
      final repo = InMemoryDataRepository();
      final minor = Donor(
        id: 'minor-1',
        name: 'Underage User',
        phone: '9888888888',
        bloodGroup: BloodGroup.bPos,
        city: 'Ahmedabad',
        dob: DateTime(now.year - 16, 5, 10),
        gender: 'Male',
      );
      await repo.upsertDonor(minor);

      expect(() => repo.logDonation(minor.id), throwsA(isA<StateError>()));
    });

    test('DataRepository rejects donation logging for donors over 65', () async {
      final now = DateTime.now();
      final repo = InMemoryDataRepository();
      final senior = Donor(
        id: 'senior-1',
        name: 'Senior User',
        phone: '9888888887',
        bloodGroup: BloodGroup.oPos,
        city: 'Ahmedabad',
        dob: DateTime(now.year - 70, 1, 1),
        gender: 'Male',
      );
      await repo.upsertDonor(senior);

      expect(() => repo.logDonation(senior.id), throwsA(isA<StateError>()));
    });

    test('DataRepository rejects event registration for minors and seniors', () async {
      final now = DateTime.now();
      final repo = InMemoryDataRepository();
      final events = await repo.getEvents();
      final eventId = events.first.id;

      final minor = Donor(
        id: 'minor-event',
        name: 'Minor',
        phone: '9888888886',
        bloodGroup: BloodGroup.aPos,
        city: 'Ahmedabad',
        dob: DateTime(now.year - 15, 1, 1),
        gender: 'Female',
      );
      await repo.upsertDonor(minor);

      expect(() => repo.registerDonorForEvent(eventId, minor.id), throwsA(isA<StateError>()));
    });
  });
}
