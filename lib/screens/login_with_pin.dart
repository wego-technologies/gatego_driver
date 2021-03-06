import 'package:beamer/beamer.dart';
import 'package:flutter/material.dart';
import 'package:gatego_driver/widgets/common/phone_input.dart';
import 'package:gatego_driver/widgets/login/error.dart';
import 'package:pinput/pinput.dart';
import '../providers/providers.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../widgets/login/header.dart';

class LoginWithPinPage extends StatefulHookConsumerWidget {
  const LoginWithPinPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _LoginWithPinPageState();
}

class _LoginWithPinPageState extends ConsumerState<LoginWithPinPage> {
  var isLoginButton = false;

  @override
  Widget build(BuildContext context) {
    final pinController = useTextEditingController();
    final pinFocusNode = useFocusNode();
    final numberController = useTextEditingController();
    final numberFocusNode = useFocusNode();

    final useAuth = ref.watch(authProvider);
    ref.watch(authProvider.notifier);

    const length = 6;
    var borderColor = Theme.of(context).primaryColor;
    var errorColor = Theme.of(context).errorColor.withAlpha(50);
    var fillColor = Theme.of(context).cardColor;
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.transparent),
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              top: 0,
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AutofillGroup(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          height: 50,
                        ),
                        const LoginHeader(),
                        const SizedBox(
                          height: 50,
                        ),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 30),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PhoneInput(
                                  text: "Phone Number",
                                  c: numberController,
                                  fn: numberFocusNode,
                                  autofillHints: const [
                                    AutofillHints.telephoneNumber
                                  ],
                                  nextFocus: (_) {
                                    pinFocusNode.requestFocus();
                                  },
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Text(
                                    "Pin",
                                    style:
                                        Theme.of(context).textTheme.bodyText1,
                                  ),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  height: 68,
                                  child: Pinput(
                                    length: length,
                                    controller: pinController,
                                    focusNode: pinFocusNode,
                                    defaultPinTheme: defaultPinTheme,
                                    onCompleted: (pin) {
                                      login(pin, numberController.text, ref,
                                          context);
                                    },
                                    enabled: !useAuth.isAuthing,
                                    focusedPinTheme: defaultPinTheme.copyWith(
                                      height: 68,
                                      width: 64,
                                      decoration:
                                          defaultPinTheme.decoration!.copyWith(
                                        border: Border.all(
                                            color: borderColor, width: 2),
                                      ),
                                    ),
                                    errorPinTheme: defaultPinTheme.copyWith(
                                      decoration: BoxDecoration(
                                        color: errorColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                if (useAuth.errorState != null)
                                  const SizedBox(
                                    height: 10,
                                  ),
                                if (useAuth.errorState != null)
                                  const ErrorCard(),
                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      Beamer.of(context).beamToNamed("/login");
                                    },
                                    label:
                                        const Text("Sign in with an account"),
                                    icon: const Icon(
                                        Icons.account_circle_rounded),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 80,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    !useAuth.isAuthing
                        ? SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: Text(
                                "Sign In",
                                style: Theme.of(context)
                                    .textTheme
                                    .headline6
                                    ?.copyWith(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                              ),
                              style: ButtonStyle(
                                padding: MaterialStateProperty.resolveWith(
                                  (states) => const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                ),
                                shape: MaterialStateProperty.resolveWith(
                                  (states) => RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50000),
                                  ),
                                ),
                              ),
                              onPressed: () {
                                isLoginButton = true;

                                login(pinController.text, numberController.text,
                                    ref, context);
                              },
                              label: const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          )
                        : CircleAvatar(
                            backgroundColor: Theme.of(context).cardColor,
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: CircularProgressIndicator(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
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

  void login(String pin, String phone, WidgetRef ref, BuildContext ctx) async {
    try {
      await ref.read(authProvider.notifier).signInWithPin(phone, pin);
    } catch (e) {
      return;
    }
  }
}
