/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
import 'package:audio_call/screens/login/login.dart';
import 'package:audio_call/theme/voximplant_theme.dart';
import 'package:audio_call/utils/navigation_helper.dart';
import 'package:audio_call/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginPage extends StatefulWidget {
  static const routeName = '/login';

  @override
  State<StatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  LoginBloc _bloc;

  bool _isUsernameValid = true;
  bool _isPasswordValid = true;

  @override
  void initState() {
    super.initState();
    _bloc = BlocProvider.of<LoginBloc>(context);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void _login() => _bloc.add(
          LoginWithPassword(
            username: _usernameController.text,
            password: _passwordController.text,
          ),
        );

    void _handleLoginFailed(String errorCode, String errorDescription) {
      if (errorCode == 'ERROR_INVALID_USERNAME') {
        setState(() => _isUsernameValid = false);
      } else if (errorCode == 'ERROR_INVALID_PASSWORD') {
        setState(() => _isPasswordValid = false);
      } else {
        Scaffold.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorDescription'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    Widget _loginForm() {
      return Center(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Widgets.textWithPadding(
                  text: 'Audio call',
                  fontSize: 30,
                  textColor: VoximplantColors.white,
                  verticalPadding: 30,
                ),
                Widgets.textFormField(
                  controller: _usernameController,
                  darkBackground: true,
                  labelText: 'user@app.account',
                  suffixText: '.voximplant.com',
                  inputType: TextInputType.emailAddress,
                  validator: (_) =>
                      _isUsernameValid ? null : 'Invalid username',
                ),
                Widgets.textFormField(
                  controller: _passwordController,
                  darkBackground: true,
                  labelText: 'password',
                  obscureText: true,
                  validator: (_) =>
                      _isPasswordValid ? null : 'Invalid password',
                ),
                Widgets.maxWidthRaisedButton(
                  text: 'Log in',
                  onPressed: _login,
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget _loginInProgress() {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LoginLastUserLoaded) {
          _usernameController.text = state.lastUser;
        }
        if (state is LoginFailure) {
          _handleLoginFailed(state.errorCode, state.errorDescription);
        }
        if (state is LoginSuccess) {
          setState(() {
            _isUsernameValid = true;
            _isPasswordValid = true;
          });
          Navigator.of(context).pushReplacementNamed(AppRoutes.main);
        }
        if (state is! LoginInProgress && state is! LoginSuccess) {
          Future.delayed(
            Duration(milliseconds: 100),
            () => _formKey?.currentState?.validate(),
          );
        }
      },
      child: BlocBuilder<LoginBloc, LoginState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: VoximplantColors.primary,
            body: SafeArea(
              child: (state is LoginInProgress || state is LoginSuccess)
                  ? _loginInProgress()
                  : _loginForm(),
            ),
          );
        },
      ),
    );
  }
}
