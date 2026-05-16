import 'dart:io';

void main() {
  final source = File('C:/Users/Ibrahem/.gemini/antigravity/brain/718b7e63-9afb-4776-a6f9-5313043e02d7/bustan_app_icon_white_1778881903669.png');
  final target = File('assets/iosn/bustan_icon.png');
  
  if (!target.parent.existsSync()) {
    target.parent.createSync(recursive: true);
  }
  
  source.copySync(target.path);
  print('Icon copied successfully to ${target.path}');
}
