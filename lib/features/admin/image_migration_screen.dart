import 'package:flutter/material.dart';
import '../../core/services/image_migration_service.dart';
import '../../shared/widgets/custom_button.dart';
import '../../core/constants/app_colors.dart';

class ImageMigrationScreen extends StatefulWidget {
  const ImageMigrationScreen({super.key});

  @override
  State<ImageMigrationScreen> createState() => _ImageMigrationScreenState();
}

class _ImageMigrationScreenState extends State<ImageMigrationScreen> {
  bool _isMigrating = false;
  Map<String, dynamic>? _results;
  String _status = 'Ready to start migration';
  final ImageMigrationService _migrationService = ImageMigrationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Migration Utility'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 24),
            _buildStatusSection(),
            if (_results != null) ...[
              const SizedBox(height: 24),
              _buildResultsSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Image Migration Utility',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This utility will migrate all product images from local file paths to Cloudinary URLs.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'The process will:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text('• Find all products with local file paths'),
            const Text('• Upload those images to Cloudinary'),
            const Text('• Update product records in Firebase'),
            const Text('• Keep network URLs unchanged'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade800),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Warning: This process may take some time depending on the number of images.',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: 'Start Migration',
            isLoading: _isMigrating,
            onPressed: _isMigrating ? null : _startMigration,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Back'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (_isMigrating)
                    Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(right: 8),
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  else
                    Icon(
                      _results == null
                          ? Icons.hourglass_empty
                          : (_results!['success'] == true
                              ? Icons.check_circle
                              : Icons.error),
                      color: _results == null
                          ? Colors.grey
                          : (_results!['success'] == true
                              ? Colors.green
                              : Colors.red),
                    ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_status)),
                ],
              ),
              if (_results != null && _results!['results'] != null) ...[
                const SizedBox(height: 16),
                _buildMigrationSummary(_results!['results']),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMigrationSummary(Map<String, dynamic> results) {
    final total = results['total'] as int;
    final success = results['success'] as int;
    final failed = results['failed'] as int;
    final skipped = results['skipped'] as int;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Total products: $total'),
        const SizedBox(height: 4),
        Text('Successfully migrated: $success', 
          style: const TextStyle(color: Colors.green)),
        const SizedBox(height: 4),
        Text('Failed: $failed', 
          style: TextStyle(color: failed > 0 ? Colors.red : Colors.black)),
        const SizedBox(height: 4),
        Text('Skipped (no local images): $skipped'),
      ],
    );
  }

  Widget _buildResultsSection() {
    if (_results == null || _results!['results'] == null) {
      return const SizedBox();
    }

    final results = _results!['results'];
    final products = results['products'] as List<dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detailed Results',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 1,
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: products.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final product = products[index] as Map<String, dynamic>;
              final status = product['status'] as String;
              
              Color statusColor;
              IconData statusIcon;
              
              switch (status) {
                case 'success':
                  statusColor = Colors.green;
                  statusIcon = Icons.check_circle;
                  break;
                case 'failed':
                  statusColor = Colors.red;
                  statusIcon = Icons.error;
                  break;
                default:
                  statusColor = Colors.grey;
                  statusIcon = Icons.remove_circle_outline;
              }
              
              return ListTile(
                leading: Icon(statusIcon, color: statusColor),
                title: Text(product['name'] ?? product['id'] ?? 'Unknown product'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: ${product['status']}'),
                    if (product['reason'] != null)
                      Text('Reason: ${product['reason']}'),
                    if (product['migrated_urls'] != null && product['migrated_urls'] is List) ...[
                      const SizedBox(height: 4),
                      const Text('Migrated URLs:',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      ...List<Widget>.from(
                        (product['migrated_urls'] as List).map(
                          (url) => Padding(
                            padding: const EdgeInsets.only(left: 8, top: 2),
                            child: Text(url.toString(),
                                style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                isThreeLine: true,
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _startMigration() async {
    setState(() {
      _isMigrating = true;
      _status = 'Migrating images to Cloudinary...';
      _results = null;
    });

    try {
      final results = await _migrationService.migrateProductImages();
      
      setState(() {
        _isMigrating = false;
        _results = results;
        _status = results['success'] == true
            ? 'Migration completed successfully!'
            : 'Migration failed: ${results['message']}';
      });
      
      if (!mounted) return;
      
      // Show a snackbar with the results
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_status),
          backgroundColor: _results!['success'] == true ? Colors.green : Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      setState(() {
        _isMigrating = false;
        _status = 'Migration failed: $e';
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Migration failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
