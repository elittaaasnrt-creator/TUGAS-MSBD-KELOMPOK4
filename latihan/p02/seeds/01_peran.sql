INSERT INTO anggota (no_id, nama, kategori, status) VALUES
  ('ADM-001', 'Admin Utama Lab', 'Petugas', 'aktif'),
  ('PTG-001', 'Petugas Laboratorium', 'Petugas', 'aktif'),
  ('MHS-001', 'Anggota Mahasiswa', 'Mahasiswa', 'aktif')
ON CONFLICT (no_id) DO UPDATE SET 
  nama = EXCLUDED.nama,
  kategori = EXCLUDED.kategori,
  status = EXCLUDED.status;