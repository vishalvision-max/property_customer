import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/owner_profile_provider.dart';
import '../../widgets/primary_button.dart';

// Keep styling close to HomeScreen design tokens
const _kPrimary = Color(0xFF6C5CE7);
const _kBg = Color(0xFFF6F7FB);
const _kTextDark = Color(0xFF1A1A2E);
const _kTextMid = Color(0xFF6B7280);
const _kBorder = Color(0xFFE5E7EB);

class EditOwnerProfileScreen extends ConsumerStatefulWidget {
  const EditOwnerProfileScreen({super.key});

  @override
  ConsumerState<EditOwnerProfileScreen> createState() =>
      _EditOwnerProfileScreenState();
}

class _EditOwnerProfileScreenState
    extends ConsumerState<EditOwnerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _picker = ImagePicker();
  File? _pickedImage;
  bool _saving = false;

  String _normalizeImage(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return v;
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    return Uri.parse(
      'https://propertysearch.visionvivante.in',
    ).resolve('/storage/$v').toString();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final token = ref.read(authProvider).user?.token;
      if (token != null && token.trim().isNotEmpty) {
        ref.read(ownerProfileProvider.notifier).load(token: token.trim());
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    if (kIsWeb) return;
    try {
      final x = await _picker.pickImage(source: source, imageQuality: 85);
      if (x == null) return;
      setState(() => _pickedImage = File(x.path));
    } catch (_) {
      // ignore
    }
  }

  Future<void> _showImageOptions() async {
    if (kIsWeb) return;
    if (_saving || ref.read(ownerProfileProvider).isLoading) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Gallery'),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await _pick(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Camera'),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await _pick(ImageSource.camera);
                  },
                ),
                if (_pickedImage != null)
                  ListTile(
                    leading: const Icon(Icons.close_rounded),
                    title: const Text('Remove'),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      setState(() => _pickedImage = null);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final ownerState = ref.watch(ownerProfileProvider);
    final ownerImage = ownerState.profile == null
        ? ''
        : _normalizeImage(ownerState.profile!.imageUrl);

    ref.listen(ownerProfileProvider, (prev, next) {
      final p = next.profile;
      if (p != null && p.name.trim().isNotEmpty && _name.text.trim().isEmpty) {
        _name.text = p.name.trim();
      }
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!.replaceFirst('Exception: ', '')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final canSubmit =
        !_saving && !ownerState.isLoading && _name.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.w900, color: _kTextDark),
        ),
      ),
      body: ListView(
        padding: AppSpacing.pagePadding,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _kBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kPrimary.withValues(alpha: 0.12),
                    border: Border.all(
                      color: _kPrimary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: _kPrimary,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (ownerState.profile?.name.trim().isNotEmpty ?? false)
                            ? ownerState.profile!.name.trim()
                            : ((user == null || user.name.trim().isEmpty)
                                  ? 'Guest'
                                  : user.name.trim()),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: _kTextDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (user == null || user.email.trim().isEmpty)
                            ? '-'
                            : user.email.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _kTextMid,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _kBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Owner Details',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: _kTextDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: InkWell(
                      onTap: (_saving || ownerState.isLoading || kIsWeb)
                          ? null
                          : _showImageOptions,
                      borderRadius: BorderRadius.circular(52),
                      child: Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _kPrimary.withValues(alpha: 0.10),
                          border: Border.all(
                            color: _kPrimary.withValues(alpha: 0.18),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _pickedImage != null
                            ? Image.file(_pickedImage!, fit: BoxFit.cover)
                            : (ownerImage.isEmpty
                                  ? const Icon(
                                      Icons.person_rounded,
                                      color: _kPrimary,
                                      size: 40,
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: ownerImage,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) =>
                                          const Icon(
                                            Icons.person_rounded,
                                            color: _kPrimary,
                                            size: 40,
                                          ),
                                    )),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      kIsWeb
                          ? 'Image upload not supported'
                          : 'Tap to change photo',
                      style: const TextStyle(
                        color: _kTextMid,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _name,
                    enabled: !_saving && !ownerState.isLoading,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Name is required'
                        : null,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: 'Save',
                    isLoading: _saving || ownerState.isLoading,
                    onPressed: canSubmit
                        ? () async {
                            if (!_formKey.currentState!.validate()) return;
                            final token = ref.read(authProvider).user?.token;
                            if (token == null || token.trim().isEmpty) return;

                            final router = GoRouter.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            setState(() => _saving = true);
                            final updated = await ref
                                .read(ownerProfileProvider.notifier)
                                .update(
                                  token: token.trim(),
                                  name: _name.text.trim(),
                                  imageFile: _pickedImage,
                                );
                            if (!mounted) return;
                            setState(() => _saving = false);
                            if (updated != null) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Profile updated'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              router.pop();
                            }
                          }
                        : null,
                    leading: const Icon(Icons.save_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
