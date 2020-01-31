/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_call/login/login.dart';
import 'package:video_call/routes.dart';
import 'package:video_call/theme/voximplant_theme.dart';
import 'package:video_call/widgets/widgets.dart';

class LoginForm extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _LoginFormState();
  }
}

class _LoginFormState extends State<LoginForm> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isUsernameValid = true;
  bool _isPasswordValid = true;

  @override
  void initState() {
    super.initState();
    BlocProvider.of<LoginBloc>(context).add(LoadLastUser());
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void _login() {
      BlocProvider.of<LoginBloc>(context).add(LoginWithPassword(
          username: _usernameController.text,
          password: _passwordController.text));
    }

    void _handleLoginFailed(String errorCode, String errorDescription) {
      if (errorCode == 'ERROR_INVALID_USERNAME') {
        setState(() {
          _isUsernameValid = false;
        });
      } else if (errorCode == 'ERROR_INVALID_PASSWORD') {
        setState(() {
          _isPasswordValid = false;
        });
      } else {
        Scaffold.of(context).showSnackBar(SnackBar(
          content: Text('$errorDescription'),
          backgroundColor: Colors.red,
        ));
      }
    }

    Widget _loginForm() {
      return Center(
          child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Widgets.textWithPadding(
                    text: 'Video call',
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
                      validator: (_) {
                        return _isUsernameValid ? null : 'Invalid username';
                      }),
                  Widgets.textFormField(
                      controller: _passwordController,
                      darkBackground: true,
                      labelText: 'password',
                      obscureText: true,
                      validator: (_) {
                        return _isPasswordValid ? null : 'Invalid password';
                      }),
                  Widgets.maxWidthRaisedButton(
                    text: 'Log in',
                    onPressed: _login,
                  ),
                ],
              )));
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
          Navigator.of(context).pushReplacementNamed(AppRoutes.makeCall);
        }
        if (state is! LoginInProgress && state is! LoginSuccess) {
          Future.delayed(Duration(milliseconds: 100),
                  () => _formKey?.currentState?.validate());
        }
      },
      child: BlocBuilder<LoginBloc, LoginState>(
        builder: (context, state) {
          if (state is LoginInProgress || state is LoginSuccess) {
            return _loginInProgress();
          } else {
            return _loginForm();
          }
        },
      ),
    );
  }
}
