import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'policy_content_model.dart';

class PoliciesScreen extends StatefulWidget {
  const PoliciesScreen({super.key});

  @override
  State<PoliciesScreen> createState() => _PoliciesScreenState();
}

class _PoliciesScreenState extends State<PoliciesScreen> {
  // Track expanded state by section ID
  final Set<String> _expandedSections = <String>{};

  void _toggleSection(String sectionId) {
    setState(() {
      if (_expandedSections.contains(sectionId)) {
        _expandedSections.remove(sectionId);
      } else {
        _expandedSections.add(sectionId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: CivicTheme.canvas,
      appBar: AppBar(
        title: Text(
          l10n.helpAndRulesTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: CivicTheme.textPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Summary Card
              _buildHeaderCard(l10n),
              const SizedBox(height: 16),

              // Categories & Accordion Sections
              for (final category in policyCategories) ...[
                _buildCategoryHeader(category, l10n),
                const SizedBox(height: 8),
                for (final section in category.sections) ...[
                  PolicyAccordionCard(
                    section: section,
                    isExpanded: _expandedSections.contains(section.id),
                    onToggle: () => _toggleSection(section.id),
                    l10n: l10n,
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 16),
              ],

              // Section 24: Important Notice Callout Card
              _buildImportantNoticeCard(l10n),
              const SizedBox(height: 16),

              // Official Civic System Footer
              _buildFooter(l10n),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CivicTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: CivicTheme.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: CivicTheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.helpAndRulesTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: CivicTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.helpAndRulesSubtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: CivicTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(PolicyCategoryModel category, AppLocalizations l10n) {
    final title = getLocalizedPolicyText(l10n, category.titleKey);
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4, bottom: 2),
      child: Row(
        children: [
          Icon(
            category.icon,
            size: 20,
            color: CivicTheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: CivicTheme.primary,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportantNoticeCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CivicTheme.primarySoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CivicTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: CivicTheme.primary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.importantCivicNoticeTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: CivicTheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.importantCivicNoticeBody,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CivicTheme.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CivicTheme.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 16,
                color: CivicTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l10n.policyFooterHeading,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: CivicTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.policyFooterVersion,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: CivicTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class PolicyAccordionCard extends StatelessWidget {
  final PolicySectionModel section;
  final bool isExpanded;
  final VoidCallback onToggle;
  final AppLocalizations l10n;

  const PolicyAccordionCard({
    super.key,
    required this.section,
    required this.isExpanded,
    required this.onToggle,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final title = getLocalizedPolicyText(l10n, section.titleKey);
    final semanticHint = isExpanded ? l10n.policyTapToCollapse : l10n.policyTapToExpand;

    return Semantics(
      button: true,
      expanded: isExpanded,
      label: title,
      hint: semanticHint,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isExpanded ? CivicTheme.primary.withValues(alpha: 0.5) : CivicTheme.border,
            width: isExpanded ? 1.4 : 1.0,
          ),
        ),
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onToggle,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        section.icon,
                        size: 20,
                        color: isExpanded ? CivicTheme.primary : CivicTheme.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isExpanded ? CivicTheme.primary : CivicTheme.textPrimary,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: isExpanded ? CivicTheme.primary : CivicTheme.textSecondary,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isExpanded) ...[
              const Divider(height: 1, thickness: 1, color: CivicTheme.border),
              Container(
                color: const Color(0xFFFBFBFB),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < section.bodyKeys.length; i++) ...[
                      _buildParagraphItem(
                        getLocalizedPolicyText(l10n, section.bodyKeys[i]),
                      ),
                      if (i < section.bodyKeys.length - 1)
                        const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParagraphItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6, right: 8),
          child: Icon(
            Icons.circle,
            size: 6,
            color: CivicTheme.primary,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: CivicTheme.textPrimary,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
