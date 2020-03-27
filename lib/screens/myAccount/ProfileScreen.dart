import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info/package_info.dart';
import 'package:pikobar_flutter/blocs/authentication/Bloc.dart';
import 'package:pikobar_flutter/components/DialogQrCode.dart';
import 'package:pikobar_flutter/components/DialogTextOnly.dart';
import 'package:pikobar_flutter/components/ErrorContent.dart';
import 'package:pikobar_flutter/constants/Dictionary.dart';
import 'package:pikobar_flutter/constants/Navigation.dart';
import 'package:pikobar_flutter/constants/firebaseConfig.dart';
import 'package:pikobar_flutter/environment/Environment.dart';
import 'package:pikobar_flutter/repositories/AuthRepository.dart';
import 'package:pikobar_flutter/screens/myAccount/OnboardLoginScreen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthRepository _authRepository = AuthRepository();
  AuthenticationBloc _authenticationBloc;
  String _versionText = Dictionary.version;
  @override
  void initState() {
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      setState(() {
        _versionText = packageInfo.version != null
            ? packageInfo.version
            : Dictionary.version;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthenticationBloc>(
        create: (BuildContext context) => _authenticationBloc =
            AuthenticationBloc(authRepository: _authRepository)
              ..add(AppStarted()),
        child: BlocListener<AuthenticationBloc, AuthenticationState>(
          listener: (context, state) {
            if (state is AuthenticationFailure) {
              showDialog(
                  context: context,
                  builder: (BuildContext context) => DialogTextOnly(
                        description: state.error.toString(),
                        buttonText: "OK",
                        onOkPressed: () {
                          Navigator.of(context).pop(); // To close the dialog
                        },
                      ));
              Scaffold.of(context).hideCurrentSnackBar();
            } else if (state is AuthenticationLoading) {
              Scaffold.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Theme.of(context).primaryColor,
                  content: Row(
                    children: <Widget>[
                      CircularProgressIndicator(),
                      Container(
                        margin: EdgeInsets.only(left: 15.0),
                        child: Text(Dictionary.loading),
                      )
                    ],
                  ),
                  duration: Duration(seconds: 5),
                ),
              );
            } else {
              Scaffold.of(context).hideCurrentSnackBar();
            }
          },
          child: Scaffold(
              appBar: AppBar(
                title: Text(Dictionary.profile),
              ),
              body: BlocBuilder<AuthenticationBloc, AuthenticationState>(
                builder: (
                  BuildContext context,
                  AuthenticationState state,
                ) {
                  if (state is AuthenticationUnauthenticated ||
                      state is AuthenticationLoading) {
                    return OnBoardingLoginScreen(
                      authenticationBloc: _authenticationBloc,
                    );
                  } else if (state is AuthenticationAuthenticated ||
                      state is AuthenticationLoading) {
                    AuthenticationAuthenticated _profilLoaded =
                        state as AuthenticationAuthenticated;
                    return StreamBuilder<DocumentSnapshot>(
                        stream: Firestore.instance
                            .collection('users')
                            .document(_profilLoaded.record.uid)
                            .snapshots(),
                        builder: (BuildContext context,
                            AsyncSnapshot<DocumentSnapshot> snapshot) {
                          if (snapshot.hasError)
                            return ErrorContent(error: snapshot.error);
                          switch (snapshot.connectionState) {
                            case ConnectionState.waiting:
                              return Center(
                                child: CircularProgressIndicator(),
                              );
                            default:
                              return _buildContent(snapshot,_profilLoaded);
                          }
                        });
                  } else {
                    return Container();
                  }
                },
              )),
        ));
  }

  Widget _buildContent(AsyncSnapshot<DocumentSnapshot> state,AuthenticationAuthenticated _profilLoaded) {
    return Center(
        child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 30,
          ),
          Row(
            children: <Widget>[
              Container(
                width: 98,
                height: 98,
                child: CircleAvatar(
                  minRadius: 90,
                  maxRadius: 150,
                  backgroundImage: (_profilLoaded.record.photoUrlFull) != null
                      ? NetworkImage(_profilLoaded.record.photoUrlFull)
                      : ExactAssetImage('${Environment.imageAssets}user.png'),
                ),
              ),
              SizedBox(
                width: 20,
              ),

              Container(
                height: 98,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      height: 32.0,
                      child: Text(
                       _profilLoaded.record.name,
                        style: TextStyle(
                            color: Color(0xff4F4F4F),
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      height: 32.0,
                      child: Text(_profilLoaded.record.email,
                          style: TextStyle(
                            color: Color(0xff828282),
                            fontSize: 14,
                          )),
                    ),

                    FutureBuilder<RemoteConfig>(
                        future: setupRemoteConfig(),
                        builder:
                            (BuildContext context, AsyncSnapshot<RemoteConfig> snapshot) {

                          bool visible = snapshot.data != null && snapshot.data.getBool(FirebaseConfig.healthStatusVisible) != null ? snapshot.data.getBool(FirebaseConfig.healthStatusVisible) : false;

                          return visible ? Container(
                            decoration: BoxDecoration(
                                color: Color(0xff27AE60),
                                borderRadius: BorderRadius.circular(4)),
                            child: Padding(
                              padding:
                              EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                              child: Row(
                                children: <Widget>[
                                  Container(
                                      height: 12,
                                      child: Image.asset(
                                          '${Environment.iconAssets}sthetoscope.png')),
                                  SizedBox(width: 5),
                                  Text(Dictionary.statusUser,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      )),
                                ],
                              ),
                            ),
                          ) : SizedBox(height: 32.0,);
                        }),
                  ],
                ),
              )
            ],
          ),
          SizedBox(
            height: 20,
          ),
          InkWell(
            onTap: () {
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return DialogQrCode(idUser: state.data['id']);
                  });
            },
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: EdgeInsets.all(15.0),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                                height: 20,
                                child: Image.asset(
                                    '${Environment.iconAssets}qr-code.png')),
                            SizedBox(
                              width: 20,
                            ),
                            Text(
                              Dictionary.qrCodeMenu,
                              style: TextStyle(color: Color(0xff4F4F4F)),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xff828282),
                          size: 15,
                        )
                      ],
                    ),
                    SizedBox(
                      height: 5,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: 30,
          ),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: EdgeInsets.all(15.0),
              child: Column(
                children: <Widget>[
                  InkWell(onTap: () {
                            Navigator.pushNamed(
                                context, NavigationConstrants.Edit,
                                arguments: state);
                          },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                                height: 20,
                                child: Image.asset(
                                    '${Environment.iconAssets}edit.png')),
                            SizedBox(
                              width: 20,
                            ),
                            Text(
                              Dictionary.edit,
                              style: TextStyle(color: Color(0xff4F4F4F)),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xff828282),
                          size: 15,
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Divider(),
                  SizedBox(
                    height: 5,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                              height: 20,
                              child: Image.asset(
                                  '${Environment.iconAssets}versionLogo.png')),
                          SizedBox(
                            width: 20,
                          ),
                          Text(
                            Dictionary.versionText,
                            style: TextStyle(color: Color(0xff4F4F4F)),
                          ),
                        ],
                      ),
                      Text(
                        _versionText + ' ' + Dictionary.betaText,
                        style: TextStyle(color: Color(0xff828282)),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 15,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 3),
            child: RaisedButton(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              color: Color(0xffEB5757),
              onPressed: () {
                _authenticationBloc.add(LoggedOut());
              },
              child: Padding(
                padding: EdgeInsets.all(15),
                child: Container(
                    width: MediaQuery.of(context).size.width,
                    child: Center(
                        child: Text(
                      Dictionary.textLogoutButton,
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ))),
              ),
            ),
          )
        ],
      ),
    ));
  }

  Future<RemoteConfig> setupRemoteConfig() async {
    final RemoteConfig remoteConfig = await RemoteConfig.instance;
    remoteConfig.setDefaults(<String, dynamic>{
      FirebaseConfig.healthStatusVisible: false,
    });

    try {
      await remoteConfig.fetch(expiration: Duration(minutes: 5));
      await remoteConfig.activateFetched();

    } catch (exception) {
      print('Unable to fetch remote config. Cached or default values will be '
          'used');
    }

    return remoteConfig;
  }

  @override
  void dispose() {
    _authenticationBloc.close();
    super.dispose();
  }
}