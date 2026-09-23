import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_willbefore/core/utils/extensions/button_extensions.dart';
import 'package:flutter_web_willbefore/core/utils/extensions/input_decoration_extensions.dart';
import 'package:flutter_web_willbefore/features/auth/domain/requests/login_request.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/common/widgets/app_icons.dart';
import '../../../../core/common/widgets/app_scaffold.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons_const.dart';
import '../../../../core/routes/route_endpoint.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final ValueNotifier<bool> _obscurePassword = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _rememberMe = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = LoginRequest(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      rememberMe: _rememberMe.value,
    );

    final resutl = await ref.read(authProvider.notifier).login(data);

    DPrint.log("Success login in login screen -> $resutl");

    if (resutl && mounted) {
      context.pushReplacement(RouteEndpoint.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.errorMessage.isNotEmpty &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    final authState = ref.watch(authProvider);

    return AppScaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.center,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 600, minWidth: 300),
                  child: Form(
                    key: _formKey,
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            'Hello, Welcome!',
                            style: TextStyle(
                              color: AppColors.primaryLaurel,
                              fontSize: 40,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Gap.h24,

                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 32,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bgColor,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.borderColor.withAlpha(
                                    (0.2 * 255).toInt(),
                                  ),
                                  spreadRadius: 2,
                                  blurRadius: 10,
                                  offset: Offset(2, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                "Email".text18w500(
                                  color: AppColors.primaryLaurel,
                                ),
                                Gap.h12,
                                TextFormField(
                                  controller: _emailController,
                                  focusNode: _emailFocus,
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(
                                    color: AppColors.textSecondaryColor,
                                  ),
                                  decoration: context.primaryInputDecoration
                                      .copyWith(
                                        hintText: 'Enter your Email',
                                        prefixIcon: AppFormIcon(
                                          assetPath: AssetsPath.email,
                                        ),
                                      ),
                                  validator: Validators.email,
                                  onFieldSubmitted: (_) => FocusScope.of(
                                    context,
                                  ).requestFocus(_passwordFocus),
                                  autofillHints: const [AutofillHints.email],
                                ),

                                Gap.h16,

                                "Password".text18w500(
                                  color: AppColors.primaryLaurel,
                                ),
                                Gap.h12,

                                /// [Text field] Password
                                ValueListenableBuilder<bool>(
                                  valueListenable: _obscurePassword,
                                  builder: (context, obscure, _) {
                                    return TextFormField(
                                      controller: _passwordController,
                                      focusNode: _passwordFocus,
                                      obscureText: obscure,
                                      textInputAction: TextInputAction.done,
                                      style: TextStyle(
                                        color: AppColors.textSecondaryColor,
                                      ),
                                      decoration: context.primaryInputDecoration
                                          .copyWith(
                                            hintText: "Enter your Password",
                                            prefixIcon: AppFormIcon(
                                              assetPath: AssetsPath.lock,
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                obscure
                                                    ? Icons
                                                          .visibility_off_outlined
                                                    : Icons.visibility_outlined,
                                                color:
                                                    AppColors.searchHintColor,
                                              ),
                                              onPressed: () =>
                                                  _obscurePassword.value =
                                                      !obscure,
                                            ),
                                          ),

                                      // validator: Validators.password,
                                      autofillHints: const [
                                        AutofillHints.password,
                                      ],
                                      onFieldSubmitted: (_) => _submit(),
                                    );
                                  },
                                ),
                                Gap.h8,
                                // Remember me and forgot password
                                Row(
                                  children: [
                                    ValueListenableBuilder<bool>(
                                      valueListenable: _rememberMe,
                                      builder: (context, remember, _) {
                                        return Checkbox(
                                          side: BorderSide(
                                            color: AppColors.borderColor,
                                          ),
                                          value: remember,
                                          onChanged: (value) {
                                            _rememberMe.value = value ?? false;
                                          },
                                        );
                                      },
                                    ),
                                    Text(
                                      "Remember me",
                                      style: TextStyle(
                                        color: AppColors.textSecondaryHintColor,
                                      ),
                                    ),
                                    Spacer(),
                                    TextButton(
                                      onPressed: () {},
                                      child: Text(
                                        "Forgot password?",
                                        style: TextStyle(
                                          color: AppColors.textAppLaurel,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Gap.h16,

                                /// [Button] Sign In
                                context.primaryButton(
                                  isLoading: authState.isLoading,
                                  onPressed: _submit,
                                  text: "Sign In",
                                ),
                                // Gap.h24,
                              ],
                            ),
                            // Email field
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
