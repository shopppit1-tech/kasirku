KASIRKU + SUPABASE — TANPA RENDER

ISI:
- public/index.html: aplikasi web kasir
- public/manifest.json: metadata PWA
- supabase-schema.sql: tabel, RLS, RPC transaksi atomik dan stok masuk
- README.txt: panduan setup

SETUP SUPABASE:
1. Buat proyek di https://supabase.com.
2. Buka SQL Editor, jalankan seluruh isi supabase-schema.sql.
3. Authentication > Users > Add user: buat akun pemilik dengan email dan password.
4. Di SQL Editor jalankan:
   INSERT INTO public.store_settings(store_name,address,phone)
   VALUES ('Nama Toko','Alamat Toko','08xxxx') RETURNING id;
   Salin UUID yang dihasilkan.
5. Jalankan (ganti email dan UUID):
   INSERT INTO public.profiles(id,store_id,display_name,role)
   VALUES ((SELECT id FROM auth.users WHERE email='email-pemilik@contoh.com'),
   'UUID-STORE-DARI-LANGKAH-4','Pemilik','owner');
6. Untuk setiap akun kasir, buat user di Authentication > Users, lalu tambahkan profile:
   INSERT INTO public.profiles(id,store_id,display_name,role)
   VALUES ((SELECT id FROM auth.users WHERE email='email-kasir@contoh.com'),
   'UUID-STORE-YANG-SAMA','Nama Kasir','cashier');
7. Buka Project Settings > API. Salin Project URL dan Publishable key.
8. Edit public/index.html: ganti GANTI_DENGAN_PROJECT_URL dan GANTI_DENGAN_PUBLISHABLE_KEY.
   Publishable key/anon key boleh di frontend hanya karena kebijakan RLS mengatur akses. JANGAN masukkan service_role/secret key ke HTML.
9. Unggah folder public ke GitHub repository, aktifkan GitHub Pages dari branch utama/folder public atau gunakan root repo dengan menyalin isi folder public ke root. URL harus HTTPS.
10. Buka website. Login dengan email/password pemilik. Tambah produk dan uji transaksi. Login di perangkat lain menggunakan URL yang sama.

CETAK STRUK:
- Setelah transaksi berhasil, struk ditampilkan dan pengguna dapat memilih Thermal 58 mm, Thermal 80 mm, atau kertas biasa.
- Tombol Cetak Struk membuka dialog print browser. Di Android, pasangkan printer pada pengaturan HP dan pilih printer dari dialog cetak jika didukung.
- Untuk printer thermal Bluetooth klasik yang tidak muncul di dialog browser, perlu aplikasi Android/bridge ESC-POS khusus model printer. Web statis tidak bisa menjamin akses Bluetooth langsung ke semua printer.

PENTING:
- Ini paket starter; lakukan pengujian dengan akun uji sebelum dipakai pada toko aktif.
- Supabase SQL Editor dipakai untuk setup akun pertama. Jangan menonaktifkan RLS.
- Kebijakan produk pada contoh memberi kasir akses tambah/edit stok/produk dalam toko. Penghapusan produk dilakukan sebagai nonaktif oleh UI; bila ingin pemisahan hak akses lebih ketat, tambahkan policies/RPC sesuai role.
- GitHub Pages adalah hosting statis; Supabase menjadi database/auth/backend RPC.
- Tidak ada sinkronisasi saat perangkat offline; perubahan realtime berjalan saat koneksi tersedia.
