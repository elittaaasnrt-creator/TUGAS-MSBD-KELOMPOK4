# Bukti Q18-Q23 (Azkha)

| Soal | Bukti utama |
|---|---|
| Q19 | Sesi B menggantung sampai Sesi A COMMIT, lalu mendapat baris id 1 tanpa error |
| Q20 | Sesi B (PID 392) korban: `ERROR: 40P01: deadlock detected`, Sesi A (PID 377) lolos |
| Q21 | Urutan id 1 lalu id 2 di kedua sesi: tanpa 40P01 |
| Q22 | PID 392 `Lock/transactionid`, `diblokir_oleh = {377}`; `pg_locks` ShareLock `granted = f` |
| Q23 | statement_timeout 1s, lock_timeout 2s, idle_in_transaction 5s semuanya terbukti memutus; deadlock_timeout = 1s |

Keluaran terminal lengkap: `hasil-sesi.txt`.