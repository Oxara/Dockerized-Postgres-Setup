# PostgreSQL Multi-Environment Docker Setup

Modern, best-practice yaklaşımıyla hazırlanmış multi-environment PostgreSQL + pgAdmin kurulumu.

## 📁 Klasör Yapısı

```
postgres/
└── environments/
    ├── dev/
    │   ├── docker-compose.yml
    │   └── .env
    ├── test/
    │   ├── docker-compose.yml
    │   └── .env
    └── prod/
        ├── docker-compose.yml
        └── .env
```

> Servis `.\manage.ps1` ile proje kök dizininden yönetilir. Yönetim komutları için [ana README](../README.md)'e bakın.

## ✨ Özellikler

- ✅ **Tamamen İzole Ortamlar**: Her ortam kendi klasöründe
- ✅ **Temiz Yapı**: Her ortam için ayrı docker-compose.yml
- ✅ **Güvenli**: .env dosyaları Git'e yüklenmiyor
- ✅ **Kolay Yönetim**: Hazır scriptler ile tek komutla yönetim
- ✅ **Çakışma Yok**: Her ortam farklı portlarda çalışır
- ✅ **Best Practices**: Docker ve DevOps standartlarına uygun


## 🚀 Hızlı Başlangıç

### 1️⃣ Kurulum

**Depoyu klonladıktan sonra her ortam için `.env` dosyasını oluşturun:**

```powershell
# Her ortam için .env.example'dan kopyala
Copy-Item postgres\environments\dev\.env.example postgres\environments\dev\.env
Copy-Item postgres\environments\test\.env.example postgres\environments\test\.env
Copy-Item postgres\environments\prod\.env.example postgres\environments\prod\.env
```

**Her ortam için portları ayarlayın:**

- **Dev:** `POSTGRES_PORT=5432`, `PGADMIN_PORT=5050`
- **Test:** `POSTGRES_PORT=5433`, `PGADMIN_PORT=5051`
- **Prod:** `POSTGRES_PORT=5434`, `PGADMIN_PORT=5052`

**Güvenlik için şifreleri değiştirin:**

```powershell
# environments/dev/.env içeriği
POSTGRES_PASSWORD=güçlü_dev_şifresi
PGADMIN_PASSWORD=güçlü_pgadmin_şifresi

# environments/test/.env içeriği
POSTGRES_PASSWORD=güçlü_test_şifresi
PGADMIN_PASSWORD=güçlü_pgadmin_şifresi

# environments/prod/.env içeriği
POSTGRES_PASSWORD=ÇOK_GÜÇLÜ_PROD_ŞİFRESİ_123!@#
PGADMIN_PASSWORD=ÇOK_GÜÇLÜ_PGADMIN_ŞİFRESİ_456!@#
```

> 💡 **İpucu:** `environments/.env.example` dosyasında detaylı açıklamalar ve kurulum adımları bulunmaktadır.

### 2️⃣ Ortamı Başlatma

**Yönetim Scriptleri (Önerilen):**

```powershell
.\manage.ps1 start dev postgres
```

### 3️⃣ Erişim

| Ortam | PostgreSQL `→5432` | pgAdmin `→80` |
|-------|-------------------|---------------|
| **Dev** | `localhost:5432` | http://localhost:5050 |
| **Test** | `localhost:5433` | http://localhost:5051 |
| **Prod** | `localhost:5434` | http://localhost:5052 |

## 📖 Kullanım Kılavuzu

### Yönetim Scripti

```powershell
# BAŞLATMA
.\manage.ps1 start dev postgres      # Development başlat
.\manage.ps1 start test postgres     # Test başlat
.\manage.ps1 start prod postgres     # Production başlat

# DURDURMA
.\manage.ps1 stop dev postgres       # Development durdur
.\manage.ps1 stop test postgres      # Test durdur

# YENİDEN BAŞLATMA
.\manage.ps1 restart dev postgres    # Development yeniden başlat

# LOGLARI İZLEME
.\manage.ps1 logs dev postgres       # Development logları (Ctrl+C ile çık)

# DURUM KONTROLÜ
.\manage.ps1 status dev postgres     # Development durumu
.\manage.ps1 status prod postgres    # Production durumu

# TEMİZLEME (VERİLER SİLİNİR!)
.\manage.ps1 clean dev postgres      # Development ortamını temizle
```

**Not:** Windows'ta ilk kullanımda şu komutu çalıştırmanız gerekebilir:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Manuel Docker Compose Kullanımı

Her ortam kendi klasöründe bağımsız çalışır:

```powershell
# Development ortamında
Set-Location environments\dev
docker-compose up -d        # Başlat
docker-compose down         # Durdur
docker-compose logs -f      # Logları izle
docker-compose ps           # Durum
docker-compose restart      # Yeniden başlat
docker-compose down -v      # Verilerle birlikte sil

# Test ortamında
Set-Location environments\test
docker-compose up -d

# Production ortamında
Set-Location environments\prod
docker-compose up -d
```

**Kök dizinden çalıştırma:**

```powershell
# Development
docker-compose -f environments/dev/docker-compose.yml up -d
docker-compose -f environments/dev/docker-compose.yml down

# Test
docker-compose -f environments/test/docker-compose.yml up -d
docker-compose -f environments/test/docker-compose.yml down

# Production
docker-compose -f environments/prod/docker-compose.yml up -d
docker-compose -f environments/prod/docker-compose.yml down
```

## 🔧 Yapılandırma

Her ortamın kendi `.env` dosyası vardır:

**environments/dev/.env:**
```env
# PostgreSQL Settings
POSTGRES_USER=postgres_dev_user
POSTGRES_PASSWORD=güçlü_şifre_buraya
POSTGRES_DB=postgres_dev_db
POSTGRES_PORT=5432

# pgAdmin Settings
PGADMIN_EMAIL=admin.dev@example.com
PGADMIN_PASSWORD=pgadmin_şifresi
PGADMIN_PORT=5050
```

### Port Yapılandırması

Default portlar:
- **Dev**: PostgreSQL 5432, pgAdmin 5050
- **Test**: PostgreSQL 5433, pgAdmin 5051
- **Prod**: PostgreSQL 5434, pgAdmin 5052

Port değiştirmek için ilgili ortamın `.env` dosyasını düzenleyin.

## 🔌 Veritabanına Bağlanma

### pgAdmin'den Bağlanma

1. pgAdmin'e giriş yapın (http://localhost:5050 - dev için)
2. "Add New Server" tıklayın
3. **General** sekmesi:
   - Name: `Development` (veya istediğiniz isim)
4. **Connection** sekmesi:
   - Host: `postgres` (container adı - aynı network'te)
   - Port: `5432` (container içi port)
   - Username: `.env` dosyasındaki `POSTGRES_USER`
   - Password: `.env` dosyasındaki `POSTGRES_PASSWORD`

### Uygulama veya Harici Araçlardan Bağlanma

**Development:**
```
Host: localhost
Port: 5432
User: postgres_dev_user
Password: (environments/dev/.env içinde)
Database: postgres_dev_db
```

**Test:**
```
Host: localhost
Port: 5433
User: postgres_test_user
Password: (environments/test/.env içinde)
Database: postgres_test_db
```

**Production:**
```
Host: localhost
Port: 5434
User: postgres_prod_user
Password: (environments/prod/.env içinde)
Database: postgres_prod_db
```

**.NET Core örneği (Npgsql):**
```csharp
using Npgsql;

// Connection string
string connectionString = "Host=localhost;Port=5432;Database=postgres_dev_db;Username=postgres_dev_user;Password=your_password";

// Bağlantı oluştur
using var connection = new NpgsqlConnection(connectionString);
await connection.OpenAsync();

// Sorgu çalıştır
using var cmd = new NpgsqlCommand("SELECT version()", connection);
var version = await cmd.ExecuteScalarAsync();
Console.WriteLine($"PostgreSQL version: {version}");

// Veri ekleme
using var insertCmd = new NpgsqlCommand("INSERT INTO users (name, email) VALUES (@name, @email)", connection);
insertCmd.Parameters.AddWithValue("name", "John Doe");
insertCmd.Parameters.AddWithValue("email", "john@example.com");
await insertCmd.ExecuteNonQueryAsync();

// Veri okuma
using var selectCmd = new NpgsqlCommand("SELECT id, name, email FROM users", connection);
using var reader = await selectCmd.ExecuteReaderAsync();
while (await reader.ReadAsync())
{
    Console.WriteLine($"{reader.GetInt32(0)}: {reader.GetString(1)} - {reader.GetString(2)}");
}
```

**Entity Framework Core örneği:**
```csharp
using Microsoft.EntityFrameworkCore;

// DbContext tanımı
public class AppDbContext : DbContext
{
    public DbSet<User> Users { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        optionsBuilder.UseNpgsql("Host=localhost;Port=5432;Database=postgres_dev_db;Username=postgres_dev_user;Password=your_password");
    }
}

public class User
{
    public int Id { get; set; }
    public string Name { get; set; }
    public string Email { get; set; }
}

// Kullanım
using var context = new AppDbContext();

// Veri ekleme
context.Users.Add(new User { Name = "John Doe", Email = "john@example.com" });
await context.SaveChangesAsync();

// Veri okuma
var users = await context.Users.ToListAsync();
foreach (var user in users)
{
    Console.WriteLine($"{user.Id}: {user.Name} - {user.Email}");
}
```

**NuGet Paketleri:**
```powershell
# Npgsql için
dotnet add package Npgsql

# Entity Framework Core için
dotnet add package Npgsql.EntityFrameworkCore.PostgreSQL
dotnet add package Microsoft.EntityFrameworkCore.Design
```

## 🛡️ Güvenlik En İyi Pratikleri

### 1. Şifre Güvenliği
```powershell
# ❌ YANLIŞ - Zayıf şifre
POSTGRES_PASSWORD=123456

# ✅ DOĞRU - Güçlü şifre
POSTGRES_PASSWORD=Kx9&mP2$vL8@qR5#wN3!
```

### 2. Environment Ayrımı
- Development ve Test için basit şifreler kullanabilirsiniz
- Production için **mutlaka** güçlü, benzersiz şifreler kullanın
- Production şifrelerini asla development ile aynı yapmayın

### 3. Git Güvenliği
`.gitignore` dosyası `.env` dosyalarını otomatik olarak hariç tutar:
```gitignore
environments/*/.env
```

**Kontrol edin:**
```powershell
git status  # .env dosyaları listede olmamalı
```

### 4. Şifre Yönetimi
- Şifreleri bir şifre yöneticisinde saklayın (1Password, LastPass, vb.)
- Ekip üyeleriyle güvenli kanallardan paylaşın (Slack değil!)
- Production şifrelerini sık sık değiştirin

## 📊 İzleme ve Bakım

### Container Durumunu Kontrol Etme

**Script ile:**
```powershell
.\manage.ps1 status dev postgres
```

**Manuel:**
```powershell
# Tüm containerlar
docker ps

# PostgreSQL containerları
docker ps | Select-String "postgres"

# Belirli bir ortam
Set-Location environments\dev
docker-compose ps
```

### Disk Kullanımı
```powershell
# Volume'leri listele
docker volume ls | Select-String "postgres"

# Volume boyutunu kontrol et
docker system df -v
```

### Logları İnceleme

**Script ile:**
```powershell
# Canlı log izleme
.\manage.ps1 logs dev postgres
```

**Manuel:**
```powershell
# Development ortamı
Set-Location environments\dev
docker-compose logs -f

# Son 100 satır
docker-compose logs --tail=100

# Belirli bir servisin logları
docker logs postgres_dev
docker logs pgadmin_dev
```

### Backup Alma

```powershell
# PostgreSQL backup
docker exec postgres_dev pg_dump -U postgres_dev_user postgres_dev_db > "backup_dev_$(Get-Date -Format 'yyyyMMdd').sql"

# Restore etme
docker exec -i postgres_dev psql -U postgres_dev_user postgres_dev_db < backup_dev_20260215.sql
```

## 🐛 Sorun Giderme

### Port Zaten Kullanılıyor

**Problemi tespit edin:**
```powershell
# Port kontrolü
netstat -ano | findstr :5432
```

**Çözüm:** İlgili ortamın `.env` dosyasında portu değiştirin:
```env
POSTGRES_PORT=5435
```

### Container Başlamıyor

```powershell
# Logları kontrol et
Set-Location environments\dev
docker-compose logs

# Container'ı yeniden oluştur
docker-compose down
docker-compose up -d --force-recreate

# Volume sorunları varsa
docker-compose down -v
docker-compose up -d
```

### pgAdmin Bağlanamıyor

```powershell
# PostgreSQL hazır mı kontrol et
docker exec postgres_dev pg_isready

# Network bağlantısını kontrol et
docker network inspect postgres_dev_network

# pgAdmin'i yeniden başlat
Set-Location environments\dev
docker-compose restart pgadmin
```

### Veritabanı Bozuldu

```powershell
# 1. Backup aldıysanız restore edin
# 2. Yoksa temizleyip yeniden başlatın
.\manage.ps1 clean dev postgres
.\manage.ps1 start dev postgres
```

### Script Çalışmıyor (Windows)

```powershell
# PowerShell execution policy sorunuysa
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Sonra tekrar deneyin
.\manage.ps1 start dev
```

## 🔄 Güncelleme ve Bakım

### PostgreSQL Versiyonunu Güncelleme

1. İlgili ortamın `docker-compose.yml` dosyasını düzenleyin:
```yaml
image: postgres:17-alpine  # 16-alpine yerine
```

2. Ortamı yeniden oluşturun:
```powershell
Set-Location environments\dev
docker-compose down
docker-compose pull
docker-compose up -d
```

### Ortamı Temizleme

```powershell
# UYARI: Ortamdaki tüm veriler silinir!

# Script ile
.\manage.ps1 clean dev postgres

# veya Manuel
Set-Location environments\dev
docker-compose down -v
Set-Location ../..
```

## 💡 İpuçları ve Best Practices

1. **Geliştirme sırasında** sadece dev ortamını çalıştırın
2. **Test etmeden önce** test ortamını başlatın
3. **Production'ı** sadece deploy için kullanın
4. **Düzenli backup** alın, özellikle production için
5. **Logları** düzenli kontrol edin
6. **Disk alanını** izleyin, gereksiz volume'leri temizleyin
7. **Her ortamın .env dosyasını** farklı şifrelerle yapılandırın

## 🎯 Ortamlar Arası Geçiş

```powershell
# Development'tan Test'e geçiş
.\manage.ps1 stop dev postgres
.\manage.ps1 start test postgres

# Sadece Production
.\manage.ps1 stop dev postgres
.\manage.ps1 stop test postgres
.\manage.ps1 start prod postgres
```

## 🔍 Örnek Senaryolar

### Senaryo 1: Yeni Proje Başlangıcı

```powershell
# 1. Şifreleri güncelle
code environments\dev\.env

# 2. Development ortamını başlat
.\manage.ps1 start dev postgres

# 3. pgAdmin'e giriş yap
# http://localhost:5050

# 4. Çalışmayı bitirince durdur
.\manage.ps1 stop dev postgres
```

### Senaryo 2: Test Ortamında Çalışma

```powershell
# 1. Test ortamını başlat
Set-Location environments\test
docker-compose up -d

# 2. Logları izle
docker-compose logs -f

# 3. Bitirince durdur
docker-compose down
```

### Senaryo 3: Production Deploy

```powershell
# 1. Production .env'i güvenli şifrelerle güncelle
code environments\prod\.env

# 2. Production'ı başlat
.\manage.ps1 start prod postgres

# 3. Health check
docker ps | Select-String "prod"

# 4. Logları kontrol et
.\manage.ps1 logs prod postgres
```

## 📚 Ek Kaynaklar

- [PostgreSQL Resmi Dokümantasyon](https://www.postgresql.org/docs/)
- [pgAdmin Dokümantasyon](https://www.pgadmin.org/docs/)
- [Docker Compose Referans](https://docs.docker.com/compose/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

## ❓ Sık Sorulan Sorular

**S: Neden her ortam için ayrı klasör?**
A: İzolasyon, bağımsızlık ve karışıklığı önlemek için. Her ortam kendi bağımsız ekosisteminde çalışır.

**S: Tüm ortamları aynı anda çalıştırabilir miyim?**
A: Evet, her ortam farklı portlarda olduğu için sorunsuzca çalışabilir.

**S: Eski yapıdan nasıl geçiş yaparım?**
A: Eski yapıdaki .env dosyalarını ilgili ortamların klasörlerine taşıyın ve yeni komutları kullanın.

**S: Production'da restart policy neden "always"?**
A: Production'da sunucu yeniden başladığında containerların otomatik başlaması için. Dev/Test'te "unless-stopped" kullanıyoruz.

---

**Hazırlayan:** Best Practices ile Docker & PostgreSQL Setup  
**Son Güncelleme:** 2026-02-21  
**Versiyon:** 1.0.0
