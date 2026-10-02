import 'package:flutter/material.dart';
import '../../../core/supabase/admin_supabase.dart';
import '../../../core/theme/admin_theme.dart';
import '../../auth/domain/admin_user_model.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../lexicon/data/lexicon_repository.dart';
import '../../lexicon/presentation/controllers/lexicon_controller.dart';
import '../../lexicon/presentation/screens/lexicon_list_screen.dart';

import '../../review/data/review_repository.dart';
import '../../review/presentation/controllers/review_queue_controller.dart';
import '../../review/presentation/screens/review_queue_screen.dart';

import '../../csv_import/data/csv_import_repository.dart';
import '../../csv_import/presentation/controllers/csv_import_controller.dart';
import '../../csv_import/presentation/screens/csv_import_screen.dart';

import '../../quality/data/quality_repository.dart';
import '../../quality/presentation/controllers/quality_dashboard_controller.dart';
import '../../quality/presentation/screens/quality_dashboard_screen.dart';

import '../../csv_export/data/csv_export_repository.dart';
import '../../csv_export/presentation/controllers/csv_export_controller.dart';
import '../../csv_export/presentation/screens/csv_export_screen.dart';

enum AdminNavSection {
  dashboard,
  masterLexicon,
  reviewQueue,
  csvImport,
  csvExport,
  settings,
}

class AdminShellScreen extends StatefulWidget {
  final AuthController authController;
  final LexiconRepository? lexiconRepository; // Optional injection for testing
  final ReviewRepository? reviewRepository; // Optional injection for testing
  final CsvImportRepository? csvImportRepository; // Optional injection for testing
  final CsvExportRepository? csvExportRepository; // Optional injection for testing
  final QualityRepository? qualityRepository; // Optional injection for testing

  const AdminShellScreen({
    super.key,
    required this.authController,
    this.lexiconRepository,
    this.reviewRepository,
    this.csvImportRepository,
    this.csvExportRepository,
    this.qualityRepository,
  });

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  AdminNavSection _activeSection = AdminNavSection.masterLexicon;
  late final LexiconRepository _repository;
  late final LexiconController _lexiconController;
  late final ReviewRepository _reviewRepository;
  late final ReviewQueueController _reviewQueueController;
  late final CsvImportRepository _csvImportRepository;
  late final CsvImportController _csvImportController;
  late final CsvExportRepository _csvExportRepository;
  late final CsvExportController _csvExportController;
  late final QualityRepository _qualityRepository;
  late final QualityDashboardController _qualityController;

  @override
  void initState() {
    super.initState();
    _repository = widget.lexiconRepository ??
        SupabaseLexiconRepository(AdminSupabase.client);
    _lexiconController = LexiconController(repository: _repository);
    _reviewRepository = widget.reviewRepository ??
        SupabaseReviewRepository(client: AdminSupabase.client);
    _reviewQueueController =
        ReviewQueueController(repository: _reviewRepository);
    _csvImportRepository = widget.csvImportRepository ??
        SupabaseCsvImportRepository(AdminSupabase.client);
    _csvImportController =
        CsvImportController(_csvImportRepository);
    _csvExportRepository = widget.csvExportRepository ??
        SupabaseCsvExportRepository(AdminSupabase.client);
    _csvExportController =
        CsvExportController(repository: _csvExportRepository);
    _qualityRepository = widget.qualityRepository ??
        SupabaseQualityRepository(AdminSupabase.client);
    _qualityController =
        QualityDashboardController(repository: _qualityRepository);
  }

  @override
  void dispose() {
    _lexiconController.dispose();
    _reviewQueueController.dispose();
    _csvImportController.dispose();
    _csvExportController.dispose();
    _qualityController.dispose();
    super.dispose();
  }

  Color _getRoleBadgeColor(AdminRole role) {
    switch (role) {
      case AdminRole.superadmin:
        return AdminTheme.roleSuperadmin;
      case AdminRole.reviewer:
        return AdminTheme.roleReviewer;
      case AdminRole.editor:
        return AdminTheme.roleEditor;
      case AdminRole.unknown:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = widget.authController.currentAdmin;
    final role = admin?.role ?? AdminRole.unknown;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_stories, size: 24, color: Colors.white),
            SizedBox(width: 12),
            Flexible(
              child: Text(
                'German Master Lexicon — Admin Portal',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          if (admin != null) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRoleBadgeColor(admin.role).withValues(alpha: 0.2),
                  border: Border.all(
                    color: _getRoleBadgeColor(admin.role),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  admin.role.label,
                  style: TextStyle(
                    color: _getRoleBadgeColor(admin.role),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Center(
              child: Text(
                admin.email,
                style: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)),
              ),
            ),
            const SizedBox(width: 16),
          ],
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout, size: 20),
            onPressed: () => _confirmLogout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Sidebar Navigation
          _buildSidebar(role),
          // Divider
          const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
          // Main Workspace
          Expanded(
            child: _buildMainContent(role),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(AdminRole role) {
    return Container(
      width: 240,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildNavItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            section: AdminNavSection.dashboard,
          ),
          _buildNavItem(
            icon: Icons.menu_book,
            label: 'Master Lexicon',
            section: AdminNavSection.masterLexicon,
          ),
          _buildNavItem(
            icon: Icons.rate_review_outlined,
            label: 'Review Queue',
            section: AdminNavSection.reviewQueue,
          ),
          const Divider(height: 24, indent: 16, endIndent: 16),
          _buildNavItem(
            icon: Icons.file_upload_outlined,
            label: 'CSV Import',
            section: AdminNavSection.csvImport,
          ),
          _buildNavItem(
            icon: Icons.file_download_outlined,
            label: 'CSV Export',
            section: AdminNavSection.csvExport,
          ),
          const Divider(height: 24, indent: 16, endIndent: 16),
          if (role == AdminRole.superadmin) ...[
            _buildNavItem(
              icon: Icons.admin_panel_settings_outlined,
              label: 'User Management',
              section: AdminNavSection.settings,
            ),
          ],
          const Spacer(),
          // Environment / Role indicator
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'RLS Enforced',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Connected to Phase 12A',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required AdminNavSection section,
  }) {
    final isSelected = _activeSection == section;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? AdminTheme.primaryAccent.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          size: 20,
          color: isSelected ? AdminTheme.primaryAccent : const Color(0xFF64748B),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AdminTheme.primaryAccent : const Color(0xFF334155),
          ),
        ),
        onTap: () {
          setState(() => _activeSection = section);
        },
      ),
    );
  }

  Widget _buildMainContent(AdminRole role) {
    switch (_activeSection) {
      case AdminNavSection.dashboard:
        return QualityDashboardScreen(
          controller: _qualityController,
          userRole: role,
          onNavigateToLexicon: () {
            setState(() => _activeSection = AdminNavSection.masterLexicon);
          },
          onNavigateToReviewQueue: () {
            setState(() => _activeSection = AdminNavSection.reviewQueue);
          },
        );
      case AdminNavSection.masterLexicon:
        return LexiconListScreen(
          controller: _lexiconController,
          repository: _repository,
          userRole: role,
          onNavigateToExport: () {
            setState(() => _activeSection = AdminNavSection.csvExport);
          },
        );
      case AdminNavSection.reviewQueue:
        return ReviewQueueScreen(
          controller: _reviewQueueController,
          lexiconRepository: _repository,
          userRole: role,
          lexiconController: _lexiconController,
        );
      case AdminNavSection.csvImport:
        return CsvImportScreen(
          controller: _csvImportController,
          userRole: role,
          currentUserId: widget.authController.currentAdmin?.id,
          onNavigateToReviewQueue: () {
            setState(() => _activeSection = AdminNavSection.reviewQueue);
          },
          onNavigateToLexicon: () {
            setState(() => _activeSection = AdminNavSection.masterLexicon);
          },
        );
      case AdminNavSection.csvExport:
        return CsvExportScreen(
          controller: _csvExportController,
          userRole: role,
          onNavigateToLexicon: () {
            setState(() => _activeSection = AdminNavSection.masterLexicon);
          },
        );
      case AdminNavSection.settings:
        if (role != AdminRole.superadmin) {
          return _buildPlaceholderModule(
            'Access Restricted',
            'Admin user management is restricted to Superadmins.',
            Icons.lock_outline,
          );
        }
        return _buildPlaceholderModule(
          'User Management',
          'Admin accounts, privilege assignment, and system preferences.',
          Icons.admin_panel_settings_outlined,
        );
    }
  }


  Widget _buildPlaceholderModule(
      String title, String description, IconData icon) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 48, color: const Color(0xFF94A3B8)),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text(
            'Are you sure you want to end your administrative session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await widget.authController.signOut();
    }
  }
}
