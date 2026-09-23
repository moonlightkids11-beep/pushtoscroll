import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../di/providers.dart';
import '../domain/restricted_app.dart';
import 'restricted_app_manager.dart';

class RestrictedAppsScreen extends ConsumerStatefulWidget {
  const RestrictedAppsScreen({super.key});

  @override
  ConsumerState<RestrictedAppsScreen> createState() => _RestrictedAppsScreenState();
}

class _RestrictedAppsScreenState extends ConsumerState<RestrictedAppsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(restrictedAppManagerProvider).loadApps();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final manager = ref.watch(restrictedAppManagerProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _navigateBack(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            tooltip: 'Back',
            onPressed: () => _navigateBack(context),
          ),
          title: const Text(
            'RESTRICTED APPS',
            style: TextStyle(
              color: Colors.white,
              letterSpacing: 3.0,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(
              color: Colors.white12,
              height: 1.0,
            ),
          ),
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: manager,
            builder: (context, _) {
              return Column(
                children: [
                  // Header Summary & Search Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${manager.restrictedCount} RESTRICTED',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                              ),
                            ),
                            if (manager.apps.isNotEmpty)
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () => manager.selectAll(),
                                    style: TextButton.styleFrom(
                                      minimumSize: const Size(48, 44),
                                      foregroundColor: Colors.white70,
                                    ),
                                    child: const Text(
                                      'SELECT ALL',
                                      style: TextStyle(
                                        fontSize: 11,
                                        letterSpacing: 1.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  TextButton(
                                    onPressed: () => manager.clearAll(),
                                    style: TextButton.styleFrom(
                                      minimumSize: const Size(48, 44),
                                      foregroundColor: Colors.white38,
                                    ),
                                    child: const Text(
                                      'CLEAR ALL',
                                      style: TextStyle(
                                        fontSize: 11,
                                        letterSpacing: 1.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Search Bar
                        TextField(
                          controller: _searchController,
                          onChanged: (value) => manager.setSearchQuery(value),
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            hintText: 'Search installed apps...',
                            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                            prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      manager.setSearchQuery('');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.05),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.white24),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.white12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Apps List Content
                  Expanded(
                    child: _buildContent(context, manager),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, RestrictedAppManager manager) {
    if (manager.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2.0,
        ),
      );
    }

    if (manager.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.white70),
              const SizedBox(height: 16),
              Text(
                manager.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => manager.loadApps(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('RETRY', style: TextStyle(letterSpacing: 1.5)),
              ),
            ],
          ),
        ),
      );
    }

    final displayedApps = manager.filteredApps;

    if (displayedApps.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox_outlined, size: 48, color: Colors.white24),
              const SizedBox(height: 12),
              Text(
                manager.searchQuery.isNotEmpty
                    ? 'No apps matching "${manager.searchQuery}"'
                    : 'No launchable apps found on device.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: displayedApps.length,
      separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
      itemBuilder: (context, index) {
        final app = displayedApps[index];
        return _AppTile(
          app: app,
          onToggle: () => manager.toggleAppRestriction(app.packageName),
        );
      },
    );
  }
}

class _AppTile extends StatelessWidget {
  final RestrictedApp app;
  final VoidCallback onToggle;

  const _AppTile({
    required this.app,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      splashColor: Colors.white10,
      highlightColor: Colors.white.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 4.0),
        child: Row(
          children: [
            // App Icon
            _buildAppIcon(app),
            const SizedBox(width: 16),

            // App Name & Package Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.name,
                    style: TextStyle(
                      color: app.isRestricted ? Colors.white : Colors.white70,
                      fontWeight: app.isRestricted ? FontWeight.bold : FontWeight.w500,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    app.packageName,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // B&W Checkbox Indicator
            _buildCheckbox(app.isRestricted),
          ],
        ),
      ),
    );
  }

  Widget _buildAppIcon(RestrictedApp app) {
    if (app.iconBytes != null && app.iconBytes!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          app.iconBytes!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(app.name),
        ),
      );
    }
    return _buildFallbackIcon(app.name);
  }

  Widget _buildFallbackIcon(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildCheckbox(bool isChecked) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isChecked ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isChecked ? Colors.white : Colors.white38,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: isChecked
          ? const Icon(
              Icons.check,
              size: 16,
              color: Colors.black,
            )
          : null,
    );
  }
}
