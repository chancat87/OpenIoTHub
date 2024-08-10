import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:openiothub_api/api/OpenIoTHub/CommonDeviceApi.dart';
import 'package:openiothub_constants/constants/Config.dart';
import 'package:openiothub_constants/constants/Constants.dart';
import 'package:openiothub_grpc_api/proto/mobile/mobile.pb.dart';
import 'package:openiothub_grpc_api/proto/mobile/mobile.pbgrpc.dart';
import 'package:url_launcher/url_launcher.dart';

class FtpPortListPage extends StatefulWidget {
  FtpPortListPage({required Key key, required this.device}) : super(key: key);

  Device device;

  @override
  _FtpPortListPageState createState() => _FtpPortListPageState();
}

class _FtpPortListPageState extends State<FtpPortListPage> {
  static const double IMAGE_ICON_WIDTH = 30.0;
  List<PortConfig> _ServiceList = [];

  @override
  void initState() {
    super.initState();
    refreshmFTPList();
  }

  @override
  Widget build(BuildContext context) {
    final tiles = _ServiceList.map(
      (pair) {
        var listItemContent = Padding(
          padding: const EdgeInsets.fromLTRB(10.0, 15.0, 10.0, 15.0),
          child: Row(
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.fromLTRB(0.0, 0.0, 10.0, 0.0),
                child: Icon(Icons.devices),
              ),
              Expanded(
                  child: Text(
                "${pair.description}(${pair.remotePort})",
                style: Constants.titleTextStyle,
              )),
              Constants.rightArrowIcon
            ],
          ),
        );
        return InkWell(
          onTap: () {
            //打开此端口的详情
            _pushDetail(pair);
          },
          child: listItemContent,
        );
      },
    );
    final divided = ListTile.divideTiles(
      context: context,
      tiles: tiles,
    ).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text("FTP端口列表"),
        actions: <Widget>[
          IconButton(
              icon: const Icon(
                Icons.refresh,
                // color: Colors.white,
              ),
              onPressed: () {
                //刷新端口列表
                refreshmFTPList();
              }),
          IconButton(
              icon: const Icon(
                Icons.add_circle,
                // color: Colors.white,
              ),
              onPressed: () {
//                TODO 添加FTP端口
                _addFTP(widget.device).then((v) {
                  refreshmFTPList();
                });
              }),
        ],
      ),
      body: ListView(children: divided),
    );
  }

  void _pushDetail(PortConfig config) async {
    final List result = [];
    result.add("UUID:${config.uuid}");
    result.add("端口:${config.remotePort}");
    result.add("映射到端口:${config.localProt}");
    result.add("描述:${config.description}");
    result.add("转发连接状态:${config.remotePortStatus ? "在线" : "离线"}");
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          final tiles = result.map(
            (pair) {
              return ListTile(
                title: Text(
                  pair,
                  style: Constants.titleTextStyle,
                ),
              );
            },
          );
          final divided = ListTile.divideTiles(
            context: context,
            tiles: tiles,
          ).toList();

          return Scaffold(
            appBar: AppBar(title: const Text('端口详情'), actions: <Widget>[
              IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    //TODO 删除
                    _deleteCurrentFTP(config);
                  }),
              IconButton(
                  icon: const Icon(
                    Icons.open_in_browser,
                    // color: Colors.white,
                  ),
                  onPressed: () {
                    //                TODO 使用某种方式打开此端口，检查这个软件是否已经安装
                    _launchURL("ftp://${Config.webgRpcIp}:${config.localProt}");
                  }),
            ]),
            body: ListView(children: divided),
          );
        },
      ),
    );
  }

  Future refreshmFTPList() async {
    try {
      CommonDeviceApi.getAllFTP(widget.device).then((v) {
        setState(() {
          _ServiceList = v.portConfigs;
        });
      });
    } catch (e) {
      print('Caught error: $e');
    }
  }

  Future _addFTP(Device device) async {
    TextEditingController descriptionController =
        TextEditingController.fromValue(const TextEditingValue(text: "FTP"));
    TextEditingController remotePortController =
        TextEditingController.fromValue(const TextEditingValue(text: "21"));
    TextEditingController localPortController =
        TextEditingController.fromValue(const TextEditingValue(text: "21"));
    return showDialog(
        context: context,
        builder: (_) => AlertDialog(
                title: const Text("添加端口："),
                content: SizedBox.expand(
                    child: ListView(
                  children: <Widget>[
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(10.0),
                        labelText: '备注',
                        helperText: '自定义备注',
                      ),
                    ),
                    TextFormField(
                      controller: remotePortController,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(10.0),
                        labelText: '端口号',
                        helperText: '该机器的端口号',
                      ),
                    ),
                    TextFormField(
                        controller: localPortController,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.all(10.0),
                          labelText: '映射到本手机端口号(随机则填0)',
                          helperText: '本手机1024以上空闲端口号',
                        ))
                  ],
                )),
                actions: <Widget>[
                  TextButton(
                    child: const Text("取消"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: const Text("添加"),
                    onPressed: () {
                      var FTPConfig = PortConfig();
                      FTPConfig.device = device;
                      FTPConfig.description = descriptionController.text;
                      try {
                        FTPConfig.remotePort =
                            int.parse(remotePortController.text);
                        FTPConfig.localProt =
                            int.parse(localPortController.text);
                      } catch (e) {
                        showToast("检查端口是否为数字$e");
                        return;
                      }
                      FTPConfig.networkProtocol = "tcp";
                      FTPConfig.applicationProtocol = "ftp";
                      CommonDeviceApi.createOneFTP(FTPConfig).then((restlt) {
                        Navigator.of(context).pop();
                      });
                    },
                  )
                ]));
  }

  Future _deleteCurrentFTP(PortConfig config) async {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
                title: const Text("删除FTP"),
                content: SizedBox.expand(
                  child: const Text("确认删除此FTP？"),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text("取消"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: const Text("删除"),
                    onPressed: () {
                      CommonDeviceApi.deleteOneFTP(config).then((result) {
                        Navigator.of(context).pop();
                      });
                    },
                  )
                ])).then((v) {
      Navigator.of(context).pop();
    }).then((v) {
      refreshmFTPList();
    });
  }

  _launchURL(String url) async {
    if (await canLaunchUrl(url as Uri)) {
      await launchUrl(url as Uri);
    } else {
      print('Could not launch $url');
    }
  }
}
