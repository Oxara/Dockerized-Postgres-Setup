# Multi-Service Docker Environment Setup

Modern, best-practice yaklaşımıyla hazırlanmış multi-environment **PostgreSQL** + **Redis** + **RabbitMQ** + **Elasticsearch** + **MongoDB** + **Monitoring (Prometheus + Grafana)** Docker kurulumu.

> ## ⚠️ ÖNEMLİ GÜVENLİK UYARISI
> 
> Bu proje **ÖRNEK AMAÇLI** `.env` dosyaları içermektedir. Bu dosyalar eğitim ve hızlı başlangıç için tasarlanmıştır.
> 
> **GERÇEK PROJENIZDE MUTLAKA YAPMANIZ GEREKENLER:**
> 
> 1. **`.gitignore` dosyasını güncelleyin**: `.env` satırlarının yorumunu kaldırarak `.env` dosyalarını Git'e eklemeyin
> 2. **Tüm şifreleri değiştirin**: `.env` dosyalarındaki tüm şifreler güçlü, unique şifreler ile değiştirilmelidir
> 3. **Production'da ekstra önlemler**: Güvenlik duvarı, SSL/TLS, network izolasyonu ekleyin
> 4. **Düzenli güvenlik güncellemeleri**: Docker image'larını güncel tutun
> 
> **Bu projeyi olduğu gibi production'da kullanmayın!** 🔒

## 🎯 Genel Bakış

Bu proje, PostgreSQL, Redis, RabbitMQ, Elasticsearch, MongoDB ve Monitoring (Prometheus + Grafana) servislerini birden fazla ortamda (Development, Test, Production) kolayca yönetmenize olanak sağlar. Her servis için ayrı yönetim arayüzü entegre edilmiştir.

### 📦 İçerik

- **PostgreSQL Stack**: PostgreSQL + pgAdmin
- **Redis Stack**: Redis + RedisInsight
- **RabbitMQ Stack**: RabbitMQ + Management UI
- **Elasticsearch Stack**: Elasticsearch + Kibana
- **MongoDB Stack**: MongoDB + Mongo Express
- **Monitoring Stack**: Prometheus + Grafana
- **Tek Komutla Yönetim**: Tüm servisleri veya seçtiğiniz servisi başlatın/durdurun
- **Multi-Environment**: Dev, Test, Prod ortamları tamamen izole

## 📁 Klasör Yapısı

```
database-stack/
├── postgres/
│   └── environments/
│       ├── dev/
│       │   ├── docker-compose.yml
│       │   └── .env
│       ├── test/
│       │   ├── docker-compose.yml
│       │   └── .env
│       └── prod/
│           ├── docker-compose.yml
│           └── .env
├── redis/
│   └── environments/
│       ├── dev/
│       │   ├── docker-compose.yml
│       │   └── .env
│       ├── test/
│       │   ├── docker-compose.yml
│       │   └── .env
│       └── prod/
│           ├── docker-compose.yml
│           └── .env
├── rabbitmq/
│   └── environments/
│       ├── dev/
│       │   ├── docker-compose.yml
│       │   └── .env
│       ├── test/
│       │   ├── docker-compose.yml
│       │   └── .env
│       └── prod/
│           ├── docker-compose.yml
│           └── .env
├── elasticsearch/
│   └── environments/
│       ├── dev/
│       │   ├── docker-compose.yml
│       │   └── .env
│       ├── test/
│       │   ├── docker-compose.yml
│       │   └── .env
│       └── prod/
│           ├── docker-compose.yml
│           └── .env
├── mongodb/
│   └── environments/
│       ├── dev/
│       │   ├── docker-compose.yml
│       │   └── .env
│       ├── test/
│       │   ├── docker-compose.yml
│       │   └── .env
│       └── prod/
│           ├── docker-compose.yml
│           └── .env
├── monitoring/
│   └── environments/
│       ├── dev/
│       │   ├── docker-compose.yml
│       │   ├── prometheus.yml
│       │   └── .env
│       ├── test/
│       │   ├── docker-compose.yml
│       │   ├── prometheus.yml
│       │   └── .env
│       └── prod/
│           ├── docker-compose.yml
│           ├── prometheus.yml
│           └── .env
├── manage.ps1                # Windows yönetim scripti
├── SECURITY-WARNING.txt      # ⚠️ ÖNEMLI GÜVENLİK TALİMATLARI
├── .gitignore                # Git ignore ayarları (güvenlik uyarıları içerir)
├── README.md                 # Bu dosya
├── README-PostgreSQL.md      # PostgreSQL detaylı dokümantasyon
├── README-Redis.md           # Redis detaylı dokümantasyon
├── README-RabbitMQ.md        # RabbitMQ detaylı dokümantasyon
├── README-Elasticsearch.md   # Elasticsearch detaylı dokümantasyon
├── README-MongoDB.md         # MongoDB detaylı dokümantasyon
└── README-Monitoring.md      # Monitoring detaylı dokümantasyon
```

## ✨ Özellikler

- ✅ **Multi-Service Support**: PostgreSQL, Redis, RabbitMQ, Elasticsearch, MongoDB ve Monitoring aynı anda veya ayrı ayrı
- ✅ **Tamamen İzole Ortamlar**: Her ortam kendi klasöründe
- ✅ **Kolay Yönetim**: Tek komutla tüm servisleri kontrol edin
- ✅ **Çakışma Yok**: Her ortam ve servis farklı portlarda
- ✅ **Best Practices**: Docker ve DevOps standartlarına uygun
- ✅ **Güvenli**: .env dosyaları Git'e yüklenmiyor
- ✅ **Kapsamlı Dokümantasyon**: Her servis için detaylı README

## 🚀 Hızlı Başlangıç

### 1️⃣ İlk Kurulum: `.env` Dosyalarını Oluşturun

Her servis için `.env.example` şablonlarından `.env` dosyaları oluşturun:

```powershell
# Tüm servislerin .env.example dosyalarından .env oluştur
$services = @("postgres","redis","rabbitmq","elasticsearch","mongodb","monitoring")
$envs     = @("dev","test","prod")
foreach ($svc in $services) {
    foreach ($env in $envs) {
        $src = "$svc\environments\$env\.env.example"
        $dst = "$svc\environments\$env\.env"
        if (Test-Path $src) { Copy-Item $src $dst }
    }
}
```

> 💡 `.env` dosyaları `.gitignore` tarafından korunuyor — Git'e yüklenmez.

### ⚠️ Şifreleri Güncelleyin

**Gerçek kullanım öncesi mutlaka yapın:**

1. **Her servisteki `.env` dosyalarını düzenleyin** ve şifreleri güçlü değerlerle değiştirin
   ```powershell
   # Her serviste 3 ortam var (dev, test, prod) → toplam 18 .env dosyası
   code postgres\environments\prod\.env
   ```

2. **`SECURITY-WARNING.txt` dosyasını okuyun**

### 1️⃣ Gereksinimler

- Docker Desktop (Windows)
- Docker Compose
- PowerShell 5.1 veya üzeri

### 2️⃣ Temel Komutlar

**Format:**
```powershell
.\manage.ps1 [komut] [ortam] [servis]

# Örnek kullanım
.\manage.ps1 start dev postgres
```

**Parametreler:**
- **Komut**: `start`, `stop`, `restart`, `logs`, `status`, `clean`
- **Ortam**: `dev`, `test`, `prod`
- **Servis**: `postgres`, `redis`, `rabbitmq`, `elasticsearch`, `mongodb`, `monitoring`, `all`

### 3️⃣ Örnek Kullanımlar

```powershell
# 🐘 Sadece PostgreSQL başlat (Development)
.\manage.ps1 start dev postgres

# 🔴 Sadece Redis başlat (Development)
.\manage.ps1 start dev redis

# 🐰 Sadece RabbitMQ başlat (Development)
.\manage.ps1 start dev rabbitmq

# 🔍 Sadece Elasticsearch başlat (Development)
.\manage.ps1 start dev elasticsearch

# 🍃 Sadece MongoDB başlat (Development)
.\manage.ps1 start dev mongodb

# 📊 Sadece Monitoring başlat (Development)
.\manage.ps1 start dev monitoring

# 🎯 Development ortamındaki tüm servisleri başlat
.\manage.ps1 start dev all

# 📊 Production ortamındaki tüm servislerin durumunu görüntüle
.\manage.ps1 status prod all

# 🛑 Test ortamındaki Redis'i durdur
.\manage.ps1 stop test redis

# 🔄 Production'daki tüm servisleri yeniden başlat
.\manage.ps1 restart prod all

# 📋 Development Redis loglarını izle
.\manage.ps1 logs dev redis

# 🔁 Ortamlar arası geçiş (dev → test → prod)
.\manage.ps1 stop dev all
.\manage.ps1 start test all

# 🗑️ Test ortamındaki PostgreSQL'i temizle (veriler silinir!)
.\manage.ps1 clean test postgres
```

## 📊 Port Dağılımı

### PostgreSQL Stack

| Ortam | PostgreSQL | pgAdmin |
|-------|-----------|----------|
| **Dev** | 5432 | 5050 |
| **Test** | 5433 | 5051 |
| **Prod** | 5434 | 5052 |

### Redis Stack

| Ortam | Redis | RedisInsight |
|-------|-------|-------------|
| **Dev** | 6379 | 8001 |
| **Test** | 6380 | 8002 |
| **Prod** | 6381 | 8003 |

### RabbitMQ Stack

| Ortam | AMQP | Management UI |
|-------|------|---------------|
| **Dev** | 5672 | 15672 |
| **Test** | 5673 | 15673 |
| **Prod** | 5674 | 15674 |

### Elasticsearch Stack

| Ortam | Elasticsearch | Kibana |
|-------|---------------|--------|
| **Dev** | 9200 | 5601 |
| **Test** | 9201 | 5602 |
| **Prod** | 9202 | 5603 |

### MongoDB Stack

| Ortam | MongoDB | Mongo Express |
|-------|---------|---------------|
| **Dev** | 27017 | 8081 |
| **Test** | 27018 | 8082 |
| **Prod** | 27019 | 8083 |

### Monitoring Stack

| Ortam | Prometheus | Grafana |
|-------|------------|---------|
| **Dev** | 9090 | 3000 |
| **Test** | 9091 | 3001 |
| **Prod** | 9092 | 3002 |

## 🔧 Yapılandırma

Her servisin her ortamı için ayrı `.env` dosyası bulunmaktadır.  
`.env.example` şablon dosyalarından kopyalanarak oluşturulur (bkz. Hızlı Başlangıç):

- `postgres/environments/dev/.env`
- `postgres/environments/test/.env`
- `postgres/environments/prod/.env`
- `redis/environments/dev/.env`
- `redis/environments/test/.env`
- `redis/environments/prod/.env`
- `rabbitmq/environments/dev/.env`
- `rabbitmq/environments/test/.env`
- `rabbitmq/environments/prod/.env`
- `elasticsearch/environments/dev/.env`
- `elasticsearch/environments/test/.env`
- `elasticsearch/environments/prod/.env`

**Önemli:** Production ortamları için mutlaka güçlü şifreler kullanın!

## 📖 Detaylı Dokümantasyon

Her servis için kapsamlı dokümantasyon mevcuttur:

### [📘 PostgreSQL Dokümantasyonu](README-PostgreSQL.md)
- PostgreSQL + pgAdmin kurulumu
- Bağlantı örnekleri (.NET/C#)
- Backup ve restore işlemleri
- Sorun giderme rehberi
- Güvenlik best practices

### [📕 Redis Dokümantasyonu](README-Redis.md)
- Redis + RedisInsight kurulumu
- Redis komutları ve kullanımları
- Cache senaryoları
- AOF persistence ayarları
- Performance optimizasyonu

### [📙 RabbitMQ Dokümantasyonu](README-RabbitMQ.md)
- RabbitMQ + Management UI kurulumu
- Message queue kullanımı
- Exchange ve queue yönetimi
- Bağlantı örnekleri (.NET/C#)
- Production best practices

### [📗 Elasticsearch Dokümantasyonu](README-Elasticsearch.md)
- Elasticsearch + Kibana kurulumu
- REST API kullanımı
- Index ve mapping yönetimi
- Arama sorguları (Query DSL)
- Kibana Dev Tools ve dashboard'lar
- Aggregation ve analytics örnekleri

## 💡 Kullanım Senaryoları

### Senaryo 1: Sadece PostgreSQL ile Çalışma

```powershell
# Development ortamını başlat
.\manage.ps1 start dev postgres

# pgAdmin'e bağlan: http://localhost:5050

# İşin bitince durdur
.\manage.ps1 stop dev postgres
```

### Senaryo 2: Sadece Redis ile Çalışma

```powershell
# Development ortamını başlat
.\manage.ps1 start dev redis

# RedisInsight'a bağlan: http://localhost:8001

# İşin bitince durdur
.\manage.ps1 stop dev redis
```

### Senaryo 3: Sadece RabbitMQ ile Çalışma

```powershell
# Development ortamını başlat
.\manage.ps1 start dev rabbitmq

# Management UI'a bağlan: http://localhost:15672

# İşin bitince durdur
.\manage.ps1 stop dev rabbitmq
```

### Senaryo 4: Tüm Servisleri Birlikte Kullanma

```powershell
# Tümünü başlat
.\manage.ps1 start dev all

# PostgreSQL: localhost:5432
# pgAdmin: http://localhost:5050
# Redis: localhost:6379
# RedisInsight: http://localhost:8001
# RabbitMQ AMQP: localhost:5672
# RabbitMQ Management: http://localhost:15672
# Elasticsearch: localhost:9200
# Kibana: http://localhost:5601
# MongoDB: localhost:27017
# Mongo Express: http://localhost:8081
# Prometheus: http://localhost:9090
# Grafana: http://localhost:3000

# Durumu kontrol et
.\manage.ps1 status dev all

# Tümünü durdur
.\manage.ps1 stop dev all
```

### Senaryo 5: Sadece Elasticsearch ile Çalışma

```powershell
# Development Elasticsearch başlat
.\manage.ps1 start dev elasticsearch

# Kibana'ya bağlan: http://localhost:5601
# API'ye erişim: http://localhost:9200

# Index oluştur ve arama yap
Invoke-RestMethod -Uri "http://localhost:9200/_cat/indices?v" -Method Get -Credential (Get-Credential)

# İşin bitince durdur
.\manage.ps1 stop dev elasticsearch
```

### Senaryo 6: Test Ortamında Çalışma

```powershell
# Test ortamında tüm servisleri başlat
.\manage.ps1 start test all

# Test portları kullanılır:
# PostgreSQL: localhost:5433
# Redis: localhost:6380
# RabbitMQ: localhost:5673
# Elasticsearch: localhost:9201
# vb.

# Bitirince temizle
.\manage.ps1 clean test all
```

## 🛡️ Güvenlik Notları

### Development/Test Ortamları
- Basit şifreler kullanılabilir
- Localhost erişimi yeterli
- Debug modları açık olabilir

### Production Ortamı
- **ÖNEMLİ**: `.env` dosyalarındaki tüm şifreleri değiştirin!
- Güçlü, benzersiz şifreler kullanın (min 20 karakter, özel karakterler)
- Firewall kurallarını yapılandırın
- SSL/TLS kullanımını etkinleştirin
- Port erişimlerini kısıtlayın
- Düzenli backup alın
- Log monitoring ekleyin

## 📋 Yönetim Komutları Özeti

### Başlatma
```powershell
.\manage.ps1 start <env> <service>
# Örnek: .\manage.ps1 start dev postgres
```

### Durdurma
```powershell
.\manage.ps1 stop <env> <service>
# Örnek: .\manage.ps1 stop dev all
```

### Yeniden Başlatma
```powershell
.\manage.ps1 restart <env> <service>
# Örnek: .\manage.ps1 restart test redis
```

### Log İzleme
```powershell
.\manage.ps1 logs <env> <service>
# Örnek: .\manage.ps1 logs dev postgres
# Not: 'all' ortamı ile kullanılamaz
```

### Durum Kontrolü
```powershell
.\manage.ps1 status <env> <service>
# Örnek: .\manage.ps1 status dev all
```

### Temizleme (Veriler Silinir!)
```powershell
.\manage.ps1 clean <env> <service>
# Örnek: .\manage.ps1 clean test postgres
```

## 🔍 Sorun Giderme

### Port Çakışması

```powershell
# Windows - Port kontrolü
netstat -ano | findstr :5432
netstat -ano | findstr :6379

# Çözüm: İlgili .env dosyasındaki portu değiştirin
```

### Container Başlamıyor

```powershell
# Logları kontrol et
.\manage.ps1 logs dev postgres

# Yeniden oluştur
.\manage.ps1 stop dev postgres
.\manage.ps1 start dev postgres
```

### Script Çalışmıyor (Windows)

```powershell
# Execution policy ayarla
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Sonra tekrar dene
.\manage.ps1 start dev all
```

## 🔄 Güncelleme ve Bakım

### Image Güncelleme

```powershell
# Belirli bir servis için
Set-Location postgres/environments/dev
docker-compose pull
docker-compose up -d

# veya
Set-Location redis/environments/dev
docker-compose pull
docker-compose up -d
```

### Disk Temizliği

```powershell
# Kullanılmayan volume'leri temizle
docker volume prune

# Kullanılmayan image'leri temizle
docker image prune -a

# Sistem geneli temizlik
docker system prune -a --volumes
```

## 💡 İpuçları

1. **Tek seferde bir ortam**: Development sırasında sadece dev ortamını çalıştırın
2. **Servis izolasyonu**: PostgreSQL, Redis, RabbitMQ ve Elasticsearch işlerinizi ayırın
3. **Düzenli backup**: Özellikle production için otomatik backup kurulumu yapın
4. **Log monitoring**: Kritik ortamlar için log aggregation ekleyin (Elasticsearch + Kibana ideal!)
5. **Resource limit**: Production container'larına CPU/Memory limiti koyun
6. **Network segmentation**: Production'da farklı network'ler kullanın
7. **Health checks**: Container health check'lerini aktif tutun

## 🎯 Sonraki Adımlar

1. ✅ **Kurulum Tamamlandı** - Servisleri başlatın
2. 📖 **Dokümantasyon** - Servis-specific README'leri okuyun
3. 🔐 **Güvenlik** - Production şifrelerini güncelleyin
4. � **Backup** - Otomatik backup stratejisi oluşturun
5. 🔧 **Özelleştirme** - İhtiyacınıza göre ayarlayın

## 📚 Ek Kaynaklar

- [PostgreSQL Dokümantasyonu](https://www.postgresql.org/docs/)
- [Redis Dokümantasyonu](https://redis.io/documentation)
- [RabbitMQ Dokümantasyonu](https://www.rabbitmq.com/documentation.html)
- [Elasticsearch Dokümantasyonu](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)
- [Kibana Dokümantasyonu](https://www.elastic.co/guide/en/kibana/current/index.html)
- [Docker Compose Referans](https://docs.docker.com/compose/)

## ℹ️ Proje Hakkında

Bu proje bireysel olarak geliştirilmekte ve yönetilmektedir. Public olarak paylaşılmıştır; MIT lisansı kapsamında özgürce kullanabilir ve fork'layabilirsiniz.

## 📄 Lisans

Bu proje [MIT Lisansı](LICENSE) ile lisanslanmıştır.

---

**Hazırlayan**: Multi-Service Docker Environment Setup  
**Son Güncelleme**: 2026-02-21  
**Versiyon**: 1.0.0

📘 PostgreSQL Detayları: [README-PostgreSQL.md](README-PostgreSQL.md)  
📕 Redis Detayları: [README-Redis.md](README-Redis.md)  
📙 RabbitMQ Detayları: [README-RabbitMQ.md](README-RabbitMQ.md)  
📗 Elasticsearch Detayları: [README-Elasticsearch.md](README-Elasticsearch.md)  
🍃 MongoDB Detayları: [README-MongoDB.md](README-MongoDB.md)  
📊 Monitoring Detayları: [README-Monitoring.md](README-Monitoring.md)

Herhangi bir sorunuz için ilgili servis dokümantasyonuna bakın! 🚀
