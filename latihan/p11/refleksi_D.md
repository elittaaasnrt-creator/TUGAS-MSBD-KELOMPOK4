# Refleksi D
Enkripsi kolom saja tidak membuat basis data aman.

Ancaman tetap terbuka:
1. Kebocoran kunci. Q22-B: kunci literal terlihat utuh di pg_stat_activity; log server dan riwayat shell juga berisiko.
2. Identifikasi ulang dan inferensi lewat data tersamar. Q24: kombinasi (kota, lahir) unik 6000 baris, dan selisih dua agregat membuka saldo satu orang (8474971.00). Enkripsi tidak mencegah ini.

Risiko operasional: kunci hilang berarti rekening_enc tak bisa didekripsi (Q21). Kunci juga harus disuntik tiap session dan dikelola aman (Q22-A), serta dekripsi menambah beban kerja query.