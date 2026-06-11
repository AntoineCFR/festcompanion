import '../../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/profile_service.dart';

class ProfilePhoto extends StatefulWidget {
  final int userId;
  final Function(String?) onPhotoUploaded;
  final bool isUploading;

  const ProfilePhoto({
    super.key,
    required this.userId,
    required this.onPhotoUploaded,
    this.isUploading = false,
  });

  @override
  State<ProfilePhoto> createState() => _ProfilePhotoState();
}

class _ProfilePhotoState extends State<ProfilePhoto> {
  bool _isUploading = false;

  @override
  void didUpdateWidget(ProfilePhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    _isUploading = widget.isUploading;
  }

  Future<void> _uploadPhoto() async {
    if (!mounted) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null || !mounted) return;

    setState(() => _isUploading = true);
    try {
      final ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('user_photos/${widget.userId}.jpg');
      await ref.putFile(File(image.path));

      if (!mounted) return;
      final photoUrl = await ref.getDownloadURL();
      widget.onPhotoUploaded(photoUrl);
    } catch (e) {
      rethrow;
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Utilise FutureBuilder comme dans ProfileAvatar
    return FutureBuilder<String?>(
      future: ProfileService.getPhotoUrl(widget.userId),
      builder: (context, snapshot) {
        return GestureDetector(
          onTap: _uploadPhoto,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.surface,
                backgroundImage: snapshot.hasData
                    ? CachedNetworkImageProvider(snapshot.data!)
                    : null,
                child: !snapshot.hasData
                    ? const Icon(Icons.camera_alt, size: 40, color: Colors.white54)
                    : null,
              ),
              if (_isUploading)
                const CircularProgressIndicator(),
            ],
          ),
        );
      },
    );
  }
}