import 'dart:io';
import 'package:image_picker/image_picker.dart';

/// Simple test to verify camera permissions are working
void main() async {
  print('🧪 Testing Camera Permissions...');
  
  try {
    final ImagePicker picker = ImagePicker();
    
    // Test camera availability
    print('📱 Testing camera access...');
    
    // This will trigger permission request if not granted
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );
    
    if (image != null) {
      print('✅ Camera permission granted and image captured!');
      print('   Image path: ${image.path}');
      print('   Image size: ${await File(image.path).length()} bytes');
      
      // Clean up test image
      await File(image.path).delete();
      print('🧹 Test image cleaned up');
    } else {
      print('❌ No image captured (user may have cancelled)');
    }
    
  } catch (e) {
    print('❌ Camera permission test failed: $e');
    
    if (e.toString().contains('camera_access_denied')) {
      print('💡 Camera access was denied by user');
      print('   Please enable camera permission in device settings');
    } else if (e.toString().contains('permission')) {
      print('💡 Permission-related error detected');
      print('   Check that camera permissions are properly configured');
    }
  }
  
  // Test gallery access
  try {
    print('📷 Testing gallery access...');
    final ImagePicker picker = ImagePicker();
    
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    
    if (image != null) {
      print('✅ Gallery permission granted and image selected!');
      print('   Image path: ${image.path}');
    } else {
      print('❌ No image selected (user may have cancelled)');
    }
    
  } catch (e) {
    print('❌ Gallery permission test failed: $e');
  }
  
  print('🏁 Camera permissions test completed');
}