import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/vault_crypto_service.dart';
import '../services/database_service.dart';

class VaultPinDialog extends StatefulWidget {
  final bool isSetup;
  const VaultPinDialog({super.key, this.isSetup = false});

  @override
  State<VaultPinDialog> createState() => _VaultPinDialogState();
}

class _VaultPinDialogState extends State<VaultPinDialog> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      setState(() => _error = 'El PIN debe tener al menos 4 dígitos');
      return;
    }

    if (widget.isSetup) {
      final confirm = _confirmController.text.trim();
      if (pin != confirm) {
        setState(() => _error = 'Los PINs no coinciden');
        return;
      }
      final hash = VaultCryptoService.hashPin(pin);
      await DatabaseService().setVaultPin(hash);
      if (mounted) Navigator.pop(context, true);
      return;
    }

    final stored = await DatabaseService().getVaultPin();
    final hash = VaultCryptoService.hashPin(pin);
    if (stored == hash) {
      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() => _error = 'PIN incorrecto');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isSetup ? 'Crear PIN de Bóveda' : 'Acceder a Bóveda'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'PIN',
              counterText: '',
            ),
          ),
          if (widget.isSetup)
            TextField(
              controller: _confirmController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Confirmar PIN',
                counterText: '',
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Aceptar'),
        ),
      ],
    );
  }
}
