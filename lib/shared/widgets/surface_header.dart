import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/models/listing.dart';
import '../../core/services/api/identity_cache.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/responsive.dart';
import '../../features/profile/view/profile_page.dart';

/// The header every surface wears: title, a line of context, and the avatar.
///
/// One widget so the three tabs cannot drift apart, and so the way to reach
/// Profile is in the same place on all of them — it is not a tab any more, and
/// a control that moves around is a control people stop looking for.
class SurfaceHeader extends StatelessWidget {
  const SurfaceHeader({
    super.key,
    this.title = '',
    this.subtitle,
    this.trailing,
    this.leading,
  });

  /// Ignored when [leading] is supplied — that replaces the whole title block.
  final String title;
  final String? subtitle;

  /// Sits to the left of the avatar — counters, a refresh button.
  final Widget? trailing;

  /// Replaces the title block entirely (the Ona mark lockup, for instance).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 14, 8),
      // Bounded like everything under it. The header was the one unbounded
      // thing on these screens, so on a tablet the title sat to the left of
      // the cards it was labelling.
      child: ContentBounds(
        child: Row(
          children: <Widget>[
            Expanded(
              child: leading ??
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  height: 1.05,
                                ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
            ),
            if (trailing != null) ...<Widget>[
              trailing!,
              const SizedBox(width: 10),
            ],
            const ProfileAvatarButton(),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: -0.15, curve: Curves.easeOutCubic);
  }
}

/// The avatar that opens Profile.
///
/// Resolves the signed-in user once per app run and caches it here: three
/// surfaces each rendering a header would otherwise each fire `/api/me` on
/// every rebuild, and the answer changes about as often as someone changes job.
class ProfileAvatarButton extends StatefulWidget {
  const ProfileAvatarButton({super.key});

  @override
  State<ProfileAvatarButton> createState() => _ProfileAvatarButtonState();
}

class _ProfileAvatarButtonState extends State<ProfileAvatarButton> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Deduplicated in the cache: the shell asks for this in the same frame,
    // and both asks share one request. A failure is not reported here — the
    // header is a 38px circle, and Profile says so properly.
    await IdentityCache.ensure();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final Me? me = IdentityCache.current;

    return Semantics(
      button: true,
      label: 'Profile',
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ProfilePage()),
        ),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.logoGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.green.withValues(alpha: 0.32),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            me?.initials ?? '·',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

/// A rounded search field, shared by Pipeline and Listings.
///
/// Not named `SearchBar`: Material ships a widget by that name, and importing
/// both would make every use of it ambiguous.
class RoundedSearchField extends StatelessWidget {
  const RoundedSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onSubmitted,
    this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onSubmitted;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      // Search on submit, not per keystroke: each one is a database query, and
      // typing "Siddharth" would otherwise fire nine of them.
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        isDense: true,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
        suffixIcon: onClear == null
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: onClear,
              ),
        border: _border(AppColors.cardBorder),
        enabledBorder: _border(AppColors.cardBorder),
        focusedBorder: _border(AppColors.green),
      ),
    );
  }

  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        borderSide: BorderSide(color: color),
      );
}
