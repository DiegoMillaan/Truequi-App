import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart';

class GoogleLoginButton extends StatelessWidget {
  final VoidCallback? onSuccess;
  final void Function(String mensaje)? onError;

  const GoogleLoginButton({
    super.key,
    this.onSuccess,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 50,
      child: renderButton(
        configuration: GSIButtonConfiguration(
          type: GSIButtonType.standard,
          theme: GSIButtonTheme.outline,
          size: GSIButtonSize.large,
          text: GSIButtonText.continueWith,
          shape: GSIButtonShape.rectangular,
          minimumWidth: 300,
          locale: 'es',
        ),
      ),
    );
  }
}