import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexobank_mobile/core/router/app_router.dart';
import 'package:nexobank_mobile/core/storage/secure_storage.dart';
import 'package:nexobank_mobile/features/notifications/presentation/providers/notifications_notifier.dart';
import 'package:nexobank_mobile/features/profile/presentation/providers/profile_notifier.dart';
import 'package:nexobank_mobile/features/profile/presentation/widgets/profile_avatar_widget.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error al cargar perfil: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Sin datos de perfil'));
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(child: ProfileAvatarWidget(name: profile.name, size: 88)),
              const SizedBox(height: 24),
              _InfoTile(label: 'Nombre', value: profile.name),
              _InfoTile(label: 'Correo', value: profile.email),
              if (profile.phone != null)
                _InfoTile(label: 'Teléfono', value: profile.phone!),
              _InfoTile(
                label: 'Miembro desde',
                value: _formatDate(profile.createdAt),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.push(AppRoutes.editProfile),
                child: const Text('Editar perfil'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _logout(context, ref),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Cerrar sesión'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(notificationsNotifierProvider.notifier).disconnect();
    await ref.read(secureStorageProvider).clearTokens();
    ref.read(routerAuthNotifierProvider).onAuthStateChanged();
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16)),
          const Divider(),
        ],
      ),
    );
  }
}
