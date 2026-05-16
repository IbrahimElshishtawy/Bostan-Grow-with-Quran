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
    label: 'أذان بستان',
    resourceName: 'azan',
    assetPath: 'assets/voice/azan.mp3',
  );

  static const values = <AdhanSoundOption>[main];

  static AdhanSoundOption byId(String id) {
    // We only have one sound now, so always return main
    return main;
  }
}
