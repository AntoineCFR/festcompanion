import 'package:flutter/material.dart';
import '../../services/profile_service.dart';
import '../../pages/profile_page.dart';

class ProfileAvatar extends StatelessWidget {
  final int userId;
  final String username;

  const ProfileAvatar({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: ProfileService.getPhotoUrl(userId),
      builder: (context, snapshot) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(
                  username: username,
                  userId: userId,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[800],
              backgroundImage: snapshot.hasData
                  ? NetworkImage('${snapshot.data}!${DateTime.now().millisecondsSinceEpoch}')
                  : null,
              child: snapshot.hasData
                  ? null
                  : const Icon(Icons.account_circle, color: Colors.white),
            ),
          ),
        );
      },
    );
  }
}