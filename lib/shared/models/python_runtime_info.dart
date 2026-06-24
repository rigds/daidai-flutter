class PythonRuntimeInfo {
  final String version;
  final String executable;

  const PythonRuntimeInfo({this.version = '', this.executable = ''});

  factory PythonRuntimeInfo.fromJson(Map<String, dynamic> json) =>
      PythonRuntimeInfo(
        version: json['version']?.toString() ?? '',
        executable: json['executable']?.toString() ?? '',
      );
}
