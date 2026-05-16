class AdhanSoundOption {
  const AdhanSoundOption({
    required this.id,
    required this.label,
    required this.resourceName,
    required this.assetPath,
  });

  final String id;
  final String label;
  final String resourceName;
  final String assetPath;
}

class AdhanSounds {
  static const main = AdhanSoundOption(
    id: 'azan',
    label: 'أذان بستان (افتراضي)',
    resourceName: 'azan',
    assetPath: 'assets/voice/azan.mp3',
  );

  static const makkah = AdhanSoundOption(
    id: 'makkah',
    label: 'أذان مكة المكرمة',
    resourceName: 'adhan_makkah',
    assetPath: 'assets/voice/azan.mp3', // Fallback asset for now
  );

  static const madinah = AdhanSoundOption(
    id: 'madinah',
    label: 'أذان المدينة المنورة',
    resourceName: 'adhan_madinah',
    assetPath: 'assets/voice/azan.mp3', // Fallback asset for now
  );

  static const alaqsa = AdhanSoundOption(
    id: 'alaqsa',
    label: 'أذان المسجد الأقصى',
    resourceName: 'adhan_alaqsa',
    assetPath: 'assets/voice/azan.mp3', // Fallback asset for now
  );

  static const values = <AdhanSoundOption>[main, makkah, madinah, alaqsa];

  static AdhanSoundOption byId(String id) {
    return values.firstWhere(
      (e) => e.id == id,
      orElse: () => main,
    );
  }
}
