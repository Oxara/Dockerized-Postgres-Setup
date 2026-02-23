# Multi-Service Docker Environment Setup

Modern, best-practice yaklaşımıyla hazırlanmış multi-environment **PostgreSQL** + **Redis** + **RabbitMQ** + **Elasticsearch** + **MongoDB** + **Monitoring (Prometheus + Grafana)** + **MSSQL (SQL Server)** + **Keycloak** + **Seq** + **MailHog** Docker kurulumu.

> ## ⚠️ ÖNEMLİ GÜVENLİK UYARISI
> 
> Bu proje **ÖRNEK AMAÇLI** `.env` dosyaları içermektedir. Bu dosyalar eğitim ve hızlı başlangıç için tasarlanmıştır.
> 
> **GERÇEK PROJENIZDE MUTLAKA YAPMANIZ GEREKENLER:**
> 
> 1. **Tüm şifreleri değiştirin**: `.env` dosyalarındaki tüm şifreler güçlü, unique şifreler ile değiştirilmelidir
> 2. **Production'da ekstra önlemler**: Güvenlik duvarı, SSL/TLS, network izolasyonu ekleyin
> 3. **Düzenli güvenlik güncellemeleri**: Docker image'larını güncel tutun
> 
> **Bu projeyi olduğu gibi production'da kullanmayın!** 🔒

## 🎯 Genel Bakış

Bu proje, 10 bağımsız servisi birden fazla ortamda (Development, Test, Production) kolayca yönetmenize olanak sağlar. Her servis tamamen izole çalışır ve kendi yönetim arayüzüne sahiptir.

### 📦 İçerik

| Stack | Bileşenler | Kullanım Amacı |
|-------|-----------|----------------|
| **PostgreSQL** | PostgreSQL + pgAdmin | İlişkisel veritabanı |
| **Redis** | Redis + RedisInsight | Cache, session, pub/sub |
| **RabbitMQ** | RabbitMQ + Management UI | Message queue / event bus |
| **Elasticsearch** | Elasticsearch + Kibana | Full-text search, analytics |
| **MongoDB** | MongoDB + Mongo Express | Doküman veritabanı |
| **Monitoring** | Prometheus + Grafana | Metrik toplama ve görselleştirme |
| **MSSQL** | SQL Server 2022 + Adminer | İlişkisel DB (.NET native) |
| **Keycloak** | Keycloak 26 + PostgreSQL | OAuth2/OIDC identity server |
| **Seq** | Seq Log Server | Structured log analizi (.NET) |
| **MailHog** | Fake SMTP Server | E-posta tuzağı (dev/test) |
| **n8n** | n8n Workflow | Otomasyon ve entegrasyon |

Her servis **dev / test / prod** ortamlarında tamamen izole çalışır. `manage.ps1` ile tek komutla yönetilir.

## 📁 Klasör Yapısı

Tüm servisler aynı klasör yapısını paylaşır:

```
docker-service-stack/
├── {servis}/
│   └── environments/
│       ├── dev/
│       │   ├── docker-compose.yml
│       │   └── .env.example      # → .env olarak kopyalanır (.gitignore'da)
│       ├── test/
│       │   └── ...               # aynı yapı
│       └── prod/
│           └── ...               # aynı yapı (monitoring: + prometheus.yml)
├── manage.ps1
├── .gitignore · LICENSE · CHANGELOG.md · SECURITY-WARNING.txt
└── README.md · README-{Servis}.md × 10
```

| Klasör | Servis | UI Bileşeni |
|--------|--------|-------------|
| `postgres/` | PostgreSQL | pgAdmin |
| `redis/` | Redis | RedisInsight |
| `rabbitmq/` | RabbitMQ | Management UI |
| `elasticsearch/` | Elasticsearch | Kibana |
| `mongodb/` | MongoDB | Mongo Express |
| `monitoring/` | Prometheus | Grafana |
| `mssql/` | SQL Server 2022 | Adminer |
| `keycloak/` | Keycloak 26 | Admin Console |
| `seq/` | Seq Log Server | Web UI (dahili) |
| `mailhog/` | MailHog SMTP | Web UI (dahili) |
| `n8n/` | n8n Workflow | Web UI (dahili) |

## ✨ Özellikler

- ✅ **Multi-Service Support**: PostgreSQL, Redis, RabbitMQ, Elasticsearch, MongoDB, Monitoring, MSSQL, Keycloak, Seq, MailHog ve n8n aynı anda veya ayrı ayrı
- ✅ **Tamamen İzole Ortamlar**: Her ortam kendi klasöründe
- ✅ **Kolay Yönetim**: Tek komutla tüm servisleri kontrol edin
- ✅ **Paralel Çalışma**: `start`, `stop`, `restart` ve `pull` komutları tüm servisler için paralel çalışır
- ✅ **Akıllı Pull**: `pull` komutu, image zaten lokalde mevcutsa tekrar indirmez (`= Already exists`)
- ✅ **Canlı Durum + Sonuç Tablosu**: İşlem sırasında her servis anlık izlenir; bitince tek bir özet tablo (harcanan süre dahil) görüntülenir
- ✅ **Çakışma Yok**: Her ortam ve servis farklı portlarda
- ✅ **Best Practices**: Docker ve DevOps standartlarına uygun
- ✅ **Güvenli**: .env dosyaları Git'e yüklenmiyor
- ✅ **Kapsamlı Dokümantasyon**: Her servis için detaylı README

## 🚀 Hızlı Başlangıç

### ⚙️ Gereksinimler

- Docker Desktop (Windows) + Docker Compose
- PowerShell 5.1 veya üzeri

### 1️⃣ `.env` Dosyalarını Oluşturun

```powershell
$services = @("postgres","redis","rabbitmq","elasticsearch","mongodb","monitoring","mssql","keycloak","seq","mailhog")
$envs     = @("dev","test","prod")
foreach ($svc in $services) {
    foreach ($env in $envs) {
        $src = "$svc\environments\$env\.env.example"
        $dst = "$svc\environments\$env\.env"
        if (Test-Path $src) { Copy-Item $src $dst }
    }
}
```

> 💡 `.env` dosyaları `.gitignore` tarafından korunur — Git'e yüklenmez.

### ⚠️ Şifreleri Güncelleyin

Oluşturulan `.env` dosyalarındaki örnek şifreleri gerçek kullanımdan önce değiştirin.  
Özellikle `prod` ortamı için zorunludur. Detaylar için `SECURITY-WARNING.txt` dosyasına bakın.

### 2️⃣ Servisleri Başlatın

```powershell
.\manage.ps1 [komut] [ortam] [servis]
```

| Parametre | Seçenekler |
|-----------|-----------|
| **komut** | `start` · `stop` · `restart` · `logs` · `status` · `clean` · `purge` · `pull` |
| **ortam** | `dev` · `test` · `prod` |
| **servis** | `postgres` · `redis` · `rabbitmq` · `elasticsearch` · `mongodb` · `monitoring` · `mssql` · `keycloak` · `seq` · `mailhog` · `n8n` · `all` |

### 3️⃣ Örnek Komutlar

```powershell
# Tek servis — başlat / durdur
.\manage.ps1 start dev postgres
.\manage.ps1 stop  dev postgres

# Tüm servisleri başlat
.\manage.ps1 start dev all

# Ortam geçişi (dev → test)
.\manage.ps1 stop dev all
.\manage.ps1 start test all

# Diğer
.\manage.ps1 status dev all            # tüm container durumu
.\manage.ps1 logs   dev rabbitmq       # canlı log takibi
.\manage.ps1 restart prod monitoring   # yeniden başlat
.\manage.ps1 clean test postgres       # ⚠️ veri silinir
```

## 📊 Port Dağılımı

> **Host Port** → container'a yönlendirilen host portu. **Container Port** → container içindeki gerçek port.

| Servis | Bileşen | Container Port | Dev | Test | Prod |
|--------|---------|:--------------:|-----|------|------|
| **PostgreSQL** | PostgreSQL | 5432 | 5432 | 5433 | 5434 |
| | pgAdmin | 80 | 5050 | 5051 | 5052 |
| **Redis** | Redis | 6379 | 6379 | 6380 | 6381 |
| | RedisInsight | 5540 | 8001 | 8002 | 8003 |
| **RabbitMQ** | AMQP | 5672 | 5672 | 5673 | 5674 |
| | Management UI | 15672 | 15672 | 15673 | 15674 |
| **Elasticsearch** | Elasticsearch | 9200 | 9200 | 9201 | 9202 |
| | Kibana | 5601 | 5601 | 5602 | 5603 |
| **MongoDB** | MongoDB | 27017 | 27017 | 27018 | 27019 |
| | Mongo Express | 8081 | 8081 | 8082 | 8083 |
| **Monitoring** | Prometheus | 9090 | 9090 | 9091 | 9092 |
| | Grafana | 3000 | 3000 | 3001 | 3002 |
| **MSSQL** | SQL Server | 1433 | 1433 | 1434 | 1435 |
| | Adminer | 8080 | 8380 | 8381 | 8382 |
| **Keycloak** | Admin UI | 8080 | 8080 | 8180 | 8280 |
| **Seq** | Web UI + Ingestion | 80 | 5341 | 5342 | 5343 |
| **MailHog** | SMTP | 1025 | 1025 | 1026 | 1027 |
| | Web UI | 8025 | 8025 | 8026 | 8027 |
| **n8n** | Web UI | 5678 | 5678 | 5679 | 5680 |
## 🔧 Yapılandırma

Şablon: `{servis}/environments/{env}/.env.example` → `{servis}/environments/{env}/.env` olarak kopyalanır.

Toplam **30 dosya** (10 servis × 3 ortam) — hepsi `.gitignore` tarafından korunur.

Servisler: `postgres` · `redis` · `rabbitmq` · `elasticsearch` · `mongodb` · `monitoring` · `mssql` · `keycloak` · `seq` · `mailhog` · `n8n`

> ⚠️ Production ortamları için mutlaka güçlü şifreler kullanın!

## 📖 Detaylı Dokümantasyon

| Servis | Dokümantasyon | İçerik |
|--------|---------------|--------|
| 📘 PostgreSQL | [README-PostgreSQL.md](postgres/README-PostgreSQL.md) | pgAdmin kurulumu · Npgsql / EF Core · Backup/Restore · Security |
| 📕 Redis | [README-Redis.md](redis/README-Redis.md) | StackExchange.Redis · Cache senaryoları · AOF persistence |
| 📙 RabbitMQ | [README-RabbitMQ.md](rabbitmq/README-RabbitMQ.md) | RabbitMQ.Client · Exchange/Queue yönetimi · Best practices |
| 📗 Elasticsearch | [README-Elasticsearch.md](elasticsearch/README-Elasticsearch.md) | NEST / REST API · Query DSL · Kibana Dashboard |
| 🍃 MongoDB | [README-MongoDB.md](mongodb/README-MongoDB.md) | MongoDB.Driver · CRUD · Repository pattern |
| 📊 Monitoring | [README-Monitoring.md](monitoring/README-Monitoring.md) | Prometheus metrik toplama · Grafana dashboard |
| 🔴 MSSQL | [README-MSSQL.md](mssql/README-MSSQL.md) | EF Core / Microsoft.Data.SqlClient · Migration · Backup |
| 🔐 Keycloak | [README-Keycloak.md](keycloak/README-Keycloak.md) | JWT Bearer · OIDC · Blazor entegrasyonu · Admin API |
| 📋 Seq | [README-Seq.md](seq/README-Seq.md) | Serilog/NLog sink · FilterExpressions · Alert/Signal |
| 📧 MailHog | [README-MailHog.md](mailhog/README-MailHog.md) | MailKit servisi · DI entegrasyonu · Integration test |
| ⚙️ n8n | [README-n8n.md](n8n/README-n8n.md) | Workflow otomasyonu · Webhook entegrasyonu · .NET API bağlantısı |

## 💡 Kullanım Senaryoları

### Senaryo 1: Tek Servis ile Çalışma

```powershell
# Herhangi bir servisi başlat (postgres, redis, rabbitmq, mssql, keycloak, seq, mailhog…)
.\manage.ps1 start dev postgres

# Servis UI/API erişim örnekleri:
#   pgAdmin       → http://localhost:5050
#   RedisInsight  → http://localhost:8001
#   RabbitMQ UI   → http://localhost:15672
#   Keycloak      → http://localhost:8080/admin
#   Seq           → http://localhost:5341
#   MailHog       → http://localhost:8025

# İşin bitince durdur
.\manage.ps1 stop dev postgres
```

### Senaryo 2: Tüm Servisleri Birlikte Kullanma

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
# SQL Server: localhost:1433
# Adminer (MSSQL): http://localhost:8380
# Keycloak: http://localhost:8080/admin
# Seq: http://localhost:5341
# MailHog Web UI: http://localhost:8025
# MailHog SMTP: localhost:1025
# n8n: http://localhost:5678

# Durumu kontrol et
.\manage.ps1 status dev all

# Tümünü durdur
.\manage.ps1 stop dev all
```

### Senaryo 3: Elasticsearch API ile Çalışma

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

### Senaryo 4: Test Ortamında Çalışma

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

> Şablon: `.\manage.ps1 <komut> <env> <servis>`  
> `<env>`: `dev` · `test` · `prod` — `<servis>`: servis adı veya `all`

| Komut | Açıklama | Örnek |
|-------|----------|-------|
| `start` | Servisleri başlat | `.\manage.ps1 start dev postgres` |
| `stop` | Servisleri durdur | `.\manage.ps1 stop dev all` |
| `restart` | Yeniden başlat | `.\manage.ps1 restart test redis` |
| `logs` | Log çıktısını izle (`all` desteklenmez) | `.\manage.ps1 logs dev postgres` |
| `status` | Durum kontrolü | `.\manage.ps1 status dev all` |
| `pull` | Image'ları indir (zaten varsa atlar) | `.\manage.ps1 pull dev all` |
| `clean` ⚠️ | Durdur + volume sil | `.\manage.ps1 clean test postgres` |
| `purge` 💀 | Durdur + volume + image sil | `.\manage.ps1 purge dev postgres` |

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
# manage.ps1 pull komutu ile image'ları güncelle
# Lokalde zaten mevcut olan image'lar atlanır (= Already exists)
.\manage.ps1 pull dev all

# Tek servis için
.\manage.ps1 pull dev postgres

# Güncellemeden sonra servisi yeniden başlatın
.\manage.ps1 restart dev postgres
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
**Versiyon**: 1.2.0

Herhangi bir sorunuz için ilgili servis dokümantasyonuna bakın! 🚀
