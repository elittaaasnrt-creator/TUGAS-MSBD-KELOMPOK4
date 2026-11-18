-- Diminta: REVOKE DROP dari skema_owner, kutip galat, jelaskan hak biasa vs hak kepemilikan.
-- Dipilih: jalankan apa adanya dan kutip galat PostgreSQL.
-- Alternatif: hanya teori; tidak dipilih karena soal meminta bukti.
REVOKE DROP ON lab11.akun FROM skema_owner;
-- GALAT (postgres): ERROR:  unrecognized privilege type "drop"
-- Penjelasan: SELECT/UPDATE dst. adalah hak di ACL yang bisa diberi/dicabut. DROP dan ALTER
-- bukan hak di ACL, melainkan wewenang yang melekat pada pemilik (atau anggota peran pemilik
-- dan superuser). Satu-satunya cara mencabutnya: ALTER ... OWNER TO atau menghapus peran.