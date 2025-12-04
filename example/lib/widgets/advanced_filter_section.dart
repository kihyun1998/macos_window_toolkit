import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdvancedFilterSection extends StatefulWidget {
  final Function({
    int? windowId,
    String? name,
    bool? nameExactMatch,
    bool? nameCaseSensitive,
    bool? nameWildcard,
    String? ownerName,
    bool? ownerNameExactMatch,
    bool? ownerNameCaseSensitive,
    bool? ownerNameWildcard,
    int? processId,
    bool? isOnScreen,
    int? layer,
    double? x,
    double? y,
    double? width,
    double? height,
  })
  onApplyFilters;
  final bool isLoading;

  const AdvancedFilterSection({
    super.key,
    required this.onApplyFilters,
    required this.isLoading,
  });

  @override
  State<AdvancedFilterSection> createState() => _AdvancedFilterSectionState();
}

class _AdvancedFilterSectionState extends State<AdvancedFilterSection> {
  bool _isExpanded = false;
  bool _showBasicFilters = true;
  bool _showPositionFilters = false;
  bool _showAdvancedFilters = false;

  // Controllers
  final _windowIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _processIdController = TextEditingController();
  final _layerController = TextEditingController();
  final _xController = TextEditingController();
  final _yController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();

  // Dropdown value for isOnScreen
  String _isOnScreenValue = 'any'; // 'any', 'yes', 'no'

  // Matching options
  bool _nameExactMatch = false;
  bool _nameCaseSensitive = true;
  bool _nameWildcard = false;
  bool _ownerNameExactMatch = false;
  bool _ownerNameCaseSensitive = true;
  bool _ownerNameWildcard = false;

  @override
  void dispose() {
    _windowIdController.dispose();
    _nameController.dispose();
    _ownerNameController.dispose();
    _processIdController.dispose();
    _layerController.dispose();
    _xController.dispose();
    _yController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  int get _activeFilterCount {
    int count = 0;
    if (_windowIdController.text.isNotEmpty) count++;
    if (_nameController.text.isNotEmpty) count++;
    if (_ownerNameController.text.isNotEmpty) count++;
    if (_processIdController.text.isNotEmpty) count++;
    if (_isOnScreenValue != 'any') count++;
    if (_layerController.text.isNotEmpty) count++;
    if (_xController.text.isNotEmpty) count++;
    if (_yController.text.isNotEmpty) count++;
    if (_widthController.text.isNotEmpty) count++;
    if (_heightController.text.isNotEmpty) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.filter_list, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Advanced Filters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (_activeFilterCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_activeFilterCount',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // Expandable Content
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Basic Filters Section
                  _buildSection(
                    title: 'Basic Filters',
                    icon: Icons.search,
                    isExpanded: _showBasicFilters,
                    onToggle: () =>
                        setState(() => _showBasicFilters = !_showBasicFilters),
                    colorScheme: colorScheme,
                    children: [
                      _buildTextField(
                        controller: _windowIdController,
                        label: 'Window ID',
                        hint: 'e.g., 12345',
                        icon: Icons.tag,
                        colorScheme: colorScheme,
                        isNumeric: true,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _nameController,
                        label: 'Window Title',
                        hint: 'e.g., Gmail, Document1',
                        icon: Icons.title,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              title: const Text(
                                'Exact Match',
                                style: TextStyle(fontSize: 13),
                              ),
                              value: _nameExactMatch,
                              onChanged: widget.isLoading || _nameWildcard
                                  ? null
                                  : (value) {
                                      setState(
                                        () => _nameExactMatch = value ?? false,
                                      );
                                    },
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: CheckboxListTile(
                              title: const Text(
                                'Case Sensitive',
                                style: TextStyle(fontSize: 13),
                              ),
                              value: _nameCaseSensitive,
                              onChanged: widget.isLoading
                                  ? null
                                  : (value) {
                                      setState(
                                        () =>
                                            _nameCaseSensitive = value ?? true,
                                      );
                                    },
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      CheckboxListTile(
                        title: const Text(
                          'Wildcard (* = any chars, ? = single char)',
                          style: TextStyle(fontSize: 13),
                        ),
                        value: _nameWildcard,
                        onChanged: widget.isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _nameWildcard = value ?? false;
                                  if (_nameWildcard) {
                                    _nameExactMatch = false;
                                  }
                                });
                              },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _ownerNameController,
                        label: 'Owner Name (App Name)',
                        hint: 'e.g., Chrome, Safari',
                        icon: Icons.app_settings_alt,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              title: const Text(
                                'Exact Match',
                                style: TextStyle(fontSize: 13),
                              ),
                              value: _ownerNameExactMatch,
                              onChanged: widget.isLoading || _ownerNameWildcard
                                  ? null
                                  : (value) {
                                      setState(
                                        () => _ownerNameExactMatch =
                                            value ?? false,
                                      );
                                    },
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: CheckboxListTile(
                              title: const Text(
                                'Case Sensitive',
                                style: TextStyle(fontSize: 13),
                              ),
                              value: _ownerNameCaseSensitive,
                              onChanged: widget.isLoading
                                  ? null
                                  : (value) {
                                      setState(
                                        () => _ownerNameCaseSensitive =
                                            value ?? true,
                                      );
                                    },
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      CheckboxListTile(
                        title: const Text(
                          'Wildcard (* = any chars, ? = single char)',
                          style: TextStyle(fontSize: 13),
                        ),
                        value: _ownerNameWildcard,
                        onChanged: widget.isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _ownerNameWildcard = value ?? false;
                                  if (_ownerNameWildcard) {
                                    _ownerNameExactMatch = false;
                                  }
                                });
                              },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _processIdController,
                        label: 'Process ID',
                        hint: 'e.g., 67890',
                        icon: Icons.numbers,
                        colorScheme: colorScheme,
                        isNumeric: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Position & Size Section
                  _buildSection(
                    title: 'Position & Size',
                    icon: Icons.aspect_ratio,
                    isExpanded: _showPositionFilters,
                    onToggle: () => setState(
                      () => _showPositionFilters = !_showPositionFilters,
                    ),
                    colorScheme: colorScheme,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _xController,
                              label: 'X',
                              hint: '0',
                              icon: Icons.height,
                              colorScheme: colorScheme,
                              isNumeric: true,
                              isDecimal: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _yController,
                              label: 'Y',
                              hint: '0',
                              icon: Icons.height,
                              colorScheme: colorScheme,
                              isNumeric: true,
                              isDecimal: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _widthController,
                              label: 'Width',
                              hint: '800',
                              icon: Icons.width_normal,
                              colorScheme: colorScheme,
                              isNumeric: true,
                              isDecimal: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _heightController,
                              label: 'Height',
                              hint: '600',
                              icon: Icons.height,
                              colorScheme: colorScheme,
                              isNumeric: true,
                              isDecimal: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Advanced Filters Section
                  _buildSection(
                    title: 'Advanced Filters',
                    icon: Icons.tune,
                    isExpanded: _showAdvancedFilters,
                    onToggle: () => setState(
                      () => _showAdvancedFilters = !_showAdvancedFilters,
                    ),
                    colorScheme: colorScheme,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _isOnScreenValue,
                        decoration: InputDecoration(
                          labelText: 'Is On Screen',
                          prefixIcon: const Icon(Icons.visibility, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: colorScheme.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'any', child: Text('Any')),
                          DropdownMenuItem(value: 'yes', child: Text('Yes')),
                          DropdownMenuItem(value: 'no', child: Text('No')),
                        ],
                        onChanged: widget.isLoading
                            ? null
                            : (value) {
                                setState(() => _isOnScreenValue = value!);
                              },
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _layerController,
                        label: 'Layer',
                        hint: 'e.g., 0 for normal windows',
                        icon: Icons.layers,
                        colorScheme: colorScheme,
                        isNumeric: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _activeFilterCount > 0 && !widget.isLoading
                              ? _applyFilters
                              : null,
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Apply Filters'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: _activeFilterCount > 0
                              ? _clearAllFilters
                              : null,
                          icon: const Icon(Icons.clear_all, size: 18),
                          label: const Text('Clear All'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Help Text
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Fill any combination of filters and click Apply. '
                            'All conditions are combined with AND logic.',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required ColorScheme colorScheme,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: children),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ColorScheme colorScheme,
    bool isNumeric = false,
    bool isDecimal = false,
  }) {
    return TextField(
      controller: controller,
      enabled: !widget.isLoading,
      keyboardType: isNumeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: isNumeric
          ? isDecimal
                ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
                : [FilteringTextInputFormatter.digitsOnly]
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  controller.clear();
                  setState(() {});
                },
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  void _applyFilters() {
    widget.onApplyFilters(
      windowId: _windowIdController.text.isNotEmpty
          ? int.tryParse(_windowIdController.text)
          : null,
      name: _nameController.text.isNotEmpty ? _nameController.text : null,
      nameExactMatch: _nameController.text.isNotEmpty ? _nameExactMatch : null,
      nameCaseSensitive: _nameController.text.isNotEmpty
          ? _nameCaseSensitive
          : null,
      nameWildcard: _nameController.text.isNotEmpty ? _nameWildcard : null,
      ownerName: _ownerNameController.text.isNotEmpty
          ? _ownerNameController.text
          : null,
      ownerNameExactMatch: _ownerNameController.text.isNotEmpty
          ? _ownerNameExactMatch
          : null,
      ownerNameCaseSensitive: _ownerNameController.text.isNotEmpty
          ? _ownerNameCaseSensitive
          : null,
      ownerNameWildcard: _ownerNameController.text.isNotEmpty
          ? _ownerNameWildcard
          : null,
      processId: _processIdController.text.isNotEmpty
          ? int.tryParse(_processIdController.text)
          : null,
      isOnScreen: _isOnScreenValue == 'any'
          ? null
          : _isOnScreenValue == 'yes'
          ? true
          : false,
      layer: _layerController.text.isNotEmpty
          ? int.tryParse(_layerController.text)
          : null,
      x: _xController.text.isNotEmpty
          ? double.tryParse(_xController.text)
          : null,
      y: _yController.text.isNotEmpty
          ? double.tryParse(_yController.text)
          : null,
      width: _widthController.text.isNotEmpty
          ? double.tryParse(_widthController.text)
          : null,
      height: _heightController.text.isNotEmpty
          ? double.tryParse(_heightController.text)
          : null,
    );
  }

  void _clearAllFilters() {
    _windowIdController.clear();
    _nameController.clear();
    _ownerNameController.clear();
    _processIdController.clear();
    _layerController.clear();
    _xController.clear();
    _yController.clear();
    _widthController.clear();
    _heightController.clear();
    setState(() {
      _isOnScreenValue = 'any';
      _nameExactMatch = false;
      _nameCaseSensitive = true;
      _nameWildcard = false;
      _ownerNameExactMatch = false;
      _ownerNameCaseSensitive = true;
      _ownerNameWildcard = false;
    });
  }
}
