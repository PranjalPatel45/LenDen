import 'package:flutter/material.dart';

import '../data/security_repository.dart';
import '../utils/app_colors.dart';
import '../utils/app_design.dart';
import '../utils/app_snackbar.dart';
import '../widget/glass_widgets.dart';

class RecoveryQuestionsScreen extends StatefulWidget {
  const RecoveryQuestionsScreen({
    super.key,
    this.pinToSave,
    this.securityRepository = const SecurityRepository(),
  });

  final String? pinToSave;
  final SecurityRepository securityRepository;

  @override
  State<RecoveryQuestionsScreen> createState() =>
      _RecoveryQuestionsScreenState();
}

class _RecoveryQuestionsScreenState extends State<RecoveryQuestionsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstAnswerController = TextEditingController();
  final _secondAnswerController = TextEditingController();
  String _firstQuestion = SecurityRepository.recoveryQuestionChoices.first;
  String _secondQuestion = SecurityRepository.recoveryQuestionChoices[1];
  bool _isSaving = false;

  @override
  void dispose() {
    _firstAnswerController.dispose();
    _secondAnswerController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_firstQuestion == _secondQuestion) {
      _showError('Choose two different recovery questions.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final pin = widget.pinToSave;
      if (pin == null) {
        await widget.securityRepository.saveRecoveryQuestions(
          questionOne: _firstQuestion,
          answerOne: _firstAnswerController.text,
          questionTwo: _secondQuestion,
          answerTwo: _secondAnswerController.text,
        );
      } else {
        await widget.securityRepository.savePinAndRecovery(
          pin: pin,
          questionOne: _firstQuestion,
          answerOne: _firstAnswerController.text,
          questionTwo: _secondQuestion,
          answerTwo: _secondAnswerController.text,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) _showError('Could not save recovery questions. Try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    AppSnackbar.showError(
      context: context,
      message: message,
    );
  }

  String? _validateAnswer(String? value) {
    if (value == null || value.trim().length < 2) {
      return 'Enter an answer with at least 2 characters.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recovery Questions')),
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Form(
                  key: _formKey,
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                    radius: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          size: 58,
                          color: AppColors.highlight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Choose answers you will remember',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'You will need both answers if you forget your PIN. Answers ignore capital letters and extra spaces.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.secondaryText),
                        ),
                        const SizedBox(height: 28),
                        DropdownButtonFormField<String>(
                          initialValue: _firstQuestion,
                          decoration: const InputDecoration(
                            labelText: 'First question',
                          ),
                          isExpanded: true,
                          items: SecurityRepository.recoveryQuestionChoices
                              .map(
                                (question) => DropdownMenuItem(
                                  value: question,
                                  child: Text(
                                    question,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _firstQuestion = value);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _firstAnswerController,
                          textInputAction: TextInputAction.next,
                          validator: _validateAnswer,
                          decoration: const InputDecoration(
                            labelText: 'First answer',
                          ),
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          initialValue: _secondQuestion,
                          decoration: const InputDecoration(
                            labelText: 'Second question',
                          ),
                          isExpanded: true,
                          items: SecurityRepository.recoveryQuestionChoices
                              .map(
                                (question) => DropdownMenuItem(
                                  value: question,
                                  child: Text(
                                    question,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _secondQuestion = value);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _secondAnswerController,
                          textInputAction: TextInputAction.done,
                          validator: _validateAnswer,
                          onFieldSubmitted: (_) => _save(),
                          decoration: const InputDecoration(
                            labelText: 'Second answer',
                          ),
                        ),
                        const SizedBox(height: 28),
                        GlassButton(
                          onPressed: _isSaving ? null : _save,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isSaving)
                                const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                                )
                              else
                                const Icon(Icons.check_rounded, size: 20, color: AppColors.white),
                              const SizedBox(width: 8),
                              Text(
                                widget.pinToSave == null
                                    ? 'Save Recovery Questions'
                                    : 'Save PIN and Recovery',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
