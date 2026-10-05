import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/app_scope.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/johar_header.dart';
import '../../data/models/worker.dart';
import '../home/home_shell.dart';

class RegisterWorkerScreen extends StatefulWidget {
  const RegisterWorkerScreen({super.key});

  @override
  State<RegisterWorkerScreen> createState() => _RegisterWorkerScreenState();
}

class _RegisterWorkerScreenState extends State<RegisterWorkerScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _employeeId = TextEditingController();
  final _employer = TextEditingController();
  String _sector = 'coal';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {})); // live avatar initials
  }

  @override
  void dispose() {
    _name.dispose();
    _employeeId.dispose();
    _employer.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final scope = AppScope.of(context);
    await scope.store.addWorker(Worker(
      id: const Uuid().v4(),
      name: _name.text.trim(),
      employeeId: _employeeId.text.trim(),
      employer: _employer.text.trim(),
      sector: _sector,
      language: scope.localeController.contentLang,
      createdAt: DateTime.now(),
    ));
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(builder: (_) => const HomeShell()),
      (route) => false,
    );
  }

  String get _initials {
    final parts = _name.text.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    return parts.take(2).map((p) => p.characters.first).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    String? required(String? v) => (v == null || v.trim().isEmpty) ? l.fieldRequired : null;

    return Scaffold(
      body: Form(
        key: _form,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            JoharHeader(
              overlap: 44,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (Navigator.canPop(context))
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    )
                  else
                    const SizedBox(height: 32),
                  const SizedBox(height: 8),
                  Text(l.registerTitle, style: t.headlineMedium?.copyWith(color: Colors.white)),
                  const SizedBox(height: 6),
                  Text(l.registerHint, style: const TextStyle(color: Color(0xFFD9D4E8), fontSize: 16)),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    SoftCard(
                      child: Column(children: [
                        Row(children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.ochreSoft,
                            child: _initials.isEmpty
                                ? const Icon(Icons.person, color: AppColors.ochre, size: 32)
                                : Text(_initials,
                                    style: const TextStyle(
                                        color: AppColors.ochre, fontSize: 22, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _name,
                              decoration: InputDecoration(labelText: l.fieldName),
                              textCapitalization: TextCapitalization.words,
                              validator: required,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _employeeId,
                          decoration: InputDecoration(
                            labelText: l.fieldWorkerId,
                            prefixIcon: const Icon(Icons.badge_outlined),
                          ),
                          validator: required,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _employer,
                          decoration: InputDecoration(
                            labelText: l.fieldEmployer,
                            prefixIcon: const Icon(Icons.factory_outlined),
                          ),
                          validator: required,
                        ),
                      ]),
                    ),
                    const SizedBox(height: 18),
                    SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.sectorLabel, style: t.titleMedium),
                          const SizedBox(height: 14),
                          Row(children: [
                            for (final (id, label, icon) in [
                              ('coal', l.sectorCoal, Icons.landscape_rounded),
                              ('steel', l.sectorSteel, Icons.factory_rounded),
                              ('mica', l.sectorMica, Icons.diamond_rounded),
                            ]) ...[
                              Expanded(
                                child: _SectorTile(
                                  label: label,
                                  icon: icon,
                                  selected: _sector == id,
                                  onTap: () => setState(() => _sector = id),
                                ),
                              ),
                              if (id != 'mica') const SizedBox(width: 10),
                            ],
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(l.saveAndStart),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectorTile extends StatelessWidget {
  const _SectorTile({required this.label, required this.icon, required this.selected, required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: selected ? AppColors.manganese : AppColors.mineral,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
            child: Column(children: [
              Icon(icon, size: 34, color: selected ? Colors.white : AppColors.manganese),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: selected ? Colors.white : AppColors.coal,
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
