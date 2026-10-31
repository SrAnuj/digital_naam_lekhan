import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'package:sankalp/features/home/data/naam_library_repository.dart';

// ───────────────────────── 8. CREATE SANKALP ─────────────────────────

class CreateSankalpScreen extends StatefulWidget {
  const CreateSankalpScreen({super.key});

  @override
  State<CreateSankalpScreen> createState() => _CreateSankalpScreenState();
}

class _CreateSankalpScreenState extends State<CreateSankalpScreen> {
  List<Map<String, dynamic>> _members = <Map<String, dynamic>>[];

  bool _isLoading = true;
  String? _errorMessage;

  late final TextEditingController _name =
      TextEditingController(text: AppState.name);

  late final TextEditingController _intent =
      TextEditingController(text: AppState.intention);

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final members = await NaamLibraryRepository.fetchSankalpMembers();

      if (!mounted) return;

      if (members.isEmpty) {
        throw Exception('No Sankalp members available.');
      }

      Map<String, dynamic>? selectedMember;

      // Restore previously selected member by database ID.
      for (final member in members) {
        final id = int.tryParse(
          member['id']?.toString() ?? '',
        );

        if (id != null && id == AppState.sankalpMemberId) {
          selectedMember = member;
          break;
        }
      }

      // Restore selection by member name.
      if (selectedMember == null) {
        for (final member in members) {
          final memberName = member['name']?.toString().trim() ?? '';

          if (memberName.toLowerCase() ==
              AppState.forWhom.trim().toLowerCase()) {
            selectedMember = member;
            break;
          }
        }
      }

      // Default selection: Myself, otherwise first API member.
      selectedMember ??= members.firstWhere(
        (member) => member['name']?.toString().toLowerCase() == 'myself',
        orElse: () => members.first,
      );

      final selectedId = int.tryParse(
        selectedMember['id']?.toString() ?? '',
      );

      if (selectedId == null) {
        throw Exception('Invalid Sankalp member ID.');
      }

      AppState.sankalpMemberId = selectedId;
      AppState.forWhom = selectedMember['name']?.toString() ?? '';

      if (!mounted) return;

      setState(() {
        _members = List<Map<String, dynamic>>.from(members);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _selectMember(Map<String, dynamic> member) {
    final id = int.tryParse(
      member['id']?.toString() ?? '',
    );

    if (id == null) return;

    setState(() {
      AppState.sankalpMemberId = id;
      AppState.forWhom = member['name']?.toString() ?? '';
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _intent.dispose();
    super.dispose();
  }

  InputDecoration _dec() => InputDecoration(
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.maroon,
            width: 1.4,
          ),
        ),
      );

  Widget _buildMemberList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(
            color: AppColors.maroon,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppText.body(
                  13,
                  c: AppColors.muted,
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Retry',
                trailing: Icons.refresh_rounded,
                onTap: _loadMembers,
              ),
            ],
          ),
        ),
      );
    }

    if (_members.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No Sankalp members available.'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];

        final memberId = int.tryParse(
          member['id']?.toString() ?? '',
        );

        return SelectTile(
          label: member['name']?.toString() ?? '',
          selected: AppState.sankalpMemberId == memberId,
          onTap: () => _selectMember(member),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DevScaffold(
      title: 'Create Your Sankalp',
      subtitle: 'यह संकल्प किसके है ?',
      bottom: PrimaryButton(
        label: 'Continue',
        trailing: Icons.arrow_forward_rounded,
        onTap: () {
          if (_isLoading || _errorMessage != null) return;

          if (AppState.sankalpMemberId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a Sankalp member.'),
              ),
            );
            return;
          }

          AppState.name =
              _name.text.trim().isEmpty ? 'Devotee' : _name.text.trim();

          AppState.intention = _intent.text.trim();

          Navigator.pushNamed(context, '/design');
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildMemberList(),
          const SizedBox(height: 12),
          Text(
            'Name',
            style: AppText.body(
              12,
              c: AppColors.muted,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _name,
            style: AppText.body(14.5),
            decoration: _dec(),
          ),
          const SizedBox(height: 16),
          Text(
            'Sankalp Intention (Optional)',
            style: AppText.body(
              12,
              c: AppColors.muted,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _intent,
            style: AppText.body(14.5),
            maxLines: 3,
            decoration: _dec().copyWith(
              hintText: 'For the peace and happiness of my family.',
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── 9. CHOOSE DESIGN ─────────────────────────

class MiniPage extends StatelessWidget {
  final int style;

  const MiniPage({
    super.key,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final lines = Column(
      children: [
        for (var i = 0; i < 9; i++)
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.line,
                    width: 0.8,
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'राम',
                  style: AppText.hindi(
                    8,
                    c: AppColors.muted.o(0.55),
                    w: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    if (style == 0) {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(4),
        ),
        child: lines,
      );
    }

    if (style == 1) {
      return Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppColors.creamLight,
            border: Border.all(
              color: AppColors.maroon,
              width: 1,
            ),
          ),
          child: lines,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: const LinearGradient(
          colors: [
            AppColors.goldLight,
            AppColors.gold,
            AppColors.maroon,
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF3CC),
              Color(0xFFFBE5A8),
            ],
          ),
        ),
        child: Column(
          children: [
            Text(
              'ॐ',
              style: AppText.hindi(
                9,
                c: AppColors.maroon,
              ),
            ),
            Expanded(child: lines),
          ],
        ),
      ),
    );
  }
}

class ChooseDesignScreen extends StatefulWidget {
  const ChooseDesignScreen({super.key});

  @override
  State<ChooseDesignScreen> createState() => _ChooseDesignScreenState();
}

class _ChooseDesignScreenState extends State<ChooseDesignScreen> {
  List<Map<String, dynamic>> _designs = [];

  bool _isLoading = true;
  String? _errorMessage;
  int? _selectedDesignId;

  @override
  void initState() {
    super.initState();
    _loadDesigns();
  }

  Future<void> _loadDesigns() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final designs = await NaamLibraryRepository.fetchDesigns();

      if (!mounted) return;

      if (designs.isEmpty) {
        throw Exception('No active writing designs available.');
      }

      Map<String, dynamic>? selected;

      // Restore previously selected design.
      for (final design in designs) {
        final id = int.tryParse(design['id']?.toString() ?? '');

        if (id != null && id == AppState.designId) {
          selected = design;
          break;
        }
      }

      // Default to the first available design.
      selected ??= designs.first;

      final selectedId = int.tryParse(selected['id']?.toString() ?? '');

      if (selectedId == null) {
        throw Exception('Invalid design ID received from server.');
      }

      setState(() {
        _designs = List<Map<String, dynamic>>.from(designs);
        _selectedDesignId = selectedId;
        _isLoading = false;
      });

      _saveSelectedDesign(selected);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _saveSelectedDesign(Map<String, dynamic> design) {
    final id = int.tryParse(design['id']?.toString() ?? '');

    if (id == null) return;

    AppState.designId = id;
    AppState.designName = design['name']?.toString();

    AppState.designPreviewImageUrl = design['preview_image_url']?.toString();

    AppState.designAssetUrl = design['asset_url']?.toString();

    // Keep the existing index variable for compatibility.
    AppState.design = _designs.indexOf(design);
  }

  Widget _buildDesignCard(Map<String, dynamic> design) {
    final id = int.tryParse(design['id']?.toString() ?? '');
    final selected = id != null && id == _selectedDesignId;

    final name = design['name']?.toString() ?? 'Writing Design';
    final imageUrl = design['preview_image_url']?.toString() ?? '';

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (id == null) return;

          setState(() {
            _selectedDesignId = id;
          });

          _saveSelectedDesign(design);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 190,
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? AppColors.maroon : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: AppColors.muted,
                                size: 35,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;

                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                        )
                      : const Center(
                          child: Icon(
                            Icons.menu_book_rounded,
                            color: AppColors.maroon,
                            size: 35,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppText.body(
                  13,
                  c: selected ? AppColors.maroon : AppColors.ink,
                  w: FontWeight.w600,
                ),
              ),
              Text(
                design['description']?.toString() ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppText.body(
                  10,
                  c: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: AppText.body(13, c: AppColors.muted),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadDesigns,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _designs.map(_buildDesignCard).toList(),
        ),
        const SizedBox(height: 28),
        DevCard(
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppColors.gold,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'You can change the writing design later from Settings. Your Naam are never lost.',
                  style: AppText.body(12, c: AppColors.muted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DevScaffold(
      title: 'Choose Writing Style',
      subtitle: 'अपनी पसंद का डिज़ाइन चुनें',
      bottom: PrimaryButton(
        label: 'Continue',
        trailing: Icons.arrow_forward_rounded,
        onTap: () {
          if (_isLoading || _errorMessage != null) return;

          if (_selectedDesignId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a writing design.'),
              ),
            );
            return;
          }

          Navigator.pushNamed(context, '/preview');
        },
      ),
      body: _buildContent(),
    );
  }
}
// ───────────────────────── 10. PREVIEW PUSTIKA ─────────────────────────


class PreviewPustikaScreen extends StatefulWidget {
  const PreviewPustikaScreen({super.key});

  @override
  State<PreviewPustikaScreen> createState() => _PreviewPustikaScreenState();
}

class _PreviewPustikaScreenState extends State<PreviewPustikaScreen> {
  bool _isCreatingSankalp = false;

  Future<void> _startSankalp() async {
    if (_isCreatingSankalp) return;

    final deity = AppState.deity;

    if (deity == null) {
      _showMessage('Please choose your Naam first.');
      return;
    }

    final naamLibraryId = int.tryParse(deity.id);

    if (naamLibraryId == null) {
      _showMessage('Invalid Naam selected. Please choose Naam again.');
      return;
    }

    final targetId = AppState.sankalpTargetId;
    final memberId = AppState.sankalpMemberId;

    if (targetId == null || memberId == null) {
      _showMessage('Please complete your Sankalp details first.');
      return;
    }

    setState(() {
      _isCreatingSankalp = true;
    });

    try {
      final result = await NaamLibraryRepository.createSankalp(
        naamLibraryId: naamLibraryId,
        sankalpTargetId: targetId,
        sankalpMemberId: memberId,
        recipientName:
            AppState.name.trim().isEmpty ? null : AppState.name.trim(),
        intention: AppState.intention.trim().isEmpty
            ? null
            : AppState.intention.trim(),
      );

      if (!mounted) return;

      final createdId = int.tryParse(result['id']?.toString() ?? '');

      if (createdId == null) {
        throw Exception('Sankalp created, but ID was not returned.');
      }

      AppState.createdSankalpId = createdId;

      final nav = Navigator.of(context);

      nav.pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
      );

      nav.pushNamed('/writing');
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingSankalp = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.maroon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = AppState.deity;

    if (d == null) {
      return DevScaffold(
        title: 'Preview Pustika',
        subtitle: 'आपकी पुस्तिका',
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  size: 48,
                  color: AppColors.maroon,
                ),
                const SizedBox(height: 12),
                Text(
                  'Please choose your Naam before previewing your Pustika.',
                  textAlign: TextAlign.center,
                  style: AppText.body(
                    14,
                    c: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Choose Naam',
                  trailing: Icons.arrow_forward_rounded,
                  onTap: () {
                    Navigator.pushNamed(context, '/library');
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DevScaffold(
      title: 'Preview Pustika',
      subtitle: 'आपकी पुस्तिका',
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SecondaryButton(
            label: 'Preview Pages',
            onTap: () {
              Navigator.pushNamed(context, '/example-page');
            },
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            label: _isCreatingSankalp ? 'Creating Sankalp...' : 'Start Sankalp',
            trailing: _isCreatingSankalp ? null : Icons.arrow_forward_rounded,
            onTap: _isCreatingSankalp ? () {} : _startSankalp,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 270,
              ),
              child: PustikaCover(
                deity: d,
                name: AppState.name,
                count: AppState.target,
                title: '${d.hi} नाम लेखन',
                designImageUrl: AppState.designAssetUrl,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Created for ${AppState.name}',
            style: AppText.body(
              13,
              c: AppColors.muted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sankalp · ${fmt(AppState.target)} Naam',
            style: AppText.display(16),
          ),
        ],
      ),
    );
  }
}
