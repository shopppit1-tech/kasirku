KASIRKU + SUPABASE — GITHUB PAGES

ISI:
- public/index.html: aplikasi web kasir, pendaftaran email, setup toko, dan cetak struk
- public/manifest.json: metadata PWA
- supabase-schema.sql: tabel, RLS, RPC transaksi/stok, dan RPC setup owner dari web
- .github/workflows/pages.yml: deploy otomatis dari folder public

SETUP:
1. Untuk proyek Supabase baru, jalankan seluruh supabase-schema.sql sekali di SQL Editor. Proyek KasirKu yang sudah dibuat telah menerima fungsi onboarding ini.
2. Buka https://shopppit1-tech.github.io/kasirku/.
3. Tekan “Buat akun”, masukkan email dan password, lalu konfirmasi email dari inbox.
4. Kembali ke website, masuk dengan email/password, lalu isi nama toko. Alamat, nomor telepon, dan nama pemilik bersifat opsional.
5. Setelah masuk, tambahkan produk dan uji transaksi.
6. Saat menambahkan produk, barcode Code 128 dibuat otomatis dan dapat diubah. Setelah produk disimpan, tekan “Cetak label” untuk mencetak barcode produk.
7. Untuk transaksi, tekan “Scan” di Kasir dan izinkan kamera, atau fokuskan kolom pencarian lalu scan memakai scanner USB/Bluetooth. Produk yang cocok akan tampil dan otomatis masuk ke keranjang.

PENGGUNA KASIR:
Untuk menambahkan kasir, buat akun Auth untuk email kasir, lalu buat profile role `cashier` dengan store_id toko yang sama. Jangan pernah memakai service_role/secret key di frontend. Publishable key di HTML aman hanya selama kebijakan RLS tetap aktif.

DEPLOY:
Perubahan pada branch main otomatis diterbitkan ke GitHub Pages dari folder public. Repository GitHub saat ini publik sesuai permintaan pemilik.

CETAK STRUK:
- Setelah transaksi berhasil, struk ditampilkan dan pengguna dapat memilih Thermal 58 mm, Thermal 80 mm, atau kertas biasa.
- Tombol Cetak Struk membuka dialog print browser. Di Android, pasangkan printer pada pengaturan HP dan pilih printer dari dialog cetak jika didukung.
- Untuk printer thermal Bluetooth klasik yang tidak muncul di dialog browser, perlu aplikasi Android/bridge ESC-POS khusus model printer. Web statis tidak bisa menjamin akses Bluetooth langsung ke semua printer.

PENTING:
- Uji dengan akun dan transaksi uji sebelum dipakai pada toko aktif.
- Jangan menonaktifkan RLS. Email confirmation wajib pada konfigurasi Auth proyek ini.
- Tidak ada sinkronisasi saat perangkat offline; realtime berjalan saat koneksi tersedia.
