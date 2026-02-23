# Business Requirements Document (BRD)
## Docker Service Stack — Multi-Environment Management Platform

| Alan | Değer |
|------|-------|
| **Belge Adı** | Docker Service Stack BRD |
| **Versiyon** | 1.0.0 |
| **Tarih** | 2026-02-23 |
| **Referans Kaynak** | README.md, manage.ps1, CHANGELOG.md, tüm docker-compose.yml dosyaları |
| **Durum** | Taslak |

---

## 1. Proje Özeti

**Docker Service Stack**, modern yazılım projelerinde yaygın kullanılan altyapı servislerini tek bir yönetilebilir yapıya kavuşturan, multi-environment destekli bir Docker Compose tabanlı yönetim platformudur.

### 1.1 Amaç

- Geliştirme, test ve üretim ortamlarında aynı servisler için tutarlı ve izole Docker yapılandırmaları sunmak
- Tek bir yönetim arayüzü (`manage.ps1`) üzerinden tüm servisleri kontrol etmek
- DevOps best practice standartlarını tüm servisler genelinde zorunlu kılmak
- Yeni servis ekleme ve mevcut servisleri genişletme için net bir şablon sağlamak

### 1.2 Kapsam

10 bağımsız altyapı servisi, 3 ortam (dev / test / prod) ve bu yapıyı yöneten PowerShell tabanlı bir yönetim betiği kapsamdadır.

---

## 2. Servis Kataloğu ve Gereksinimler

Her servis için aşağıdaki standart gereksinimler geçerlidir. Ayrıca servis özelinde ek gereksinimler belirtilmiştir.

### 2.1 Ortak Standartlar (Tüm Servisler)

| Gereksinim | Zorunluluk | Açıklama |
|------------|:----------:|----------|
| `docker-compose.yml` her ortam için mevcut | ZORUNLU | `environments/dev/`, `environments/test/`, `environments/prod/` |
| `.env.example` dosyası | ZORUNLU | Tüm ortamlar için şablon, Git'e dahil |
| `.env` dosyası | ZORUNLU (çalışma zamanı) | `.env.example` kopyasından türetilir, `.gitignore`'da |
| `restart` politikası — dev/test | ZORUNLU | `unless-stopped` |
| `restart` politikası — prod | ZORUNLU | `always` |
| `healthcheck` tanımı | ZORUNLU | `interval`, `timeout`, `retries`, `start_period` içermeli |
| Named volume | ZORUNLU | `{servis}_{ortam}_{amaç}` adlandırma şeması |
| Named network | ZORUNLU | `{servis}_{ortam}_network` adlandırma şeması |
| Network driver | ZORUNLU | `bridge` |
| Volume driver | ZORUNLU | `local` |
| Container adı | ZORUNLU | `{servis}_{ortam}` formatı (örn. `postgres_dev`) |
| Port çakışması yok | ZORUNLU | Her servis × ortam kombinasyonu benzersiz host portu kullanır |
| Ortam değişkenleri `.env`'den okunur | ZORUNLU | Şifreler, portlar vb. doğrudan compose dosyasına yazılmaz |
| Servis-level README | ZORUNLU | `{servis}/README-{Servis}.md` dosyası mevcut olmalı |

#### Healthcheck Standart Değerleri

```
interval:     10s   (ağır başlangıçlı servisler 15s–30s olabilir)
timeout:       5s   (ağır servisler 10s olabilir)
retries:        5
start_period:  Servise göre: 10s / 20s / 30s / 60s
```

---

### 2.2 PostgreSQL

| Alan | Değer |
|------|-------|
| **Image** | `postgres:16-alpine` |
| **UI Bileşeni** | pgAdmin 4 (`dpage/pgadmin4:latest`) |
| **Kullanım Amacı** | İlişkisel veritabanı |

#### Zorunlu Ortam Değişkenleri

| Değişken | Açıklama |
|----------|----------|
| `POSTGRES_USER` | Veritabanı kullanıcı adı |
| `POSTGRES_PASSWORD` | Veritabanı şifresi |
| `POSTGRES_DB` | Varsayılan veritabanı adı |
| `POSTGRES_PORT` | Host port (dev: 5432, test: 5433, prod: 5434) |
| `PGADMIN_EMAIL` | pgAdmin giriş e-postası |
| `PGADMIN_PASSWORD` | pgAdmin giriş şifresi |
| `PGADMIN_PORT` | pgAdmin host port (dev: 5050, test: 5051, prod: 5052) |

#### Yapılandırma Gereksinimleri

- `PGDATA` `/var/lib/postgresql/data/pgdata` olarak sabitlenmiş olmalı
- pgAdmin, `depends_on: postgres: condition: service_healthy` ile tanımlanmalı
- `PGADMIN_CONFIG_SERVER_MODE: 'False'` — tek kullanıcı modu
- `PGADMIN_CONFIG_MASTER_PASSWORD_REQUIRED: 'False'`

#### Healthcheck

```yaml
test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
start_period: 10s
```

#### Port Dağılımı

| Bileşen | Dev | Test | Prod |
|---------|-----|------|------|
| PostgreSQL | 5432 | 5433 | 5434 |
| pgAdmin | 5050 | 5051 | 5052 |

---

### 2.3 Redis

| Alan | Değer |
|------|-------|
| **Image** | `redis:7-alpine` |
| **UI Bileşeni** | RedisInsight (`redis/redisinsight:latest`) |
| **Kullanım Amacı** | Cache, session yönetimi, pub/sub |

#### Zorunlu Ortam Değişkenleri

| Değişken | Açıklama |
|----------|----------|
| `REDIS_PASSWORD` | Sunucu şifresi |
| `REDIS_PORT` | Host port (dev: 6379, test: 6380, prod: 6381) |
| `REDISINSIGHT_PORT` | RedisInsight host port (dev: 8001, test: 8002, prod: 8003) |

#### Yapılandırma Gereksinimleri

- `command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}` — AOF persistence zorunlu
- RedisInsight, `depends_on: redis: condition: service_healthy` ile tanımlanmalı

#### Healthcheck

```yaml
test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
start_period: 10s
```

#### Port Dağılımı

| Bileşen | Dev | Test | Prod |
|---------|-----|------|------|
| Redis | 6379 | 6380 | 6381 |
| RedisInsight | 8001 | 8002 | 8003 |

---

### 2.4 RabbitMQ

| Alan | Değer |
|------|-------|
| **Image** | `rabbitmq:3-management-alpine` |
| **UI Bileşeni** | Management UI (image içinde dahili) |
| **Kullanım Amacı** | Message queue, event bus |

#### Zorunlu Ortam Değişkenleri

| Değişken | Açıklama |
|----------|----------|
| `RABBITMQ_USER` | Admin kullanıcı adı |
| `RABBITMQ_PASSWORD` | Admin şifresi |
| `RABBITMQ_PORT` | AMQP host port (dev: 5672, test: 5673, prod: 5674) |
| `RABBITMQ_MANAGEMENT_PORT` | Management UI host port (dev: 15672, test: 15673, prod: 15674) |

#### Yapılandırma Gereksinimleri

- `rabbitmq_data` ve `rabbitmq_logs` olmak üzere iki ayrı named volume
- Management plugin etkinleştirmek için `rabbitmq:3-management-alpine` image kullanılmalı

#### Healthcheck

```yaml
test: ["CMD", "rabbitmq-diagnostics", "-q", "ping"]
start_period: 30s
```

#### Port Dağılımı

| Bileşen | Dev | Test | Prod |
|---------|-----|------|------|
| AMQP | 5672 | 5673 | 5674 |
| Management UI | 15672 | 15673 | 15674 |

---

### 2.5 Elasticsearch

| Alan | Değer |
|------|-------|
| **Image** | `docker.elastic.co/elasticsearch/elasticsearch:8.12.0` |
| **UI Bileşeni** | Kibana (`docker.elastic.co/kibana/kibana:8.12.0`) |
| **Yardımcı Servis** | `setup` (tek seferlik Kibana şifre kurulumu) |
| **Kullanım Amacı** | Full-text arama, log analiz, analytics |

#### Zorunlu Ortam Değişkenleri

| Değişken | Açıklama |
|----------|----------|
| `ELASTIC_PASSWORD` | `elastic` süper kullanıcı şifresi |
| `KIBANA_PASSWORD` | `kibana_system` kullanıcı şifresi |
| `ELASTIC_PORT` | Elasticsearch host port (dev: 9200, test: 9201, prod: 9202) |
| `KIBANA_PORT` | Kibana host port (dev: 5601, test: 5602, prod: 5603) |

#### Yapılandırma Gereksinimleri

- `discovery.type: single-node` — tek düğüm modu
- `xpack.security.enabled: true` — güvenlik aktif
- `xpack.security.enrollment.enabled: false`
- `ES_JAVA_OPTS: -Xms512m -Xmx512m` — JVM heap limiti
- `ulimits.memlock: soft: -1, hard: -1` — memory lock
- `setup` servisi `restart: "no"` ile tanımlanmalı; Kibana buna `condition: service_completed_successfully` beklemeli
- Node ve cluster adı ortama göre unique olmalı: `elasticsearch-{ortam}`, `es-docker-cluster-{ortam}`

#### Healthcheck

```yaml
# Elasticsearch
test: ["CMD-SHELL", "curl -s http://localhost:9200 >/dev/null || exit 1"]
start_period: 60s

# Kibana
test: ["CMD-SHELL", "curl -s http://localhost:5601/api/status >/dev/null || exit 1"]
start_period: 60s
```

#### Port Dağılımı

| Bileşen | Dev | Test | Prod |
|---------|-----|------|------|
| Elasticsearch | 9200 | 9201 | 9202 |
| Kibana | 5601 | 5602 | 5603 |

---

### 2.6 MongoDB

| Alan | Değer |
|------|-------|
| **Image** | `mongo:7-jammy` |
| **UI Bileşeni** | Mongo Express (`mongo-express:latest`) |
| **Kullanım Amacı** | Doküman veritabanı |

#### Zorunlu Ortam Değişkenleri

| Değişken | Açıklama |
|----------|----------|
| `MONGO_INITDB_ROOT_USERNAME` | Root kullanıcı adı |
| `MONGO_INITDB_ROOT_PASSWORD` | Root şifresi |
| `MONGO_PORT` | MongoDB host port (dev: 27017, test: 27018, prod: 27019) |
| `MONGOEXPRESS_LOGIN` | Mongo Express web arayüz kullanıcı adı |
| `MONGOEXPRESS_PASSWORD` | Mongo Express web arayüz şifresi |
| `MONGOEXPRESS_PORT` | Mongo Express host port (dev: 8081, test: 8082, prod: 8083) |

#### Yapılandırma Gereksinimleri

- `mongodb_data` ve `mongodb_config` olmak üzere iki ayrı named volume
- Mongo Express, `depends_on: mongodb: condition: service_healthy` ile tanımlanmalı

#### Healthcheck

```yaml
test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
start_period: 20s
```

#### Port Dağılımı

| Bileşen | Dev | Test | Prod |
|---------|-----|------|------|
| MongoDB | 27017 | 27018 | 27019 |
| Mongo Express | 8081 | 8082 | 8083 |

---

### 2.7 Monitoring (Prometheus + Grafana)

| Alan | Değer |
|------|-------|
| **Image (Prometheus)** | `prom/prometheus:latest` |
| **Image (Grafana)** | `grafana/grafana:latest` |
| **Kullanım Amacı** | Metrik toplama ve görselleştirme |
| **Ek Dosya** | `prometheus.yml` — her ortam için ayrı scrape config |

#### Zorunlu Ortam Değişkenleri

| Değişken | Açıklama |
|----------|----------|
| `GRAFANA_ADMIN_USER` | Grafana admin kullanıcı adı |
| `GRAFANA_ADMIN_PASSWORD` | Grafana admin şifresi |
| `PROMETHEUS_PORT` | Prometheus host port (dev: 9090, test: 9091, prod: 9092) |
| `GRAFANA_PORT` | Grafana host port (dev: 3000, test: 3001, prod: 3002) |

#### Yapılandırma Gereksinimleri

- `prometheus.yml` dosyası `./prometheus.yml:/etc/prometheus/prometheus.yml` bind mount ile servis edilmeli
- `GF_SERVER_ROOT_URL` Grafana port'una göre ayarlanmalı
- Grafana, `depends_on: prometheus: condition: service_healthy` ile tanımlanmalı
- `prometheus.yml` içinde `external_labels.environment` her ortamda farklı olmalı

#### prometheus.yml Zorunlu Alanlar

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    monitor: 'docker-{ortam}-monitor'
    environment: '{ortam}'
```

#### Healthcheck

```yaml
# Prometheus
test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:9090/-/healthy"]
start_period: 10s

# Grafana
test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3000/api/health"]
start_period: 10s
```

#### Port Dağılımı

| Bileşen | Dev | Test | Prod |
|---------|-----|------|------|
| Prometheus | 9090 | 9091 | 9092 |
| Grafana | 3000 | 3001 | 3002 |

---

### 2.8 MSSQL (SQL Server)

| Alan | Değer |
|------|-------|
| **Image** | `mcr.microsoft.com/mssql/server:2022-latest` |
| **UI Bileşeni** | Adminer (`adminer:latest`) |
| **Kullanım Amacı** | .NET native ilişkisel veritabanı |

#### Zorunlu Ortam Değişkenleri

| Değişken | Açıklama |
|----------|----------|
| `MSSQL_SA_PASSWORD` | SA (System Administrator) şifresi |
| `MSSQL_PID` | SQL Server sürüm lisansı (dev/test: `Developer`, prod: `Standard`/`Enterprise`) |
| `MSSQL_PORT` | SQL Server host port (dev: 1433, test: 1434, prod: 1435) |
| `ADMINER_PORT` | Adminer host port (dev: 8380, test: 8381, prod: 8382) |

#### Yapılandırma Gereksinimleri

- `ACCEPT_EULA: "Y"` zorunlu
- `MSSQL_SA_PASSWORD` Microsoft güvenlik gereksinimlerini karşılamalı (büyük harf, küçük harf, rakam, özel karakter; min 8 karakter)
- Adminer, `depends_on: mssql: condition: service_healthy` ile tanımlanmalı

#### Healthcheck

```yaml
test: ["CMD-SHELL", "/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P '${MSSQL_SA_PASSWORD}' -Q 'SELECT 1' -No || exit 1"]
interval: 15s
timeout: 10s
start_period: 30s
```

#### Port Dağılımı

| Bileşen | Dev | Test | Prod |
|---------|-----|------|------|
| SQL Server | 1433 | 1434 | 1435 |
| Adminer | 8380 | 8381 | 8382 |

---

### 2.9 Keycloak

| Alan | Değer |
|------|-------|
| **Image** | `quay.io/keycloak/keycloak:26.0` |
| **Veritabanı** | PostgreSQL sidecar (`postgres:16-alpine`) |
| **Kullanım Amacı** | OAuth2 / OIDC identity server |

#### Zorunlu Ortam Değişkenleri

| Değişken | Açıklama |
|----------|----------|
| `KC_DB_USER` | Keycloak veritabanı kullanıcı adı |
| `KC_DB_PASSWORD` | Keycloak veritabanı şifresi |
| `KC_DB_NAME` | Keycloak veritabanı adı |
| `KEYCLOAK_ADMIN` | Admin kullanıcı adı |
| `KEYCLOAK_ADMIN_PASSWORD` | Admin şifresi |
| `KEYCLOAK_PORT` | Keycloak host port (dev: 8080, test: 8180, prod: 8280) |

#### Yapılandırma Gereksinimleri

- Dev ortamında `command: start-dev` kullanılmalı
- `KC_DB: postgres` — veritabanı tipi belirtilmeli
- `KC_DB_URL: jdbc:postgresql://keycloak_db:5432/${KC_DB_NAME}`
- `KC_HTTP_PORT: 8080` ve `KC_HTTP_ENABLED: "true"` dev/test için zorunlu
- `KC_HEALTH_ENABLED: "true"` — healthcheck endpoint aktif
- Keycloak kendi veritabanı için `keycloak_db` adında ayrı bir PostgreSQL container'ı kullanır
- Keycloak container'ı `depends_on: keycloak_db: condition: service_healthy` ile tanımlanmalı

#### Healthcheck

```yaml
# Keycloak
test: ["CMD-SHELL", "curl -sf http://localhost:8080/health/ready || exit 1"]
interval: 30s
timeout: 10s
start_period: 60s

# keycloak_db (PostgreSQL sidecar)
test: ["CMD-SHELL", "pg_isready -U ${KC_DB_USER} -d ${KC_DB_NAME}"]
start_period: 10s
```

#### Port Dağılımı

| Bileşen | Dev | Test | Prod |
|---------|-----|------|------|
| Keycloak Admin UI | 8080 | 8180 | 8280 |

---

### 2.10 Seq

| Alan | Değer |
|------|-------|
| **Image** | `datalust/seq:latest` |
| **UI Bileşeni** | Dahili Web UI (ayrı container yok) |
| **Kullanım Amacı** | .NET uygulamaları için structured log yönetimi |

#### Zorunlu Ortam Değişkenleri

| Değişken | Açıklama |
|----------|----------|
| `SEQ_ADMIN_PASSWORD` | Admin şifresi (ilk kurulum) |
| `SEQ_PORT` | Web UI + log ingest host port (dev: 5341, test: 5342, prod: 5343) |

#### Yapılandırma Gereksinimleri

- `ACCEPT_EULA: "Y"` zorunlu
- `SEQ_FIRSTRUN_ADMINPASSWORD` değişkeni container ilk başlatıldığında admin şifresini ayarlar
- Container port `80` → host port `SEQ_PORT` olarak yönlendirilmeli

#### Healthcheck

```yaml
test: ["CMD-SHELL", "curl -sf http://localhost:80/ || exit 1"]
start_period: 20s
```

#### Port Dağılımı

| Bileşen | Dev | Test | Prod |
|---------|-----|------|------|
| Seq Web UI + Ingest | 5341 | 5342 | 5343 |

---

### 2.11 MailHog

| Alan | Değer |
|------|-------|
| **Image** | `mailhog/mailhog:latest` |
| **UI Bileşeni** | Dahili Web UI (ayrı container yok) |
| **Kullanım Amacı** | Geliştirme/test ortamı için sahte SMTP sunucusu |
| **Healthcheck** | — (gerektirmez; stateless, hızlı başlayan servis) |

#### Zorunlu Ortam Değişkenleri

| Değişken | Açıklama |
|----------|----------|
| `MAILHOG_SMTP_PORT` | SMTP host port (dev: 1025, test: 1026, prod: 1027) |
| `MAILHOG_WEB_PORT` | Web UI host port (dev: 8025, test: 8026, prod: 8027) |

#### Yapılandırma Gereksinimleri

- Named volume tanımlı **olmamalı** — MailHog persistent depolama gerektirmez (`volumes: {}`)
- Yalnızca dev ve test ortamlarında anlamlı kullanıma sahiptir; prod için uyarı notu README'de bulunmalı

#### Port Dağılımı

| Bileşen | Dev | Test | Prod |
|---------|-----|------|------|
| SMTP | 1025 | 1026 | 1027 |
| Web UI | 8025 | 8026 | 8027 |
---

### 2.12 n8n

| Alan | Değer |
|------|-------|
| **Image** | `n8nio/n8n:latest` |
| **UI Bileşeni** | Dahili Web UI (ayrı container yok) |
| **Kullanım Amacı** | Workflow otomasyonu ve servisler arası entegrasyon |

#### Zorunlu Ortam Değişkenleri

| Değişken | Açıklama |
|----------|----------|
| `N8N_PORT` | Web UI host port (dev: 5678, test: 5679, prod: 5680) |
| `N8N_HOST` | Kullanıcıya gösterilen host adı |
| `N8N_PROTOCOL` | `http` veya `https` |
| `WEBHOOK_URL` | Dışardan erişilebilir webhook taban URL'si |
| `N8N_BASIC_AUTH_ACTIVE` | Web UI kimlik doğrulama açma/kapama |
| `N8N_BASIC_AUTH_USER` | Web UI kullanıcı adı |
| `N8N_BASIC_AUTH_PASSWORD` | Web UI şifresi |
| `N8N_ENCRYPTION_KEY` | Kimlik bilgisi şifreleme anahtarı |
| `GENERIC_TIMEZONE` | Cron zamanlayıcı saat dilimi (varsayılan: `Europe/Istanbul`) |

#### Yapılandırma Gereksinimleri

- `DB_TYPE: sqlite` — tüm ortamlarda SQLite (gelişmiş kurulum için PostgreSQL sidecar eklenebilir)
- `N8N_ENCRYPTION_KEY` ilk çalıştırmadan sonra **asla değiştirilmemeli** — değiştirilirse kayıtlı kimlik bilgileri geçersiz olur
- Container iç port sabit `5678`; host port `.env` üzerinden `N8N_PORT` değişkeniyle yönetilir
- `/home/node/.n8n` volume ile kalıcı depolamaya bağlanmalı
- Prod ortamında `N8N_PROTOCOL=https` ve gerçek domain ile `WEBHOOK_URL` ayarlanmalı

#### Healthcheck

```yaml
test: ["CMD-SHELL", "wget --quiet --tries=1 --spider http://localhost:5678/healthz || exit 1"]
start_period: 30s
```

#### Port Dağılımı

| Bileşen | Dev | Test | Prod |
|---------|-----|------|------|
| n8n Web UI | 5678 | 5679 | 5680 |
---

## 3. Klasör Yapısı Standardı

Her servis için aşağıdaki dosya yapısı **zorunludur**:

```
{servis}/
├── README-{ServisAdı}.md          ← Servis dokümantasyonu (ZORUNLU)
└── environments/
    ├── dev/
    │   ├── docker-compose.yml     ← ZORUNLU
    │   └── .env.example           ← ZORUNLU (Git'e dahil)
    │   └── .env                   ← Çalışma zamanı (.gitignore'da)
    │   └── prometheus.yml         ← YALNIZCA monitoring servisi için
    ├── test/
    │   ├── docker-compose.yml
    │   └── .env.example
    │   └── .env
    │   └── prometheus.yml         ← YALNIZCA monitoring servisi için
    └── prod/
        ├── docker-compose.yml
        └── .env.example
        └── .env
        └── prometheus.yml         ← YALNIZCA monitoring servisi için
```

### Adlandırma Kuralları

| Varlık | Format | Örnek |
|--------|--------|-------|
| Container adı | `{servis}_{ortam}` | `postgres_dev`, `redis_prod` |
| Volume adı | `{servis}_{ortam}_{amaç}` | `postgres_dev_data`, `rabbitmq_prod_logs` |
| Network adı | `{servis}_{ortam}_network` | `redis_dev_network`, `mongodb_test_network` |
| Compose project | `{servis}_{ortam}` | `postgres_dev`, `keycloak_prod` |

---

## 4. Port Dağılımı — Tam Tablo

> Hiçbir servis × ortam kombinasyonu aynı host portunu paylaşamaz.

| Servis | Bileşen | Dev | Test | Prod |
|--------|---------|-----|------|------|
| **PostgreSQL** | PostgreSQL | 5432 | 5433 | 5434 |
| | pgAdmin | 5050 | 5051 | 5052 |
| **Redis** | Redis | 6379 | 6380 | 6381 |
| | RedisInsight | 8001 | 8002 | 8003 |
| **RabbitMQ** | AMQP | 5672 | 5673 | 5674 |
| | Management UI | 15672 | 15673 | 15674 |
| **Elasticsearch** | Elasticsearch | 9200 | 9201 | 9202 |
| | Kibana | 5601 | 5602 | 5603 |
| **MongoDB** | MongoDB | 27017 | 27018 | 27019 |
| | Mongo Express | 8081 | 8082 | 8083 |
| **Monitoring** | Prometheus | 9090 | 9091 | 9092 |
| | Grafana | 3000 | 3001 | 3002 |
| **MSSQL** | SQL Server | 1433 | 1434 | 1435 |
| | Adminer | 8380 | 8381 | 8382 |
| **Keycloak** | Admin UI | 8080 | 8180 | 8280 |
| **Seq** | Web UI + Ingest | 5341 | 5342 | 5343 |
| **MailHog** | SMTP | 1025 | 1026 | 1027 |
| | Web UI | 8025 | 8026 | 8027 |
| **n8n** | Web UI | 5678 | 5679 | 5680 |

---

## 5. manage.ps1 — Yönetim Betiği Gereksinimleri

### 5.1 Parametre Şeması

```powershell
.\manage.ps1 <action> <environment> <service>
```

| Parametre | Zorunlu | Geçerli Değerler |
|-----------|:-------:|-----------------|
| `action` | EVET | `start`, `stop`, `restart`, `logs`, `status`, `clean`, `purge`, `pull` |
| `environment` | EVET | `dev`, `test`, `prod` |
| `service` | EVET | `postgres`, `redis`, `rabbitmq`, `elasticsearch`, `mongodb`, `monitoring`, `mssql`, `keycloak`, `seq`, `mailhog`, `n8n`, `all` |

### 5.2 Komut Davranış Gereksinimleri

| Komut | Davranış | Açıklama |
|-------|----------|----------|
| `start` | Container'ları başlatır | Zaten çalışıyorsa `AlreadyRunning` döner; image eksikse `MissingImage` uyarısı verir |
| `stop` | Container'ları durdurur | Zaten durdurulmuşsa `AlreadyStopped` döner |
| `restart` | Durdur + başlat | `stop` + 2s bekleme + `start` sırası |
| `logs` | Canlı log akışı | `all` desteği yok; `docker-compose logs -f` |
| `status` | Container durumu | Tüm ortamlar için `docker-compose ps` çıktısı |
| `pull` | Image indirme | Tüm image'lar lokalde mevcutsa atlar (`AlreadyPulled`); akıllı skip |
| `clean` | Durdur + volume sil | Kullanıcı onayı ister (`Y/N`); `docker-compose down -v` |
| `purge` | Durdur + volume + image sil | Kullanıcı onayı ister; `down -v` + `image rm -f` |

### 5.3 Paralel İşlem Gereksinimleri

`all` servisi ile çalıştırıldığında `start`, `stop`, `restart` ve `pull` komutları **paralel** çalışmalıdır.

- `clean` ve `purge` komutları kullanıcı onayı gerektirdiğinden **sıralı** çalışır
- `logs` ve `status` komutları `all` için özel işleme sahiptir

### 5.4 Durum Çıktısı (Result Table)

İşlem sonunda tablo çıktısı şu sütunları içermelidir:

| Sütun | Renk Kuralı |
|-------|------------|
| Service | — |
| Environment | — |
| Status | Yeşil: başarı; Cyan: zaten yapılmış; Sarı: iptal; Kırmızı: hata/bulunamadı |

#### Durum Kodları ve Renkleri

| Status | Renk | Durum |
|--------|------|-------|
| `Started`, `Stopped`, `Restarted`, `Cleaned`, `Purged`, `Pulled` | Yeşil | Başarı |
| `AlreadyRunning`, `AlreadyStopped`, `AlreadyPulled` | Cyan | Zaten yapılmış |
| `Cancelled` | Sarı | Kullanıcı iptal etti |
| `NotFound`, `MissingImage`, `Failed` | Kırmızı | Hata |

### 5.5 Docker Daemon Kontrolü

Script başlangıcında `docker info` ile daemon erişilebilirliği kontrol edilmeli. Erişilemiyorsa:
1. Kullanıcıya Docker Desktop'ı başlatmak isteyip istemediği sorulur
2. Onay alınırsa `$env:ProgramFiles\Docker\Docker\Docker Desktop.exe` başlatılır
3. 120 saniye timeout ile hazır olması beklenir

### 5.6 Argüman Doğrulama

- Geçersiz argüman girildiğinde prefix tabanlı "did you mean?" önerisi sunulmalı
- Tüm hatalar tek seferde toplanıp gösterilmeli (fail-fast birden fazla hata için)
- Kullanım örneği her hata mesajının altında gösterilmeli

---

## 6. Güvenlik Gereksinimleri

### 6.1 Zorunlu Güvenlik Kuralları

| Kural | Kapsam |
|-------|--------|
| `.env` dosyaları `.gitignore`'a eklenmiş olmalı | Tüm ortamlar |
| Şifreler `.env.example` içinde yer tutucu değerler olmalı | Tüm servisler |
| `SECURITY-WARNING.txt` dosyası repo kökünde mevcut olmalı | Proje geneli |
| Production `.env.example` güçlü şifre zorunluluğunu açıkça belirtmeli | Prod ortamı |

### 6.2 Production Özel Güvenlik Gereksinimleri

- Tüm şifreler minimum 20 karakter, büyük/küçük harf + rakam + özel karakter içermeli
- pgAdmin `Server Mode: False` — production'da kısıtlanmalı
- Elasticsearch'te `xpack.security.enabled: true` zorunlu
- Keycloak prod ortamında `start-dev` yerine `start` komutuyla başlamalı ve SSL konfigürasyonu eklenebilmeli
- MSSQL `MSSQL_PID` prod'da `Express` veya `Developer` yerine `Standard`/`Enterprise` olmalı

---

## 7. Docker Compose Dosyası Standartları

### 7.1 Genel Yapı Sırası (ZORUNLU)

Her `docker-compose.yml` dosyasında servis tanımları aşağıdaki sırayla yazılmalıdır:

```yaml
services:
  {servis-adı}:
    image:            # 1. Image
    container_name:   # 2. Container adı
    restart:          # 3. Restart politikası
    environment:      # 4. Ortam değişkenleri
    ports:            # 5. Port yönlendirmeleri
    volumes:          # 6. Volume bağlantıları
    networks:         # 7. Network bağlantıları
    depends_on:       # 8. Bağımlılıklar (varsa)
    healthcheck:      # 9. Sağlık kontrolü
    ulimits:          # 10. Sistem limitleri (yalnızca Elasticsearch)
    command:          # 11. Komut geçersiz kılma (yalnızca gerekirse)

volumes:
  {volume-adı}:
    name: {volume-tam-adı}
    driver: local

networks:
  {network-adı}:
    name: {network-tam-adı}
    driver: bridge
```

### 7.2 Healthcheck Zorunluluk Tablosu

| Servis | Healthcheck Zorunlu | Notlar |
|--------|:-------------------:|--------|
| postgres | EVET | `pg_isready` |
| redis | EVET | `redis-cli ping` |
| rabbitmq | EVET | `rabbitmq-diagnostics ping` |
| elasticsearch | EVET | HTTP 9200 curl |
| kibana | EVET | HTTP 5601 curl |
| mongodb | EVET | `mongosh ping` |
| prometheus | EVET | HTTP `/-/healthy` |
| grafana | EVET | HTTP `/api/health` |
| mssql | EVET | `sqlcmd SELECT 1` |
| keycloak | EVET | HTTP `/health/ready` |
| keycloak_db | EVET | `pg_isready` (sidecar) |
| seq | EVET | HTTP `/` curl |
| mailhog | HAYIR | Stateless, gerektirmez |
| n8n | EVET | HTTP `/healthz` wget |
| adminer | HAYIR | UI yardımcısı |
| pgadmin | HAYIR | UI yardımcısı |
| redisinsight | HAYIR | UI yardımcısı |
| mongo-express | HAYIR | UI yardımcısı |

---

## 8. Servis Bağımlılık Matrisi

UI/yardımcı container'lar ana servise `condition: service_healthy` ile bağımlı olmalıdır.

| UI/Yardımcı Container | Bağımlı Olduğu Servis | Condition |
|-----------------------|----------------------|-----------|
| pgAdmin | postgres | `service_healthy` |
| RedisInsight | redis | `service_healthy` |
| Kibana | elasticsearch + setup | `service_healthy` + `service_completed_successfully` |
| Mongo Express | mongodb | `service_healthy` |
| Grafana | prometheus | `service_healthy` |
| Adminer | mssql | `service_healthy` |
| keycloak | keycloak_db | `service_healthy` |

---

## 9. Docker Image Versiyonlama Politikası

| Servis | Image Tag Politikası | Gerekçe |
|--------|---------------------|---------|
| PostgreSQL | Sabit major: `postgres:16-alpine` | Breaking changes kontrolü |
| Redis | Sabit major: `redis:7-alpine` | Breaking changes kontrolü |
| RabbitMQ | Sabit major: `rabbitmq:3-management-alpine` | Protocol uyumluluğu |
| Elasticsearch | Sabit patch: `8.12.0` | Kibana ile versiyon uyumu zorunlu |
| Kibana | Sabit patch: `8.12.0` | Elasticsearch ile aynı versiyon |
| MongoDB | Sabit major-distro: `mongo:7-jammy` | Breaking changes kontrolü |
| Prometheus | `latest` | Geriye dönük uyumlu güncelleme |
| Grafana | `latest` | Geriye dönük uyumlu güncelleme |
| MSSQL | `mcr.microsoft.com/mssql/server:2022-latest` | Yıllık major sürüm |
| Keycloak | Sabit major-minor: `26.0` | API uyumluluğu |
| Seq | `latest` | Geriye dönük uyumlu güncelleme |
| MailHog | `latest` | Stabil proje, güncelleme düşük risk |
| n8n | `latest` | Hızlı gelişen ürün; major sürüm pin’lemek tercih edilebilir |
| pgAdmin | `latest` | UI bileşeni, kritik değil |
| RedisInsight | `latest` | UI bileşeni, kritik değil |
| Mongo Express | `latest` | UI bileşeni, kritik değil |
| Adminer | `latest` | UI bileşeni, kritik değil |

> **Elasticsearch ↔ Kibana**: Her ikisi de **aynı patch versiyonunda** olmalıdır.

---

## 10. Yeni Servis Ekleme Kontrol Listesi

Platforma yeni bir servis eklenmek istendiğinde aşağıdaki adımlar sırasıyla tamamlanmalıdır:

- [ ] `{servis}/environments/dev/docker-compose.yml` oluşturuldu
- [ ] `{servis}/environments/test/docker-compose.yml` oluşturuldu
- [ ] `{servis}/environments/prod/docker-compose.yml` oluşturuldu
- [ ] Her ortam için `.env.example` oluşturuldu
- [ ] Adlandırma kuralları uygulandı (container, volume, network)
- [ ] Port çakışması olmadığı doğrulandı
- [ ] Tüm ana servislere healthcheck eklendi
- [ ] UI/yardımcı container'lar `service_healthy` bağımlılığıyla tanımlandı
- [ ] `restart: unless-stopped` (dev/test) ve `restart: always` (prod) ayarlandı
- [ ] `{servis}/README-{Servis}.md` oluşturuldu
- [ ] `manage.ps1` içindeki `$services` hash tablosuna servis eklendi
- [ ] `manage.ps1` içindeki `$validServices`, tüm `all` listeleri ve `servicesToProcess` güncellendi
- [ ] Ana `README.md` port tablosu ve servis kataloğu güncellendi
- [ ] `CHANGELOG.md` güncellendi

---

## 11. Ortamlar Arası Fark Matrisi

| Konfigürasyon | Dev | Test | Prod |
|---------------|-----|------|------|
| `restart` politikası | `unless-stopped` | `unless-stopped` | `always` |
| Port aralığı | Temel port | Temel port + 1 | Temel port + 2 |
| Container adı suffix | `_dev` | `_test` | `_prod` |
| Volume/network adı suffix | `_dev_*` | `_test_*` | `_prod_*` |
| Şifre güvenlik seviyesi | Basit/örnek | Basit/örnek | Güçlü ve unique |
| Elasticsearch JVM heap | 512m/512m | 512m/512m | Ortama uygun artırılmalı |
| Keycloak start modu | `start-dev` | `start-dev` | `start` (production mode) |
| MSSQL PID | `Developer` | `Developer` | `Standard`/`Enterprise` |

---

## 12. Sürüm ve Değişiklik Yönetimi

- Proje [Semantic Versioning](https://semver.org/) (SemVer) kullanır: `MAJOR.MINOR.PATCH`
- Tüm değişiklikler `CHANGELOG.md`'de [Keep a Changelog](https://keepachangelog.com/) formatında belgelenir
- `BREAKING CHANGE` içeren güncellemeler MAJOR versiyonu artırır
- Yeni servis ekleme MINOR versiyonu artırır
- Bug fix ve davranış düzeltmeleri PATCH versiyonu artırır

| Mevcut Versiyon | Tarih |
|-----------------|-------|
| 1.2.0 | 2026-02-21 |

---

## Ekler

### Ek A — Tam Port Referansı (Numerik Sıra)

| Port | Servis | Ortam | Tür |
|------|--------|-------|-----|
| 1025 | MailHog | dev | SMTP |
| 1026 | MailHog | test | SMTP |
| 1027 | MailHog | prod | SMTP |
| 1433 | MSSQL | dev | SQL |
| 1434 | MSSQL | test | SQL |
| 1435 | MSSQL | prod | SQL |
| 3000 | Grafana | dev | HTTP |
| 3001 | Grafana | test | HTTP |
| 3002 | Grafana | prod | HTTP |
| 5050 | pgAdmin | dev | HTTP |
| 5051 | pgAdmin | test | HTTP |
| 5052 | pgAdmin | prod | HTTP |
| 5341 | Seq | dev | HTTP |
| 5342 | Seq | test | HTTP |
| 5343 | Seq | prod | HTTP |
| 5432 | PostgreSQL | dev | TCP |
| 5433 | PostgreSQL | test | TCP |
| 5434 | PostgreSQL | prod | TCP |
| 5601 | Kibana | dev | HTTP |
| 5602 | Kibana | test | HTTP |
| 5603 | Kibana | prod | HTTP |
| 5678 | n8n | dev | HTTP |
| 5679 | n8n | test | HTTP |
| 5680 | n8n | prod | HTTP |
| 5672 | RabbitMQ AMQP | dev | AMQP |
| 5673 | RabbitMQ AMQP | test | AMQP |
| 5674 | RabbitMQ AMQP | prod | AMQP |
| 6379 | Redis | dev | TCP |
| 6380 | Redis | test | TCP |
| 6381 | Redis | prod | TCP |
| 8001 | RedisInsight | dev | HTTP |
| 8002 | RedisInsight | test | HTTP |
| 8003 | RedisInsight | prod | HTTP |
| 8025 | MailHog Web UI | dev | HTTP |
| 8026 | MailHog Web UI | test | HTTP |
| 8027 | MailHog Web UI | prod | HTTP |
| 8080 | Keycloak | dev | HTTP |
| 8081 | Mongo Express | dev | HTTP |
| 8082 | Mongo Express | test | HTTP |
| 8083 | Mongo Express | prod | HTTP |
| 8180 | Keycloak | test | HTTP |
| 8280 | Keycloak | prod | HTTP |
| 8380 | Adminer (MSSQL) | dev | HTTP |
| 8381 | Adminer (MSSQL) | test | HTTP |
| 8382 | Adminer (MSSQL) | prod | HTTP |
| 9090 | Prometheus | dev | HTTP |
| 9091 | Prometheus | test | HTTP |
| 9092 | Prometheus | prod | HTTP |
| 9200 | Elasticsearch | dev | HTTP |
| 9201 | Elasticsearch | test | HTTP |
| 9202 | Elasticsearch | prod | HTTP |
| 15672 | RabbitMQ Mgmt | dev | HTTP |
| 15673 | RabbitMQ Mgmt | test | HTTP |
| 15674 | RabbitMQ Mgmt | prod | HTTP |
| 27017 | MongoDB | dev | TCP |
| 27018 | MongoDB | test | TCP |
| 27019 | MongoDB | prod | TCP |

### Ek B — Gereksinim Karşılaştırma Özeti (Tüm Servisler)

| Servis | Sidecar DB | Named Volumes | Healthcheck | UI Bileşeni | .env Değişken Sayısı |
|--------|:----------:|:-------------:|:-----------:|:-----------:|:--------------------:|
| PostgreSQL | — | 2 (data, pgadmin) | EVET | pgAdmin | 7 |
| Redis | — | 2 (data, insight) | EVET | RedisInsight | 3 |
| RabbitMQ | — | 2 (data, logs) | EVET | Dahili Management | 4 |
| Elasticsearch | — | 1 (data) + Kibana 1 | EVET | Kibana | 4 |
| MongoDB | — | 2 (data, config) | EVET | Mongo Express | 6 |
| Monitoring | — | 2 (prom, grafana) | EVET | Grafana | 4 |
| MSSQL | — | 1 (data) | EVET | Adminer | 4 |
| Keycloak | PostgreSQL | 1 (db) | EVET | Dahili Admin | 6 |
| Seq | — | 1 (data) | EVET | Dahili Web UI | 2 |
| MailHog | — | 0 | HAYIR | Dahili Web UI | 2 |
| n8n | — | 1 (data) | EVET | Dahili Web UI | 9 |
