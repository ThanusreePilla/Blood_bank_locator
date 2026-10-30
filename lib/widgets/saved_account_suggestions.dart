import 'package:flutter/material.dart';

class SavedAccountSuggestions extends StatelessWidget {
  const SavedAccountSuggestions({
    required this.accounts,
    required this.onSelect,
    required this.onRemove,
    super.key,
  });

  final List<String> accounts;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD9E2EC)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 4),
            child: Text(
              'Saved accounts',
              style: TextStyle(
                color: Color(0xFF52606D),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (final email in accounts)
            SizedBox(
              height: 42,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => onSelect(email),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.account_circle_outlined,
                              size: 19,
                              color: Color(0xFFB42332),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF172B4D),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove saved account',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => onRemove(email),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
