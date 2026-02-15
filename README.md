# PostgreSQL Multi-Environment Docker Setup

Modern, best-practice yaklaşımıyla hazırlanmış multi-environment PostgreSQL + pgAdmin kurulumu.

## 📁 Klasör Yapısı

```
postgres-docker/
├── environments/
│   ├── dev/
│   │   ├── docker-compose.yml
│   │   └── .env
│   ├── test/
│   │   ├── docker-compose.yml
│   │   └── .env
│   ├── prod/
│   │   ├── docker-compose.yml
│   │   └── .env
│   └── .env.example
├── manage.ps1              # Windows yönetim scripti
├── manage.sh               # Linux/Mac yönetim scripti
├── .gitignore
└── README.md
```

### 🔍 Klasör Yapısı Açıklaması

**Her ortam tamamen izole şekilde kendi klasöründe çalışır:**

- **`environments/dev/`** - Development (Geliştirme) ortamı
  - `docker-compose.yml` - Dev için compose yapılandırması
  - `.env` - Dev ortam değişkenleri (port: 5432, 5050)

- **`environments/test/`** - Test ortamı
  - `docker-compose.yml` - Test için compose yapılandırması
  - `.env` - Test ortam değişkenleri (port: 5433, 5051)

- **`environments/prod/`** - Production (Canlı) ortamı
  - `docker-compose.yml` - Prod için compose yapılandırması
  - `.env` - Prod ortam değişkenleri (port: 5434, 5052)

- **`environments/.env.example`** - Şablon dosya (yeni ortam eklemek için)

**Yönetim Dosyaları:**
- `manage.ps1` - Windows için otomatik yönetim scripti
- `manage.sh` - Linux/Mac için otomatik yönetim scripti

### 📝 Yeni Ortam Ekleme

Yeni bir ortam eklemek isterseniz:

```bash
# 1. Yeni klasör oluştur
mkdir environments/staging

# 2. .env.example'ı kopyala
cp environments/.env.example environments/staging/.env

# 3. docker-compose.yml'yi başka ortamdan kopyala
cp environments/dev/docker-compose.yml environments/staging/docker-compose.yml

# 4. Değerleri düzenle (.env ve docker-compose.yml)
# - Container isimleri: postgres_staging, pgadmin_staging
# - Portlar: 5435, 5053 (benzersiz olmalı)
# - Volume ve network isimleri: postgres_staging_*, postgres_staging_network

# 5. Başlat
cd environments/staging
docker-compose up -d
```

## ✨ Özellikler

- ✅ **Tamamen İzole Ortamlar**: Her ortam kendi klasöründe
- ✅ **Temiz Yapı**: Her ortam için ayrı docker-compose.yml
- ✅ **Güvenli**: .env dosyaları Git'e yüklenmiyor
- ✅ **Kolay Yönetim**: Hazır scriptler ile tek komutla yönetim
- ✅ **Çakışma Yok**: Her ortam farklı portlarda çalışır
- ✅ **Best Practices**: Docker ve DevOps standartlarına uygun

## 🚀 Hızlı Başlangıç

### 1️⃣ Kurulum

Proje zaten hazır! Her ortamın .env dosyası şablon değerlerle oluşturulmuş durumda.

**Eğer .env dosyalarını oluşturmanız gerekiyorsa:**

```bash
# Her ortam için .env.example'dan kopyala
cp environments/.env.example environments/dev/.env
cp environments/.env.example environments/test/.env
cp environments/.env.example environments/prod/.env
```

**Her ortam için portları ayarlayın:**

- **Dev:** `POSTGRES_PORT=5432`, `PGADMIN_PORT=5050`
- **Test:** `POSTGRES_PORT=5433`, `PGADMIN_PORT=5051`
- **Prod:** `POSTGRES_PORT=5434`, `PGADMIN_PORT=5052`

**Güvenlik için şifreleri değiştirin:**

```bash
# environments/dev/.env
POSTGRES_PASSWORD=güçlü_dev_şifresi
PGADMIN_PASSWORD=güçlü_pgadmin_şifresi

# environments/test/.env
POSTGRES_PASSWORD=güçlü_test_şifresi
PGADMIN_PASSWORD=güçlü_pgadmin_şifresi

# environments/prod/.env
POSTGRES_PASSWORD=ÇOK_GÜÇLÜ_PROD_ŞİFRESİ_123!@#
PGADMIN_PASSWORD=ÇOK_GÜÇLÜ_PGADMIN_ŞİFRESİ_456!@#
```

> 💡 **İpucu:** `environments/.env.example` dosyasında detaylı açıklamalar ve kurulum adımları bulunmaktadır.

### 2️⃣ Ortamı Başlatma

**Yönetim Scriptleri (Önerilen):**

```powershell
# Windows
.\manage.ps1 start dev

# Linux/Mac
./manage.sh start dev
```

**Manuel Yol:**

```bash
# Development ortamını başlat
cd environments/dev
docker-compose up -d

# veya kök dizinden
docker-compose -f environments/dev/docker-compose.yml up -d
```

### 3️⃣ Erişim

| Ortam | PostgreSQL | pgAdmin |
|-------|-----------|---------|
| **Dev** | `localhost:5432` | http://localhost:5050 |
| **Test** | `localhost:5433` | http://localhost:5051 |
| **Prod** | `localhost:5434` | http://localhost:5052 |

## 📖 Kullanım Kılavuzu

### Yönetim Scriptleri

```bash
# BAŞLATMA
.\manage.ps1 start dev      # Development başlat
.\manage.ps1 start test     # Test başlat
.\manage.ps1 start prod     # Production başlat
.\manage.ps1 start all      # Tümünü başlat

# DURDURMA
.\manage.ps1 stop dev       # Development durdur
.\manage.ps1 stop all       # Tümünü durdur

# YENİDEN BAŞLATMA
.\manage.ps1 restart dev    # Development yeniden başlat

# LOGLARI İZLEME
.\manage.ps1 logs dev       # Development logları (Ctrl+C ile çık)

# DURUM KONTROLÜ
.\manage.ps1 status all     # Tüm ortamların durumu

# TEMİZLEME (VERİLER SİLİNİR!)
.\manage.ps1 clean dev      # Development ortamını temizle
```

**Not:** Windows'ta ilk kullanımda şu komutu çalıştırmanız gerekebilir:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Manuel Docker Compose Kullanımı

Her ortam kendi klasöründe bağımsız çalışır:

```bash
# Development ortamında
cd environments/dev
docker-compose up -d        # Başlat
docker-compose down         # Durdur
docker-compose logs -f      # Logları izle
docker-compose ps           # Durum
docker-compose restart      # Yeniden başlat
docker-compose down -v      # Verilerle birlikte sil

# Test ortamında
cd environments/test
docker-compose up -d

# Production ortamında
cd environments/prod
docker-compose up -d
```

**Kök dizinden çalıştırma:**

```bash
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

**Python örneği:**
```python
import psycopg2

conn = psycopg2.connect(
    host="localhost",
    port=5432,
    database="postgres_dev_db",
    user="postgres_dev_user",
    password="your_password"
)
```

**Node.js örneği:**
```javascript
const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'postgres_dev_db',
  user: 'postgres_dev_user',
  password: 'your_password'
});
```

## 🛡️ Güvenlik En İyi Pratikleri

### 1. Şifre Güvenliği
```bash
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
```bash
git status  # .env dosyaları listede olmamalı
```

### 4. Şifre Yönetimi
- Şifreleri bir şifre yöneticisinde saklayın (1Password, LastPass, vb.)
- Ekip üyeleriyle güvenli kanallardan paylaşın (Slack değil!)
- Production şifrelerini sık sık değiştirin

## 📊 İzleme ve Bakım

### Container Durumunu Kontrol Etme

**Script ile:**
```bash
.\manage.ps1 status all
```

**Manuel:**
```bash
# Tüm containerlar
docker ps

# PostgreSQL containerları
docker ps | grep postgres

# Belirli bir ortam
cd environments/dev
docker-compose ps
```

### Disk Kullanımı
```bash
# Volume'leri listele
docker volume ls | grep postgres

# Volume boyutunu kontrol et
docker system df -v
```

### Logları İnceleme

**Script ile:**
```bash
# Canlı log izleme
.\manage.ps1 logs dev
```

**Manuel:**
```bash
# Development ortamı
cd environments/dev
docker-compose logs -f

# Son 100 satır
docker-compose logs --tail=100

# Belirli bir servisin logları
docker logs postgres_dev
docker logs pgadmin_dev
```

### Backup Alma

```bash
# PostgreSQL backup
docker exec postgres_dev pg_dump -U postgres_dev_user postgres_dev_db > backup_dev_$(date +%Y%m%d).sql

# Windows PowerShell için
docker exec postgres_dev pg_dump -U postgres_dev_user postgres_dev_db > "backup_dev_$(Get-Date -Format 'yyyyMMdd').sql"

# Restore etme
docker exec -i postgres_dev psql -U postgres_dev_user postgres_dev_db < backup_dev_20260215.sql
```

## 🐛 Sorun Giderme

### Port Zaten Kullanılıyor

**Problemi tespit edin:**
```bash
# Windows - Port kontrolü
netstat -ano | findstr :5432

# Linux/Mac - Port kontrolü
lsof -i :5432
```

**Çözüm:** İlgili ortamın `.env` dosyasında portu değiştirin:
```env
POSTGRES_PORT=5435
```

### Container Başlamıyor

```bash
# Logları kontrol et
cd environments/dev
docker-compose logs

# Container'ı yeniden oluştur
docker-compose down
docker-compose up -d --force-recreate

# Volume sorunları varsa
docker-compose down -v
docker-compose up -d
```

### pgAdmin Bağlanamıyor

```bash
# PostgreSQL hazır mı kontrol et
docker exec postgres_dev pg_isready

# Network bağlantısını kontrol et
docker network inspect postgres_dev_network

# pgAdmin'i yeniden başlat
cd environments/dev
docker-compose restart pgadmin
```

### Veritabanı Bozuldu

```bash
# 1. Backup aldıysanız restore edin
# 2. Yoksa temizleyip yeniden başlatın
.\manage.ps1 clean dev
.\manage.ps1 start dev
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
```bash
cd environments/dev
docker-compose down
docker-compose pull
docker-compose up -d
```

### Tüm Ortamları Temizleme

```bash
# UYARI: Tüm veriler silinir!

# Script ile
.\manage.ps1 clean all

# veya Manuel
cd environments/dev && docker-compose down -v && cd ../..
cd environments/test && docker-compose down -v && cd ../..
cd environments/prod && docker-compose down -v && cd ../..
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

```bash
# Development'tan Test'e geçiş
.\manage.ps1 stop dev
.\manage.ps1 start test

# Tümünü çalıştır (farklı portlarda)
.\manage.ps1 start all

# Sadece Production
.\manage.ps1 stop dev
.\manage.ps1 stop test
.\manage.ps1 start prod
```

## 🔍 Örnek Senaryolar

### Senaryo 1: Yeni Proje Başlangıcı

```bash
# 1. Şifreleri güncelle
code environments/dev/.env

# 2. Development ortamını başlat
.\manage.ps1 start dev

# 3. pgAdmin'e giriş yap
# http://localhost:5050

# 4. Çalışmayı bitirince durdur
.\manage.ps1 stop dev
```

### Senaryo 2: Test Ortamında Çalışma

```bash
# 1. Test ortamını başlat
cd environments/test
docker-compose up -d

# 2. Logları izle
docker-compose logs -f

# 3. Bitirince durdur
docker-compose down
```

### Senaryo 3: Production Deploy

```bash
# 1. Production .env'i güvenli şifrelerle güncelle
code environments/prod/.env

# 2. Production'ı başlat
.\manage.ps1 start prod

# 3. Health check
docker ps | grep prod

# 4. Logları kontrol et
.\manage.ps1 logs prod
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
**Son Güncelleme:** 2026-02-15  
**Versiyon:** 2.0 - Multi-Environment Isolated Structure
