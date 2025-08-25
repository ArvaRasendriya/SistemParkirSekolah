class UserData {
  final String nama;
  final String statusSim; // "Punya SIM" / "Tidak Punya SIM"
  final String waktu;
  final String tanggal;
  final String jenis;
  final String noKendaraan;

  UserData({
    required this.nama,
    required this.statusSim,
    required this.waktu,
    required this.tanggal,
    required this.jenis,
    required this.noKendaraan,
  });

  Map<String, dynamic> toJson() {
    return {
      'nama': nama,
      'statusSim': statusSim,
      'waktu': waktu,
      'tanggal': tanggal,
      'jenis': jenis,
      'noKendaraan': noKendaraan,
    };
  }

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      nama: json['nama'],
      statusSim: json['statusSim'],
      waktu: json['waktu'],
      tanggal: json['tanggal'],
      jenis: json['jenis'],
      noKendaraan: json['noKendaraan'],
    );
  }
}
