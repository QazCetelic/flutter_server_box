import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:provider/provider.dart';
import 'package:toolbox/core/extension/context/common.dart';
import 'package:toolbox/core/extension/context/dialog.dart';
import 'package:toolbox/core/extension/context/locale.dart';
import 'package:toolbox/core/extension/context/snackbar.dart';
import 'package:toolbox/core/extension/stringx.dart';
import 'package:toolbox/core/extension/widget.dart';
import 'package:toolbox/core/utils/ui.dart';
import 'package:toolbox/data/model/app/shell_func.dart';
import 'package:toolbox/data/model/server/custom.dart';
import 'package:toolbox/data/res/provider.dart';
import 'package:toolbox/view/widget/expand_tile.dart';

import '../../../core/route.dart';
import '../../../data/model/server/private_key_info.dart';
import '../../../data/model/server/server_private_info.dart';
import '../../../data/provider/private_key.dart';
import '../../../data/res/ui.dart';
import '../../widget/appbar.dart';
import '../../widget/input_field.dart';
import '../../widget/cardx.dart';
import '../../widget/tag.dart';

class ServerEditPage extends StatefulWidget {
  const ServerEditPage({super.key, this.spi});

  final ServerPrivateInfo? spi;

  @override
  _ServerEditPageState createState() => _ServerEditPageState();
}

class _ServerEditPageState extends State<ServerEditPage> {
  final _nameController = TextEditingController();
  final _ipController = TextEditingController();
  final _altUrlController = TextEditingController();
  final _portController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pveAddrCtrl = TextEditingController();
  final _customCmdCtrl = TextEditingController();

  final _nameFocus = FocusNode();
  final _ipFocus = FocusNode();
  final _alterUrlFocus = FocusNode();
  final _portFocus = FocusNode();
  final _usernameFocus = FocusNode();

  late FocusScopeNode _focusScope;

  final _keyIdx = ValueNotifier<int?>(null);
  final _autoConnect = ValueNotifier(true);
  final _jumpServer = ValueNotifier<String?>(null);
  final _pveIgnoreCert = ValueNotifier(false);

  var _tags = <String>[];

  @override
  void initState() {
    super.initState();

    final spi = widget.spi;
    if (spi != null) {
      _nameController.text = spi.name;
      _ipController.text = spi.ip;
      _portController.text = spi.port.toString();
      _usernameController.text = spi.user;
      if (spi.keyId == null) {
        _passwordController.text = spi.pwd ?? '';
      } else {
        _keyIdx.value = Pros.key.pkis.indexWhere(
          (e) => e.id == widget.spi!.keyId,
        );
      }

      /// List in dart is passed by pointer, so you need to copy it here
      _tags.addAll(spi.tags ?? []);

      _altUrlController.text = spi.alterUrl ?? '';
      _autoConnect.value = spi.autoConnect ?? true;
      _jumpServer.value = spi.jumpId;

      final custom = spi.custom;
      if (custom != null) {
        _pveAddrCtrl.text = custom.pveAddr ?? '';
        _pveIgnoreCert.value = custom.pveIgnoreCert;
        try {
          // Add a null check here to prevent setting `null` to the controller
          final encoded = json.encode(custom.cmds!);
          if (encoded.isNotEmpty) {
            _customCmdCtrl.text = encoded;
          }
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    _nameController.dispose();
    _ipController.dispose();
    _altUrlController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _ipFocus.dispose();
    _alterUrlFocus.dispose();
    _portFocus.dispose();
    _usernameFocus.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _focusScope = FocusScope.of(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildForm(),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return CustomAppBar(
      title: Text(l10n.edit, style: UIs.text18),
      actions: widget.spi != null ? [_buildDelBtn()] : null,
    );
  }

  Widget _buildDelBtn() {
    return IconButton(
      onPressed: () {
        var delScripts = false;
        context.showRoundDialog(
          title: Text(l10n.attention),
          child: StatefulBuilder(builder: (ctx, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.askContinue(
                  '${l10n.delete} ${l10n.server}(${widget.spi!.name})',
                )),
                UIs.height13,
                if (widget.spi?.server?.canViewDetails ?? false)
                  CheckboxListTile(
                    value: delScripts,
                    onChanged: (_) => setState(
                      () => delScripts = !delScripts,
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(l10n.deleteScripts),
                    tileColor: Colors.transparent,
                    contentPadding: EdgeInsets.zero,
                  )
              ],
            );
          }),
          actions: [
            TextButton(
              onPressed: () async {
                context.pop();
                if (delScripts) {
                  await context.showLoadingDialog(
                    fn: () async {
                      const cmd = 'rm ${ShellFunc.srvBoxDir}/mobile_v*.sh';
                      return widget.spi?.server?.client?.run(cmd);
                    },
                  );
                }
                Pros.server.delServer(widget.spi!.id);
                context.pop(true);
              },
              child: Text(l10n.ok, style: UIs.textRed),
            ),
          ],
        );
      },
      icon: const Icon(Icons.delete),
    );
  }

  Widget _buildForm() {
    final children = [
      Input(
        autoFocus: true,
        controller: _nameController,
        type: TextInputType.text,
        node: _nameFocus,
        onSubmitted: (_) => _focusScope.requestFocus(_ipFocus),
        hint: l10n.exampleName,
        label: l10n.name,
        icon: BoxIcons.bx_rename,
        obscureText: false,
        autoCorrect: true,
        suggestiion: true,
      ),
      Input(
        controller: _ipController,
        type: TextInputType.url,
        onSubmitted: (_) => _focusScope.requestFocus(_portFocus),
        node: _ipFocus,
        label: l10n.host,
        icon: BoxIcons.bx_server,
        hint: 'example.com',
      ),
      Input(
        controller: _portController,
        type: TextInputType.number,
        node: _portFocus,
        onSubmitted: (_) => _focusScope.requestFocus(_usernameFocus),
        label: l10n.port,
        icon: Bootstrap.number_123,
        hint: '22',
      ),
      Input(
        controller: _usernameController,
        type: TextInputType.text,
        node: _usernameFocus,
        onSubmitted: (_) => _focusScope.requestFocus(_alterUrlFocus),
        label: l10n.user,
        icon: Icons.account_box,
        hint: 'root',
      ),
      Input(
        controller: _altUrlController,
        type: TextInputType.url,
        node: _alterUrlFocus,
        label: l10n.alterUrl,
        icon: MingCute.link_line,
        hint: 'user@ip:port',
      ),
      TagEditor(
        tags: _tags,
        onChanged: (p0) => _tags = p0,
        allTags: [...Pros.server.tags.value],
        onRenameTag: Pros.server.renameTag,
      ),
      ListTile(
        title: Text(l10n.autoConnect),
        trailing: ListenableBuilder(
          listenable: _autoConnect,
          builder: (_, __) => Switch(
            value: _autoConnect.value,
            onChanged: (val) {
              _autoConnect.value = val;
            },
          ),
        ),
      ),
      _buildAuth(),
      //_buildJumpServer(),
      _buildPVE(),
      _buildCustomCmd(),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(17, 17, 17, 47),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildAuth() {
    final switch_ = ListTile(
      title: Text(l10n.keyAuth),
      trailing: ListenableBuilder(
        listenable: _keyIdx,
        builder: (_, __) => Switch(
          value: _keyIdx.value != null,
          onChanged: (val) {
            if (val) {
              _keyIdx.value = -1;
            } else {
              _keyIdx.value = null;
            }
          },
        ),
      ),
    );

    /// Put [switch_] out of [ValueBuilder] to avoid rebuild
    return ListenableBuilder(
      listenable: _keyIdx,
      builder: (_, __) {
        final children = <Widget>[switch_];
        if (_keyIdx.value != null) {
          children.add(_buildKeyAuth());
        } else {
          children.add(Input(
            controller: _passwordController,
            obscureText: true,
            type: TextInputType.text,
            label: l10n.pwd,
            icon: Icons.password,
            hint: l10n.pwd,
            onSubmitted: (_) => _onSave(),
          ));
        }
        return Column(children: children);
      },
    );
  }

  Widget _buildKeyAuth() {
    return Consumer<PrivateKeyProvider>(
      builder: (_, key, __) {
        final tiles = List<Widget>.generate(key.pkis.length, (index) {
          final e = key.pkis[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Text(
              '#${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            title: Text(e.id, textAlign: TextAlign.start),
            subtitle: Text(
              e.type ?? l10n.unknown,
              textAlign: TextAlign.start,
              style: UIs.textGrey,
            ),
            trailing: _buildRadio(index, e),
          );
        });
        tiles.add(
          ListTile(
            title: Text(l10n.addPrivateKey),
            contentPadding: EdgeInsets.zero,
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => AppRoute.keyEdit().go(context),
            ),
          ),
        );
        return CardX(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17),
            child: Column(
              children: tiles,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPVE() {
    return ExpandTile(
      title: const Text('PVE'),
      children: [
        Input(
          controller: _pveAddrCtrl,
          type: TextInputType.url,
          icon: MingCute.web_line,
          label: l10n.addr,
          hint: 'https://example.com:8006',
        ),
        ListTile(
          leading: const Icon(MingCute.certificate_line),
          title: Text(l10n.ignoreCert),
          subtitle: Text(l10n.pveIgnoreCertTip, style: UIs.text12Grey),
          trailing: ListenableBuilder(
            listenable: _pveIgnoreCert,
            builder: (_, __) => Switch(
              value: _pveIgnoreCert.value,
              onChanged: (val) {
                _pveIgnoreCert.value = val;
              },
            ),
          ),
        ).card,
      ],
    );
  }

  Widget _buildCustomCmd() {
    return ExpandTile(
      title: Text(l10n.customCmd),
      children: [
        Input(
          controller: _customCmdCtrl,
          type: TextInputType.text,
          maxLines: 3,
          label: 'Json',
          icon: Icons.code,
          hint: '{${l10n.customCmdHint}}',
        ),
        ListTile(
          leading: const Icon(MingCute.doc_line),
          title: Text(l10n.doc),
          trailing: const Icon(Icons.open_in_new, size: 17),
          onTap: () => openUrl(l10n.customCmdDocUrl),
        ).card,
      ],
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _onSave,
      child: const Icon(Icons.save),
    );
  }

  Widget _buildRadio(int index, PrivateKeyInfo pki) {
    return ListenableBuilder(
      listenable: _keyIdx,
      builder: (_, __) => Radio<int>(
        value: index,
        groupValue: _keyIdx.value,
        onChanged: (value) {
          _keyIdx.value = value;
        },
      ),
    );
  }

  // Widget _buildJumpServer() {
  //   return ListenableBuilder(
  //     listenable: _jumpServer,
  //     builder: (_, __) {
  //       final children = Pros.server.servers
  //           .where((element) => element.spi.jumpId == null)
  //           .where((element) => element.spi.id != widget.spi?.id)
  //           .map(
  //             (e) => ListTile(
  //               title: Text(e.spi.name),
  //               subtitle: Text(e.spi.id, style: UIs.textGrey),
  //               trailing: Radio<String>(
  //                 groupValue: _jumpServer.value,
  //                 value: e.spi.id,
  //                 onChanged: (val) => _jumpServer.value = val,
  //               ),
  //               onTap: () {
  //                 _jumpServer.value = e.spi.id;
  //               },
  //             ),
  //           )
  //           .toList();
  //       children.add(ListTile(
  //         title: Text(l10n.clear),
  //         trailing: const Icon(Icons.clear),
  //         onTap: () => _jumpServer.value = null,
  //       ));
  //       return CardX(
  //         child: ExpandTile(
  //           leading: const Icon(Icons.map),
  //           initiallyExpanded: _jumpServer.value != null,
  //           title: Text(l10n.jumpServer),
  //           subtitle: const Text(
  //             "It was temporarily disabled because it has some bugs (Issues #210)",
  //             style: UIs.textGrey,
  //           ),
  //           children: children,
  //         ),
  //       );
  //     },
  //   );
  // }

  void _onSave() async {
    if (_ipController.text.isEmpty) {
      context.showSnackBar(l10n.plzEnterHost);
      return;
    }
    if (_keyIdx.value == null && _passwordController.text.isEmpty) {
      final cancel = await context.showRoundDialog<bool>(
        title: Text(l10n.attention),
        child: Text(l10n.askContinue(l10n.useNoPwd)),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(l10n.ok),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: Text(l10n.cancel),
          )
        ],
      );
      if (cancel ?? true) {
        return;
      }
    }
    // If [_pubKeyIndex] is -1, it means that the user has not selected
    if (_keyIdx.value == -1) {
      context.showSnackBar(l10n.plzSelectKey);
      return;
    }
    if (_usernameController.text.isEmpty) {
      _usernameController.text = 'root';
    }
    if (_portController.text.isEmpty) {
      _portController.text = '22';
    }
    final customCmds = () {
      if (_customCmdCtrl.text.isEmpty) return null;
      try {
        return json.decode(_customCmdCtrl.text).cast<String, String>();
      } catch (e) {
        context.showSnackBar(l10n.invalidJson);
        return null;
      }
    }();
    final pveAddr = _pveAddrCtrl.text.selfIfNotNullEmpty;
    final custom = ServerCustom(
      pveAddr: pveAddr,
      pveIgnoreCert: _pveIgnoreCert.value,
      cmds: customCmds,
    );

    final spi = ServerPrivateInfo(
      name: _nameController.text.isEmpty
          ? _ipController.text
          : _nameController.text,
      ip: _ipController.text,
      port: int.parse(_portController.text),
      user: _usernameController.text,
      pwd: _passwordController.text.isEmpty ? null : _passwordController.text,
      keyId: _keyIdx.value != null
          ? Pros.key.pkis.elementAt(_keyIdx.value!).id
          : null,
      tags: _tags,
      alterUrl: _altUrlController.text.isEmpty ? null : _altUrlController.text,
      autoConnect: _autoConnect.value,
      jumpId: _jumpServer.value,
      custom: custom,
    );

    if (widget.spi == null) {
      Pros.server.addServer(spi);
    } else {
      Pros.server.updateServer(widget.spi!, spi);
    }

    context.pop();
  }
}
