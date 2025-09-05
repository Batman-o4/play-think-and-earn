import 'package:flutter/material.dart';
import 'package:skillstreak/utils/app_theme.dart';

class AvatarSelector extends StatelessWidget {
  final String? selectedAvatarPath;
  final Function(String) onAvatarSelected;

  const AvatarSelector({
    Key? key,
    this.selectedAvatarPath,
    required this.onAvatarSelected,
  }) : super(key: key);

  static const List<String> _avatarPaths = [
    'assets/images/avatar_1.png',
    'assets/images/avatar_2.png',
    'assets/images/avatar_3.png',
    'assets/images/avatar_4.png',
    'assets/images/avatar_5.png',
    'assets/images/avatar_6.png',
    'assets/images/avatar_7.png',
    'assets/images/avatar_8.png',
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _avatarPaths.length,
      itemBuilder: (context, index) {
        final avatarPath = _avatarPaths[index];
        final isSelected = selectedAvatarPath == avatarPath;

        return GestureDetector(
          onTap: () => onAvatarSelected(avatarPath),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                width: isSelected ? 3 : 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: ClipOval(
              child: _buildAvatarImage(avatarPath, index),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarImage(String avatarPath, int index) {
    // Since we don't have actual avatar images, we'll create colorful placeholder avatars
    final colors = [
      Colors.red[300]!,
      Colors.blue[300]!,
      Colors.green[300]!,
      Colors.orange[300]!,
      Colors.purple[300]!,
      Colors.teal[300]!,
      Colors.pink[300]!,
      Colors.indigo[300]!,
    ];

    final icons = [
      Icons.face,
      Icons.pets,
      Icons.star,
      Icons.favorite,
      Icons.flash_on,
      Icons.music_note,
      Icons.palette,
      Icons.rocket_launch,
    ];

    return Container(
      color: colors[index % colors.length],
      child: Center(
        child: Icon(
          icons[index % icons.length],
          size: 32,
          color: Colors.white,
        ),
      ),
    );
  }
}