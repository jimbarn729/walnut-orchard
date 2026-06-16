import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({
    super.key,
    required this.solBalance,
    required this.wlntBalance,
    required this.userEmail,
    required this.myReferralCode,
    required this.themeMode,
    required this.onToggleTheme,
    required this.onLogout,
    required this.onDepositSol,
    required this.onWithdrawSol,
    required this.onDepositWlnt,
    required this.onWithdrawWlnt,
    required this.onConvertSolToWlnt,
    required this.onConvertWlntToSol,
    required this.onToggleAudio,
    required this.audioMuted,
    required this.dailyRewardAvailable,
    required this.onClaimDailyReward,
  });

  final double solBalance;
  final double wlntBalance;
  final String userEmail;
  final String myReferralCode;
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onLogout;
  final ValueChanged<double> onDepositSol;
  final ValueChanged<double> onWithdrawSol;
  final ValueChanged<double> onDepositWlnt;
  final ValueChanged<double> onWithdrawWlnt;
  final ValueChanged<double> onConvertSolToWlnt;
  final ValueChanged<double> onConvertWlntToSol;
  final VoidCallback onToggleAudio;
  final bool audioMuted;
  final bool dailyRewardAvailable;
  final Future<bool> Function() onClaimDailyReward;

  Future<void> _showAmountDialog(BuildContext context, String title, String hint, ValueChanged<double> onConfirm) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.panel,
        title: Text(title, style: const TextStyle(color: AppTheme.text)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppTheme.text),
            decoration: InputDecoration(hintText: hint, filled: true, fillColor: AppTheme.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
            validator: (value) {
              final amount = double.tryParse(value ?? '');
              if (amount == null || amount <= 0) return 'Введите корректную сумму';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена', style: TextStyle(color: AppTheme.muted))),
          ElevatedButton(onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              Navigator.pop(context, double.parse(controller.text));
            }
          }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853)), child: const Text('Ок')),
        ],
      ),
    );
    if (result != null) onConfirm(result);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(child: Text('Кошелёк', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
                  IconButton(onPressed: onToggleTheme, icon: Icon(themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode, color: AppTheme.gold)),
                  IconButton(onPressed: onToggleAudio, icon: Icon(audioMuted ? Icons.volume_off : Icons.volume_up, color: AppTheme.gold)),
                  IconButton(onPressed: onLogout, icon: const Icon(Icons.logout, color: AppTheme.muted)),
                ],
              ),
              const SizedBox(height: 8),
              Text(userEmail, style: const TextStyle(color: AppTheme.muted)),
              const SizedBox(height: 4),
              Text('Реферальный код: $myReferralCode', style: const TextStyle(color: AppTheme.gold)),
              const SizedBox(height: 22),
              _BalanceCard(icon: Icons.currency_bitcoin, label: 'Solana (SOL)', balance: solBalance.toStringAsFixed(4), color: const Color(0xFF9945FF)),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _ActionChip(label: 'Пополнить', icon: Icons.add, onTap: () => _showAmountDialog(context, 'Пополнить SOL', 'Сумма SOL', onDepositSol))),
                const SizedBox(width: 10),
                Expanded(child: _ActionChip(label: 'Вывести', icon: Icons.arrow_upward, onTap: () => _showAmountDialog(context, 'Вывести SOL', 'Сумма SOL', onWithdrawSol))),
              ]),
              const SizedBox(height: 16),
              _BalanceCard(icon: Icons.eco, label: 'Walnut Token (WLNT)', balance: wlntBalance.toStringAsFixed(0), color: AppTheme.gold),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _ActionChip(label: 'SOL → WLNT', icon: Icons.swap_horiz, onTap: () => _showAmountDialog(context, 'Обменять SOL на WLNT', 'Сумма SOL', onConvertSolToWlnt))),
                const SizedBox(width: 10),
                Expanded(child: _ActionChip(label: 'WLNT → SOL', icon: Icons.swap_horiz, onTap: () => _showAmountDialog(context, 'Обменять WLNT на SOL', 'Сумма WLNT', onConvertWlntToSol))),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _ActionChip(label: 'Пополнить', icon: Icons.add_circle_outline, onTap: () => _showAmountDialog(context, 'Пополнить WLNT', 'Сумма WLNT', onDepositWlnt))),
                const SizedBox(width: 10),
                Expanded(child: _ActionChip(label: 'Вывести', icon: Icons.arrow_circle_up_outlined, onTap: () => _showAmountDialog(context, 'Вывести WLNT', 'Сумма WLNT', onWithdrawWlnt))),
              ]),
              const SizedBox(height: 22),
              if (dailyRewardAvailable)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppTheme.panel, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.gold.withOpacity(0.25))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ежедневный бонус', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.text)),
                      const SizedBox(height: 10),
                      const Text('Получите 500 WLNT раз в сутки.', style: TextStyle(color: AppTheme.muted)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: onClaimDailyReward,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853)),
                        child: const Text('Забрать награду'),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppTheme.panel, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.panelBorder)),
                  child: const Text('Ежедневный бонус уже получен. Возвращайтесь завтра.', style: TextStyle(color: AppTheme.muted)),
                ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.panel, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.panelBorder)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Процентная ставка', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.text)),
                    SizedBox(height: 8),
                    Text('Используйте обмен для покупки ресурсов и ускорения роста. 1 SOL = 1000 WLNT.', style: TextStyle(color: AppTheme.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.icon, required this.label, required this.balance, required this.color});
  final IconData icon;
  final String label;
  final String balance;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.panel, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.4))),
      child: Row(
        children: [
          Icon(icon, size: 34, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppTheme.muted)),
                const SizedBox(height: 8),
                Text(balance, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(color: AppTheme.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.panelBorder)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(icon, size: 18, color: AppTheme.text), const SizedBox(width: 8), Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.text))],
        ),
      ),
    );
  }
}
